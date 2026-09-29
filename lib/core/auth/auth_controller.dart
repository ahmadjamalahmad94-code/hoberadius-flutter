import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/notifications/push/push_service.dart';
import '../api/api_client.dart';
import '../api/api_endpoint_storage.dart';
import '../api/api_exception.dart';
import '../format/currency.dart';
import '../format/panel_time.dart';
import 'permissions.dart';
import 'security_key_storage.dart';
import 'session_reset.dart';
import 'system_settings.dart';
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
    this.systemCurrency = '',
  });

  /// `data.system.currency` of /api/admin/me or the login answer — the
  /// tenant's effective currency (empty on older servers).
  final String systemCurrency;

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
    String? systemCurrency,
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
              systemCurrency: systemCurrency ?? this.systemCurrency,
            );
}

/// `system.currency` of an /api/admin/me or login payload ('' if absent).
String systemCurrencyOf(Map<String, dynamic> data) {
  final system = data['system'];
  if (system is! Map) return '';
  return '${system['currency'] ?? ''}'.trim().toUpperCase();
}

/// Applies the panel time zone of an /api/admin/me or login payload.
///
/// Reads the zone NAME (`system.timezone`, or the older `system.tz_name`)
/// — DST comes from the bundled tz database — and, as a fallback for an
/// unknown name, the current offset (`system.utc_offset_minutes` /
/// `tz_offset_minutes`, or the legacy hour value `system.tz_offset`).
/// Returns false when the payload carries no zone (older servers) so the
/// caller can ask /api/v1/settings.
bool applyPanelTimeZoneFrom(Map<String, dynamic> data) {
  final system = data['system'];
  if (system is! Map) return false;
  final name = '${system['timezone'] ?? system['tz_name'] ?? ''}'.trim();
  num? read(Object? v) => v is num ? v : num.tryParse('${v ?? ''}');
  final minutes = read(system['utc_offset_minutes']) ??
      read(system['tz_offset_minutes']) ??
      read(system['offset_minutes']);
  final hours = minutes != null ? minutes / 60 : read(system['tz_offset']);
  if (name.isEmpty && hours == null) return false;
  PanelTimeZone.configure(
    name: name,
    offsetHours: hours,
    label: '${system['timezone_label'] ?? ''}',
  );
  return true;
}

