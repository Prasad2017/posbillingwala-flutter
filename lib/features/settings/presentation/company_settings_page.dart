import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pos_billingwala_v2/core/constants/app_colors.dart';
import 'package:pos_billingwala_v2/core/widgtes/widgtes.dart';
import 'package:pos_billingwala_v2/core/widgets/app_module_icon.dart';
import 'package:pos_billingwala_v2/core/widgets/app_module_icon.dart';
import 'package:pos_billingwala_v2/features/auth/domain/auth_controller.dart';
import 'package:pos_billingwala_v2/features/company/data/company_api.dart';
import 'package:pos_billingwala_v2/features/company/data/company_dtos.dart';
import 'package:pos_billingwala_v2/features/print/domain/shop_receipt_profile.dart';

/// Company / shop profile only (Android Shop Details parity).
class CompanySettingsPage extends ConsumerStatefulWidget {
  const CompanySettingsPage({super.key});

  @override
  ConsumerState<CompanySettingsPage> createState() =>
      _CompanySettingsPageState();
}

class _CompanySettingsPageState extends ConsumerState<CompanySettingsPage> {
  late final TextEditingController _companyName;
  late final TextEditingController _shopName1;
  late final TextEditingController _shopName2;
  late final TextEditingController _cashierName;
  late final TextEditingController _companyMobile;
  late final TextEditingController _companyAddress;
  late final TextEditingController _addressLine1;
  late final TextEditingController _addressLine2;
  late final TextEditingController _addressLine3;
  late final TextEditingController _phoneNo1;
  late final TextEditingController _phoneNo2;
  late final TextEditingController _gstNumber;
  late final TextEditingController _panNumber;
  late final TextEditingController _companyFssis;
  late final TextEditingController _shopCgst;
  late final TextEditingController _shopSgst;
  late final TextEditingController _currencyName;
  late final TextEditingController _countryName;
  late final TextEditingController _stateName;
  late final TextEditingController _noOfTable;
  late final TextEditingController _paymentLogo;
  late final TextEditingController _openingMinutes;
  late final TextEditingController _closingMinutes;
  bool _gstEnabled = false;
  bool _busy = false;
  String _logoPath = '';

  @override
  void initState() {
    super.initState();
    final shop = ref.read(authControllerProvider).session?.shopName ?? '';
    final profile = ref.read(shopReceiptProfileProvider);
    _companyName = TextEditingController(text: shop);
    _shopName1 = TextEditingController();
    _shopName2 = TextEditingController();
    _cashierName = TextEditingController();
    _companyMobile = TextEditingController();
    _companyAddress = TextEditingController();
    _addressLine1 = TextEditingController();
    _addressLine2 = TextEditingController();
    _addressLine3 = TextEditingController();
    _phoneNo1 = TextEditingController();
    _phoneNo2 = TextEditingController();
    _gstNumber = TextEditingController();
    _panNumber = TextEditingController();
    _companyFssis = TextEditingController();
    _shopCgst = TextEditingController(text: '0');
    _shopSgst = TextEditingController(text: '0');
    _currencyName = TextEditingController(text: 'INR');
    _countryName = TextEditingController(text: 'India');
    _stateName = TextEditingController();
    _noOfTable = TextEditingController();
    _paymentLogo = TextEditingController();
    _openingMinutes = TextEditingController();
    _closingMinutes = TextEditingController();
    _logoPath = profile.logoLocalPath;
    Future.microtask(_load);
  }

  @override
  void dispose() {
    _companyName.dispose();
    _shopName1.dispose();
    _shopName2.dispose();
    _cashierName.dispose();
    _companyMobile.dispose();
    _companyAddress.dispose();
    _addressLine1.dispose();
    _addressLine2.dispose();
    _addressLine3.dispose();
    _phoneNo1.dispose();
    _phoneNo2.dispose();
    _gstNumber.dispose();
    _panNumber.dispose();
    _companyFssis.dispose();
    _shopCgst.dispose();
    _shopSgst.dispose();
    _currencyName.dispose();
    _countryName.dispose();
    _stateName.dispose();
    _noOfTable.dispose();
    _paymentLogo.dispose();
    _openingMinutes.dispose();
    _closingMinutes.dispose();
    super.dispose();
  }

