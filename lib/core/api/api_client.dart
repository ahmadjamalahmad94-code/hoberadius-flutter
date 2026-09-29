import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/security_key_storage.dart';
import '../auth/token_storage.dart';
import 'api_endpoint_storage.dart';
import 'api_exception.dart';

/// Tunable transport policy for [ApiClient]. Values are deliberately
/// conservative so the app never hangs indefinitely and never overwhelms the
/// VPS (which would trip the server's rate limiter / connection ceiling).
class ApiClientConfig {
  const ApiClientConfig({
    this.connectTimeout = const Duration(seconds: 10),
    this.receiveTimeout = const Duration(seconds: 30),
    this.sendTimeout = const Duration(seconds: 30),
    this.maxRetries = 3,
    this.baseBackoff = const Duration(milliseconds: 300),
    this.maxBackoff = const Duration(seconds: 5),
    this.maxRetryAfterSeconds = 30,
    this.maxConcurrentRequests = 6,
  });

  /// Time to establish the TCP/TLS connection before failing.
  final Duration connectTimeout;

  /// Time to wait for the response once connected. A MISSING receive timeout is
  /// the usual cause of "the app hangs forever" — this guarantees a bound.
  final Duration receiveTimeout;

  /// Time to upload the request body (POST/PUT) before failing.
  final Duration sendTimeout;

  /// Extra attempts after the first for transient failures (network error,
  /// timeout, 502/503/504, 429). 0 disables retries.
  final int maxRetries;

  /// First backoff step; grows exponentially with jitter up to [maxBackoff].
  final Duration baseBackoff;
  final Duration maxBackoff;

  /// Upper bound honoured from a 429 `Retry-After`; longer waits are capped so
  /// the UI never blocks for minutes.
  final int maxRetryAfterSeconds;

  /// Max simultaneous in-flight requests. Excess requests queue. 0 = unlimited.
  final int maxConcurrentRequests;
}

