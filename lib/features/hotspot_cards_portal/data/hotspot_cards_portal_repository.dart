import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_endpoint_storage.dart';
import '../../../core/api/api_exception.dart';
import '../domain/hotspot_cards_portal_model.dart';

class HotspotCardsPortalRepository {
  HotspotCardsPortalRepository(
    this._endpointStorage, {
    Dio? dio,
  }) : dio = dio ?? _createDio();

  final ApiEndpointStorage _endpointStorage;
  final Dio dio;

  Future<HotspotPortalLoginResult> login({
    required String baseUrl,
    required String username,
    required String password,
    int tenantId = 1,
  }) async {
    await _endpointStorage.writeBaseUrl(baseUrl);
    final payload = await _post(
      '/api/v1/hotspot/cards/login',
      tenantId: tenantId,
      body: {
        'username': username.trim(),
        'password': password,
      },
      explicitBaseUrl: baseUrl,
    );
    return HotspotPortalLoginResult.fromJson(payload);
  }

  Future<HotspotPortalProfile> me({
    required String token,
    int tenantId = 1,
  }) async {
    final payload = await _get(
      '/api/v1/hotspot/cards/me',
      token: token,
      tenantId: tenantId,
    );
    return HotspotPortalProfile.fromJson(payload);
  }

  Future<List<HotspotCatalogItem>> catalog({
    required String token,
    int tenantId = 1,
  }) async {
    final payload = await _get(
      '/api/v1/hotspot/cards/catalog',
      token: token,
      tenantId: tenantId,
    );
    final items = payload['items'];
    if (items is! List) return const [];
    return items
        .whereType<Map>()
        .map((item) => HotspotCatalogItem.fromJson(_map(item)))
        .toList();
  }

  Future<List<HotspotOwnedCard>> myCards({
    required String token,
    int tenantId = 1,
  }) async {
    final payload = await _get(
      '/api/v1/hotspot/cards/my-cards',
      token: token,
      tenantId: tenantId,
    );
    final items = payload['items'];
    if (items is! List) return const [];
    return items
        .whereType<Map>()
        .map((item) => HotspotOwnedCard.fromJson(_map(item)))
        .toList();
  }

  Future<HotspotPurchaseResult> purchase({
    required String token,
    required String catalogItemId,
    required String clientRequestId,
    int tenantId = 1,
  }) async {
    final payload = await _post(
      '/api/v1/hotspot/cards/purchase',
      token: token,
      tenantId: tenantId,
      body: {
        'catalog_item_id': catalogItemId,
        'client_request_id': clientRequestId,
      },
    );
    return HotspotPurchaseResult.fromJson(payload);
  }

  Future<void> sendSms({
    required String token,
    required String purchaseId,
    required String phone,
    int tenantId = 1,
  }) async {
    await _post(
      '/api/v1/hotspot/cards/send-sms',
      token: token,
      tenantId: tenantId,
      body: {
        'purchase_id': purchaseId,
        'phone': phone.trim(),
      },
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
    return ApiException(
      code: code,
      message: _portalMessage(code),
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
      message: _portalMessage(code),
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

final hotspotCardsPortalRepositoryProvider =
    Provider<HotspotCardsPortalRepository>((ref) {
  return HotspotCardsPortalRepository(ref.watch(apiEndpointStorageProvider));
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
      402 => 'insufficient_balance',
      403 => 'forbidden',
      404 => 'not_found',
      409 => 'catalog_item_unavailable',
      429 => 'rate_limited',
      _ => 'portal_error',
    };

String _portalMessage(String code) => switch (code) {
      'invalid_credentials' => 'اسم المستخدم أو كلمة المرور غير صحيحة.',
      'inactive_account' => 'الحساب غير مفعل أو منتهي.',
      'token_required' ||
      'token_expired' =>
        'انتهت جلسة بوابة الكروت. سجل الدخول مرة أخرى.',
      'forbidden' => 'لا تملك صلاحية تنفيذ هذا الإجراء.',
      'catalog_item_not_found' => 'الباقة المطلوبة غير موجودة.',
      'catalog_item_unavailable' => 'هذه الباقة غير متاحة حاليًا.',
      'insufficient_balance' => 'رصيد المحفظة غير كافٍ لإتمام الشراء.',
      'purchase_failed' => 'تعذر إتمام عملية الشراء. حاول مرة أخرى.',
      'sms_not_configured' => 'إرسال الرسائل غير مفعّل على الخادم الحالي.',
      'invalid_phone' => 'رقم الجوال غير صحيح.',
      'rate_limited' => 'محاولات كثيرة بسرعة. انتظر قليلًا ثم حاول مرة أخرى.',
      'timeout' => 'انتهت مهلة الطلب. تحقق من الاتصال ثم حاول مرة أخرى.',
      'connection_error' =>
        'تعذر الوصول إلى الخادم. تأكد من العنوان والمنفذ ونوع الاتصال.',
      _ => 'تعذر تنفيذ الطلب. حاول مرة أخرى.',
    };
