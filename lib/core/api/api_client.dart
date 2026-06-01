import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/token_storage.dart';
import 'api_endpoint_storage.dart';
import 'api_exception.dart';

/// Single Dio instance, configured once.
///
/// Base URL is selected on the login screen and stored locally so one Flutter
/// binary can manage different customer VPS installations.
class ApiClient {
  ApiClient(this._tokenStorage, this._endpointStorage) {
    _dio = Dio(
      BaseOptions(
        baseUrl: defaultApiBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Accept': 'application/json'},
        validateStatus: (s) => s != null && s < 500,
      ),
    );
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          options.baseUrl = await _endpointStorage.readBaseUrl();
          final isLogin = options.path == '/api/admin/login';
          final tok = isLogin ? null : await _tokenStorage.read();
          if (tok != null && tok.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $tok';
          }
          handler.next(options);
        },
      ),
    );
  }

  final TokenStorage _tokenStorage;
  final ApiEndpointStorage _endpointStorage;
  late final Dio _dio;
  final Map<String, Future<Map<String, dynamic>>> _inFlightGets = {};

  Dio get dio => _dio;

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? query,
  }) {
    final key = _requestKey(path, query);
    final existing = _inFlightGets[key];
    if (existing != null) return existing;
    final pending = _send('GET', path, query: query);
    _inFlightGets[key] = pending;
    return pending.whenComplete(() => _inFlightGets.remove(key));
  }

  Future<Map<String, dynamic>> post(String path, {Object? body}) =>
      _send('POST', path, body: body);

  Future<Map<String, dynamic>> put(String path, {Object? body}) =>
      _send('PUT', path, body: body);

  Future<Map<String, dynamic>> patch(String path, {Object? body}) =>
      _send('PATCH', path, body: body);

  Future<Map<String, dynamic>> delete(String path) => _send('DELETE', path);

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, dynamic>? query,
    Object? body,
  }) async {
    try {
      final res = await _dio.request<dynamic>(
        path,
        queryParameters: query,
        data: body,
        options: Options(method: method),
      );
      final data = res.data;
      if (data is Map<String, dynamic>) {
        if ((res.statusCode ?? 200) >= 400) {
          final code =
              (data['error']?['code'] ?? _statusCodeToError(res.statusCode))
                  .toString();
          final rawMessage =
              (data['error']?['message'] ?? 'Request failed').toString();
          throw ApiException(
            code: code,
            message: _apiErrorMessage(code, rawMessage),
            status: res.statusCode,
            details: data['error']?['details'],
          );
        }
        if (data['ok'] == false) {
          final code = (data['error']?['code'] ?? 'error').toString();
          final rawMessage =
              (data['error']?['message'] ?? 'Request failed').toString();
          throw ApiException(
            code: code,
            message: _apiErrorMessage(code, rawMessage),
            status: res.statusCode,
            details: data['error']?['details'],
          );
        }
        return data;
      }
      if ((res.statusCode ?? 200) >= 400) {
        final code = _statusCodeToError(res.statusCode);
        throw ApiException(
          code: code,
          message: _apiErrorMessage(code, data?.toString() ?? ''),
          status: res.statusCode,
        );
      }
      return {'ok': true, 'data': data};
    } on DioException catch (e) {
      throw ApiException(
        code: e.type.name,
        message: _networkMessage(e),
        status: e.response?.statusCode,
      );
    }
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
        _ => 'request_failed',
      };

  String _networkMessage(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout) {
      return 'انتهت مهلة الاتصال. تأكد من عنوان الخادم والمنفذ.';
    }
    if (e.type == DioExceptionType.receiveTimeout) {
      return 'الخادم تأخر في الرد. جرّب مرة أخرى أو افحص حالة الـ VPS.';
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
      'rate_limited' =>
        'تم إرسال طلبات كثيرة بسرعة. انتظر دقيقة ثم حاول مرة أخرى.',
      'not_implemented' => 'هذه الميزة غير مفعّلة على الخادم الحالي.',
      'forbidden' || 'permission_denied' => 'لا تملك صلاحية تنفيذ هذا الإجراء.',
      'unauthorized' ||
      'invalid_token' =>
        'انتهت الجلسة أو بيانات الدخول غير صحيحة. سجّل الدخول مرة أخرى.',
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

final apiClientProvider = Provider<ApiClient>((ref) {
  final storage = ref.watch(tokenStorageProvider);
  final endpointStorage = ref.watch(apiEndpointStorageProvider);
  return ApiClient(storage, endpointStorage);
});
