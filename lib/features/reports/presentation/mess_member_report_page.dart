import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pos_billingwala_v2/core/constants/app_colors.dart';
import 'package:pos_billingwala_v2/features/mess/domain/mess_providers.dart';
import 'package:pos_billingwala_v2/features/mess/presentation/mess_payments_page.dart';
import 'package:pos_billingwala_v2/core/widgtes/widgtes.dart';
import 'package:pos_billingwala_v2/core/widgets/app_module_icon.dart';

/// Android-style mess member list → open payment history.
class MessMemberReportPage extends ConsumerWidget {
  const MessMemberReportPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(messMembersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mess member report'),
        actions: [
          IconButton(
            tooltip: 'Sync members',
            onPressed: () =>
                ref.read(messControllerProvider.notifier).syncMembers(),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Column(children: [
        Container(margin: const EdgeInsets.fromLTRB(16, 10, 16, 4), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: AppColors.teal.withValues(alpha: .08), borderRadius: BorderRadius.circular(20)), child: const Row(children: [AppModuleIcon(icon: Icons.people_alt_rounded, color: AppColors.teal, size: 48), SizedBox(width: 12), Expanded(child: Text('Member activity and payment history', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.navy)))])),
        Expanded(child: membersAsync.when(
        data: (members) {
          if (members.isEmpty) {
            return const Center(child: Text('No mess members yet'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: members.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final m = members[i];
              final initial = m.memberName.trim().isEmpty
                  ? '?'
                  : m.memberName.trim()[0].toUpperCase();
              return AppCard(
                accentColor: i.isEven ? AppColors.teal : AppColors.purple,
            padding: EdgeInsets.zero,
            child: ListTile(
                  leading: AppModuleIcon(
                    icon: Icons.person_rounded,
                    color: i.isEven ? AppColors.teal : AppColors.purple,
                    size: 48,
                  ),
                  title: Text(
                    m.memberName,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    [
                      if ((m.memberMobileNumber ?? '').trim().isNotEmpty)
                        m.memberMobileNumber!,
                      if (m.memberType.trim().isNotEmpty) m.memberType,
                      if ((m.registrationNo ?? '').trim().isNotEmpty)
                        m.registrationNo!,
                    ].join(' • '),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => MessPaymentsPage(member: m),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
      )),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/mess/payments'),
        icon: const Icon(Icons.payments_rounded),
        label: const Text('All payments'),
      ),
    );
  }
}
