import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:pos_billingwala_v2/core/network/api_client.dart';
import 'package:pos_billingwala_v2/core/network/api_response.dart';
import 'package:pos_billingwala_v2/features/auth/data/device_identity_service.dart';
import 'package:pos_billingwala_v2/features/mess/domain/mess_dtos.dart';
import 'package:pos_billingwala_v2/core/constants/api_constants.dart';

class MessApi {
  MessApi(this._client);

  final ApiClient _client;

  static final _date = DateFormat('yyyy-MM-dd HH:mm:ss');

  Future<List<MessMemberDto>> fetchMembers(String userId) async {
    final data = await _get(
      ApiEndpoints.getMessMemberList,
      query: {'userId': userId},
    );
    return mapJsonList(
      data[ApiResponseKeys.memberResponse],
      MessMemberDto.fromJson,
    );
  }

  Future<MessCommonQrDto?> fetchCommonQr(String userId) async {
    final data = await _get(
      ApiEndpoints.messQrGet,
      query: {'userId': userId},
    );
    final hasQr = data['hasQr']?.toString() == '1';
    final raw = data['qr'];
    if (!hasQr || raw is! Map) return null;
    return MessCommonQrDto.fromJson(Map<String, dynamic>.from(raw));
  }

  Future<MessCommonQrDto?> generateCommonQr(
    String userId, {
    required String deviceId,
    String? deviceName,
    String messLabel = '',
    String branchLabel = '',
  }) async {
    final data = await _post(
      ApiEndpoints.messQrGenerate,
      data: {
        'userId': userId,
        'messLabel': messLabel,
        'branchLabel': branchLabel,
        ...DeviceApiFields.asForm(
          deviceId: deviceId,
          deviceName: deviceName,
        ),
      },
    );
    final raw = data['qr'];
    if (raw is! Map) return null;
    return MessCommonQrDto.fromJson(Map<String, dynamic>.from(raw));
  }

  Future<MessCommonQrDto?> regenerateCommonQr(
    String userId, {
    required String deviceId,
    String? deviceName,
    String messLabel = '',
    String branchLabel = '',
  }) async {
    final data = await _post(
      ApiEndpoints.messQrRegenerate,
      data: {
        'userId': userId,
        'messLabel': messLabel,
        'branchLabel': branchLabel,
        ...DeviceApiFields.asForm(
          deviceId: deviceId,
          deviceName: deviceName,
        ),
      },
    );
    final raw = data['qr'];
    if (raw is! Map) return null;
    return MessCommonQrDto.fromJson(Map<String, dynamic>.from(raw));
  }

  Future<bool> setCommonQrStatus(
    String userId, {
    required String status,
    required String deviceId,
    String? deviceName,
  }) async {
    final data = await _post(
      ApiEndpoints.messQrSetStatus,
      data: {
        'userId': userId,
        'status': status,
        ...DeviceApiFields.asForm(
          deviceId: deviceId,
          deviceName: deviceName,
        ),
      },
    );
    return isApiSuccess(data);
  }

  Future<bool> insertMessMember({
    required String userId,
    required MessMemberDto member,
  }) async {
    final data = await _post(
      ApiEndpoints.insertMessMember,
      data: {
        'userId': userId,
        'memberName': member.memberName,
        'memberMobileNumber': member.memberMobileNumber ?? '',
        'memberAltenetMobileNumber': member.memberAltenetMobileNumber ?? '',
        'memberAddress': member.memberAddress ?? '',
        'memberNetworkStatus': member.memberNetworkStatus ?? '',
        'memberStatus': member.memberStatus,
        'registrationNo': member.registrationNo ?? '',
        'memberType': member.memberType,
        'rollNo': member.rollNo ?? '',
        'college': member.college ?? '',
        'studentYear': member.studentYear ?? '',
        'company': member.company ?? '',
      },
    );
    return isApiSuccess(data);
  }

  Future<bool> insertMessToken({
    required String userId,
    required String tokenCode,
    String memberId = '',
    String memberName = '',
    String memberMobile = '',
    String memberType = 'member',
    String messType = 'Lunch',
    String tokenAmount = '0',
    DateTime? tokenDate,
    String tokenNetworkStatus = '',
  }) async {
    final data = await _post(
      ApiEndpoints.insertMessToken,
      data: {
        'userId': userId,
        'tokenCode': tokenCode,
        'memberId': memberId,
        'memberName': memberName,
        'memberMobile': memberMobile,
        'memberType': memberType,
        'messType': messType,
        'tokenAmount': tokenAmount,
        'tokenDate': _date.format(tokenDate ?? DateTime.now()),
        'tokenNetworkStatus': tokenNetworkStatus,
      },
    );
    return isApiSuccess(data);
  }

  Future<bool> verifyMessToken({
    required String userId,
    required String tokenCode,
    DateTime? verifiedDate,
    String verifyNetworkStatus = '',
  }) async {
    final data = await _post(
      ApiEndpoints.verifyMessToken,
      data: {
        'userId': userId,
        'tokenCode': tokenCode,
        'verifiedDate': _date.format(verifiedDate ?? DateTime.now()),
        'verifyNetworkStatus': verifyNetworkStatus,
      },
    );
    return isApiSuccess(data);
  }

