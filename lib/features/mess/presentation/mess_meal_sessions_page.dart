import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_billingwala_v2/core/constants/app_colors.dart';
import 'package:pos_billingwala_v2/features/auth/domain/auth_controller.dart';
import 'package:pos_billingwala_v2/features/mess/data/mess_api.dart';
import 'package:pos_billingwala_v2/features/mess/domain/mess_dtos.dart';
import 'package:pos_billingwala_v2/core/widgtes/widgtes.dart';
import 'package:pos_billingwala_v2/core/widgets/app_module_icon.dart';

class MessMealSessionsPage extends ConsumerStatefulWidget {
  const MessMealSessionsPage({super.key});

  @override
  ConsumerState<MessMealSessionsPage> createState() =>
      _MessMealSessionsPageState();
}

Color _sessionColor(int index) => [AppColors.orange, AppColors.purple, AppColors.teal, AppColors.primary][index % 4];

class _MessMealSessionsPageState extends ConsumerState<MessMealSessionsPage> {
  AsyncValue<List<MessMealSessionDto>> _sessions = const AsyncLoading();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    final userId = ref.read(authControllerProvider).session?.userId;
    if (userId == null || userId.isEmpty) {
      setState(
        () => _sessions = AsyncError('Login required', StackTrace.current),
      );
      return;
    }
    setState(() => _sessions = const AsyncLoading());
    final result = await AsyncValue.guard(() async {
      return MessApi(ref.read(apiClientProvider)).fetchMealSessions(userId);
    });
    if (!mounted) return;
    setState(() => _sessions = result);
  }

  Future<void> _edit(MessMealSessionDto session) async {
    final nameCtrl = TextEditingController(text: session.sessionName);
    final prefixCtrl = TextEditingController(text: session.tokenPrefix);
    var start = session.startTime;
    var end = session.endTime;
    var active = session.active;

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: Text(session.sessionId.isEmpty ? 'Add session' : 'Edit session'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
          Container(margin: const EdgeInsets.fromLTRB(16, 10, 16, 8), padding: const EdgeInsets.all(14), decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.teal, AppColors.primary]), borderRadius: BorderRadius.circular(22)), child: const Row(children: [AppModuleIcon(icon: Icons.schedule_rounded, color: Colors.white, size: 48), SizedBox(width: 12), Expanded(child: Text('Plan breakfast, lunch & dinner sessions', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)))])),
                AppTextField(
                      controller: nameCtrl,
                      label: 'Session name',
                    ),
                const SizedBox(height: 12),
                AppTextField(
                      controller: prefixCtrl,
                      label: 'Token prefix',
                    ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Start: $start'),
                  trailing: const Icon(Icons.schedule),
                  onTap: () async {
                    final parts = start.split(':');
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay(
                        hour: int.tryParse(parts.first) ?? 8,
                        minute: parts.length > 1
                            ? int.tryParse(parts[1]) ?? 0
                            : 0,
                      ),
                    );
                    if (picked != null) {
                      setLocal(() {
                        start =
                            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                      });
                    }
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('End: $end'),
                  trailing: const Icon(Icons.schedule),
                  onTap: () async {
                    final parts = end.split(':');
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay(
                        hour: int.tryParse(parts.first) ?? 10,
                        minute: parts.length > 1
                            ? int.tryParse(parts[1]) ?? 0
                            : 0,
                      ),
                    );
                    if (picked != null) {
                      setLocal(() {
                        end =
                            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                      });
                    }
                  },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Active'),
                  value: active,
                  onChanged: (v) => setLocal(() => active = v),
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
            label: 'Save',
            onPressed: () => Navigator.pop(context, true),
          ),
          ],
        ),
      ),
    );

    if (ok != true || !mounted) return;
    final userId = ref.read(authControllerProvider).session?.userId;
    if (userId == null) return;
    setState(() => _saving = true);
    try {
      final success = await MessApi(ref.read(apiClientProvider)).saveMealSession(
        userId: userId,
        sessionId: session.sessionId.isEmpty
            ? 'sess_${DateTime.now().millisecondsSinceEpoch}'
            : session.sessionId,
        sessionName: nameCtrl.text.trim(),
        startTime: start,
        endTime: end,
        tokenPrefix: prefixCtrl.text.trim(),
        isActive: active ? '1' : '0',
        menuNotes: session.menuNotes,
        sortOrder: session.sortOrder,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Session saved' : 'Save failed'),
        ),
      );
      if (success) await _load();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
    nameCtrl.dispose();
    prefixCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meal Sessions'),
        actions: [
          IconButton(
            onPressed: _saving ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saving
            ? null
            : () => _edit(
                  const MessMealSessionDto(
                    sessionId: '',
                    sessionName: '',
                  ),
                ),
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
      body: _sessions.when(
        data: (rows) {
          if (rows.isEmpty) {
            return const Center(child: Text('No meal sessions yet'));
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
            itemCount: rows.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final s = rows[index];
              final color = _sessionColor(index);
          return AppCard(
            accentColor: color,
            padding: EdgeInsets.zero,
            child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: s.active
                        ? AppColors.primaryLight
                        : Colors.grey.shade200,
                    child: Icon(
                      Icons.restaurant_rounded,
                      color: s.active ? AppColors.primary : Colors.grey,
                    ),
                  ),
                  title: Text(
                    s.sessionName,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    '${s.startTime} â€“ ${s.endTime}'
                    '${s.tokenPrefix.isNotEmpty ? ' • ${s.tokenPrefix}' : ''}'
                    '${s.active ? '' : ' • Inactive'}',
                  ),
                  trailing: const Icon(Icons.edit_outlined),
                  onTap: () => _edit(s),
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
