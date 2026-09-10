import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pos_billingwala_v2/features/company/data/company_dtos.dart';

/// Local snapshot of shop identity used on thermal bills (Android ShopHeader).
class ShopReceiptProfile {
  const ShopReceiptProfile({
    this.companyName = '',
    this.companyMobile = '',
    this.companyAddress = '',
    this.addressLine1 = '',
    this.addressLine2 = '',
    this.addressLine3 = '',
    this.phoneNo1 = '',
    this.phoneNo2 = '',
    this.gstNumber = '',
    this.panNumber = '',
    this.companyFssis = '',
    this.paymentLogo = '',
    this.shopName1 = '',
    this.shopName2 = '',
    this.cashierName = '',
    this.logoLocalPath = '',
    this.shopCgst = '',
    this.shopSgst = '',
    this.gstEnabled = false,
  });

  final String companyName;
  final String companyMobile;
  final String companyAddress;
  final String addressLine1;
  final String addressLine2;
  final String addressLine3;
  final String phoneNo1;
  final String phoneNo2;
  final String gstNumber;
  final String panNumber;
  final String companyFssis;
  /// Android stores UPI VPA in `paymentLogo` when it looks like `name@bank`.
  final String paymentLogo;
  final String shopName1;
  final String shopName2;
  final String cashierName;
  /// Local filesystem path for shop logo used on thermal bills.
  final String logoLocalPath;
  final String shopCgst;
  final String shopSgst;
  final bool gstEnabled;

  double get shopGstPercent {
    final c = double.tryParse(shopCgst.trim()) ?? 0;
    final s = double.tryParse(shopSgst.trim()) ?? 0;
    return c + s;
  }

  bool get hasUpiId {
    final v = paymentLogo.trim();
    if (v.isEmpty || v.length > 120) return false;
    if (v.contains(' ') || v.contains('\n')) return false;
    final at = v.indexOf('@');
    return at > 0 && at < v.length - 1;
  }

  String get upiId => hasUpiId ? paymentLogo.trim() : '';

  /// Android ShopHeaderBuilder layout for thermal bills.
  List<String> headerLines() {
    final lines = <String>[];
    void add(String? v) {
      final t = v?.trim() ?? '';
      if (t.isNotEmpty) lines.add(t);
    }

    // Primary title: shopName1 else companyName (do not stack both).
    final title = shopName1.trim().isNotEmpty ? shopName1.trim() : companyName.trim();
    add(title);
    add(shopName2);
    add(addressLine1);
    add(addressLine2);
    add(addressLine3);
    if (addressLine1.isEmpty && addressLine2.isEmpty && addressLine3.isEmpty) {
      add(companyAddress);
    }
    add(phoneNo1);
    add(phoneNo2);
    if (phoneNo1.trim().isEmpty &&
        phoneNo2.trim().isEmpty &&
        companyMobile.trim().isEmpty == false) {
      add(companyMobile);
    }
    if (gstEnabled && gstNumber.trim().isNotEmpty) {
      lines.add('GSTIN: ${gstNumber.trim()}');
    }
    if (companyFssis.trim().isNotEmpty) {
      lines.add('FSSAI No: ${companyFssis.trim()}');
    }
    return lines;
  }

  factory ShopReceiptProfile.fromCompany(CompanyDto c) {
    return ShopReceiptProfile(
      companyName: c.companyName,
      companyMobile: c.companyMobile ?? '',
      companyAddress: c.companyAddress ?? '',
      addressLine1: c.addressLine1 ?? '',
      addressLine2: c.addressLine2 ?? '',
      addressLine3: c.addressLine3 ?? '',
      phoneNo1: c.phoneNo1 ?? '',
      phoneNo2: c.phoneNo2 ?? '',
      gstNumber: c.gstNumber ?? '',
      panNumber: c.panNumber ?? '',
      companyFssis: c.companyFssis ?? '',
      paymentLogo: c.paymentLogo ?? '',
      shopName1: c.shopName1 ?? '',
      shopName2: c.shopName2 ?? '',
      cashierName: c.cashierName ?? '',
      shopCgst: c.shopCgst ?? '',
      shopSgst: c.shopSgst ?? '',
      gstEnabled: c.gstStatus == '1' || c.gstStatus?.toLowerCase() == 'yes',
    );
  }

  ShopReceiptProfile copyWith({
    String? companyName,
    String? companyMobile,
    String? companyAddress,
    String? addressLine1,
    String? addressLine2,
    String? addressLine3,
    String? phoneNo1,
    String? phoneNo2,
    String? gstNumber,
    String? panNumber,
    String? companyFssis,
    String? paymentLogo,
    String? shopName1,
    String? shopName2,
    String? cashierName,
    String? logoLocalPath,
    String? shopCgst,
    String? shopSgst,
    bool? gstEnabled,
  }) {
    return ShopReceiptProfile(
      companyName: companyName ?? this.companyName,
      companyMobile: companyMobile ?? this.companyMobile,
      companyAddress: companyAddress ?? this.companyAddress,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      addressLine3: addressLine3 ?? this.addressLine3,
      phoneNo1: phoneNo1 ?? this.phoneNo1,
      phoneNo2: phoneNo2 ?? this.phoneNo2,
      gstNumber: gstNumber ?? this.gstNumber,
      panNumber: panNumber ?? this.panNumber,
      companyFssis: companyFssis ?? this.companyFssis,
      paymentLogo: paymentLogo ?? this.paymentLogo,
      shopName1: shopName1 ?? this.shopName1,
      shopName2: shopName2 ?? this.shopName2,
      cashierName: cashierName ?? this.cashierName,
      logoLocalPath: logoLocalPath ?? this.logoLocalPath,
      shopCgst: shopCgst ?? this.shopCgst,
      shopSgst: shopSgst ?? this.shopSgst,
      gstEnabled: gstEnabled ?? this.gstEnabled,
    );
  }
}

