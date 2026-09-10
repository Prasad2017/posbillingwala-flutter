import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_billingwala_v2/core/database/app_database.dart';
import 'package:pos_billingwala_v2/core/database/database_provider.dart';
import 'package:pos_billingwala_v2/features/auth/domain/auth_controller.dart';
import 'package:pos_billingwala_v2/features/masters/data/masters_api.dart';
import 'package:pos_billingwala_v2/features/pos/domain/billing_session.dart';

enum FloorTableStatus { available, running, hold, billRequest, blocked, reserved }

class FloorTableView {
  const FloorTableView({
    required this.table,
    required this.status,
    required this.currentAmount,
    this.openSession,
    this.joinedLabel,
    this.isJoinedSecondary = false,
  });

  final PosTable table;
  final FloorTableStatus status;
  final double currentAmount;
  final DiningSession? openSession;
  final String? joinedLabel;
  final bool isJoinedSecondary;

  String get statusLabel {
    switch (status) {
      case FloorTableStatus.available:
        return 'Available';
      case FloorTableStatus.running:
        return 'Running';
      case FloorTableStatus.hold:
        return 'Hold';
      case FloorTableStatus.billRequest:
        return 'Bill requested';
      case FloorTableStatus.blocked:
        return 'Blocked';
      case FloorTableStatus.reserved:
        return 'Reserved';
    }
  }

  /// Cart / billing always uses the primary table number.
  String get billingTableNumber =>
      openSession?.primaryTableNumber ?? table.tableNumber;
}

final posTablesProvider = StreamProvider<List<PosTable>>((ref) async* {
  final db = ref.watch(appDatabaseProvider);
  await db.seedDefaultTablesIfEmpty();
  yield* db.watchActivePosTables();
});

final openDiningSessionsProvider = StreamProvider<List<DiningSession>>((ref) {
  return ref.watch(appDatabaseProvider).watchOpenDiningSessions();
});

final allCartItemsProvider = StreamProvider<List<CartItem>>((ref) {
  return ref.watch(appDatabaseProvider).watchAllCartItems();
});

final floorTablesProvider = Provider<List<FloorTableView>>((ref) {
  final tables = ref.watch(posTablesProvider).maybeWhen(
        data: (rows) => rows,
        orElse: () => const <PosTable>[],
      );
  final sessions = ref.watch(openDiningSessionsProvider).maybeWhen(
        data: (rows) => rows,
        orElse: () => const <DiningSession>[],
      );
  final cart = ref.watch(allCartItemsProvider).maybeWhen(
        data: (rows) => rows,
        orElse: () => const <CartItem>[],
      );
  final db = ref.watch(appDatabaseProvider);

  final totals = <String, double>{};
  for (final item in cart) {
    if (item.cartScope.isEmpty) continue;
    final line = item.unitPrice * item.quantity * (1 + item.gstPercent / 100);
    totals[item.cartScope] = (totals[item.cartScope] ?? 0) + line;
  }

  final sessionByAnyTable = <String, DiningSession>{};
  for (final s in sessions) {
    sessionByAnyTable[s.primaryTableNumber] = s;
    for (final joined in db.parseJoinedTables(s.joinedTableNumbers)) {
      sessionByAnyTable[joined] = s;
    }
  }

  return tables.map((table) {
    final override = table.statusOverride?.toUpperCase();
    if (override == 'BLOCKED') {
      return FloorTableView(
        table: table,
        status: FloorTableStatus.blocked,
        currentAmount: 0,
      );
    }
    if (override == 'RESERVED') {
      return FloorTableView(
        table: table,
        status: FloorTableStatus.reserved,
        currentAmount: 0,
      );
    }

    final session = sessionByAnyTable[table.tableNumber];
    final primary = session?.primaryTableNumber ?? table.tableNumber;
    final amount = double.parse((totals[primary] ?? 0).toStringAsFixed(2));
    final joined = session == null
        ? const <String>[]
        : [
            session.primaryTableNumber,
            ...db.parseJoinedTables(session.joinedTableNumbers),
          ];
    final joinedLabel = joined.length > 1
        ? joined.map((e) => 'T$e').join(' + ')
        : null;
    final isSecondary = session != null &&
        session.primaryTableNumber != table.tableNumber;

    FloorTableStatus status;
    if (session == null && amount <= 0) {
      status = FloorTableStatus.available;
    } else {
      switch (session?.sessionStatus) {
        case 'HOLD':
          status = FloorTableStatus.hold;
        case 'BILL_REQUEST':
          status = FloorTableStatus.billRequest;
        case 'PARTIALLY_PAID':
          status = FloorTableStatus.running;
        default:
          status = FloorTableStatus.running;
      }
    }

    return FloorTableView(
      table: table,
      status: status,
      currentAmount: isSecondary ? 0 : amount,
      openSession: session,
      joinedLabel: joinedLabel,
      isJoinedSecondary: isSecondary,
    );
  }).toList();
});

