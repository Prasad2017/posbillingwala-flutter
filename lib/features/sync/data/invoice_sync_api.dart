import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:pos_billingwala_v2/core/database/app_database.dart';
import 'package:pos_billingwala_v2/core/network/api_client.dart';
import 'package:pos_billingwala_v2/core/network/api_response.dart';
import 'package:pos_billingwala_v2/features/sync/domain/cloud_invoice_dto.dart';
import 'package:pos_billingwala_v2/core/constants/api_constants.dart';

class InvoiceSyncApi {
  InvoiceSyncApi(this._client);

  final ApiClient _client;

  Future<bool> uploadInvoice({
    required String userId,
    required Invoice invoice,
  }) async {
    final data = await _post(
      ApiEndpoints.insertInvoice,
      fields: {
        'userId': userId,
        'noOfTable': invoice.noOfTable,
        'invoiceNumber': invoice.invoiceNumber,
        'customerName': invoice.customerName ?? '',
        'customerMobile': invoice.customerMobile ?? '',
        'customerEmail': '',
        'customerAddress': '',
        'subTotal': invoice.subTotal.toStringAsFixed(2),
        'totalGSTAmount': invoice.totalGstAmount.toStringAsFixed(2),
        'discount': invoice.discount.toStringAsFixed(2),
        'discountType': invoice.discountType,
        'packingCharge': invoice.packingCharge.toStringAsFixed(2),
        'packingChargeType': invoice.packingChargeType,
        'totalAmount': invoice.totalAmount.toStringAsFixed(2),
        'paymentMode': invoice.paymentMode,
        'cashAmount': invoice.cashAmount.toStringAsFixed(2),
        'upiAmount': invoice.upiAmount.toStringAsFixed(2),
        'diningSessionId': '${invoice.diningSessionId ?? ''}',
        'billPrintStatus': '',
        'invoiceDate':
            DateFormat('yyyy-MM-dd HH:mm:ss').format(invoice.invoiceDate),
        'invoiceType': invoice.invoiceType,
        'invoiceOrderStatus': invoice.invoiceOrderStatus,
        'invoiceNetworkStatus': invoice.invoiceNetworkStatus,
        'organizationId': invoice.organizationId,
        'branchId': invoice.branchId,
        'deviceId': invoice.deviceId,
      },
    );
    return isApiSuccess(data);
  }

  Future<bool> uploadInvoiceItem({
    required InvoiceItem item,
  }) async {
    final network = item.invoiceItemNetworkStatus?.trim().isNotEmpty == true
        ? item.invoiceItemNetworkStatus!
        : 'item${item.invoiceItemId}';
    final data = await _post(
      ApiEndpoints.insertInvoiceProduct,
      fields: {
        'invoiceNumber': item.invoiceNumber,
        'productName': item.productName,
        'productPrice': item.productPrice.toStringAsFixed(2),
        'productUnit': item.productUnit ?? '',
        'productCGST': item.productCgst.toStringAsFixed(2),
        'productSGST': item.productSgst.toStringAsFixed(2),
        'productQuantity': '${item.productQuantity}',
        'productStatus': item.productStatus,
        'invoiceProductNetworkStatus': network,
        'portionId': '',
        'portionName': '',
        'snapshotProductName': item.productName,
        'snapshotLinePrice': item.productPrice.toStringAsFixed(2),
        'invoiceItemType': item.invoiceItemType.trim().isEmpty
            ? 'PRODUCT'
            : item.invoiceItemType.toUpperCase(),
        'comboNetworkStatus': '',
        'snapshotComboComponents': '',
        'organizationId': item.organizationId,
        'branchId': item.branchId,
        'deviceId': item.deviceId,
      },
    );
    return isApiSuccess(data);
  }

  Future<bool> deleteInvoiceProduct({
    required String invoiceProductNetworkStatus,
  }) async {
    final data = await _post(
      ApiEndpoints.deleteInvoiceProduct,
      fields: {
        'invoiceProductNetworkStatus': invoiceProductNetworkStatus,
      },
    );
    return isApiSuccess(data);
  }

  Future<List<CloudInvoiceDto>> fetchInvoices(
    String userId, {
    String? invoiceDate,
  }) async {
    final data = await _get(
      ApiEndpoints.getInvoiceList,
      query: {
        'userId': userId,
        if (invoiceDate != null && invoiceDate.isNotEmpty)
          'invoiceDate': invoiceDate,
      },
    );
    return mapJsonList(
      data[ApiResponseKeys.invoiceResponse],
      CloudInvoiceDto.fromJson,
    );
  }

  Future<List<CloudInvoiceItemDto>> fetchInvoiceItems(String userId) async {
    final data = await _get(
      ApiEndpoints.getInvoiceProductList,
      query: {'userId': userId},
    );
    return mapJsonList(
      data[ApiResponseKeys.invoiceProductResponse],
      CloudInvoiceItemDto.fromJson,
    );
  }

  Future<Map<String, dynamic>> _get(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    final response = await _client.dio.get<dynamic>(
      path,
      queryParameters: query,
      options: Options(responseType: ResponseType.json),
    );
    return asJsonMap(response.data);
  }

  Future<Map<String, dynamic>> _post(
    String path, {
    required Map<String, dynamic> fields,
  }) async {
    final response = await _client.dio.post<dynamic>(
      path,
      data: FormData.fromMap(fields),
      options: Options(responseType: ResponseType.json),
    );
    return asJsonMap(response.data);
  }
}