class ShopReceiptProfileStore {
  static const _prefix = 'shop_receipt_';

  Future<ShopReceiptProfile> load() async {
    final p = await SharedPreferences.getInstance();
    return ShopReceiptProfile(
      companyName: p.getString('${_prefix}companyName') ?? '',
      companyMobile: p.getString('${_prefix}companyMobile') ?? '',
      companyAddress: p.getString('${_prefix}companyAddress') ?? '',
      addressLine1: p.getString('${_prefix}addressLine1') ?? '',
      addressLine2: p.getString('${_prefix}addressLine2') ?? '',
      addressLine3: p.getString('${_prefix}addressLine3') ?? '',
      phoneNo1: p.getString('${_prefix}phoneNo1') ?? '',
      phoneNo2: p.getString('${_prefix}phoneNo2') ?? '',
      gstNumber: p.getString('${_prefix}gstNumber') ?? '',
      panNumber: p.getString('${_prefix}panNumber') ?? '',
      companyFssis: p.getString('${_prefix}companyFssis') ?? '',
      paymentLogo: p.getString('${_prefix}paymentLogo') ?? '',
      shopName1: p.getString('${_prefix}shopName1') ?? '',
      shopName2: p.getString('${_prefix}shopName2') ?? '',
      cashierName: p.getString('${_prefix}cashierName') ?? '',
      logoLocalPath: p.getString('${_prefix}logoLocalPath') ?? '',
      shopCgst: p.getString('${_prefix}shopCgst') ?? '',
      shopSgst: p.getString('${_prefix}shopSgst') ?? '',
      gstEnabled: p.getBool('${_prefix}gstEnabled') ?? false,
    );
  }

  Future<void> save(ShopReceiptProfile profile) async {
    final p = await SharedPreferences.getInstance();
    await p.setString('${_prefix}companyName', profile.companyName);
    await p.setString('${_prefix}companyMobile', profile.companyMobile);
    await p.setString('${_prefix}companyAddress', profile.companyAddress);
    await p.setString('${_prefix}addressLine1', profile.addressLine1);
    await p.setString('${_prefix}addressLine2', profile.addressLine2);
    await p.setString('${_prefix}addressLine3', profile.addressLine3);
    await p.setString('${_prefix}phoneNo1', profile.phoneNo1);
    await p.setString('${_prefix}phoneNo2', profile.phoneNo2);
    await p.setString('${_prefix}gstNumber', profile.gstNumber);
    await p.setString('${_prefix}panNumber', profile.panNumber);
    await p.setString('${_prefix}companyFssis', profile.companyFssis);
    await p.setString('${_prefix}paymentLogo', profile.paymentLogo);
    await p.setString('${_prefix}shopName1', profile.shopName1);
    await p.setString('${_prefix}shopName2', profile.shopName2);
    await p.setString('${_prefix}cashierName', profile.cashierName);
    await p.setString('${_prefix}logoLocalPath', profile.logoLocalPath);
    await p.setString('${_prefix}shopCgst', profile.shopCgst);
    await p.setString('${_prefix}shopSgst', profile.shopSgst);
    await p.setBool('${_prefix}gstEnabled', profile.gstEnabled);
  }
}

final shopReceiptProfileProvider =
    NotifierProvider<ShopReceiptProfileController, ShopReceiptProfile>(
  ShopReceiptProfileController.new,
);

class ShopReceiptProfileController extends Notifier<ShopReceiptProfile> {
  final _store = ShopReceiptProfileStore();

  @override
  ShopReceiptProfile build() {
    Future.microtask(_hydrate);
    return const ShopReceiptProfile();
  }

  Future<void> _hydrate() async {
    state = await _store.load();
  }

  Future<void> save(ShopReceiptProfile profile) async {
    await _store.save(profile);
    state = profile;
  }

  Future<void> saveFromCompany(CompanyDto company) async {
    final current = await _store.load();
    final next = ShopReceiptProfile.fromCompany(company).copyWith(
      logoLocalPath: current.logoLocalPath,
    );
    await save(next);
  }

  Future<void> saveLogoPath(String path) async {
    await save(state.copyWith(logoLocalPath: path));
  }
}

/// Android PaymentUpiQrHelper.buildUpiPayUri
String buildUpiPayUri({
  required String upiId,
  required String payeeName,
  required double amount,
  String note = '',
}) {
  final pa = upiId.trim();
  final pn = Uri.encodeComponent(
    payeeName.trim().isEmpty ? 'Merchant' : payeeName.trim(),
  );
  final tn = Uri.encodeComponent(note);
  final buf = StringBuffer('upi://pay?pa=$pa&pn=$pn&cu=INR');
  if (amount > 0) {
    buf.write('&am=${amount.toStringAsFixed(2)}');
  }
  if (tn.isNotEmpty) {
    buf.write('&tn=$tn');
  }
  return buf.toString();
}
