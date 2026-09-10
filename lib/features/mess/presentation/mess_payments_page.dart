import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pos_billingwala_v2/core/constants/app_colors.dart';
import 'package:pos_billingwala_v2/core/database/app_database.dart';
import 'package:pos_billingwala_v2/core/database/database_provider.dart';
import 'package:pos_billingwala_v2/features/auth/domain/auth_controller.dart';
import 'package:pos_billingwala_v2/features/mess/data/mess_api.dart';
import 'package:pos_billingwala_v2/features/mess/domain/mess_dtos.dart';
import 'package:pos_billingwala_v2/features/mess/domain/mess_providers.dart';
import 'package:pos_billingwala_v2/core/widgtes/widgtes.dart';
import 'package:pos_billingwala_v2/core/widgets/app_module_icon.dart';

class MessPaymentsPage extends ConsumerStatefulWidget {
  const MessPaymentsPage({super.key, this.member});

  final MessMember? member;

  @override
  ConsumerState<MessPaymentsPage> createState() => _MessPaymentsPageState();
}

class _MessPaymentsPageState extends ConsumerState<MessPaymentsPage> {
  AsyncValue<List<MessMemberPaymentDto>> _payments = const AsyncLoading();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    final userId = ref.read(authControllerProvider).session?.userId;
    if (userId == null || userId.isEmpty) {
      setState(
        () => _payments = AsyncError('Login required', StackTrace.current),
      );
      return;
    }
    setState(() => _payments = const AsyncLoading());
    final result = await AsyncValue.guard(() async {
      List<MessMemberPaymentDto> cloud = const [];
      try {
        cloud = await MessApi(ref.read(apiClientProvider))
            .fetchMemberPayments(userId);
      } catch (_) {}
      final local = await ref.read(appDatabaseProvider).getLocalMessPayments(
            memberId: widget.member == null ? null : '${widget.member!.memberId}',
          );
      final merged = <MessMemberPaymentDto>[
        ...cloud,
        ...local.map(
          (e) => MessMemberPaymentDto(
            paymentId: e.localPaymentId,
            memberId: e.memberId,
            memberName: e.memberName,
            paymentMessAmount: e.paymentMessAmount,
            paymentPaidAmount: e.paymentPaidAmount,
            messTotalDays: e.messTotalDays,
            paymentDate: e.paymentDate,
            paymentNetworkStatus: e.paymentNetworkStatus,
            paymentStatus: e.paymentSyncStatus == '1' ? '1' : '0',
          ),
        ),
      ];
      // Dedupe by network status key.
      final seen = <String>{};
      final unique = <MessMemberPaymentDto>[];
      for (final p in merged) {
        final key = p.paymentNetworkStatus ??
            '${p.memberId}|${p.paymentDate}|${p.paymentPaidAmount}';
        if (seen.add(key)) unique.add(p);
      }
      final member = widget.member;
      if (member == null) return unique;
      return unique
          .where((p) => p.memberId == '${member.memberId}')
          .toList();
    });
    if (!mounted) return;
    setState(() => _payments = result);
  }

  Future<void> _addPayment() async {
    final members = ref.read(messMembersProvider).maybeWhen(
          data: (v) => v,
          orElse: () => const <MessMember>[],
        );
    MessMember? selected = widget.member ??
        (members.isNotEmpty ? members.first : null);
    if (selected == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a mess member first')),
      );
      return;
    }

    final messAmt = TextEditingController(text: '3000');
    final paidAmt = TextEditingController(text: '3000');
    var days = '30';
    final month = DateFormat('yyyy-MM').format(DateTime.now());

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: const Text('Add mess payment'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.member == null)
                  AppDropdownFormField<MessMember>(
                    label: 'Member',
                    items: members,
                    itemLabel: (m) => m.memberName,
                    value: selected,
                    onChanged: (m) => setLocal(() => selected = m),
                  ),
                if (widget.member != null)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(selected!.memberName),
                    subtitle: Text(selected!.memberMobileNumber ?? ''),
                  ),
                const SizedBox(height: 12),
                StringDropdownField(
                  label: 'Mess days',
                  value: days,
                  options: const ['15', '30', '45', '60'],
                  onChanged: (v) => setLocal(() => days = v ?? '30'),
                ),
                const SizedBox(height: 12),
                AppTextField(
                      controller: messAmt,
                      label: 'Mess amount',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                    ),
                const SizedBox(height: 12),
                AppTextField(
                      controller: paidAmt,
                      label: 'Paid amount',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                    ),
                const SizedBox(height: 8),
                Text('Payment month: $month'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            AppButton(
            label: 'Save',
            onPressed: () => Navigator.pop(context, true),
          ),
          ],
        ),
      ),
    );

    if (ok != true || selected == null || !mounted) return;
    final userId = ref.read(authControllerProvider).session?.userId;
    if (userId == null) return;

    // Guard: already paid this month.
    final existing = _payments.maybeWhen(data: (v) => v, orElse: () => null);
    if (existing != null &&
        existing.any(
          (p) =>
              p.memberId == '${selected!.memberId}' && p.paymentDate == month,
        )) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Already paid for this month')),
      );
      return;
    }

    setState(() => _busy = true);
    try {
      final network = 'pay_${DateTime.now().millisecondsSinceEpoch}';
      final messAmount = double.tryParse(messAmt.text.trim()) ?? 0;
      final paidAmount = double.tryParse(paidAmt.text.trim()) ?? 0;
      final db = ref.read(appDatabaseProvider);
      if (await db.hasMessPaymentForMonth(
        memberId: '${selected!.memberId}',
        paymentDate: month,
      )) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Already paid for this month')),
        );
        return;
      }

      var success = false;
      try {
        success =
            await MessApi(ref.read(apiClientProvider)).insertMemberPayment(
          userId: userId,
          memberId: '${selected!.memberId}',
          memberName: selected!.memberName,
          paymentMessAmount: messAmt.text.trim(),
          paymentPaidAmount: paidAmt.text.trim(),
          messTotalDays: days,
          paymentDate: month,
          paymentNetworkStatus: network,
        );
      } catch (_) {
        success = false;
      }

      await db.upsertLocalMessPayment(
        memberId: '${selected!.memberId}',
        memberName: selected!.memberName,
        messAmount: messAmount,
        paidAmount: paidAmount,
        messTotalDays: days,
        paymentDate: month,
        paymentNetworkStatus: network,
      );
      if (success) {
        final pending = await db.getPendingMessPayments();
        for (final row in pending) {
          if (row.paymentNetworkStatus == network) {
            await db.markMessPaymentSynced(row.localPaymentId);
          }
        }
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Payment saved'
                : 'Saved offline â€” will sync when online',
          ),
        ),
      );
      await _load();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    messAmt.dispose();
    paidAmt.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.member == null
              ? 'Mess Payments'
              : '${widget.member!.memberName} • Payments',
        ),
        actions: [
          IconButton(
            onPressed: _busy ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      )),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _busy ? null : _addPayment,
        icon: const Icon(Icons.payments_rounded),
        label: const Text('Add payment'),
      ),
      body: Column(children: [
        Container(margin: const EdgeInsets.fromLTRB(16, 10, 16, 0), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: AppColors.teal.withValues(alpha: .08), borderRadius: BorderRadius.circular(20)), child: const Row(children: [AppModuleIcon(icon: Icons.currency_rupee_rounded, color: AppColors.teal, size: 48), SizedBox(width: 12), Expanded(child: Text('Track member payments and balances', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.navy)))])),
        Expanded(child: _payments.when(
        data: (rows) {
          if (rows.isEmpty) {
            return const Center(child: Text('No payments yet'));
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
            itemCount: rows.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final p = rows[index];
              final color = index.isEven ? AppColors.green : AppColors.orange;
          return AppCard(
            accentColor: color,
            padding: EdgeInsets.zero,
            child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.primaryLight,
                    child: Icon(Icons.payments, color: AppColors.primary),
                  ),
                  title: Text(
                    p.memberName,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    '${p.paymentDate} • ${p.messTotalDays} days • '
                    'Mess ${currency.format(p.paymentMessAmount)}',
                  ),
                  trailing: Text(
                    currency.format(p.paymentPaidAmount),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }
}
