import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_billingwala_v2/core/constants/app_colors.dart';
import 'package:pos_billingwala_v2/features/auth/domain/auth_controller.dart';
import 'package:pos_billingwala_v2/features/print/domain/bluetooth_printer_hub.dart';
import 'package:pos_billingwala_v2/features/print/domain/print_providers.dart';
import 'package:pos_billingwala_v2/features/print/domain/printer_settings.dart';
import 'package:pos_billingwala_v2/core/widgtes/widgtes.dart';
import 'package:pos_billingwala_v2/core/widgets/app_module_icon.dart';

/// Android-style sample invoice / KOT preview before test print.
class TestInvoicePreviewPage extends ConsumerStatefulWidget {
  const TestInvoicePreviewPage({
    super.key,
    required this.channel,
  });

  final PrinterChannelKind channel;

  @override
  ConsumerState<TestInvoicePreviewPage> createState() =>
      _TestInvoicePreviewPageState();
}

class _TestInvoicePreviewPageState extends ConsumerState<TestInvoicePreviewPage> {
  bool _printing = false;

  bool get _isKot => widget.channel == PrinterChannelKind.kot;

  String get _title => _isKot ? 'KOT Preview' : 'Invoice Preview';

  String? get _shopName =>
      ref.read(authControllerProvider).session?.shopName;

  String get _previewText =>
      ref.read(printServiceProvider).previewText(
            widget.channel,
            shopName: _shopName,
          );

  Future<void> _print() async {
    setState(() => _printing = true);
    try {
      final result = await ref.read(printServiceProvider).printTest(
            widget.channel,
            shopName: _shopName,
          );
      debugPrint(
        'PRINT_RESULT channel=${widget.channel.name} '
        'outcome=${result.outcome.name} message=${result.message}',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message ?? result.outcome.name)),
      );
    } catch (e, st) {
      debugPrint('PRINT_RESULT error=$e\n$st');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Print failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _printing = false);
    }
  }

  @override
  void initState() {
    super.initState();
    // Device QA: flutter run --dart-define=AUTO_TEST_PRINT=true
    if (const bool.fromEnvironment('AUTO_TEST_PRINT')) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _print();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(printerSettingsProvider);
    final chars = settings.charsPerLine;
    final text = _previewText;

    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        actions: [
          IconButton(
            tooltip: 'Copy receipt text',
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: text));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Preview copied')),
              );
            },
            icon: const Icon(Icons.copy_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          Center(child: AppModuleIcon(icon: _isKot ? Icons.restaurant_rounded : Icons.receipt_long_rounded, color: _isKot ? AppColors.orange : AppColors.primary, size: 68)),
          const SizedBox(height: 12),
          Text(
            'Sample ${_isKot ? 'KOT' : 'invoice'} — not saved to bills. '
            'Print to verify layout, ₹, and printer connection.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.black54,
                ),
          ),
          const SizedBox(height: 16),
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: chars <= 32 ? 280 : 360,
              ),
              child: AppCard(accentColor: _isKot ? AppColors.orange : AppColors.primary, padding: EdgeInsets.zero, child: Material(
                color: Colors.white,
                elevation: 2,
                shadowColor: Colors.black26,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black12),
                  ),
                  child: SelectableText(
                    text,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: chars <= 32 ? 12.5 : 11.5,
                      height: 1.35,
                      color: Colors.black87,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
            )),
          ),
          const SizedBox(height: 12),
          Text(
            'Paper: ${settings.paperSize == PrinterPaperSize.inch3 ? '80mm' : '58mm'}'
            ' Â· ${settings.transportFor(isKot: _isKot).label}',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.primary,
                ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: AppButton(
            label: 'Test print',
            isLoading: _printing,
            expanded: false,
            onPressed: _print,
          ),
        ),
      ),
    );
  }
}
