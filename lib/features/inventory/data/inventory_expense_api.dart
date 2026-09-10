import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:pos_billingwala_v2/core/database/app_database.dart';
import 'package:pos_billingwala_v2/core/network/api_client.dart';
import 'package:pos_billingwala_v2/core/network/api_response.dart';
import 'package:pos_billingwala_v2/shared/models/inventory_dtos.dart';
import 'package:pos_billingwala_v2/core/constants/api_constants.dart';

class InventoryExpenseApi {
  InventoryExpenseApi(this._client);

  final ApiClient _client;

  Future<bool> uploadInventory({
    required String userId,
    required InventoryMovement row,
  }) async {
    final data = await _post(
      ApiEndpoints.insertInventory,
      fields: {
        'userId': userId,
        'productId': '${row.productId}',
        'productInventoryQuantity':
            row.productInventoryQuantity.toStringAsFixed(2),
        'afterSaleInventoryQuantity':
            row.afterSaleInventoryQuantity.toStringAsFixed(2),
        'saleInventoryQuantity': row.saleInventoryQuantity.toStringAsFixed(2),
        'inventoryDate': DateFormat('yyyy-MM-dd').format(row.inventoryDate),
        'inventoryNetworkStatus': row.inventoryNetworkStatus,
      },
    );
    return isApiSuccess(data);
  }

  Future<bool> uploadExpense({
    required String userId,
    required ShopExpense row,
  }) async {
    final data = await _post(
      ApiEndpoints.insertExpenses,
      fields: {
        'userId': userId,
        'expensesName': row.expensesName,
        'expensesAmount': row.expensesAmount.toStringAsFixed(2),
        'expensesDate': DateFormat('yyyy-MM-dd').format(row.expensesDate),
        'expensesNetworkStatus': row.expensesNetworkStatus,
      },
    );
    return isApiSuccess(data);
  }

  Future<List<InventoryDto>> fetchInventory(String userId) async {
    final data = await _get(
      ApiEndpoints.getInventoryList,
      query: {'userId': userId},
    );
    return mapJsonList(
      data[ApiResponseKeys.inventoryResponse],
      InventoryDto.fromJson,
    );
  }

  Future<List<ExpenseDto>> fetchExpenses(String userId) async {
    final data = await _get(
      ApiEndpoints.getExpensesList,
      query: {'userId': userId},
    );
    return mapJsonList(
      data[ApiResponseKeys.expensesResponse],
      ExpenseDto.fromJson,
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
