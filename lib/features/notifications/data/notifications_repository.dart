import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../domain/notification_model.dart';

/// Wraps `GET/POST /api/v1/notifications` (Bearer admin token, tenant-scoped).
class NotificationsRepository {
  NotificationsRepository(this._api);

  final ApiClient _api;

  Future<NotificationsPage> list({
    bool unreadOnly = false,
    int limit = 30,
    int offset = 0,
  }) async {
    final res = await _api.get(
      '/api/v1/notifications',
      query: {
        if (unreadOnly) 'unread_only': 'true',
        'limit': limit,
        'offset': offset,
      },
    );
    final data = res['data'];
    if (data is Map) {
      return NotificationsPage.fromJson(
        data.map((k, v) => MapEntry(k.toString(), v)),
      );
    }
    return NotificationsPage.empty;
  }

  Future<int> unreadCount() async {
    final res = await _api.get('/api/v1/notifications/unread-count');
    final data = res['data'];
    if (data is Map) return _int(data['unread_count']);
    return 0;
  }

  /// Marks one read; returns the resulting unread count.
  Future<int> markRead(int id) async {
    final res = await _api.post('/api/v1/notifications/$id/read');
    final data = res['data'];
    if (data is Map) return _int(data['unread_count']);
    return 0;
  }

  /// Marks all read; returns the resulting unread count (0).
  Future<int> markAllRead() async {
    final res = await _api.post('/api/v1/notifications/read-all');
    final data = res['data'];
    if (data is Map) return _int(data['unread_count']);
    return 0;
  }
}

final notificationsRepositoryProvider =
    Provider<NotificationsRepository>((ref) {
  return NotificationsRepository(ref.read(apiClientProvider));
});

int _int(Object? v, [int fallback = 0]) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? fallback;
  return fallback;
}
