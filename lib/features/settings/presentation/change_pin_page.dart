import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_billingwala_v2/core/widgtes/widgtes.dart';
import 'package:pos_billingwala_v2/features/auth/domain/auth_controller.dart';

class ChangePinPage extends ConsumerStatefulWidget {
  const ChangePinPage({super.key});

  @override
  ConsumerState<ChangePinPage> createState() => _ChangePinPageState();
}

class _ChangePinPageState extends ConsumerState<ChangePinPage> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final session = ref.read(authControllerProvider).session;
    final stored = session?.appPin?.trim() ?? '';
    final current = _current.text.trim();
    final next = _next.text.trim();
    final confirm = _confirm.text.trim();

    if (stored.isNotEmpty && current != stored) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Current PB-PIN is incorrect')),
      );
      return;
    }
    if (next.length != 4 || int.tryParse(next) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New PIN must be 4 digits')),
      );
      return;
    }
    if (next != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New PIN and confirm do not match')),
      );
      return;
    }

    setState(() => _busy = true);
    try {
      final ok =
          await ref.read(authControllerProvider.notifier).updateAppPin(next);
      if (!mounted) return;
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PB-PIN updated')),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to update PIN')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasPin =
        (ref.watch(authControllerProvider).session?.appPin?.trim() ?? '')
            .isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Change PB-PIN')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppCard(
            child: Column(
              children: [
                if (hasPin) ...[
                  AppTextField(
                    controller: _current,
                    label: 'Current PB-PIN',
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    showCounter: false,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                  const SizedBox(height: 12),
                ],
                AppTextField(
                  controller: _next,
                  label: 'New PB-PIN',
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  showCounter: false,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _confirm,
                  label: 'Confirm new PB-PIN',
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  showCounter: false,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                const SizedBox(height: 16),
                AppButton(
                  label: 'Update PIN',
                  isLoading: _busy,
                  onPressed: _save,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
