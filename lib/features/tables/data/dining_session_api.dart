import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:pos_billingwala_v2/core/network/api_client.dart';
import 'package:pos_billingwala_v2/core/network/api_response.dart';
import 'package:pos_billingwala_v2/core/utils/json_parsers.dart';
import 'package:pos_billingwala_v2/core/constants/api_constants.dart';

class DiningSessionDto {
  const DiningSessionDto({
    this.sessionId,
    this.localSessionId,
    required this.primaryTableNumber,
    this.joinedTableNumbers = '',
    this.sessionStatus = 'RUNNING',
    this.guestCount = 1,
    this.startedAt,
    this.closedAt,
    this.customerName,
    this.customerMobile,
    this.waiterName,
    this.unpaidInvoiceNumber,
    this.paidAmount = 0,
    this.sessionVersion = 1,
    this.sessionNetworkStatus,
  });

  final int? sessionId;
  final String? localSessionId;
  final String primaryTableNumber;
  final String joinedTableNumbers;
  final String sessionStatus;
  final int guestCount;
  final DateTime? startedAt;
  final DateTime? closedAt;
  final String? customerName;
  final String? customerMobile;
  final String? waiterName;
  final String? unpaidInvoiceNumber;
  final double paidAmount;
  final int sessionVersion;
  final String? sessionNetworkStatus;

  factory DiningSessionDto.fromJson(Map<String, dynamic> json) {
    return DiningSessionDto(
      sessionId: parseInt(json['sessionId']),
      localSessionId: parseString(json['localSessionId']),
      primaryTableNumber: parseString(json['primaryTableNumber']) ?? '',
      joinedTableNumbers: parseString(json['joinedTableNumbers']) ?? '',
      sessionStatus: parseString(json['sessionStatus']) ?? 'RUNNING',
      guestCount: parseInt(json['guestCount']) ?? 1,
      startedAt: parseInvoiceDate(json['startedAt']),
      closedAt: parseInvoiceDate(json['closedAt']),
      customerName: parseString(json['customerName']),
      customerMobile: parseString(json['customerMobile']),
      waiterName: parseString(json['waiterName']),
      unpaidInvoiceNumber: parseString(json['unpaidInvoiceNumber']),
      paidAmount: parseMoney(json['paidAmount']),
      sessionVersion: parseInt(json['sessionVersion']) ?? 1,
      sessionNetworkStatus: parseString(json['sessionNetworkStatus']),
    );
  }

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'localSessionId': localSessionId,
        'primaryTableNumber': primaryTableNumber,
        'joinedTableNumbers': joinedTableNumbers,
        'sessionStatus': sessionStatus,
        'guestCount': guestCount,
        'startedAt': startedAt?.toIso8601String(),
        'closedAt': closedAt?.toIso8601String(),
        'customerName': customerName,
        'customerMobile': customerMobile,
        'waiterName': waiterName,
        'unpaidInvoiceNumber': unpaidInvoiceNumber,
        'paidAmount': paidAmount,
        'sessionVersion': sessionVersion,
        'sessionNetworkStatus': sessionNetworkStatus,
      };
}

class DiningSessionApi {
  DiningSessionApi(this._client);

  final ApiClient _client;

  static final _dt = DateFormat('yyyy-MM-dd HH:mm:ss');

  Future<bool> insertDiningSession({
    required String userId,
    required DiningSessionDto session,
  }) async {
    final data = await _post(
      ApiEndpoints.insertDiningSession,
      fields: {
        'userId': userId,
        'localSessionId':
            session.localSessionId ?? '${session.sessionId ?? ''}',
        'primaryTableNumber': session.primaryTableNumber,
        'joinedTableNumbers': session.joinedTableNumbers,
        'sessionStatus': session.sessionStatus,
        'guestCount': '${session.guestCount}',
        'startedAt': session.startedAt == null
            ? ''
            : _dt.format(session.startedAt!),
        'closedAt':
            session.closedAt == null ? '' : _dt.format(session.closedAt!),
        'customerName': session.customerName ?? '',
        'customerMobile': session.customerMobile ?? '',
        'waiterName': session.waiterName ?? '',
        'unpaidInvoiceNumber': session.unpaidInvoiceNumber ?? '',
        'paidAmount': session.paidAmount.toStringAsFixed(2),
        'sessionVersion': '${session.sessionVersion}',
        'sessionNetworkStatus': session.sessionNetworkStatus ?? '',
      },
    );
    return isApiSuccess(data);
  }

  Future<List<DiningSessionDto>> fetchDiningSessions(
    String userId, {
    bool openOnly = true,
  }) async {
    final data = await _get(
      ApiEndpoints.getDiningSessionList,
      query: {
        'userId': userId,
        'openOnly': openOnly ? '1' : '0',
      },
    );
    return mapJsonList(
      data[ApiResponseKeys.diningSessionResponse],
      DiningSessionDto.fromJson,
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
