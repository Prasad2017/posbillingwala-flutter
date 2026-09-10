import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_billingwala_v2/core/constants/app_colors.dart';
import 'package:pos_billingwala_v2/core/widgets/brand_logo.dart';
import 'package:pos_billingwala_v2/features/auth/domain/auth_controller.dart';
import 'package:pos_billingwala_v2/features/auth/presentation/device_conflict_dialog.dart';

class MpinPage extends ConsumerStatefulWidget {
  const MpinPage({super.key});

  @override
  ConsumerState<MpinPage> createState() => _MpinPageState();
}

class _MpinPageState extends ConsumerState<MpinPage>
    with SingleTickerProviderStateMixin {
  final _controllers = List.generate(4, (_) => TextEditingController());
  final _focusNodes = List.generate(4, (_) => FocusNode());
  late final AnimationController _animation;

  @override
  void initState() {
    super.initState();
    _animation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authControllerProvider.notifier).setDeviceConflictHandler(
            (message) => showDeviceConflictDialog(context, message),
          );
      _focusNodes.first.requestFocus();
    });
  }

  @override
  void dispose() {
    _animation.dispose();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final n in _focusNodes) {
      n.dispose();
    }
    super.dispose();
  }

  String get _mpin => _controllers.map((c) => c.text).join();

  Future<void> _submit() async {
    if (_mpin.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter your 4-digit PB-PIN')),
      );
      return;
    }
    FocusScope.of(context).unfocus();
    final ok =
        await ref.read(authControllerProvider.notifier).loginWithMpin(_mpin);
    if (!ok && mounted) {
      for (final c in _controllers) {
        c.clear();
      }
      _focusNodes.first.requestFocus();
    }
  }

  void _onDigitChanged(int index, String value) {
    setState(() {});
    if (value.length == 1 && index < 3) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    if (_mpin.length == 4) _submit();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final theme = Theme.of(context);
    final shopName = auth.session?.displayName ?? 'Your Business';

    ref.listen(authControllerProvider, (prev, next) {
      if (next.errorMessage != null &&
          next.errorMessage != prev?.errorMessage &&
          next.errorMessage != 'Device binding cancelled') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage!)),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [
          Positioned(
            top: -120,
            left: -100,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: .12),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: FadeTransition(
                    opacity: CurvedAnimation(
                      parent: _animation,
                      curve: Curves.easeOut,
                    ),
                    child: Column(
                      children: [
                        const BrandLogo(width: 185),
                        const SizedBox(height: 34),
                        Container(
                          width: 78,
                          height: 78,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.primary, AppColors.primaryDark],
                            ),
                            borderRadius: BorderRadius.circular(26),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: .22),
                                blurRadius: 22,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.lock_rounded,
                            color: Colors.white,
                            size: 34,
                          ),
                        ),
                        const SizedBox(height: 22),
                        Text(
                          'Welcome back 👋',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: AppColors.navy,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          shopName,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Enter your secure 4-digit PB-PIN',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.navy.withValues(alpha: .6),
                          ),
                        ),
                        const SizedBox(height: 30),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(4, (index) {
                            final filled = _controllers[index].text.isNotEmpty;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              width: 58,
                              height: 64,
                              margin: const EdgeInsets.symmetric(horizontal: 6),
                              decoration: BoxDecoration(
                                color: filled
                                    ? AppColors.primaryLight
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: filled
                                      ? AppColors.primary
                                      : const Color(0xFFDCE6F5),
                                  width: filled ? 1.8 : 1,
                                ),
                              ),
                              child: TextField(
                                controller: _controllers[index],
                                focusNode: _focusNodes[index],
                                textAlign: TextAlign.center,
                                keyboardType: TextInputType.number,
                                obscureText: true,
                                maxLength: 1,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.navy,
                                ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                decoration: const InputDecoration(
                                  counterText: '',
                                  border: InputBorder.none,
                                  filled: false,
                                  contentPadding: EdgeInsets.only(bottom: 3),
                                ),
                                onChanged: (value) =>
                                    _onDigitChanged(index, value),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 30),
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: FilledButton.icon(
                            onPressed: auth.busy ? null : _submit,
                            icon: auth.busy
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.login_rounded),
                            label: Text(
                              auth.busy ? 'Verifying...' : 'Login Securely',
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextButton.icon(
                          onPressed: auth.busy
                              ? null
                              : () async {
                                  await ref
                                      .read(authControllerProvider.notifier)
                                      .logout();
                                },
                          icon: const Icon(Icons.swap_horiz_rounded),
                          label: const Text('Use a different licence key'),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.green.withValues(alpha: .09),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.verified_user_rounded,
                                size: 17,
                                color: AppColors.green,
                              ),
                              SizedBox(width: 7),
                              Text(
                                'Secure business access',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
