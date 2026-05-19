import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/token_storage.dart';
import 'api_exception.dart';

/// Single Dio instance, configured once.
///
/// Base URL is read from env via --dart-define=API_BASE_URL=...; defaults to
/// http://localhost:5000 (the radius-module Flask dev server). The Bearer
/// token is pulled lazily from secure storage on each request so login state
/// updates don't require a Dio rebuild.
class ApiClient {
  ApiClient(this._tokenStorage) {
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Accept': 'application/json'},
        validateStatus: (s) => s != null && s < 500,
      ),
    );
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final tok = await _tokenStorage.read();
          if (tok != null && tok.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $tok';
          }
          handler.next(options);
        },
      ),
    );
  }

  static const String _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:5000',
  );

  final TokenStorage _tokenStorage;
  late final Dio _dio;

  Dio get dio => _dio;

  Future<Map<String, dynamic>> get(String path, {Map<String, dynamic>? query}) =>
      _send('GET', path, query: query);

  Future<Map<String, dynamic>> post(String path, {Object? body}) =>
      _send('POST', path, body: body);

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
        if (data['ok'] == false) {
          throw ApiException(
            code: (data['error']?['code'] ?? 'error').toString(),
            message: (data['error']?['message'] ?? 'Request failed').toString(),
            status: res.statusCode,
            details: data['error']?['details'],
          );
        }
        return data;
      }
      return {'ok': true, 'data': data};
    } on DioException catch (e) {
      throw ApiException(
        code: e.type.name,
        message: e.message ?? 'Network error',
        status: e.response?.statusCode,
      );
    }
  }
}

final apiClientProvider = Provider<ApiClient>((ref) {
  final storage = ref.watch(tokenStorageProvider);
  return ApiClient(storage);
});