/// Single Dio instance, configured once.
///
/// Base URL is selected on the login screen and stored locally so one Flutter
/// binary can manage different customer VPS installations.
///
/// Every request carries two credentials so it passes the hardened web auth
/// (global `/api` guard): the bearer **token** (`Authorization: Bearer`) and,
/// when the operator has configured one, the per-deployment **security key**
/// (`X-API-Key`). Transient failures are retried with backoff, 429s honour
/// `Retry-After`, and a concurrency cap keeps the server from being flooded —
/// every failure path resolves to a visible Arabic error, never a dead spinner.
class ApiClient {
  ApiClient(
    this._tokenStorage,
    this._endpointStorage, {
    SecurityKeyStorage? securityKeyStorage,
    ApiClientConfig? config,
  })  : _securityKeyStorage = securityKeyStorage,
        _config = config ?? const ApiClientConfig() {
    _semaphore = _Semaphore(_config.maxConcurrentRequests);
    _dio = Dio(
      BaseOptions(
        baseUrl: defaultApiBaseUrl,
        connectTimeout: _config.connectTimeout,
        receiveTimeout: _config.receiveTimeout,
        sendTimeout: _config.sendTimeout,
        headers: {'Accept': 'application/json'},
        // Accept every status so HTTP errors (incl. 429/5xx) flow through the
        // unified parse + retry logic instead of throwing as DioExceptions.
        validateStatus: (_) => true,
      ),
    );
    // One bad ledger row with Infinity/NaN made whole lists invalid JSON
    // (distributors, profit-loss…) and the app blamed the network. Decode
    // tolerantly (non-finite → null) — see [decodeJsonTolerant].
    _dio.transformer = BackgroundTransformer()
      ..jsonDecodeCallback = decodeJsonTolerant;
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          options.baseUrl = await _endpointStorage.readBaseUrl();
          final isLogin = options.path == '/api/admin/login';
          final tok = isLogin ? null : await _tokenStorage.read();
          if (tok != null && tok.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $tok';
          }
          // The security key is a transport-level credential (checked by the
          // global API guard / any edge gateway), so it is sent on EVERY
          // request including login — the public login route ignores it, but a
          // gateway in front of Flask would otherwise reject the call.
          final secKey = await _securityKeyStorage?.read();
          if (secKey != null && secKey.isNotEmpty) {
            options.headers['X-API-Key'] = secKey;
          }
          handler.next(options);
        },
      ),
    );
  }

  final TokenStorage _tokenStorage;
  final ApiEndpointStorage _endpointStorage;
  final SecurityKeyStorage? _securityKeyStorage;
  final ApiClientConfig _config;
  late final Dio _dio;
  late final _Semaphore _semaphore;
  final Map<String, Future<Map<String, dynamic>>> _inFlightGets = {};
  final Random _random = Random();

  Dio get dio => _dio;

  /// Called when an authenticated request answers 401 (token revoked after
  /// a password change on another device, admin disabled, expired session).
  /// The auth controller signs the user out and shows the server's message
  /// instead of leaving every screen in an error loop.
  void Function(ApiException error)? onUnauthorized;

  static const _loginPath = '/api/admin/login';

  /// [background]: a best-effort read (e.g. the panel time zone after a
  /// sign-in) whose 401 must not sign the operator out by itself.
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? query,
    bool background = false,
  }) {
    if (background) {
      return _send('GET', path, query: query, background: true);
    }
    final key = _requestKey(path, query);
    final existing = _inFlightGets[key];
    if (existing != null) return existing;
    final pending = _send('GET', path, query: query);
    _inFlightGets[key] = pending;
    return pending.whenComplete(() => _inFlightGets.remove(key));
  }

  /// [headers] carries per-request extras such as `Idempotency-Key` (money
  /// actions); servers that do not know a header simply ignore it.
  Future<Map<String, dynamic>> post(
    String path, {
    Object? body,
    Map<String, String>? headers,
  }) =>
      _send('POST', path, body: body, headers: headers);

  Future<Map<String, dynamic>> put(
    String path, {
    Object? body,
    Map<String, String>? headers,
  }) =>
      _send('PUT', path, body: body, headers: headers);

  Future<Map<String, dynamic>> patch(
    String path, {
    Object? body,
    Map<String, String>? headers,
  }) =>
      _send('PATCH', path, body: body, headers: headers);

  Future<Map<String, dynamic>> delete(
    String path, {
    Object? body,
    Map<String, String>? headers,
  }) =>
      _send('DELETE', path, body: body, headers: headers);

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, dynamic>? query,
    Object? body,
    Map<String, String>? headers,
    bool background = false,
  }) async {
    final idempotent = _isIdempotent(method);
    final isLogin = path == _loginPath;
    var attempt = 0;
    while (true) {
      attempt += 1;
      final canRetry = attempt <= _config.maxRetries;

      Response<dynamic>? res;
      DioException? dioErr;
      await _semaphore.acquire();
      try {
        res = await _dio.request<dynamic>(
          path,
          queryParameters: query,
          data: body,
          options: Options(
            method: method,
            headers: headers == null || headers.isEmpty ? null : headers,
          ),
        );
      } on DioException catch (e) {
        dioErr = e;
      } finally {
        _semaphore.release();
      }

      // ── A response that is not valid JSON (not a network failure) ──
      if (dioErr != null && dioErr.error is FormatException) {
        throw ApiException(
          code: 'bad_response',
          message: 'وصل ردّ غير صالح من الخادم (بيانات تالفة). '
              'أعد المحاولة أو أبلغ الدعم الفني.',
          status: dioErr.response?.statusCode,
        );
      }
      // ── Transport-level failure (no HTTP response): network / timeout ──
      if (dioErr != null) {
        if (idempotent && canRetry && _isRetryableDio(dioErr)) {
          await Future<void>.delayed(_backoff(attempt));
          continue;
        }
        throw ApiException(
          code: dioErr.type.name,
          message: _networkMessage(dioErr),
          status: dioErr.response?.statusCode,
        );
      }

      final status = res!.statusCode ?? 200;

      // ── 429: honour Retry-After (capped), else backoff. Never for the
      // login: a 429 there is the lockout after repeated wrong passwords and
      // must be shown at once, not retried for minutes. ──
      if (status == 429 && canRetry && !isLogin) {
        await Future<void>.delayed(_retryDelayFor429(res, attempt));
        continue;
      }

      // ── 502/503/504: retry idempotent requests with backoff ──
      if (idempotent && canRetry && _isRetryableStatus(status)) {
        await Future<void>.delayed(_backoff(attempt));
        continue;
      }

      try {
        return _parseResponse(res);
      } on ApiException catch (e) {
        if (e.status == 401 && !isLogin && !background) {
          onUnauthorized?.call(e);
        }
        rethrow;
      }
    }
  }

  Map<String, dynamic> _parseResponse(Response<dynamic> res) {
    final data = res.data;
    final status = res.statusCode ?? 200;
    if (data is Map<String, dynamic>) {
      if (status >= 400 || data['ok'] == false) {
        final err = _errorFields(data['error']);
        final code = (err['code'] ??
                (status >= 400 ? _statusCodeToError(status) : 'error'))
            .toString();
        final rawMessage = (err['message'] ?? 'تعذّر تنفيذ الطلب').toString();
        throw ApiException(
          code: code,
          message: _apiErrorMessage(code, rawMessage),
          status: status,
          details: err['details'],
        );
      }
      return data;
    }
    if (status >= 400) {
      final code = _statusCodeToError(status);
      throw ApiException(
        code: code,
        message: _apiErrorMessage(code, data?.toString() ?? ''),
        status: status,
      );
    }
    return {'ok': true, 'data': data};
  }

  /// The API envelope puts `{code, message, details}` under `error`, but a
  /// few framework-level failures (413 body-too-large, some proxies) send a
  /// flat `{"ok":false,"status":"too_large","error":"<text>"}` instead.
  /// Normalise both to one map so the caller never crashes on a String.
  static Map<String, dynamic> _errorFields(dynamic error) {
    if (error is Map) {
      return error.map((k, v) => MapEntry(k.toString(), v));
    }
    if (error is String && error.isNotEmpty) {
      return {'message': error};
    }
    return const {};
  }

  bool _isIdempotent(String method) {
    final m = method.toUpperCase();
    return m == 'GET' || m == 'HEAD' || m == 'PUT' || m == 'DELETE';
  }

  bool _isRetryableStatus(int status) =>
      status == 502 || status == 503 || status == 504;

  bool _isRetryableDio(DioException e) {
    // A set (not an exhaustive switch) so newer dio versions that add enum
    // values (e.g. transformTimeout in dio 5.9) keep compiling in CI.
    const retryable = {
      DioExceptionType.connectionTimeout,
      DioExceptionType.receiveTimeout,
      DioExceptionType.sendTimeout,
      DioExceptionType.connectionError,
    };
    return retryable.contains(e.type);
  }

  /// Exponential backoff with full jitter, capped at [ApiClientConfig.maxBackoff].
  Duration _backoff(int attempt) {
    final exp = _config.baseBackoff.inMilliseconds * pow(2, attempt - 1);
    final capped =
        min(exp.toDouble(), _config.maxBackoff.inMilliseconds.toDouble());
    final jittered = capped * (0.5 + _random.nextDouble() * 0.5);
    return Duration(milliseconds: jittered.round());
  }

  Duration _retryDelayFor429(Response<dynamic> res, int attempt) {
    final cap = _config.maxRetryAfterSeconds;
    final header = res.headers.value('retry-after');
    final headerSecs = header == null ? null : int.tryParse(header.trim());
    if (headerSecs != null) {
      return Duration(seconds: headerSecs.clamp(0, cap));
    }
    // Flask surfaces the hint in the error body when the header is absent.
    final data = res.data;
    if (data is Map) {
      final error = data['error'];
      final details = error is Map ? error['details'] : null;
      final hint = details is Map ? details['retry_after_seconds'] : null;
      final secs = hint is int ? hint : int.tryParse('${hint ?? ''}');
      if (secs != null) return Duration(seconds: secs.clamp(0, cap));
    }
    return _backoff(attempt);
  }

  String _requestKey(String path, Map<String, dynamic>? query) {
    if (query == null || query.isEmpty) return path;
    final parts = query.entries
        .where((entry) => entry.value != null)
        .map((entry) => MapEntry(entry.key, entry.value.toString()))
        .toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return '$path?${parts.map((e) => '${e.key}=${e.value}').join('&')}';
  }

  String _statusCodeToError(int? statusCode) => switch (statusCode) {
        400 => 'bad_request',
        401 => 'unauthorized',
        403 => 'forbidden',
        404 => 'not_found',
        409 => 'conflict',
        422 => 'validation_error',
        429 => 'rate_limited',
        502 || 503 || 504 => 'server_unavailable',
        _ => 'request_failed',
      };

  String _networkMessage(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout) {
      return 'انتهت مهلة الاتصال. تأكد من عنوان الخادم والمنفذ.';
    }
    if (e.type == DioExceptionType.receiveTimeout) {
      return 'الخادم تأخر في الرد. جرّب مرة أخرى أو افحص حالة الـ VPS.';
    }
    if (e.type == DioExceptionType.sendTimeout) {
      return 'تأخّر إرسال الطلب للخادم. تحقّق من الاتصال ثم حاول مرة أخرى.';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'تعذّر الوصول للخادم. تأكد من IP والمنفذ، وأن HTTP/HTTPS صحيح، وأن لوحة HobeRadius تعمل على الخادم.';
    }
    if (e.type == DioExceptionType.badCertificate) {
      return 'شهادة HTTPS غير مقبولة. استخدم شهادة صحيحة أو جرّب HTTP إذا كان الخادم داخليًا.';
    }
    return e.message ?? 'تعذّر الاتصال بالخادم.';
  }

  String _apiErrorMessage(String code, String rawMessage) {
    final normalized = code.trim().toLowerCase();
    return switch (normalized) {
      'rate_limited' ||
      'too_many_attempts' ||
      'login_locked' =>
        _containsArabic(rawMessage)
            ? rawMessage.trim()
            : 'تم إرسال طلبات كثيرة بسرعة. انتظر قليلًا ثم حاول مرة أخرى.',
      'server_unavailable' =>
        'الخادم غير متاح حاليًا (صيانة أو ضغط مؤقت). حاول بعد قليل.',
      'not_implemented' => 'هذه الميزة غير مفعّلة على الخادم الحالي.',
      // The server's own Arabic reason (e.g. «لا تملك صلاحية تعديل
      // المشتركين») is more useful than the generic line.
      'forbidden' || 'permission_denied' => _containsArabic(rawMessage)
          ? rawMessage.trim()
          : 'لا تملك صلاحية تنفيذ هذا الإجراء.',
      'unauthorized' ||
      'invalid_token' ||
      'token_revoked' ||
      'token_expired' =>
        _containsArabic(rawMessage)
            ? rawMessage.trim()
            : 'انتهت الجلسة أو بيانات الدخول غير صحيحة. سجّل الدخول مرة أخرى.',
      'validation_error' ||
      'bad_request' =>
        _safeVisibleMessage(rawMessage, 'تأكد من البيانات المدخلة.'),
      _ => _safeVisibleMessage(rawMessage, 'تعذّر تنفيذ الطلب.'),
    };
  }

  String _safeVisibleMessage(String rawMessage, String fallback) {
    final msg = rawMessage.trim();
    if (msg.isEmpty) return fallback;
    if (_containsArabic(msg)) return msg;
    final lower = msg.toLowerCase();
    if (lower.contains('invalid') &&
        (lower.contains('password') ||
            lower.contains('credential') ||
            lower.contains('login') ||
            lower.contains('username'))) {
      return 'اسم المستخدم أو كلمة المرور غير صحيحة.';
    }
    if (lower.contains('csrf')) {
      return 'انتهت صلاحية نموذج الحماية. حدّث الصفحة ثم حاول مرة أخرى.';
    }
    if (lower.contains('not found')) {
      return 'العنصر المطلوب غير موجود.';
    }
    // Older servers answer field validation in English
    // («credit_limit must be >= 0», «name is required»): say WHICH field
    // instead of one generic line for everything.
    final field = RegExp(
      r'^([a-z][a-z0-9_]*) (must|is required|should|cannot|is invalid|invalid)',
    ).firstMatch(lower);
    if (field != null) {
      final required = lower.contains('required');
      return required
          ? 'الحقل «${field.group(1)}» مطلوب.'
          : 'قيمة الحقل «${field.group(1)}» غير صحيحة.';
    }
    if (lower.contains('already exists') || lower.contains('duplicate')) {
      return 'القيمة مستخدمة مسبقًا (مكرّرة). غيّر الاسم أو المعرّف.';
    }
    if (lower.contains('timeout')) {
      return 'انتهت مهلة الطلب. حاول مرة أخرى.';
    }
    if (lower.contains('server') || lower.contains('internal')) {
      return 'حدث خطأ داخلي في الخادم.';
    }
    if (lower.contains('request failed') || lower.contains('bad request')) {
      return fallback;
    }
    return fallback;
  }

  bool _containsArabic(String value) {
    return value.runes.any(
      (r) =>
          (r >= 0x0600 && r <= 0x06FF) ||
          (r >= 0x0750 && r <= 0x077F) ||
          (r >= 0x08A0 && r <= 0x08FF) ||
          (r >= 0xFB50 && r <= 0xFDFF) ||
          (r >= 0xFE70 && r <= 0xFEFF),
    );
  }
}

