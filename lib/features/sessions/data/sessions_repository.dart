import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../domain/session_model.dart';

class SessionsRepository {
  SessionsRepository(this._api);
  final ApiClient _api;

  Future<List<OnlineSession>> listOnline() async {
    final res = await _api.get('/api/v1/sessions/online');
    final items = (res['data']?['items'] ?? const []) as List;
    return items
        .whereType<Map<String, dynamic>>()
        .map(OnlineSession.fromJson)
        .toList();
  }

  Future<void> disconnect({required String username, String? sessionId}) {
    return _api.post(
      '/api/v1/sessions/disconnect',
      body: {
        'username': username,
        if (sessionId != null && sessionId.isNotEmpty) 'session_id': sessionId,
      },
    );
  }
}

final sessionsRepositoryProvider = Provider<SessionsRepository>((ref) {
  return SessionsRepository(ref.watch(apiClientProvider));
});

final onlineSessionsProvider =
    FutureProvider.autoDispose<List<OnlineSession>>((ref) {
  return ref.watch(sessionsRepositoryProvider).listOnline();
});
