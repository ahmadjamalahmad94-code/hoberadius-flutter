import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_endpoint_storage.dart';
import '../../../core/api/api_exception.dart';
import '../domain/subscriber_portal_model.dart';

class SubscriberPortalRepository {
  SubscriberPortalRepository(
    this._endpointStorage, {
    Dio? dio,
  }) : dio = dio ?? _createDio();

  final ApiEndpointStorage _endpointStorage;
  final Dio dio;

  Future<SubscriberPortalLoginResult> login({
    required String baseUrl,
    required String username,
    required String password,
    int tenantId = 1,
  }) async {
    await _endpointStorage.writeBaseUrl(baseUrl);
    final payload = await _post(
      '/api/v1/subscriber-portal/login',
      tenantId: tenantId,
      explicitBaseUrl: baseUrl,
      body: {
        'username': username.trim(),
        'password': password,
      },
    );
    return SubscriberPortalLoginResult.fromJson(payload);
  }

  Future<SubscriberPortalProfile> me({
    required String token,
    int tenantId = 1,
  }) async {
    final payload = await _get(
      '/api/v1/subscriber-portal/me',
      token: token,
      tenantId: tenantId,
    );
    return SubscriberPortalProfile.fromJson(payload);
  }

  Future<SubscriberPortalDashboard> dashboard({
    required String token,
    int tenantId = 1,
  }) async {
    final payload = await _get(
      '/api/v1/subscriber-portal/dashboard',
      token: token,
      tenantId: tenantId,
    );
    return SubscriberPortalDashboard.fromJson(_map(payload['dashboard']));
  }

  Future<List<SubscriberPortalRequest>> requests({
    required String token,
    int tenantId = 1,
  }) async {
    final payload = await _get(
      '/api/v1/subscriber-portal/requests',
      token: token,
      tenantId: tenantId,
    );
    final items = payload['items'];
    if (items is! List) return const [];
    return items
        .whereType<Map>()
        .map((item) => SubscriberPortalRequest.fromJson(_map(item)))
        .toList();
  }

  Future<SubscriberPortalRequest> requestDetail({
    required String token,
    required int requestId,
    int tenantId = 1,
  }) async {
    final payload = await _get(
      '/api/v1/subscriber-portal/requests/$requestId',
      token: token,
      tenantId: tenantId,
    );
    final item = payload['request'] ?? payload['item'] ?? payload;
    return SubscriberPortalRequest.fromJson(
      _map(item is Map ? item : payload),
    );
  }

  Future<SubscriberPortalRequest> loanRequest({
    required String token,
    required int requestedMinutes,
    required String reason,
    int tenantId = 1,
  }) async {
    final payload = await _post(
      '/api/v1/subscriber-portal/loan-request',
      token: token,
      tenantId: tenantId,
      body: {
        'requested_minutes': requestedMinutes,
        'reason': reason.trim(),
      },
    );
    return SubscriberPortalRequest.fromJson(_map(payload['request']));
  }

  Future<SubscriberPortalRequest> renewalRequest({
    required String token,
    required String reason,
    int tenantId = 1,
  }) async {
    final payload = await _post(
      '/api/v1/subscriber-portal/renewal-request',
      token: token,
      tenantId: tenantId,
      body: {'reason': reason.trim()},
    );
    return SubscriberPortalRequest.fromJson(_map(payload['request']));
  }

  Future<void> logout({
    required String token,
    int tenantId = 1,
  }) async {
    await _post(
      '/api/v1/subscriber-portal/logout',
      token: token,
      tenantId: tenantId,
    );
  }

  Future<Map<String, dynamic>> _get(
    String path, {
    String token = '',
    int tenantId = 1,
  }) async {
    await _applyBaseUrl();
    try {
      final res = await dio.get<Object?>(
        path,
        options: Options(headers: _headers(token: token, tenantId: tenantId)),
      );
      return _payload(res);
    } on DioException catch (error) {
      throw _dioError(error);
    }
  }

