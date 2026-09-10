import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_billingwala_v2/core/database/database_provider.dart';
import 'package:pos_billingwala_v2/core/network/api_client.dart';
import 'package:pos_billingwala_v2/features/auth/data/auth_api.dart';
import 'package:pos_billingwala_v2/features/auth/data/auth_repository.dart';
import 'package:pos_billingwala_v2/features/auth/data/device_identity_service.dart';
import 'package:pos_billingwala_v2/features/auth/data/session_store.dart';
import 'package:pos_billingwala_v2/features/auth/domain/user_session.dart';
import 'package:pos_billingwala_v2/features/notifications/domain/fcm_service.dart';

enum AuthStatus {
  unknown,
  unauthenticated,
  needsMpin,
  authenticated,
}

class AuthState {
  const AuthState({
    required this.status,
    this.session,
    this.errorMessage,
    this.busy = false,
  });

  final AuthStatus status;
  final UserSession? session;
  final String? errorMessage;
  final bool busy;

  AuthState copyWith({
    AuthStatus? status,
    UserSession? session,
    String? errorMessage,
    bool? busy,
    bool clearError = false,
    bool clearSession = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      session: clearSession ? null : (session ?? this.session),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      busy: busy ?? this.busy,
    );
  }
}

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    api: AuthApi(ref.watch(apiClientProvider)),
    sessionStore: SessionStore(),
    deviceIdentityService: DeviceIdentityService(),
  );
});

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState(status: AuthStatus.unknown);

  AuthRepository get _repo => ref.read(authRepositoryProvider);

  Future<void> _bindBranchScope(UserSession session) async {
    final device = await DeviceIdentityService().resolve();
    await ref.read(appDatabaseProvider).applyLicenceScope(
          session: session,
          deviceId: device.deviceId,
        );
  }

  Future<void> bootstrap() async {
    state = state.copyWith(status: AuthStatus.unknown, clearError: true);
    final session = await _repo.readStoredSession();
    if (session == null) {
      state = const AuthState(status: AuthStatus.unauthenticated);
      return;
    }
    // Bind Drift branch filters before MPIN so cold-start queries stay scoped.
    await _bindBranchScope(session);
    // Stronger than Android: require PB-PIN unlock each cold start.
    state = AuthState(status: AuthStatus.needsMpin, session: session);
  }

  Future<DeviceConflictAction> Function(String message)? _conflictHandler;

  void setDeviceConflictHandler(
    Future<DeviceConflictAction> Function(String message)? handler,
  ) {
    _conflictHandler = handler;
  }

  Future<bool> loginWithLicence(String licenceKey) async {
    state = state.copyWith(busy: true, clearError: true);
    try {
      final session = await _repo.loginWithLicence(
        licenceKey: licenceKey,
        onDeviceConflict: _conflictHandler,
      );
      ref.read(apiClientProvider).setAuthToken(session.authToken);
      await _bindBranchScope(session);
      state = AuthState(
        status: AuthStatus.authenticated,
        session: session,
      );
      // Fire-and-forget FCM registration.
      FcmService(apiClient: ref.read(apiClientProvider))
          .registerForUser(session.userId);
      return true;
    } on AuthException catch (e) {
      state = state.copyWith(
        busy: false,
        errorMessage: e.message,
        status: AuthStatus.unauthenticated,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        busy: false,
        errorMessage: 'Something went wrong.\n$e',
        status: AuthStatus.unauthenticated,
      );
      return false;
    }
  }

  Future<bool> loginWithMpin(String mpin) async {
    state = state.copyWith(busy: true, clearError: true);
    try {
      final session = await _repo.loginWithMpin(
        mpin: mpin,
        onDeviceConflict: _conflictHandler,
      );
      ref.read(apiClientProvider).setAuthToken(session.authToken);
      await _bindBranchScope(session);
      state = AuthState(
        status: AuthStatus.authenticated,
        session: session,
      );
      FcmService(apiClient: ref.read(apiClientProvider))
          .registerForUser(session.userId);
      return true;
    } on AuthException catch (e) {
      state = state.copyWith(
        busy: false,
        errorMessage: e.message,
        status: AuthStatus.needsMpin,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        busy: false,
        errorMessage: 'Something went wrong.\n$e',
        status: AuthStatus.needsMpin,
      );
      return false;
    }
  }

  Future<void> logout() async {
    final session = state.session;
    final userId = session?.userId;
    if (userId != null && userId.isNotEmpty) {
      await FcmService(apiClient: ref.read(apiClientProvider))
          .clearForUser(userId);
    }
    await _repo.clearSession(licenceKey: session?.licenceKey);
    ref.read(apiClientProvider).setAuthToken(null);
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  Future<bool> updateAppPin(String newPin) async {
    final session = state.session;
    if (session == null) return false;
    final pin = newPin.trim();
    if (pin.length != 4 || int.tryParse(pin) == null) return false;
    await SessionStore().updateAppPin(pin);
    final updated = session.copyWith(appPin: pin);
    await SessionStore().saveSession(updated);
    state = state.copyWith(session: updated);
    return true;
  }
}

final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);
