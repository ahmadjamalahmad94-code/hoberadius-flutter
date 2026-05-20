import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../domain/subscriber_model.dart';

class SubscribersRepository {
  SubscribersRepository(this._api);
  final ApiClient _api;

  Future<List<Subscriber>> list({String? status, int limit = 100, int offset = 0}) async {
    final res = await _api.get('/api/v1/accounts', query: {
      if (status != null) 'status': status,
      'limit': limit,
      'offset': offset,
    },);
    final items = (res['data']?['items'] ?? res['items'] ?? []) as List;
    return items
        .whereType<Map<String, dynamic>>()
        .map(Subscriber.fromJson)
        .toList();
  }

  Future<Subscriber> get(String username) async {
    final res = await _api.get('/api/v1/accounts/$username');
    return Subscriber.fromJson(_payload(res));
  }

  Future<Subscriber> create(Subscriber s) async {
    final res = await _api.post('/api/v1/accounts', body: s.toCreateBody());
    return Subscriber.fromJson(_payload(res));
  }

  Future<Subscriber> update(Subscriber s) async {
    final res = await _api.patch('/api/v1/accounts/${s.username}', body: s.toPatchBody());
    return Subscriber.fromJson(_payload(res));
  }

  Future<void> delete(String username) => _api.delete('/api/v1/accounts/$username');

  Future<void> disable(String username) =>
      _api.post('/api/v1/accounts/$username/disable');

  Future<void> enable(String username) =>
      _api.post('/api/v1/accounts/$username/enable');

  Future<DateTime?> extendTime(String username, int minutes) async {
    final res = await _api.post(
      '/api/v1/accounts/$username/extend_time',
      body: {'minutes': minutes},
    );
    final raw = (res['data'] ?? const {})['new_expire_at'];
    if (raw == null) return null;
    try {
      return DateTime.parse(raw.toString().replaceAll('Z', ''));
    } catch (_) {
      return null;
    }
  }

  Future<void> resetPassword(String username, String newPassword) =>
      _api.post(
        '/api/v1/accounts/$username/reset_password',
        body: {'new_password': newPassword},
      );

  Map<String, dynamic> _payload(Map<String, dynamic> res) {
    final d = res['data'];
    if (d is Map<String, dynamic>) return d;
    return res;
  }
}

final subscribersRepositoryProvider = Provider<SubscribersRepository>((ref) {
  return SubscribersRepository(ref.watch(apiClientProvider));
});
