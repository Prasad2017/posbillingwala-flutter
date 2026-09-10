/// Central API base URL, endpoint paths, and response list keys.
/// Matches WithTable `ApiInterface` / `AllApiResponse` naming.
abstract final class ApiConstants {
  ApiConstants._();

  /// Same Android API host used by WithTable.
  static const String baseUrl = 'https://posbillingwala.com/androidApp/';
}

/// PHP script paths (relative to [ApiConstants.baseUrl]).
abstract final class ApiEndpoints {
  ApiEndpoints._();

  // Auth / licence
  static const String login = 'Login.php';
  static const String loginMpin = 'LoginMpin.php';
  static const String updateMpin = 'updateMPin.php';
  static const String updateAndroidKey = 'updateAndroidKey.php';
  static const String checkLicenceExpire = 'check_licence_expire.php';
  static const String registerTrial = 'registerTrial.php';
  static const String logOut = 'LogOut.php';
  static const String refreshAuthToken = 'refreshAuthToken.php';

  // Masters / catalog
  static const String getFoodTypeList = 'getFoodTypeList.php';
  static const String getCategoryList = 'getCategoryList.php';
  static const String getSubcategoryList = 'getSubcategoryList.php';
  static const String getProductList = 'getProductList.php';
  static const String getPortionList = 'getPortionList.php';
  static const String getPortionMasterList = 'getPortionMasterList.php';
  static const String getPosTableList = 'getPosTableList.php';
  static const String insertCategory = 'insertCategory.php';
  static const String insertSubcategory = 'insertSubcategory.php';
  static const String insertProduct = 'insertProduct.php';
  static const String insertPortion = 'insertPortion.php';
  static const String insertPortionMaster = 'insertPortionMaster.php';

  // Combos
  static const String getComboList = 'getComboList.php';
  static const String getComboItemList = 'getComboItemList.php';
  static const String insertCombo = 'insertCombo.php';
  static const String insertComboItem = 'insertComboItem.php';
  static const String insertInvoiceComboItem = 'insertInvoiceComboItem.php';
  static const String getInvoiceComboItemList = 'getInvoiceComboItemList.php';

  // Company / printer
  static const String getCompanyList = 'getCompanyList.php';
  static const String insertCompanyDetail = 'insertCompanyDetail.php';
  static const String getCompanyPrinterSetting = 'getCompanyPrinterSetting.php';
  static const String insertCompanyPrinterSetting =
      'insertCompanyPrinterSetting.php';
  static const String getHomeSalesOverview = 'getHomeSalesOverview.php';

  // Tables / dining
  static const String insertPosTable = 'insertPosTable.php';
  static const String insertDiningArea = 'insertDiningArea.php';
  static const String getDiningAreaList = 'getDiningAreaList.php';
  static const String insertTableType = 'insertTableType.php';
  static const String getTableTypeList = 'getTableTypeList.php';
  static const String insertDiningSession = 'insertDiningSession.php';
  static const String getDiningSessionList = 'getDiningSessionList.php';

  // Invoices / sync
  static const String insertInvoice = 'insertInvoice.php';
  static const String insertInvoiceProduct = 'insertInvoiceProduct.php';
  static const String deleteInvoiceProduct = 'deleteInvoiceProduct.php';
  static const String getInvoiceList = 'getInvoiceList.php';
  static const String getInvoiceProductList = 'getInvoiceProductList.php';

  // Inventory / expenses
  static const String insertInventory = 'insertInventory.php';
  static const String getInventoryList = 'getInventoryList.php';
  static const String insertExpenses = 'insertExpenses.php';
  static const String getExpensesList = 'getExpensesList.php';

  // Mess
  static const String getMessMemberList = 'getMessMemberList.php';
  static const String insertMessMember = 'insertMessMember.php';
  static const String getMessMemberPaymentList = 'getMessMemberPaymentList.php';
  static const String insertMessPayment = 'insertMessPayment.php';
  static const String getMessInvoiceList = 'getMessInvoiceList.php';
  static const String insertMessInvoice = 'insertMessInvoice.php';
  static const String messQrGet = 'mess_qr_get.php';
  static const String messQrGenerate = 'mess_qr_generate.php';
  static const String messQrRegenerate = 'mess_qr_regenerate.php';
  static const String messQrSetStatus = 'mess_qr_set_status.php';
  static const String messShopSettingGet = 'mess_shop_setting_get.php';
  static const String messShopSettingSave = 'mess_shop_setting_save.php';
  static const String messMealSessionList = 'mess_meal_session_list.php';
  static const String messMealSessionSave = 'mess_meal_session_save.php';
  static const String messMealTokenPending = 'mess_meal_token_pending.php';
  static const String messMealTokenToday = 'mess_meal_token_today.php';
  static const String messMealTokenPrintAck = 'mess_meal_token_print_ack.php';
  static const String messMealTokenCancel = 'mess_meal_token_cancel.php';
  static const String getMessTokenList = 'getMessTokenList.php';
  static const String insertMessToken = 'insertMessToken.php';
  static const String verifyMessToken = 'verifyMessToken.php';

  // Notifications
  static const String registerFcmToken = 'registerFcmToken.php';

  // Support / observability
  static const String getSupportTickets = 'getSupportTickets.php';
  static const String getSupportTicketDetails = 'getSupportTicketDetails.php';
  static const String createSupportTicket = 'createSupportTicket.php';
  static const String replySupportTicket = 'replySupportTicket.php';
  static const String reportErrorLog = 'reportErrorLog.php';
}

/// JSON list / payload keys returned by PHP endpoints
/// (mirrors Android `AllApiResponse` field names).
abstract final class ApiResponseKeys {
  ApiResponseKeys._();

  static const String foodTypeResponse = 'foodTypeResponse';
  static const String categoryResponse = 'categoryResponse';
  static const String subcategoryResponse = 'subcategoryResponse';
  static const String productResponse = 'productResponse';
  static const String portionResponse = 'portionResponse';
  static const String portionMasterResponse = 'portionMasterResponse';
  static const String comboResponse = 'comboResponse';
  static const String comboItemResponse = 'comboItemResponse';
  static const String posTableResponse = 'posTableResponse';
  static const String diningAreaResponse = 'diningAreaResponse';
  static const String tableTypeResponse = 'tableTypeResponse';
  static const String diningSessionResponse = 'diningSessionResponse';
  static const String memberResponse = 'memberResponse';
  static const String messTokenResponse = 'messTokenResponse';
  static const String messPaymentResponse = 'messPaymentResponse';
  static const String messInvoiceResponse = 'messInvoiceResponse';
  static const String messMealTokens = 'messMealTokens';
  static const String messSessionCounts = 'messSessionCounts';
  static const String companyResponse = 'companyResponse';
  static const String printerResponse = 'printerResponse';
  static const String invoiceResponse = 'invoiceResponse';
  static const String invoiceProductResponse = 'invoiceProductResponse';
  static const String invoiceComboItemResponse = 'invoiceComboItemResponse';
  static const String inventoryResponse = 'inventoryResponse';
  static const String expensesResponse = 'expensesResponse';
  static const String tickets = 'tickets';
  static const String status = 'status';
  static const String message = 'message';
}
