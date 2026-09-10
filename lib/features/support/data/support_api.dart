import 'package:dio/dio.dart';
import 'package:pos_billingwala_v2/core/network/api_client.dart';
import 'package:pos_billingwala_v2/core/network/api_response.dart';
import 'package:pos_billingwala_v2/features/support/data/support_dtos.dart';
import 'package:pos_billingwala_v2/core/constants/api_constants.dart';

class SupportApi {
  SupportApi(this._client);

  final ApiClient _client;

  Future<List<SupportTicketDto>> getSupportTickets(
    String userId, {
    String status = '',
  }) async {
    final data = await _get(
      ApiEndpoints.getSupportTickets,
      query: {
        'userId': userId,
        'status': status,
      },
    );
    return mapJsonList(
      data[ApiResponseKeys.tickets],
      SupportTicketDto.fromJson,
    );
  }

  Future<StatusMessage> createSupportTicket({
    required String userId,
    required String category,
    required String subject,
    required String description,
  }) async {
    final data = await _post(
      ApiEndpoints.createSupportTicket,
      fields: {
        'userId': userId,
        'category': category,
        'subject': subject,
        'description': description,
      },
    );
    return StatusMessage.fromJson(data);
  }

  Future<SupportTicketDetailsDto> getTicketDetails(
    String userId,
    String ticketId,
  ) async {
    final data = await _get(
      ApiEndpoints.getSupportTicketDetails,
      query: {
        'userId': userId,
        'ticketId': ticketId,
      },
    );
    return SupportTicketDetailsDto.fromJson(data);
  }

  Future<StatusMessage> replyTicket({
    required String userId,
    required String ticketId,
    required String message,
  }) async {
    final data = await _post(
      ApiEndpoints.replySupportTicket,
      fields: {
        'userId': userId,
        'ticketId': ticketId,
        'message': message,
      },
    );
    return StatusMessage.fromJson(data);
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
