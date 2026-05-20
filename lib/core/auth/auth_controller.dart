import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../api/api_exception.dart';
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
    this.loading = false,
    this.error,
  });

  final String? token;
  final AuthAdmin? admin;
  final int? tenantId;
  final List<String> permissions;
  final bool loading;
  final String? error;

  bool get isAuthenticated => token != null && token!.isNotEmpty;

  AuthState copyWith({
    String? token,
    AuthAdmin? admin,
    int? tenantId,
    List<String>? permissions,
    bool? loading,
    String? error,
    bool clear = false,
    bool clearError = false,
  }) => clear
      ? const AuthState()
      : AuthState(
          token: token ?? this.token,
          admin: admin ?? this.admin,
          tenantId: tenantId ?? this.tenantId,
          permissions: permissions ?? this.permissions,
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
    if (stored == null || stored.isEmpty) return;
    state = state.copyWith(token: stored, loading: true);
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
      );
    } on ApiException {
      await _ref.read(tokenStorageProvider).clear();
      state = const AuthState();
    } catch (_) {
      // Network glitch — keep the token, app stays "loading" until next try.
      state = state.copyWith(loading: false);
    }
  }

  Future<void> login({required String username, required String password}) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final res = await _ref.read(apiClientProvider).post(
        '/api/admin/login',
        body: {'username': username, 'password': password},
      );
      final d = (res['data'] ?? {}) as Map<String, dynamic>;
      final token = (d['token'] ?? '').toString();
      if (token.isEmpty) {
        throw ApiException(code: 'empty_token', message: 'استجابة بلا token');
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
      );
    } on ApiException catch (e) {
      state = AuthState(error: e.message);
    } catch (e) {
      state = const AuthState(error: 'تعذّر الاتصال بالخادم');
    }
  }

  Future<void> logout() async {
    try {
      await _ref.read(apiClientProvider).post('/api/admin/logout');
    } catch (_) {/* best-effort */}
    await _ref.read(tokenStorageProvider).clear();
    state = const AuthState();
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) => AuthController(ref));