  CompanyDto _buildDto() {
    return CompanyDto(
      companyName: _companyName.text.trim(),
      shopName1: _shopName1.text.trim(),
      shopName2: _shopName2.text.trim(),
      cashierName: _cashierName.text.trim(),
      companyMobile: _companyMobile.text.trim(),
      companyAddress: _companyAddress.text.trim(),
      addressLine1: _addressLine1.text.trim(),
      addressLine2: _addressLine2.text.trim(),
      addressLine3: _addressLine3.text.trim(),
      phoneNo1: _phoneNo1.text.trim(),
      phoneNo2: _phoneNo2.text.trim(),
      gstStatus: _gstEnabled ? '1' : '0',
      gstNumber: _gstNumber.text.trim(),
      panNumber: _panNumber.text.trim(),
      companyFssis: _companyFssis.text.trim(),
      shopCgst: _shopCgst.text.trim(),
      shopSgst: _shopSgst.text.trim(),
      currencyName: _currencyName.text.trim(),
      countryName: _countryName.text.trim(),
      stateName: _stateName.text.trim(),
      noOfTable: _noOfTable.text.trim(),
      paymentLogo: _paymentLogo.text.trim(),
      openingMinutes: _openingMinutes.text.trim(),
      closingMinutes: _closingMinutes.text.trim(),
    );
  }

  void _applyDto(CompanyDto c) {
    _companyName.text = c.companyName;
    _shopName1.text = c.shopName1 ?? '';
    _shopName2.text = c.shopName2 ?? '';
    _cashierName.text = c.cashierName ?? '';
    _companyMobile.text = c.companyMobile ?? '';
    _companyAddress.text = c.companyAddress ?? '';
    _addressLine1.text = c.addressLine1 ?? '';
    _addressLine2.text = c.addressLine2 ?? '';
    _addressLine3.text = c.addressLine3 ?? '';
    _phoneNo1.text = c.phoneNo1 ?? '';
    _phoneNo2.text = c.phoneNo2 ?? '';
    _gstEnabled = c.gstStatus == '1' || c.gstStatus?.toLowerCase() == 'true';
    _gstNumber.text = c.gstNumber ?? '';
    _panNumber.text = c.panNumber ?? '';
    _companyFssis.text = c.companyFssis ?? '';
    _shopCgst.text = c.shopCgst ?? '0';
    _shopSgst.text = c.shopSgst ?? '0';
    _currencyName.text = c.currencyName ?? 'INR';
    _countryName.text = c.countryName ?? 'India';
    _stateName.text = c.stateName ?? '';
    _noOfTable.text = c.noOfTable ?? '';
    _paymentLogo.text = c.paymentLogo ?? '';
    _openingMinutes.text = c.openingMinutes ?? '';
    _closingMinutes.text = c.closingMinutes ?? '';
  }

