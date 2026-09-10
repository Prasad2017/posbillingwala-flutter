import 'package:dio/dio.dart';
import 'package:pos_billingwala_v2/core/network/api_client.dart';
import 'package:pos_billingwala_v2/core/network/api_response.dart';
import 'package:pos_billingwala_v2/features/auth/data/device_identity_service.dart';
import 'package:pos_billingwala_v2/core/constants/api_constants.dart';

class FcmApi {
  FcmApi(this._client);

  final ApiClient _client;

  Future<bool> registerToken({
    required String userId,
    required String deviceId,
    required String fcmToken,
  }) async {
    final response = await _client.dio.post<dynamic>(
      ApiEndpoints.registerFcmToken,
      data: FormData.fromMap({
        'userId': userId,
        'fcm_token': fcmToken,
        ...DeviceApiFields.asForm(
          deviceId: deviceId,
          includeAndroidIdAlias: false,
          includeDeviceIdAlias: false,
          includeDeviceName: false,
        ),
      }),
      options: Options(responseType: ResponseType.json),
    );
    return isApiSuccess(asJsonMap(response.data));
  }
}