/// Bounded async semaphore — caps simultaneous in-flight requests so the app
/// can't exhaust the server's connection/rate ceiling. `maxConcurrent <= 0`
/// disables the cap (unlimited).
class _Semaphore {
  _Semaphore(this.maxConcurrent);

  final int maxConcurrent;
  int _current = 0;
  final Queue<Completer<void>> _waiters = Queue<Completer<void>>();

  Future<void> acquire() {
    if (maxConcurrent <= 0) return Future<void>.value();
    if (_current < maxConcurrent) {
      _current += 1;
      return Future<void>.value();
    }
    final completer = Completer<void>();
    _waiters.add(completer);
    return completer.future;
  }

  void release() {
    if (maxConcurrent <= 0) return;
    if (_waiters.isNotEmpty) {
      _waiters.removeFirst().complete();
    } else if (_current > 0) {
      _current -= 1;
    }
  }
}

/// `jsonDecode` that survives the non-standard `Infinity` / `-Infinity` /
/// `NaN` tokens Python's json module emits for non-finite floats: they are
/// read as `null` (the row still shows, the bad value is blank).
Object? decodeJsonTolerant(String source) {
  try {
    return jsonDecode(source);
  } on FormatException {
    final cleaned = source.replaceAllMapped(
      RegExp(r'([:\[,]\s*)-?(?:Infinity|NaN)(?=\s*[,\]}])'),
      (m) => '${m.group(1)}null',
    );
    return jsonDecode(cleaned);
  }
}

final apiClientProvider = Provider<ApiClient>((ref) {
  final storage = ref.watch(tokenStorageProvider);
  final endpointStorage = ref.watch(apiEndpointStorageProvider);
  final securityKeyStorage = ref.watch(securityKeyStorageProvider);
  return ApiClient(
    storage,
    endpointStorage,
    securityKeyStorage: securityKeyStorage,
  );
});
