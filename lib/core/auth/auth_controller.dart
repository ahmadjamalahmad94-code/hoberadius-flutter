import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/notifications/push/push_service.dart';
import '../api/api_client.dart';
import '../api/api_endpoint_storage.dart';
import '../api/api_exception.dart';
import 'security_key_storage.dart';
import 'token_storage.dart';

class AuthAdmin {
  AuthAdmin({
    required this.id,
    required this.username,
    this.fullName = '',
    this.email = '',
    this.isSuperAdmin = false,
    this.avatarUrl = '',
  });

  final int id;
  final String username;
  final String fullName;
  final String email;
  final bool isSuperAdmin;
  final String avatarUrl;

  factory AuthAdmin.fromJson(Map<String, dynamic> j) => AuthAdmin(
        id: (j['id'] as int?) ?? 0,
        username: (j['username'] ?? '').toString(),
        fullName: (j['full_name'] ?? '').toString(),
        email: (j['email'] ?? '').toString(),
        isSuperAdmin: j['is_super_admin'] == true,
        avatarUrl: (j['avatar_url'] ?? '').toString(),
      );
}

class AuthState {
  const AuthState({
    this.token,
    this.admin,
    this.tenantId,
    this.permissions = const [],
    this.serverBaseUrl,
    this.loading = false,
    this.error,
  });

  final String? token;
  final AuthAdmin? admin;
  final int? tenantId;
  final List<String> permissions;
  final String? serverBaseUrl;
  final bool loading;
  final String? error;

  bool get isAuthenticated => token != null && token!.isNotEmpty;

  AuthState copyWith({
    String? token,
    AuthAdmin? admin,
    int? tenantId,
    List<String>? permissions,
    String? serverBaseUrl,
    bool? loading,
    String? error,
    bool clear = false,
    bool clearError = false,
  }) =>
      clear
          ? const AuthState()
          : AuthState(
              token: token ?? this.token,
              admin: admin ?? this.admin,
              tenantId: tenantId ?? this.tenantId,
              permissions: permissions ?? this.permissions,
              serverBaseUrl: serverBaseUrl ?? this.serverBaseUrl,
              loading: loading ?? this.loading,
              error: clearError ? null : (error ?? this.error),
            );
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._ref) : super(const AuthState()) {
    _restore();
  }

  final Ref _ref;

  Future<void> _restore() async {
    final stored = await _ref.read(tokenStorageProvider).read();
    final serverBaseUrl =
        await _ref.read(apiEndpointStorageProvider).readBaseUrl();
    if (stored == null || stored.isEmpty) {
      state = AuthState(serverBaseUrl: serverBaseUrl);
      return;
    }
    state = state.copyWith(
      token: stored,
      serverBaseUrl: serverBaseUrl,
      loading: true,
    );
    try {
      final res = await _ref.read(apiClientProvider).get('/api/admin/me');
      final d = (res['data'] ?? {}) as Map<String, dynamic>;
      state = AuthState(
        token: stored,
        admin: d['admin'] is Map<String, dynamic>
            ? AuthAdmin.fromJson(d['admin'] as Map<String, dynamic>)
            : null,
        tenantId: d['tenant_id'] as int?,
        permissions: ((d['permissions'] as List?) ?? const [])
            .map((e) => e.toString())
            .toList(),
        serverBaseUrl: serverBaseUrl,
      );
    } on ApiException {
      await _ref.read(tokenStorageProvider).clear();
      state = AuthState(serverBaseUrl: serverBaseUrl);
    } catch (_) {
      // Network glitch: keep the token so the next refresh can recover.
      state = state.copyWith(loading: false);
    }
  }

  Future<void> login({
    required String baseUrl,
    required String username,
    required String password,
    String securityKey = '',
  }) async {
    state = state.copyWith(
      loading: true,
      serverBaseUrl: baseUrl,
      clearError: true,
    );
    try {
      await _ref.read(tokenStorageProvider).clear();
      await _ref.read(apiEndpointStorageProvider).writeBaseUrl(baseUrl);
      // Persist the per-deployment security key BEFORE the login call so the
      // request itself carries `X-API-Key` (a gateway in front of Flask may
      // require it even on the public login route). Empty clears any stale key.
      final secStore = _ref.read(securityKeyStorageProvider);
      final trimmedKey = securityKey.trim();
      if (trimmedKey.isEmpty) {
        await secStore.clear();
      } else {
        await secStore.write(trimmedKey);
      }
      final res = await _ref.read(apiClientProvider).post(
        '/api/admin/login',
        body: {'username': username, 'password': password},
      );
      final d = (res['data'] ?? {}) as Map<String, dynamic>;
      final token = (d['token'] ?? '').toString();
      if (token.isEmpty) {
        throw ApiException(
          code: 'empty_token',
          message: 'استجابة تسجيل الدخول غير مكتملة.',
        );
      }
      await _ref.read(tokenStorageProvider).write(token);
      state = AuthState(
        token: token,
        admin: d['admin'] is Map<String, dynamic>
            ? AuthAdmin.fromJson(d['admin'] as Map<String, dynamic>)
            : null,
        tenantId: d['tenant_id'] as int?,
        permissions: ((d['permissions'] as List?) ?? const [])
            .map((e) => e.toString())
            .toList(),
        serverBaseUrl: baseUrl,
      );
    } on ApiException catch (e) {
      state = AuthState(serverBaseUrl: baseUrl, error: e.message);
    } catch (_) {
      state = AuthState(
        serverBaseUrl: baseUrl,
        error: 'تعذّر الاتصال بالخادم. تأكد من العنوان والبروتوكول.',
      );
    }
  }

  Future<void> logout() async {
    // Unregister this device's push token before clearing the session so the
    // signed-out device stops receiving pushes (no-op off mobile).
    try {
      await _ref.read(pushServiceProvider).onLogout(_ref);
    } catch (_) {/* best-effort */}
    try {
      await _ref.read(apiClientProvider).post('/api/admin/logout');
    } catch (_) {/* best-effort */}
    await _ref.read(tokenStorageProvider).clear();
    final serverBaseUrl =
        await _ref.read(apiEndpointStorageProvider).readBaseUrl();
    state = AuthState(serverBaseUrl: serverBaseUrl);
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) => AuthController(ref),
);
