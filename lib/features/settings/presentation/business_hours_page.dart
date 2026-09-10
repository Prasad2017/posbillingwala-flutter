import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pos_billingwala_v2/core/widgtes/widgtes.dart';
import 'package:pos_billingwala_v2/core/constants/app_colors.dart';
import 'package:pos_billingwala_v2/core/widgets/app_module_icon.dart';
import 'package:pos_billingwala_v2/features/auth/domain/auth_controller.dart';
import 'package:pos_billingwala_v2/features/company/data/company_api.dart';
import 'package:pos_billingwala_v2/features/company/data/company_dtos.dart';

class BusinessHoursPage extends ConsumerStatefulWidget {
  const BusinessHoursPage({super.key});

  @override
  ConsumerState<BusinessHoursPage> createState() => _BusinessHoursPageState();
}

class _BusinessHoursPageState extends ConsumerState<BusinessHoursPage> {
  static const _openKey = 'businessOpenMinutes';
  static const _closeKey = 'businessCloseMinutes';

  TimeOfDay _open = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _close = const TimeOfDay(hour: 22, minute: 0);
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  int _toMinutes(TimeOfDay t) => t.hour * 60 + t.minute;

  TimeOfDay _fromMinutes(int minutes) {
    final m = minutes.clamp(0, 24 * 60 - 1);
    return TimeOfDay(hour: m ~/ 60, minute: m % 60);
  }

  TimeOfDay? _parseStored(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final asInt = int.tryParse(raw.trim());
    if (asInt != null) return _fromMinutes(asInt);
    final parts = raw.trim().split(':');
    if (parts.length >= 2) {
      final h = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      if (h != null && m != null) {
        return TimeOfDay(hour: h.clamp(0, 23), minute: m.clamp(0, 59));
      }
    }
    return null;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final openPref = prefs.getInt(_openKey);
    final closePref = prefs.getInt(_closeKey);
    if (openPref != null) _open = _fromMinutes(openPref);
    if (closePref != null) _close = _fromMinutes(closePref);

    final userId = ref.read(authControllerProvider).session?.userId;
    if (userId != null && userId.isNotEmpty) {
      try {
        final companies =
            await CompanyApi(ref.read(apiClientProvider)).getCompanyList(userId);
        if (companies.isNotEmpty) {
          final c = companies.first;
          final open = _parseStored(c.openingMinutes);
          final close = _parseStored(c.closingMinutes);
          if (open != null) _open = open;
          if (close != null) _close = close;
        }
      } catch (_) {
        // Keep prefs / defaults.
      }
    }
    if (mounted) setState(() {});
  }

  Future<void> _pickOpen() async {
    final picked = await showTimePicker(context: context, initialTime: _open);
    if (picked != null) setState(() => _open = picked);
  }

  Future<void> _pickClose() async {
    final picked = await showTimePicker(context: context, initialTime: _close);
    if (picked != null) setState(() => _close = picked);
  }

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_openKey, _toMinutes(_open));
      await prefs.setInt(_closeKey, _toMinutes(_close));

      final userId = ref.read(authControllerProvider).session?.userId;
      if (userId != null && userId.isNotEmpty) {
        try {
          final api = CompanyApi(ref.read(apiClientProvider));
          final companies = await api.getCompanyList(userId);
          final base = companies.isNotEmpty ? companies.first : const CompanyDto();
          await api.insertCompanyDetail(
            userId: userId,
            company: CompanyDto(
              companyId: base.companyId,
              companyName: base.companyName,
              companyLogo: base.companyLogo,
              paymentLogo: base.paymentLogo,
              cashierName: base.cashierName,
              companyMobile: base.companyMobile,
              companyAddress: base.companyAddress,
              shopName1: base.shopName1,
              shopName2: base.shopName2,
              addressLine1: base.addressLine1,
              addressLine2: base.addressLine2,
              addressLine3: base.addressLine3,
              phoneNo1: base.phoneNo1,
              phoneNo2: base.phoneNo2,
              currencyName: base.currencyName,
              tableStatus: base.tableStatus,
              noOfTable: base.noOfTable,
              countryName: base.countryName,
              stateName: base.stateName,
              gstStatus: base.gstStatus,
              gstNumber: base.gstNumber,
              panNumber: base.panNumber,
              companyFssis: base.companyFssis,
              openingMinutes: _fmt(_open),
              closingMinutes: _fmt(_close),
              companyStatus: base.companyStatus,
            ),
          );
        } catch (_) {
          // Local prefs still saved.
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Business hours saved')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Hours'),
        actions: [
          TextButton(
            onPressed: _busy ? null : _save,
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(children: [
            const AppModuleIcon(icon: Icons.schedule_rounded, color: AppColors.orange, size: 70),
            const SizedBox(height: 12),
            const Text('Business schedule', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.navy)),
            const SizedBox(height: 18),
            AppCard(accentColor: AppColors.orange, child: Column(children: [
              children: [
                ListTile(
                  leading: const Icon(Icons.wb_sunny_outlined),
                  title: const Text('Opening time'),
                  subtitle: Text(_fmt(_open)),
                  trailing: const Icon(Icons.schedule_rounded),
                  onTap: _pickOpen,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.nights_stay_outlined),
                  title: const Text('Closing time'),
                  subtitle: Text(_fmt(_close)),
                  trailing: const Icon(Icons.schedule_rounded),
                  onTap: _pickClose,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppButton(
            label: 'Save hours',
            isLoading: _busy,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}