/// Same from /api/v1/settings: `system.tz_*`, else the raw
/// `billing.timezone` / `billing.timezone_offset` settings.
bool applyPanelTimeZoneFromSettings(Map<String, dynamic> data) {
  if (applyPanelTimeZoneFrom(data)) return true;
  final settings = data['settings'];
  if (settings is! Map) return false;
  final name = '${settings['billing.timezone'] ?? ''}'.trim();
  final off = num.tryParse('${settings['billing.timezone_offset'] ?? ''}');
  if (name.isEmpty && off == null) return false;
  PanelTimeZone.configure(name: name, offsetHours: off);
  return true;
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._ref) : super(const AuthState()) {
    _ref.listen<ApiClient>(
      apiClientProvider,
      (_, client) => client
        ..onUnauthorized = _onUnauthorized
        // Any 403 that still happens: the grants changed server-side (a
        // revoke while signed in) — re-read them so the UI hides what the
        // server now refuses. Throttled inside the controller.
        ..onForbidden = (_) => _permissions?.refresh(),
      fireImmediately: true,
    );
    _restore();
  }

  /// A 401 on any authenticated call: the token is dead (revoked by a
  /// password change elsewhere, admin disabled, expired). Sign out cleanly —
  /// the router sends the user to the login screen, which shows why.
  Future<void> _onUnauthorized(ApiException e) async {
    if (!state.isAuthenticated || state.loading) return;
    final serverBaseUrl = state.serverBaseUrl;
    await _ref.read(tokenStorageProvider).clear();
    _resetSession();
    final msg = e.message.trim();
    state = AuthState(
      serverBaseUrl: serverBaseUrl,
      error: msg.isEmpty
          ? 'انتهت الجلسة. سجّل الدخول مرة أخرى.'
          : '$msg${msg.contains('سجّل الدخول') ? '' : ' سجّل الدخول مرة أخرى.'}',
    );
  }

  final Ref _ref;

  PermissionsController? get _permissions {
    try {
      return _ref.read(permissionsProvider.notifier);
    } catch (_) {
      return null; // container disposed
    }
  }

  /// Sign-in / sign-out: drop the previous account's grants and cached
  /// app-wide state so nothing of it shows under the next account.
  void _resetSession() {
    _permissions?.clear();
    try {
      _ref.read(createWithoutExpiryProvider.notifier).state = null;
    } catch (_) {/* container disposed */}
    resetSessionScopedState(_ref);
  }

  void _publishCurrency(String code) {
    try {
      _ref.read(sessionCurrencyProvider.notifier).state = code;
    } catch (_) {/* container disposed */}
  }

  /// The panel's time zone: from the session payload, else from the
  /// settings API (older servers); never fatal.
  Future<void> _loadPanelTimeZone(Map<String, dynamic> data) async {
    publishCreateWithoutExpiry(_ref, data);
    if (applyPanelTimeZoneFrom(data)) return;
    // Settings need «عرض الإعدادات»: don't ask for a known 403.
    final perms = _ref.read(permissionsProvider);
    if (perms.loaded && !perms.can('settings.view')) return;
    try {
      final res = await _ref
          .read(apiClientProvider)
          .get('/api/v1/settings', background: true);
      final d = res['data'];
      if (d is Map<String, dynamic>) {
        applyPanelTimeZoneFromSettings(d);
        publishCreateWithoutExpiry(_ref, d);
      }
    } catch (_) {/* keep the phone's zone */}
  }

  /// The login answer carries no `system` block (fix2-final: only /me
  /// does): read it from /api/admin/me — the panel zone (Gaza), the
  /// currency and `create_without_expiry` — so a manager without
  /// «عرض الإعدادات» does not fall back to the phone's zone. Grants stay
  /// the login answer's. Null when /me is unreachable or has no system.
  Future<Map<String, dynamic>?> _systemFromMe() async {
    try {
      final res = await _ref
          .read(apiClientProvider)
          .get('/api/admin/me', background: true);
      final d = res['data'];
      if (d is Map<String, dynamic> && d['system'] is Map) {
        return {'system': d['system']};
      }
    } catch (_) {/* older server / offline: the settings fallback */}
    return null;
  }

  /// Applies the grants of `/api/admin/me`, falling back to [loginData]
  /// when /me is unreachable (never fails the sign-in).
  /// Returns the /me payload (null when it was unreachable).
  Future<Map<String, dynamic>?> _applyMe(Map<String, dynamic> loginData) async {
    try {
      final res = await _ref
          .read(apiClientProvider)
          .get('/api/admin/me', background: true);
      final me = res['data'];
      _permissions?.apply(me is Map<String, dynamic> ? me : loginData);
      return me is Map<String, dynamic> ? me : null;
    } catch (_) {
      _permissions?.apply(loginData);
      return null;
    }
  }

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
      // Grants first: the router's first redirect must already see them.
      _permissions?.apply(d);
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
        systemCurrency: systemCurrencyOf(d),
      );
      _publishCurrency(state.systemCurrency);
      await _loadPanelTimeZone(d);
    } on ApiException {
      await _ref.read(tokenStorageProvider).clear();
      _permissions?.clear();
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
      _resetSession();
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
      // Grants of the login answer (permmodel); an older login answer has
      // none, so read /me (older /me has none either → legacy, show all).
      // Applied before the session state so the first redirect sees them.
      Map<String, dynamic>? meData;
      if (d['grants'] is Map) {
        _permissions?.apply(d);
      } else {
        meData = await _applyMe(d);
      }
      final Map<String, dynamic> session;
      if (d['system'] is Map) {
        session = d;
      } else if (meData != null) {
        session = {...d, if (meData['system'] is Map) 'system': meData['system']};
      } else {
        session = {...d, ...?await _systemFromMe()};
      }
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
        systemCurrency: systemCurrencyOf(session),
      );
      _publishCurrency(state.systemCurrency);
      await _loadPanelTimeZone(session);
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
    _resetSession();
    PanelTimeZone.reset();
    final serverBaseUrl =
        await _ref.read(apiEndpointStorageProvider).readBaseUrl();
    state = AuthState(serverBaseUrl: serverBaseUrl);
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) => AuthController(ref),
);