  Future<List<MessMealSessionDto>> fetchMealSessions(String userId) async {
    final data = await _get(
      ApiEndpoints.messMealSessionList,
      query: {'userId': userId},
    );
    final raw = data['sessions'] ?? data['messSessions'];
    return mapJsonList(raw, MessMealSessionDto.fromJson);
  }

  Future<bool> saveMealSession({
    required String userId,
    required String sessionId,
    required String sessionName,
    required String startTime,
    required String endTime,
    required String tokenPrefix,
    required String isActive,
    String menuNotes = '',
    String sortOrder = '0',
  }) async {
    final data = await _post(
      ApiEndpoints.messMealSessionSave,
      data: {
        'userId': userId,
        'sessionId': sessionId,
        'sessionName': sessionName,
        'startTime': startTime,
        'endTime': endTime,
        'tokenPrefix': tokenPrefix,
        'isActive': isActive,
        'menuNotes': menuNotes,
        'sortOrder': sortOrder,
      },
    );
    return isApiSuccess(data);
  }

  Future<List<MessMemberPaymentDto>> fetchMemberPayments(String userId) async {
    final data = await _get(
      ApiEndpoints.getMessMemberPaymentList,
      query: {'userId': userId},
    );
    final raw = data[ApiResponseKeys.messPaymentResponse] ??
        data[ApiResponseKeys.memberResponse] ??
        data['payments'];
    return mapJsonList(raw, MessMemberPaymentDto.fromJson);
  }

  Future<bool> insertMemberPayment({
    required String userId,
    required String memberId,
    required String memberName,
    required String paymentMessAmount,
    required String paymentPaidAmount,
    required String messTotalDays,
    required String paymentDate,
    required String paymentNetworkStatus,
    String paymentStatus = '0',
  }) async {
    final data = await _post(
      ApiEndpoints.insertMessPayment,
      data: {
        'userId': userId,
        'memberId': memberId,
        'memberName': memberName,
        'paymentMessAmount': paymentMessAmount,
        'paymentPaidAmount': paymentPaidAmount,
        'messTotalDays': messTotalDays,
        'paymentDate': paymentDate,
        'paymentNetworkStatus': paymentNetworkStatus,
        'paymentStatus': paymentStatus,
      },
    );
    return isApiSuccess(data);
  }

  Future<MessMealTokenTodayResult> fetchMealTokensToday(
    String userId, {
    String? date,
  }) async {
    final day = date ?? DateFormat('yyyy-MM-dd').format(DateTime.now());
    final data = await _get(
      ApiEndpoints.messMealTokenToday,
      query: {'userId': userId, 'date': day},
    );
    return MessMealTokenTodayResult(
      tokens: mapJsonList(
        data[ApiResponseKeys.messMealTokens] ?? data['messMealTokens'],
        MessMealTokenDto.fromJson,
      ),
      sessionCounts: mapJsonList(
        data[ApiResponseKeys.messSessionCounts] ?? data['messSessionCounts'],
        MessSessionCountDto.fromJson,
      ),
    );
  }

  Future<bool> ackMealTokenPrint({
    required String userId,
    required String tokenId,
    required String result,
    required String deviceId,
    String? deviceName,
  }) async {
    final data = await _post(
      ApiEndpoints.messMealTokenPrintAck,
      data: {
        'userId': userId,
        'tokenId': tokenId,
        'result': result,
        ...DeviceApiFields.asForm(
          deviceId: deviceId,
          deviceName: deviceName,
        ),
      },
    );
    return isApiSuccess(data);
  }

  Future<bool> cancelMealToken({
    required String userId,
    required String tokenId,
  }) async {
    final data = await _post(
      ApiEndpoints.messMealTokenCancel,
      data: {
        'userId': userId,
        'tokenId': tokenId,
      },
    );
    return isApiSuccess(data);
  }

  Future<List<MessInvoiceDto>> fetchMessInvoices(String userId) async {
    final data = await _get(
      ApiEndpoints.getMessInvoiceList,
      query: {'userId': userId},
    );
    return mapJsonList(
      data[ApiResponseKeys.messInvoiceResponse],
      MessInvoiceDto.fromJson,
    );
  }

  Future<bool> insertMessInvoice({
    required String userId,
    required String memberName,
    required String messType,
    required String messInvoiceDate,
    required String messInvoiceNetworkStatus,
    String messInvoiceStatus = '0',
  }) async {
    final data = await _post(
      ApiEndpoints.insertMessInvoice,
      data: {
        'userId': userId,
        'memberName': memberName,
        'messType': messType,
        'messInvoiceDate': messInvoiceDate,
        'messInvoiceNetworkStatus': messInvoiceNetworkStatus,
        'messInvoiceStatus': messInvoiceStatus,
      },
    );
    return isApiSuccess(data);
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
    Map<String, dynamic>? data,
  }) async {
    final response = await _client.dio.post<dynamic>(
      path,
      data: data == null ? null : FormData.fromMap(data),
      options: Options(responseType: ResponseType.json),
    );
    return asJsonMap(response.data);
  }
}