  Future<void> _load() async {
    final userId = ref.read(authControllerProvider).session?.userId;
    if (userId == null || userId.isEmpty) return;
    setState(() => _busy = true);
    try {
      final api = CompanyApi(ref.read(apiClientProvider));
      final companies = await api.getCompanyList(userId);
      if (companies.isNotEmpty && mounted) {
        setState(() => _applyDto(companies.first));
        await ref
            .read(shopReceiptProfileProvider.notifier)
            .saveFromCompany(companies.first);
        final profile = ref.read(shopReceiptProfileProvider);
        setState(() => _logoPath = profile.logoLocalPath);
      }
    } catch (_) {
      // Keep local fields.
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickLogo(ImageSource source) async {
    final picked = await ImagePicker().pickImage(
      source: source,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (picked == null) return;
    final docs = await getApplicationDocumentsDirectory();
    final dest = File('${docs.path}/shop_logo.jpg');
    await File(picked.path).copy(dest.path);
    await ref.read(shopReceiptProfileProvider.notifier).saveLogoPath(dest.path);
    if (!mounted) return;
    setState(() => _logoPath = dest.path);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Shop logo saved for bills')),
    );
  }

  Future<void> _clearLogo() async {
    await ref.read(shopReceiptProfileProvider.notifier).saveLogoPath('');
    if (!mounted) return;
    setState(() => _logoPath = '');
  }

  Future<void> _save() async {
    final userId = ref.read(authControllerProvider).session?.userId;
    if (userId == null || userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login first')),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      final api = CompanyApi(ref.read(apiClientProvider));
      final dto = _buildDto();
      final ok = await api.insertCompanyDetail(
        userId: userId,
        company: dto,
      );
      await ref.read(shopReceiptProfileProvider.notifier).saveFromCompany(dto);
      if (_logoPath.isNotEmpty) {
        await ref
            .read(shopReceiptProfileProvider.notifier)
            .saveLogoPath(_logoPath);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? 'Shop details saved' : 'Save finished with issues'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _field(
    TextEditingController c,
    String label, {
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppTextField(
        controller: c,
        label: label,
        keyboardType: keyboardType,
        maxLines: maxLines,
        minLines: maxLines > 1 ? maxLines : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final logoFile = _logoPath.isNotEmpty ? File(_logoPath) : null;
    final hasLogo = logoFile != null && logoFile.existsSync();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop Details'),
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
                const AppModuleIcon(icon: Icons.storefront_rounded, color: AppColors.primary, size: 72),
                const SizedBox(height: 12),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Shop logo',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                if (hasLogo)
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        logoFile,
                        height: 96,
                        fit: BoxFit.contain,
                      ),
                    ),
                  )
                else
                  const Text(
                      'No logo set — enable “Print shop logo” in Printer settings.'),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    AppButton(
                      label: 'Camera',
                      icon: Icons.photo_camera_outlined,
                      expanded: false,
                      onPressed: _busy
                          ? null
                          : () => _pickLogo(ImageSource.camera),
                    ),
                    AppButton(
                      label: 'Gallery',
                      icon: Icons.photo_library_outlined,
                      expanded: false,
                      onPressed: _busy
                          ? null
                          : () => _pickLogo(ImageSource.gallery),
                    ),
                    if (hasLogo)
                      TextButton(
                        onPressed: _busy ? null : _clearLogo,
                        child: const Text('Remove'),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              children: [
                _field(_companyName, 'Company / shop name'),
                _field(_shopName1, 'Shop name line 1'),
                _field(_shopName2, 'Shop name line 2'),
                _field(_cashierName, 'Cashier name'),
                _field(
                  _companyMobile,
                  'Company mobile',
                  keyboardType: TextInputType.phone,
                ),
                _field(_phoneNo1, 'Phone 1', keyboardType: TextInputType.phone),
                _field(_phoneNo2, 'Phone 2', keyboardType: TextInputType.phone),
                _field(_companyAddress, 'Address', maxLines: 2),
                _field(_addressLine1, 'Address line 1'),
                _field(_addressLine2, 'Address line 2'),
                _field(_addressLine3, 'Address line 3'),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('GST enabled'),
                  value: _gstEnabled,
                  onChanged: (v) => setState(() => _gstEnabled = v),
                ),
                _field(_gstNumber, 'GSTIN'),
                _field(
                  _shopCgst,
                  'Shop CGST %',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                _field(
                  _shopSgst,
                  'Shop SGST %',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                _field(_panNumber, 'PAN'),
                _field(_companyFssis, 'FSSAI'),
                _field(
                  _paymentLogo,
                  'UPI ID (payment logo / VPA)',
                  keyboardType: TextInputType.emailAddress,
                ),
                _field(_currencyName, 'Currency'),
                _field(_countryName, 'Country'),
                _field(_stateName, 'State'),
                _field(
                  _noOfTable,
                  'No. of tables',
                  keyboardType: TextInputType.number,
                ),
                _field(
                  _openingMinutes,
                  'Opening minutes (from midnight)',
                  keyboardType: TextInputType.number,
                ),
                _field(
                  _closingMinutes,
                  'Closing minutes (from midnight)',
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          if (_busy)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          const SizedBox(height: 8),
          AppCard(
            color: AppColors.primaryLight,
            padding: EdgeInsets.zero,
            child: const ListTile(
              leading: Icon(Icons.info_outline, color: AppColors.primary),
              title: Text('Receipt header'),
              subtitle: Text(
                'These details print on bills. Turn on logo print in Printer Details.',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
