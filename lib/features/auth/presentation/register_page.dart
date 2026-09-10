import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pos_billingwala_v2/core/widgtes/widgtes.dart';
import 'package:pos_billingwala_v2/core/constants/app_colors.dart';
import 'package:pos_billingwala_v2/core/widgets/brand_logo.dart';
import 'package:pos_billingwala_v2/core/widgets/app_module_icon.dart';
import 'package:pos_billingwala_v2/features/auth/domain/auth_controller.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _contact = TextEditingController();
  final _shop = TextEditingController();
  final _address = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _contact.dispose();
    _shop.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final result = await ref.read(authRepositoryProvider).registerTrial(
            name: _name.text,
            contactNumber: _contact.text,
            address: _address.text,
            shopName: _shop.text,
          );
      if (!mounted) return;
      if (!result.isSuccess ||
          result.licenceKey == null ||
          result.licenceKey!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message ?? 'Registration failed')),
        );
        return;
      }

      final mpin = (result.mpin == null || result.mpin!.isEmpty)
          ? '9082'
          : result.mpin!;
      final reportPin = (result.reportPin == null || result.reportPin!.isEmpty)
          ? '9082'
          : result.reportPin!;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Row(children: [AppModuleIcon(icon: Icons.verified_rounded, color: AppColors.teal, size: 46), SizedBox(width: 10), Expanded(child: Text('Trial account created'))]),
          content: AppCard(accentColor: AppColors.teal, child: Text(
            'Licence key: ${result.licenceKey}\n'
            'PB-PIN: $mpin\n'
            'Report PIN: $reportPin\n\n'
            'Save these details. We will log you in next.',
          )),
          actions: [
            AppButton(
              label: 'Continue',
              expanded: false,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );

      final ok = await ref
          .read(authControllerProvider.notifier)
          .loginWithLicence(result.licenceKey!);
      if (ok && mounted) {
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration failed.\n$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign up for trial')),
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const BrandLogo(width: 180),
                    const SizedBox(height: 24),
                    const AppModuleIcon(icon: Icons.rocket_launch_rounded, color: AppColors.red, size: 64),
                    const SizedBox(height: 10),
                    const Text('Start your business trial', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.navy)),
                    const SizedBox(height: 24),
                    AppCard(accentColor: AppColors.primary, child: Column(children: [
                    AppTextField(
                      controller: _name,
                      label: 'Your name',
                      prefixIcon: Icons.person_outline,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: _contact,
                      label: 'Contact number',
                      prefixIcon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: _shop,
                      label: 'Shop name',
                      prefixIcon: Icons.storefront_outlined,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: _address,
                      label: 'Address',
                      prefixIcon: Icons.location_on_outlined,
                      maxLines: 2,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 24),
                    AppButton(
                      label: 'Create trial account',
                      isLoading: _busy,
                      onPressed: _submit,
                    ),
                    ])),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
