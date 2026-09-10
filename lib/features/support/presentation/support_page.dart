import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pos_billingwala_v2/core/constants/app_colors.dart';
import 'package:pos_billingwala_v2/core/widgtes/widgtes.dart';
import 'package:pos_billingwala_v2/features/auth/domain/auth_controller.dart';
import 'package:pos_billingwala_v2/features/support/data/support_api.dart';
import 'package:pos_billingwala_v2/features/support/data/support_dtos.dart';

class SupportPage extends ConsumerStatefulWidget {
  const SupportPage({super.key});

  @override
  ConsumerState<SupportPage> createState() => _SupportPageState();
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
          : _tickets.isEmpty && !_loading
              ? const Center(child: Text('No support tickets yet'))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _tickets.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final t = _tickets[index];
                    return AppCard(
            padding: EdgeInsets.zero,
            child: ListTile(
                        onTap: () {
                          final id = t.id;
                          if (id == null || id.isEmpty) return;
                          context.push('/support/$id');
                        },
                        leading: CircleAvatar(
                          backgroundColor:
                              AppColors.primary.withValues(alpha: 0.12),
                          child: const Icon(
                            Icons.support_agent_rounded,
                            color: AppColors.primary,
                          ),
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
