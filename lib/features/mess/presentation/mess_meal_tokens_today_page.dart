import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pos_billingwala_v2/core/constants/app_colors.dart';
import 'package:pos_billingwala_v2/features/auth/data/device_identity_service.dart';
import 'package:pos_billingwala_v2/features/auth/domain/auth_controller.dart';
import 'package:pos_billingwala_v2/features/mess/data/mess_api.dart';
import 'package:pos_billingwala_v2/features/mess/domain/mess_dtos.dart';
import 'package:pos_billingwala_v2/features/print/domain/print_providers.dart';
import 'package:pos_billingwala_v2/features/print/domain/print_service.dart';
import 'package:pos_billingwala_v2/core/widgtes/widgtes.dart';
import 'package:pos_billingwala_v2/core/widgets/app_module_icon.dart';

class MessMealTokensTodayPage extends ConsumerStatefulWidget {
  const MessMealTokensTodayPage({super.key});

  @override
  ConsumerState<MessMealTokensTodayPage> createState() =>
      _MessMealTokensTodayPageState();
}

class _MessMealTokensTodayPageState
    extends ConsumerState<MessMealTokensTodayPage> {
  AsyncValue<MessMealTokenTodayResult> _state = const AsyncLoading();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    final userId = ref.read(authControllerProvider).session?.userId;
    if (userId == null || userId.isEmpty) {
      setState(() {
        _state = AsyncError('Login required', StackTrace.current);
      });
      return;
    }
    setState(() => _state = const AsyncLoading());
    final next = await AsyncValue.guard(
      () => MessApi(ref.read(apiClientProvider)).fetchMealTokensToday(userId),
    );
    if (!mounted) return;
    setState(() => _state = next);
  }

  Future<void> _printToken(MessMealTokenDto token) async {
    final userId = ref.read(authControllerProvider).session?.userId;
    if (userId == null) return;
    setState(() => _busy = true);
    try {
      final text = StringBuffer()
        ..writeln('MESS MEAL TOKEN')
        ..writeln(token.tokenNumber)
        ..writeln(token.mealSession)
        ..writeln(token.memberName)
        ..writeln(token.registrationNo)
        ..writeln(token.date)
        ..writeln();
      final printResult = await ref.read(printServiceProvider).printRawText(
            text.toString(),
            label: 'Mess meal token',
          );
      final device = await DeviceIdentityService().resolve();
      final ok = printResult.outcome != PrintOutcome.failed &&
          printResult.outcome != PrintOutcome.previewOnly;
      await MessApi(ref.read(apiClientProvider)).ackMealTokenPrint(
        userId: userId,
        tokenId: token.tokenId,
        result: ok ? 'PRINTED' : 'PRINT_FAILED',
        deviceId: device.deviceId,
        deviceName: device.deviceName,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(printResult.message ?? printResult.outcome.name)),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancelToken(MessMealTokenDto token) async {
    final userId = ref.read(authControllerProvider).session?.userId;
    if (userId == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel token'),
        content: Text('Cancel ${token.tokenNumber}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          AppButton(
            label: 'Cancel token',
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _busy = true);
    try {
      await MessApi(ref.read(apiClientProvider)).cancelMealToken(
        userId: userId,
        tokenId: token.tokenId,
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = DateFormat('dd MMM yyyy').format(DateTime.now());
    return Scaffold(
      appBar: AppBar(
        title: Text('Meal tokens · $today'),
        actions: [
          IconButton(
            onPressed: _busy ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _state.when(
        data: (data) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
          Container(margin: const EdgeInsets.fromLTRB(16, 10, 16, 8), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: AppColors.orange.withValues(alpha: .10), borderRadius: BorderRadius.circular(20)), child: const Row(children: [AppModuleIcon(icon: Icons.confirmation_number_rounded, color: AppColors.orange, size: 48), SizedBox(width: 12), Expanded(child: Text('Today’s meal tokens at a glance', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.navy)))])),
              if (data.sessionCounts.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: AppCard(
                    accentColor: AppColors.primary,
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const AppModuleIcon(icon: Icons.confirmation_number_rounded, color: AppColors.primary, size: 48),
                        const SizedBox(height: 8),
                        ...data.sessionCounts
                          .map(
                            (c) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                '${c.sessionName} • Gen ${c.generated} · '
                                'Printed ${c.printed} · Pending ${c.pending} · '
                                'Failed ${c.failed}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
              Expanded(
                child: data.tokens.isEmpty
                    ? const Center(child: Text('No QR meal tokens today'))
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: data.tokens.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final t = data.tokens[i];
                          return AppCard(
                            padding: EdgeInsets.zero,
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    AppColors.primary.withValues(alpha: 0.12),
                                child: const Icon(
                                  Icons.confirmation_number_outlined,
                                  color: AppColors.primary,
                                ),
                              ),
                              title: Text(
                                t.tokenNumber.isEmpty
                                    ? t.tokenId
                                    : t.tokenNumber,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              subtitle: Text(
                                [
                                  if (t.memberName.isNotEmpty) t.memberName,
                                  if (t.mealSession.isNotEmpty) t.mealSession,
                                  if (t.printStatus.isNotEmpty) t.printStatus,
                                ].join(' · '),
                              ),
                              trailing: Wrap(
                                spacing: 4,
                                children: [
                                  IconButton(
                                    tooltip: 'Print',
                                    onPressed:
                                        _busy ? null : () => _printToken(t),
                                    icon: const Icon(Icons.print_rounded),
                                  ),
                                  IconButton(
                                    tooltip: 'Cancel',
                                    onPressed:
                                        _busy ? null : () => _cancelToken(t),
                                    icon: const Icon(Icons.cancel_outlined),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('$e', textAlign: TextAlign.center),
                const SizedBox(height: 12),
                AppButton(
                  label: 'Retry',
                  expanded: false,
                  onPressed: _load,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
