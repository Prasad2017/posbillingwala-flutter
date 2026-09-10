import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pos_billingwala_v2/core/constants/app_colors.dart';
import 'package:pos_billingwala_v2/core/widgtes/widgtes.dart';
import 'package:pos_billingwala_v2/core/widgets/app_module_icon.dart';
import 'package:pos_billingwala_v2/features/auth/domain/auth_controller.dart';
import 'package:pos_billingwala_v2/features/support/data/support_api.dart';
import 'package:pos_billingwala_v2/features/support/data/support_dtos.dart';

class SupportPage extends ConsumerStatefulWidget {
  const SupportPage({super.key});

  @override
  ConsumerState<SupportPage> createState() => _SupportPageState();
}

Color _ticketColor(String status) {
  final value = status.toLowerCase();
  if (value.contains('closed') || value.contains('resolved')) return AppColors.green;
  if (value.contains('pending')) return AppColors.orange;
  if (value.contains('urgent')) return AppColors.red;
  return AppColors.primary;
}

class _SupportPageState extends ConsumerState<SupportPage> {
  List<SupportTicketDto> _tickets = const [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  Future<void> _reload() async {
    final userId = ref.read(authControllerProvider).session?.userId;
    if (userId == null || userId.isEmpty) {
      setState(() => _error = 'Please login first');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = SupportApi(ref.read(apiClientProvider));
      final tickets = await api.getSupportTickets(userId);
      if (!mounted) return;
      setState(() {
        _tickets = tickets;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  Future<void> _showCreateDialog() async {
    final category = TextEditingController(text: 'General');
    final subject = TextEditingController();
    final description = TextEditingController();
    final created = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New support ticket'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(
                controller: category,
                label: 'Category',
              ),
              const SizedBox(height: 8),
              AppTextField(
                controller: subject,
                label: 'Subject',
              ),
              const SizedBox(height: 8),
              AppTextField(
                controller: description,
                label: 'Description',
                maxLines: 4,
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
            label: 'Create',
            expanded: false,
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (created != true || !mounted) {
      category.dispose();
      subject.dispose();
      description.dispose();
      return;
    }

    final userId = ref.read(authControllerProvider).session?.userId;
    if (userId == null || userId.isEmpty) {
      category.dispose();
      subject.dispose();
      description.dispose();
      return;
    }

    final api = SupportApi(ref.read(apiClientProvider));
    final result = await api.createSupportTicket(
      userId: userId,
      category: category.text.trim(),
      subject: subject.text.trim(),
      description: description.text.trim(),
    );
    category.dispose();
    subject.dispose();
    description.dispose();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.isSuccess
              ? (result.message ?? 'Ticket created')
              : (result.message ?? 'Failed to create ticket'),
        ),
      ),
    );
    if (result.isSuccess) await _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Support'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading ? null : _reload,
            icon: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateDialog,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New ticket'),
      ),
      body: _error != null
          ? Center(child: Text(_error!))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _tickets.length + 1,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [AppColors.purple, AppColors.primary]),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      children: [
                        const AppModuleIcon(icon: Icons.support_agent_rounded, color: Colors.white, size: 58),
                        const SizedBox(width: 16),
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('How can we help?', style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w900)),
                            const SizedBox(height: 5),
                            Text(_tickets.isEmpty ? 'Create a ticket and our team will assist you.' : _tickets.length.toString() + ' support tickets', style: const TextStyle(color: Colors.white70)),
                          ],
                        )),
                      ],
                    ),
                  );
                }
                if (_tickets.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 56),
                    child: Column(children: [
                      const AppModuleIcon(icon: Icons.mark_email_read_rounded, color: AppColors.green, size: 72),
                      const SizedBox(height: 14),
                      const Text('No support tickets yet', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
                      const SizedBox(height: 5),
                      Text('Tap New ticket whenever you need help.', style: TextStyle(color: AppColors.navy.withValues(alpha: .55))),
                    ]),
                  );
                }
                final t = _tickets[index - 1];
                    return AppCard(
                      accentColor: _ticketColor(t.status),
                      padding: EdgeInsets.zero,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        onTap: () {
                          final id = t.id;
                          if (id == null || id.isEmpty) return;
                          context.push('/support/$id');
                        },
                        leading: AppModuleIcon(
                          icon: Icons.support_agent_rounded,
                          color: _ticketColor(t.status),
                          size: 50,
                        ),
                        title: Text(
                          t.subject.isEmpty ? 'Ticket' : t.subject,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          [
                            if ((t.ticketNo ?? '').isNotEmpty) t.ticketNo!,
                            if (t.category.isNotEmpty) t.category,
                            if (t.status.isNotEmpty) t.status,
                            if ((t.createdAt ?? '').isNotEmpty) t.createdAt!,
                          ].join(' · '),
                        ),
                        isThreeLine: (t.description).isNotEmpty,
                      ),
                    );
                  },
                ),
    );
  }
}
