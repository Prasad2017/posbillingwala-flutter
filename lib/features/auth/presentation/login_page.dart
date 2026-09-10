import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pos_billingwala_v2/core/constants/app_colors.dart';
import 'package:pos_billingwala_v2/core/constants/app_constants.dart';
import 'package:pos_billingwala_v2/core/widgets/brand_logo.dart';
import 'package:pos_billingwala_v2/core/widgtes/widgtes.dart';
import 'package:pos_billingwala_v2/features/auth/domain/auth_controller.dart';
import 'package:pos_billingwala_v2/features/auth/presentation/device_conflict_dialog.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _licenceController = TextEditingController();
  late final AnimationController _animation;

  @override
  void initState() {
    super.initState();
    _animation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authControllerProvider.notifier).setDeviceConflictHandler(
            (message) => showDeviceConflictDialog(context, message),
          );
    });
  }

  @override
  void dispose() {
    _animation.dispose();
    _licenceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    await ref.read(authControllerProvider.notifier).loginWithLicence(
          _licenceController.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final theme = Theme.of(context);

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
            top: -130,
            right: -100,
            child: _Glow(color: AppColors.primary.withValues(alpha: .12)),
          ),
          Positioned(
            bottom: -150,
            left: -110,
            child: _Glow(color: AppColors.orange.withValues(alpha: .13)),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 30, 24, 24),
                  child: FadeTransition(
                    opacity: CurvedAnimation(
                      parent: _animation,
                      curve: Curves.easeOut,
                    ),
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, .06),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: _animation,
                        curve: Curves.easeOutCubic,
                      )),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Center(child: BrandLogo(width: 230)),
                            const SizedBox(height: 34),
                            Text(
                              'Welcome Back! 👋',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: AppColors.navy,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 9),
                            Text(
                              'Enter your licence key to activate your business',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppColors.navy.withValues(alpha: .62),
                              ),
                            ),
                            const SizedBox(height: 30),
                            Container(
                              padding: const EdgeInsets.all(22),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(26),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: .08),
                                    blurRadius: 30,
                                    offset: const Offset(0, 12),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    'Licence Activation',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      color: AppColors.navy,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Your licence securely connects this device.',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: AppColors.navy.withValues(alpha: .55),
                                    ),
                                  ),
                                  const SizedBox(height: 22),
                                  AppTextField(
                                    controller: _licenceController,
                                    label: 'Licence Key',
                                    hint: 'Enter your licence key',
                                    prefixIcon: Icons.key_rounded,
                                    textCapitalization: TextCapitalization.characters,
                                    textInputAction: TextInputAction.done,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                        RegExp(r'[A-Za-z0-9\\-]'),
                                      ),
                                    ],
                                    validator: (value) =>
                                        value == null || value.trim().isEmpty
                                            ? 'Licence key is required'
                                            : null,
                                    onSubmitted: (_) => _submit(),
                                  ),
                                  const SizedBox(height: 18),
                                  SizedBox(
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
                                          : const Icon(Icons.arrow_forward_rounded),
                                      label: Text(auth.busy
                                          ? 'Activating...'
                                          : 'Login & Activate'),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  OutlinedButton.icon(
                                    onPressed: auth.busy
                                        ? null
                                        : () => context.push('/register'),
                                    icon: const Icon(Icons.rocket_launch_rounded),
                                    label: const Text('Start Free Trial'),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            _TrustRow(
                              icon: Icons.cloud_done_rounded,
                              text: 'Online & Offline Billing',
                            ),
                            const SizedBox(height: 18),
                            Text(
                              AppConstants.website,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.navy.withValues(alpha: .48),
                              ),
                            ),
                          ],
                        ),
                      ),
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

class _Glow extends StatelessWidget {
  const _Glow({required this.color});
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
        width: 280,
        height: 280,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      );
}

class _TrustRow extends StatelessWidget {
  const _TrustRow({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppColors.green.withValues(alpha: .12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 17, color: AppColors.green),
          ),
          const SizedBox(width: 9),
          Text(text,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.navy,
              )),
        ],
      );
}
