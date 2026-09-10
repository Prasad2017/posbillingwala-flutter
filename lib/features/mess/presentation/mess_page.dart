import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gal/gal.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:pos_billingwala_v2/core/constants/app_colors.dart';
import 'package:pos_billingwala_v2/core/widgets/app_module_icon.dart';
import 'package:pos_billingwala_v2/core/database/app_database.dart';
import 'package:pos_billingwala_v2/features/mess/domain/mess_providers.dart';
import 'package:pos_billingwala_v2/features/mess/presentation/mess_coupon_page.dart';
import 'package:pos_billingwala_v2/features/mess/presentation/mess_token_qr_page.dart';
import 'package:pos_billingwala_v2/features/print/domain/print_providers.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:ui' as ui;
import 'package:pos_billingwala_v2/core/widgtes/widgtes.dart';

class MessPage extends ConsumerStatefulWidget {
  const MessPage({super.key});

  @override
  ConsumerState<MessPage> createState() => _MessPageState();
}

class _MessPageState extends ConsumerState<MessPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _verifyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _tabs.addListener(() {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(messCommonQrProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    _verifyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final syncState = ref.watch(messControllerProvider);
    final isSyncing = syncState.isLoading;

    ref.listen(messControllerProvider, (prev, next) {
      next.whenOrNull(
        error: (error, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$error')),
          );
        },
      );
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mess'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Members'),
            Tab(text: 'Tokens'),
            Tab(text: 'Common QR'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Sync members',
            onPressed: isSyncing
                ? null
                : () => ref.read(messControllerProvider.notifier).syncMembers(),
            icon: isSyncing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.cloud_download_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          Material(
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  _MessHubChip(
                    icon: Icons.groups_rounded,
                    label: 'Members',
                    onTap: () => _tabs.animateTo(0),
                  ),
                  _MessHubChip(
                    icon: Icons.qr_code_2_rounded,
                    label: 'Manage QR',
                    onTap: () => _tabs.animateTo(2),
                  ),
                  _MessHubChip(
                    icon: Icons.today_rounded,
                    label: "Today's tokens",
                    onTap: () => _tabs.animateTo(1),
                  ),
                  _MessHubChip(
                    icon: Icons.qr_code_scanner_rounded,
                    label: 'QR meal tokens',
                    onTap: () => context.push('/mess/meal-tokens-today'),
                  ),
                  _MessHubChip(
                    icon: Icons.schedule_rounded,
                    label: 'Meal sessions',
                    onTap: () => context.push('/mess/meal-sessions'),
                  ),
                  _MessHubChip(
                    icon: Icons.payments_rounded,
                    label: 'Payments',
                    onTap: () => context.push('/mess/payments'),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _MembersTab(
                  isSyncing: isSyncing,
                  onEditMember: (m) => _editMember(context, m),
                ),
                _TokensTab(verifyController: _verifyController),
                const _CommonQrTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _tabs.index == 0
          ? FloatingActionButton.extended(
              onPressed: () => _addMember(context),
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: const Text('Add member'),
            )
          : null,
    );
  }

  Future<void> _editMember(BuildContext context, MessMember member) async {
    final nameCtrl = TextEditingController(text: member.memberName);
    final mobileCtrl =
        TextEditingController(text: member.memberMobileNumber ?? '');
    final regCtrl = TextEditingController(text: member.registrationNo ?? '');

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit mess member'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(
                      controller: nameCtrl,
                      label: 'Name',
                    ),
            AppTextField(
                      controller: mobileCtrl,
                      label: 'Mobile',
                      keyboardType: TextInputType.phone,
                    ),
            AppTextField(
                      controller: regCtrl,
                      label: 'Registration no',
                    ),
          ],
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
    );

    if (ok != true || !context.mounted) return;
    final name = nameCtrl.text.trim();
    if (name.isEmpty) return;
    await ref.read(messControllerProvider.notifier).updateLocalMember(
          memberId: member.memberId,
          name: name,
          mobile:
              mobileCtrl.text.trim().isEmpty ? null : mobileCtrl.text.trim(),
          registrationNo:
              regCtrl.text.trim().isEmpty ? null : regCtrl.text.trim(),
        );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Member updated')),
    );
  }

  Future<void> _addMember(BuildContext context) async {
    final nameCtrl = TextEditingController();
    final mobileCtrl = TextEditingController();
    final regCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add mess member'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(
                      controller: nameCtrl,
                      label: 'Name',
                    ),
            AppTextField(
                      controller: mobileCtrl,
                      label: 'Mobile',
                      keyboardType: TextInputType.phone,
                    ),
            AppTextField(
                      controller: regCtrl,
                      label: 'Registration no',
                    ),
          ],
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
    );

    if (ok != true || !context.mounted) return;
    final name = nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name is required')),
      );
      return;
    }

    await ref.read(messControllerProvider.notifier).addLocalMember(
          name: name,
          mobile: mobileCtrl.text.trim().isEmpty ? null : mobileCtrl.text.trim(),
          registrationNo:
              regCtrl.text.trim().isEmpty ? null : regCtrl.text.trim(),
        );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Member saved locally')),
    );
  }
}