  Future<Map<String, dynamic>> _post(
    String path, {
    Map<String, Object?> body = const {},
    String token = '',
    int tenantId = 1,
    String? explicitBaseUrl,
  }) async {
    if (explicitBaseUrl != null) {
      dio.options.baseUrl = explicitBaseUrl;
    } else {
      await _applyBaseUrl();
    }
    try {
      final res = await dio.post<Object?>(
        path,
        data: body,
        options: Options(headers: _headers(token: token, tenantId: tenantId)),
      );
      return _payload(res);
    } on DioException catch (error) {
      throw _dioError(error);
    }
  }

  Future<void> _applyBaseUrl() async {
    dio.options.baseUrl = await _endpointStorage.readBaseUrl();
  }

  Map<String, String> _headers({required String token, required int tenantId}) {
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'X-Tenant-Id': tenantId.toString(),
      if (token.trim().isNotEmpty) 'Authorization': 'Bearer ${token.trim()}',
    };
  }

  Map<String, dynamic> _payload(Response<Object?> res) {
    final data = res.data;
    final map = data is Map ? _map(data) : <String, dynamic>{};
    final status = res.statusCode ?? 0;
    if (map['ok'] == false || status >= 400) {
      throw _portalError(map, status);
    }
    if (map.isEmpty) {
      throw ApiException(
        code: 'invalid_response',
        message: 'استجابة الخادم غير واضحة. حاول مرة أخرى.',
        status: status,
      );
    }
    return map;
  }

  ApiException _portalError(Map<String, dynamic> map, int status) {
    final code = _string(map['error']).isNotEmpty
        ? _string(map['error'])
        : _statusCodeToCode(status);
    final serverMessage = _string(map['message']);
    return ApiException(
      code: code,
      message: _portalMessage(code, serverMessage),
      status: status,
      details: map,
    );
  }

  ApiException _dioError(DioException error) {
    if (error.response != null) {
      return _portalError(
        _map(error.response!.data),
        error.response!.statusCode ?? 0,
      );
    }
    final code = switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.sendTimeout =>
        'timeout',
      _ => 'connection_error',
    };
    return ApiException(
      code: code,
      message: _portalMessage(code, ''),
      details: error.message,
    );
  }

  static Dio _createDio() {
    return Dio(
      BaseOptions(
        baseUrl: defaultApiBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 20),
        sendTimeout: const Duration(seconds: 10),
        validateStatus: (status) => status != null && status < 500,
      ),
    );
  }
}

final subscriberPortalRepositoryProvider =
    Provider<SubscriberPortalRepository>((ref) {
  return SubscriberPortalRepository(ref.watch(apiEndpointStorageProvider));
});

Map<String, dynamic> _map(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, val) => MapEntry(key.toString(), val));
  }
  return const {};
}

String _string(Object? value) => (value ?? '').toString().trim();

String _statusCodeToCode(int status) => switch (status) {
      401 => 'token_required',
      403 => 'forbidden',
      404 => 'request_not_found',
      429 => 'rate_limited',
      _ => 'portal_error',
    };

String _portalMessage(String code, String serverMessage) => switch (code) {
      'invalid_credentials' => 'اسم المستخدم أو كلمة المرور غير صحيحة.',
      'token_required' ||
      'token_expired' =>
        'انتهت جلسة بوابة المشترك. سجل الدخول مرة أخرى.',
      'forbidden' => 'لا تملك صلاحية تنفيذ هذا الإجراء.',
      'request_not_found' => 'الطلب غير موجود أو لا يتبع حسابك.',
      'validation_error' =>
        serverMessage.isNotEmpty ? serverMessage : 'قيمة الطلب غير صحيحة.',
      'rate_limited' =>
        'محاولات كثيرة بسرعة. انتظر قليلًا ثم حاول مرة أخرى.',
      'timeout' =>
        'انتهت مهلة الطلب. تحقق من الاتصال ثم حاول مرة أخرى.',
      'connection_error' =>
        'تعذر الوصول إلى الخادم. تأكد من العنوان والمنفذ ونوع الاتصال.',
      _ => serverMessage.isNotEmpty
          ? serverMessage
          : 'تعذر تنفيذ الطلب. حاول مرة أخرى.',
    };