class TablesController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> syncTables() async {
    final userId = ref.read(authControllerProvider).session?.userId;
    if (userId == null || userId.isEmpty) {
      state = AsyncError('Please login first', StackTrace.current);
      return;
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final db = ref.read(appDatabaseProvider);
      final api = MastersApi(ref.read(apiClientProvider));
      try {
        final tables = await api.fetchPosTables(userId);
        if (tables.isNotEmpty) {
          await db.replacePosTables(
            tables
                .where((e) => e.tableId > 0 && e.tableNumber.trim().isNotEmpty)
                .map(
                  (e) => PosTablesCompanion.insert(
                    tableId: Value(e.tableId),
                    tableNumber: e.tableNumber,
                    displayName: Value(
                      e.tableName.isEmpty
                          ? 'Table ${e.tableNumber}'
                          : e.tableName,
                    ),
                    capacity: Value(e.capacity),
                    areaId: Value(e.areaId),
                    tableActive: Value(e.tableActive),
                    sortOrder: Value(e.sortOrder),
                    statusOverride: Value(e.statusOverride),
                    posTableNetworkStatus: Value(e.posTableNetworkStatus),
                  ),
                )
                .toList(),
          );
        } else {
          await db.seedDefaultTablesIfEmpty();
        }
      } catch (_) {
        await db.seedDefaultTablesIfEmpty();
      }
    });
  }

  Future<BillingSession> openTable(FloorTableView floor) async {
    if (floor.status == FloorTableStatus.blocked ||
        floor.status == FloorTableStatus.reserved) {
      throw StateError('Table is ${floor.statusLabel.toLowerCase()}');
    }

    final db = ref.read(appDatabaseProvider);
    final session =
        await db.openOrGetDiningSession(floor.billingTableNumber);
    final label = floor.joinedLabel ??
        (floor.table.displayName.isEmpty
            ? floor.table.tableNumber
            : floor.table.displayName);
    ref.read(billingSessionProvider.notifier).startTableBilling(
          tableNumber: session.primaryTableNumber,
          tableName: label,
          diningSessionId: session.sessionId,
        );
    return ref.read(billingSessionProvider);
  }

  Future<DiningSession> joinTables({
    required String primaryTable,
    required String secondaryTable,
  }) async {
    final session = await ref.read(appDatabaseProvider).joinTables(
          primaryTable: primaryTable,
          secondaryTable: secondaryTable,
        );
    return session;
  }

  Future<void> splitJoined(int sessionId) async {
    await ref.read(appDatabaseProvider).splitJoinedTables(sessionId);
  }

  Future<void> transferTable({
    required String fromTable,
    required String toTable,
  }) async {
    await ref.read(appDatabaseProvider).transferTable(
          fromTable: fromTable,
          toTable: toTable,
        );
  }

  Future<void> setSessionStatus({
    required int sessionId,
    required String status,
  }) async {
    await ref.read(appDatabaseProvider).setDiningSessionStatus(
          sessionId: sessionId,
          status: status,
        );
  }

  Future<void> moveItems({
    required String fromTable,
    required String toTable,
    required List<CartItem> items,
  }) async {
    await ref.read(appDatabaseProvider).moveCartItemsToTable(
          fromTable: fromTable,
          toTable: toTable,
          items: items,
        );
  }
}

final tablesControllerProvider =
    NotifierProvider<TablesController, AsyncValue<void>>(
  TablesController.new,
);
