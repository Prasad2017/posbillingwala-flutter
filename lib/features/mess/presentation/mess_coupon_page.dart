import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pos_billingwala_v2/core/constants/app_colors.dart';
import 'package:pos_billingwala_v2/core/database/app_database.dart';
import 'package:pos_billingwala_v2/core/database/database_provider.dart';
import 'package:pos_billingwala_v2/features/auth/domain/auth_controller.dart';
import 'package:pos_billingwala_v2/features/mess/data/mess_api.dart';
import 'package:pos_billingwala_v2/features/print/domain/print_providers.dart';
import 'package:pos_billingwala_v2/features/print/domain/print_service.dart';
import 'package:pos_billingwala_v2/core/widgtes/widgtes.dart';

/// Android InvoiceMess / CouponBluetoothPrint â€” paper meal coupon.
class MessCouponPage extends ConsumerStatefulWidget {
  const MessCouponPage({super.key, required this.member});

  final MessMember member;

  @override
  ConsumerState<MessCouponPage> createState() => _MessCouponPageState();
}

class _MessCouponPageState extends ConsumerState<MessCouponPage> {
  String _messType = 'Lunch';
  bool _busy = false;
  int _used = 0;
  int _limit = 30;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadCounts);
  }

  Future<void> _loadCounts() async {
    final db = ref.read(appDatabaseProvider);
    final used = await db.countMessCouponsForMember(widget.member.memberName);
    final payments = await db.getLocalMessPayments(
      memberId: '${widget.member.memberId}',
    );
    var limit = 30;
    if (payments.isNotEmpty) {
      limit = int.tryParse(payments.first.messTotalDays) ?? 30;
    }
    if (!mounted) return;
    setState(() {
      _used = used;
      _limit = limit;
    });
  }

  Future<void> _issueAndPrint() async {
    if (_used >= _limit) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Coupon limit $_limit reached for this member')),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      final db = ref.read(appDatabaseProvider);
      final couponNo = _used + 1;
      final id = await db.issueMessCoupon(
        memberId: '${widget.member.memberId}',
        memberName: widget.member.memberName,
        messType: _messType,
      );
      final now = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());
      final shop = ref.read(authControllerProvider).session?.shopName ??
          'POS Billingwala';
      final text = StringBuffer()
        ..writeln(shop)
        ..writeln('MESS COUPON')
        ..writeln('-' * 32)
        ..writeln(widget.member.memberName)
        ..writeln(_messType)
        ..writeln(now)
        ..writeln('MESS COUPON No: $couponNo')
        ..writeln('-' * 32)
        ..writeln();
      final printResult = await ref.read(printServiceProvider).printRawText(
            text.toString(),
            label: 'Mess coupon',
          );

      final userId = ref.read(authControllerProvider).session?.userId;
      if (userId != null && userId.isNotEmpty) {
        final row = await db.getMessInvoiceById(id);
        if (row != null) {
          final ok =
              await MessApi(ref.read(apiClientProvider)).insertMessInvoice(
            userId: userId,
            memberName: row.memberName,
            messType: row.messType,
            messInvoiceDate:
                DateFormat('yyyy-MM-dd HH:mm:ss').format(row.messInvoiceDate),
            messInvoiceNetworkStatus: row.messInvoiceNetworkStatus,
            messInvoiceStatus: '0',
          );
          if (ok) await db.markMessInvoiceSynced(id);
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            printResult.outcome == PrintOutcome.failed
                ? (printResult.message ?? 'Coupon saved (print failed)')
                : 'Coupon #$couponNo issued',
          ),
        ),
      );
      await _loadCounts();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Paper mess coupon')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppCard(
            padding: EdgeInsets.zero,
            child: ListTile(
              leading: const Icon(Icons.person_outline, color: AppColors.primary),
              title: Text(
                widget.member.memberName,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text(
                'Used $_used / $_limit coupons',
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Meal type',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ['Lunch', 'Dinner', 'Breakfast', 'Snacks']
                .map(
                  (t) => ChoiceChip(
                    label: Text(t),
                    selected: _messType == t,
                    onSelected: _busy
                        ? null
                        : (_) => setState(() => _messType = t),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 24),
          AppButton(
            label: 'Print coupon',
            isLoading: _busy,
            expanded: false,
            onPressed: _issueAndPrint,
          ),
        ],
      ),
    );
  }
}
