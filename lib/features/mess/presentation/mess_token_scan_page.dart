import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:pos_billingwala_v2/core/constants/app_colors.dart';
import 'package:pos_billingwala_v2/features/mess/domain/mess_providers.dart';
import 'package:pos_billingwala_v2/core/widgets/app_module_icon.dart';

class MessTokenScanPage extends ConsumerStatefulWidget {
  const MessTokenScanPage({super.key});

  @override
  ConsumerState<MessTokenScanPage> createState() => _MessTokenScanPageState();
}

class _MessTokenScanPageState extends ConsumerState<MessTokenScanPage> {
  final _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );
  bool _busy = false;
  String? _last;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_busy) return;
    final raw = capture.barcodes
        .map((b) => b.rawValue)
        .whereType<String>()
        .firstWhere((e) => e.trim().isNotEmpty, orElse: () => '');
    if (raw.isEmpty || raw == _last) return;
    _last = raw;
    setState(() => _busy = true);
    try {
      final token =
          await ref.read(messControllerProvider.notifier).verifyRaw(raw);
      if (!mounted) return;
      if (token == null) {
        throw StateError('Token not found');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Verified: ${token.memberName ?? token.tokenCode}'),
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
      await Future<void>.delayed(const Duration(seconds: 2));
      _last = null;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Mess Token'),
        actions: [
          IconButton(
            tooltip: 'Toggle torch',
            onPressed: () => _controller.toggleTorch(),
            icon: const Icon(Icons.flashlight_on_rounded),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          Align(
            alignment: Alignment.topCenter,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: .94), borderRadius: BorderRadius.circular(20)),
                  child: const Row(
                    children: [
                      AppModuleIcon(icon: Icons.qr_code_scanner_rounded, color: AppColors.primary, size: 48),
                      SizedBox(width: 12),
                      Expanded(child: Text('Scan meal token', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.navy))),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              color: Colors.black54,
              padding: const EdgeInsets.all(16),
              child: Text(
                _busy
                    ? 'Verifying…'
                    : 'Point the camera at a POSBILL meal token QR',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
          Positioned(top: 24, left: 24, right: 24, child: Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: AppColors.navy.withValues(alpha: .82), borderRadius: BorderRadius.circular(20)), child: const Row(children: [AppModuleIcon(icon: Icons.qr_code_scanner_rounded, color: AppColors.teal, size: 46), SizedBox(width: 12), Expanded(child: Text('Scan mess meal token', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)))]))),
          if (_busy)
            const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
        ],
      ),
    );
  }
}
