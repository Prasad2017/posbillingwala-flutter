import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_billingwala_v2/core/constants/app_colors.dart';
import 'package:pos_billingwala_v2/core/constants/app_constants.dart';
import 'package:pos_billingwala_v2/features/auth/domain/auth_controller.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _logoScale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..forward();
    _logoScale = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );
    _fade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.15, 1, curve: Curves.easeOut),
    );

    Future<void>.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      ref.read(authControllerProvider.notifier).bootstrap();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFF9FCFF), Color(0xFFE8F3FF)],
              ),
            ),
          ),
          Positioned(
            top: -90,
            right: -70,
            child: _Glow(color: AppColors.primary.withValues(alpha: 0.14)),
          ),
          Positioned(
            bottom: -130,
            left: -100,
            child: _Glow(color: AppColors.orange.withValues(alpha: 0.16)),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 24, 28, 30),
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  ScaleTransition(
                    scale: _logoScale,
                    child: FadeTransition(
                      opacity: _fade,
                      child: Image.asset(
                        'assets/images/pos2_billingwala_logo.png',
                        width: 280,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 26),
                  FadeTransition(
                    opacity: _fade,
                    child: Column(
                      children: [
                        Text(
                          'Smart Billing',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: AppColors.navy,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'For Smarter Business',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryDark,
                              ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Online & Offline Billing Software',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.navy.withValues(alpha: 0.68),
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(flex: 3),
                  FadeTransition(
                    opacity: _fade,
                    child: Column(
                      children: [
                        const SizedBox(
                          width: 170,
                          child: LinearProgressIndicator(
                            minHeight: 7,
                            borderRadius: BorderRadius.all(Radius.circular(99)),
                            color: AppColors.primary,
                            backgroundColor: Color(0xFFD7E2F2),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Loading Your Business...',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.navy.withValues(alpha: 0.65),
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppConstants.appVersionLabel,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: AppColors.navy.withValues(alpha: 0.42),
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
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
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      height: 260,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}