class _MessHubChip extends StatelessWidget {
  const _MessHubChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const colors = [AppColors.primary, AppColors.orange, AppColors.green, AppColors.purple, AppColors.red, AppColors.teal];
    final color = colors[icon.codePoint % colors.length];
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        avatar: Icon(icon, size: 18, color: color),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: color.withValues(alpha: .09),
        side: BorderSide(color: color.withValues(alpha: .15)),
        onPressed: onTap,
      ),
    );
  }
}

class _MembersTab extends ConsumerWidget {
  const _MembersTab({
    required this.isSyncing,
    required this.onEditMember,
  });

  final bool isSyncing;
  final void Function(MessMember member) onEditMember;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(messMembersProvider);

    return membersAsync.when(
      data: (members) {
        if (members.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.groups_outlined,
                    size: 56,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No mess members yet',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Sync from cloud or add a local member.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  AppButton(
                    label: 'Sync members',
                    icon: Icons.cloud_download_rounded,
                    expanded: false,
                    onPressed: isSyncing
                        ? null
                        : () => ref
                            .read(messControllerProvider.notifier)
                            .syncMembers(),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
          itemCount: members.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final member = members[index];
            return AppCard(
            padding: EdgeInsets.zero,
            child: ListTile(
                leading: AppModuleIcon(
                  icon: Icons.person_rounded,
                  color: member.memberType.toLowerCase().contains('staff')
                      ? AppColors.purple
                      : AppColors.teal,
                  size: 48,
                ),
                title: Text(
                  member.memberName,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  [
                    if (member.registrationNo?.isNotEmpty == true)
                      member.registrationNo!,
                    if (member.memberMobileNumber?.isNotEmpty == true)
                      member.memberMobileNumber!,
                    member.memberType,
                  ].join(' • '),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Payments',
                      onPressed: () => context.push(
                        '/mess/payments',
                        extra: member,
                      ),
                      icon: const Icon(Icons.payments_outlined),
                    ),
                    IconButton(
                      tooltip: 'Edit',
                      onPressed: () => onEditMember(member),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    IconButton(
                      tooltip: 'Paper coupon',
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => MessCouponPage(member: member),
                          ),
                        );
                      },
                      icon: const Icon(Icons.confirmation_number_outlined),
                    ),
                    IconButton(
                      tooltip: 'Issue token',
                      onPressed: () => _issueToken(context, ref, member),
                      icon: const Icon(Icons.qr_code_2_rounded),
                    ),
                  ],
                ),
                onLongPress: () => onEditMember(member),
                onTap: () => _issueToken(context, ref, member),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
    );
  }

  Future<void> _issueToken(
    BuildContext context,
    WidgetRef ref,
    MessMember member,
  ) async {
    try {
      final result = await ref
          .read(messControllerProvider.notifier)
          .issueMemberToken(member);
      if (!context.mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => MessTokenQrPage(
            title: 'Member token',
            subtitle: member.memberName,
            payload: result.payload,
            tokenCode: result.token.tokenCode,
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
  }
}

class _TokensTab extends ConsumerWidget {
  const _TokensTab({required this.verifyController});

  final TextEditingController verifyController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokensAsync = ref.watch(todayMessTokensProvider);
    final time = DateFormat('HH:mm');

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: AppTextField(
                      controller: verifyController,
                      label: 'Scan / paste QR or token code',
                    ),
              ),
              const SizedBox(width: 8),
              AppButton(
            label: 'Verify',
            onPressed: () async {
                  final token = await ref
                      .read(messControllerProvider.notifier)
                      .verifyRaw(verifyController.text);
                  if (!context.mounted) return;
                  if (token == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Token not found')),
                    );
                    return;
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Verified: ${token.memberName ?? token.tokenCode}',
                      ),
                    ),
                  );
                  verifyController.clear();
                },
          ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                tooltip: 'Camera scan',
                onPressed: () => context.push('/mess/scan'),
                icon: const Icon(Icons.qr_code_scanner_rounded),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: AppButton(
              label: 'Issue walk-in token',
              icon: Icons.add_rounded,
              variant: AppButtonVariant.outlined,
              expanded: false,
              onPressed: () async {
                final nameCtrl = TextEditingController();
                final mobileCtrl = TextEditingController();
                final amountCtrl = TextEditingController(text: '0');
                var messType = 'Lunch';
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (context) => StatefulBuilder(
                    builder: (context, setLocal) => AlertDialog(
                      title: const Text('Walk-in token'),
                      content: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AppTextField(
                              controller: nameCtrl,
                              label: 'Customer name',
                            ),
                            const SizedBox(height: 12),
                            AppTextField(
                              controller: mobileCtrl,
                              label: 'Mobile',
                              keyboardType: TextInputType.phone,
                            ),
                            const SizedBox(height: 12),
                            AppTextField(
                              controller: amountCtrl,
                              label: 'Amount',
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                            ),
                            const SizedBox(height: 12),
                            StringDropdownField(
                              label: 'Meal',
                              value: messType,
                              options: const ['Breakfast', 'Lunch', 'Dinner'],
                              onChanged: (v) {
                                if (v != null) setLocal(() => messType = v);
                              },
                            ),
                          ],
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        AppButton(
                          label: 'Issue',
                          expanded: false,
                          onPressed: () => Navigator.pop(context, true),
                        ),
                      ],
                    ),
                  ),
                );
                if (ok != true || !context.mounted) return;
                final result = await ref
                    .read(messControllerProvider.notifier)
                    .issueWalkInToken(
                      name: nameCtrl.text,
                      mobile: mobileCtrl.text,
                      messType: messType,
                      amount: double.tryParse(amountCtrl.text.trim()) ?? 0,
                    );
                if (!context.mounted) return;
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => MessTokenQrPage(
                      title: 'Walk-in token',
                      subtitle: result.token.memberName ?? 'Walk-in',
                      payload: result.payload,
                      tokenCode: result.token.tokenCode,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: tokensAsync.when(
            data: (tokens) {
              if (tokens.isEmpty) {
                return const Center(child: Text('No tokens issued today'));
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount: tokens.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final token = tokens[index];
                  final verified = token.tokenState == 'verified';
                  return AppCard(
            padding: EdgeInsets.zero,
            child: ListTile(
                      leading: Icon(
                        verified
                            ? Icons.verified_rounded
                            : Icons.qr_code_rounded,
                        color: verified ? AppColors.success : AppColors.primary,
                      ),
                      title: Text(
                        token.memberName ?? 'Token',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        '${token.messType} Â· ${token.memberType} Â· ${time.format(token.tokenDate)}',
                      ),
                      trailing: Text(
                        verified ? 'Verified' : 'Active',
                        style: TextStyle(
                          color:
                              verified ? AppColors.success : AppColors.warning,
                          fontWeight: FontWeight.w700,
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
        ),
      ],
    );
  }
}

class _CommonQrTab extends ConsumerStatefulWidget {
  const _CommonQrTab();

  @override
  ConsumerState<_CommonQrTab> createState() => _CommonQrTabState();
}

class _CommonQrTabState extends ConsumerState<_CommonQrTab> {
  final GlobalKey _qrKey = GlobalKey();

  Future<void> _shareUrl(BuildContext context, String url) async {
    final box = context.findRenderObject() as RenderBox?;
    await SharePlus.instance.share(
      ShareParams(
        text: url,
        subject: 'Mess Common QR',
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      ),
    );
  }

  Future<void> _printUrl(WidgetRef ref, BuildContext context, String url) async {
    final result = await ref.read(printServiceProvider).printRawText(
          'Mess Common QR\n\n$url\n',
          label: 'Mess QR',
        );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.message ?? result.outcome.name)),
    );
  }

  Future<void> _saveToGallery(BuildContext context) async {
    try {
      final boundary =
          _qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        throw StateError('QR not ready');
      }
      final image = await boundary.toImage(pixelRatio: 3);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData?.buffer.asUint8List();
      if (bytes == null) {
        throw StateError('Could not capture QR image');
      }
      final granted = await Gal.requestAccess(toAlbum: true);
      if (!granted) {
        throw StateError('Gallery permission denied');
      }
      await Gal.putImageBytes(bytes, name: 'mess_qr_${DateTime.now().millisecondsSinceEpoch}');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('QR saved to gallery')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final qrAsync = ref.watch(messCommonQrProvider);
    final controller = ref.read(messCommonQrProvider.notifier);

    return qrAsync.when(
      data: (qr) {
        if (qr == null || qr.qrUrl.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.qr_code_2_outlined, size: 56),
                  const SizedBox(height: 12),
                  Text(
                    'No active common Mess QR',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Generate a public QR so diners can request meal tokens.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  AppButton(
            label: 'Generate QR',
            icon: Icons.auto_awesome,
            onPressed: () => controller.generate(),
            expanded: false,
          ),
                  const SizedBox(height: 8),
                  AppButton(
                        label: 'Refresh',
                        icon: Icons.refresh_rounded,
                        variant: AppButtonVariant.outlined,
                        onPressed: () => controller.load(),
                        expanded: false,
                      ),
                ],
              ),
            ),
          );
        }

        final active = qr.status.toUpperCase() == 'ACTIVE';

        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            AppCard(
            padding: const EdgeInsets.all(24),
            child: Column(
                  children: [
                    Text(
                      qr.messLabel?.isNotEmpty == true
                          ? qr.messLabel!
                          : 'Mess Common QR',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    if (qr.branchLabel?.isNotEmpty == true) ...[
                      const SizedBox(height: 4),
                      Text(qr.branchLabel!),
                    ],
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: active
                            ? AppColors.success.withValues(alpha: 0.12)
                            : AppColors.danger.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        qr.status,
                        style: TextStyle(
                          color: active ? AppColors.success : AppColors.danger,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    RepaintBoundary(
                      key: _qrKey,
                      child: QrImageView(
                        data: qr.qrUrl,
                        size: 240,
                        backgroundColor: Colors.white,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: AppColors.primary,
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SelectableText(
                      qr.qrUrl,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                AppButton(
                        label: 'Refresh',
                        icon: Icons.refresh_rounded,
                        variant: AppButtonVariant.outlined,
                        onPressed: () => controller.load(),
                        expanded: false,
                      ),
                AppButton(
            label: 'Generate',
            icon: Icons.auto_awesome,
            onPressed: () => controller.generate(),
            expanded: false,
          ),
                AppButton(
                        label: 'Regenerate',
                        icon: Icons.autorenew_rounded,
                        onPressed: () => controller.regenerate(),
                        expanded: false,
                      ),
                AppButton(
            label: 'Share URL',
            icon: Icons.ios_share_rounded,
            variant: AppButtonVariant.outlined,
            expanded: false,
            onPressed: () => _shareUrl(context, qr.qrUrl),
          ),
                AppButton(
                        label: 'Save image',
                        icon: Icons.save_alt_rounded,
                        variant: AppButtonVariant.outlined,
                        onPressed: () => _saveToGallery(context),
                        expanded: false,
                      ),
                AppButton(
            label: 'Print',
            icon: Icons.print_rounded,
            variant: AppButtonVariant.outlined,
            expanded: false,
            onPressed: () => _printUrl(ref, context, qr.qrUrl),
          ),
                if (active)
                  AppButton(
                        label: 'Deactivate',
                        icon: Icons.block_rounded,
                        variant: AppButtonVariant.outlined,
                        onPressed: () => controller.setStatus('INACTIVE'),
                        expanded: false,
                      )
                else
                  AppButton(
            label: 'Activate',
            icon: Icons.check_circle_outline_rounded,
            onPressed: () => controller.setStatus('ACTIVE'),
            expanded: false,
          ),
              ],
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
            onPressed: () => controller.load(),
            expanded: false,
          ),
            ],
          ),
        ),
      ),
    );
  }
}
