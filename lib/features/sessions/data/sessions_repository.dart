import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../domain/session_model.dart';

enum OnlineSessionKind { all, subscribers, cards }

extension OnlineSessionKindApi on OnlineSessionKind {
  String get apiValue => switch (this) {
        OnlineSessionKind.all => 'all',
        OnlineSessionKind.subscribers => 'subscriber',
        OnlineSessionKind.cards => 'card',
      };

  String get label => switch (this) {
        OnlineSessionKind.all => 'الكل',
        OnlineSessionKind.subscribers => 'المشتركون',
        OnlineSessionKind.cards => 'الكروت',
      };
}

class OnlineSessionsQuery {
  const OnlineSessionsQuery({
    this.kind = OnlineSessionKind.all,
    this.search = '',
  });

  final OnlineSessionKind kind;
  final String search;

  Map<String, String> toApiQuery() => {
        'type': kind.apiValue,
        if (search.trim().isNotEmpty) 'q': search.trim(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OnlineSessionsQuery &&
          other.kind == kind &&
          other.search == search;

  @override
  int get hashCode => Object.hash(kind, search);
}

class SessionsRepository {
  SessionsRepository(this._api);

  final ApiClient _api;

  Future<List<OnlineSession>> listOnline({
    OnlineSessionKind kind = OnlineSessionKind.all,
    String search = '',
  }) async {
    final res = await _api.get(
      '/api/v1/sessions/online',
      query: OnlineSessionsQuery(kind: kind, search: search).toApiQuery(),
    );
    final items = (res['data']?['items'] ?? const []) as List;
    return items
        .whereType<Map<String, dynamic>>()
        .map(OnlineSession.fromJson)
        .toList();
  }

  Map<String, String> _sessionBody({
    required String username,
    required String sessionId,
  }) =>
      {
        'username': username,
        'session_id': sessionId,
      };

  Future<void> disconnect({required String username, String? sessionId}) {
    return _api.post(
      '/api/v1/sessions/disconnect',
      body: {
        'username': username,
        if (sessionId != null && sessionId.isNotEmpty) 'session_id': sessionId,
      },
    );
  }

  Future<void> lockMac({
    required String username,
    required String sessionId,
  }) {
    return _api.post(
      '/api/v1/sessions/lock-mac',
      body: _sessionBody(username: username, sessionId: sessionId),
    );
  }

  Future<void> lockIp({
    required String username,
    required String sessionId,
  }) {
    return _api.post(
      '/api/v1/sessions/lock-ip',
      body: _sessionBody(username: username, sessionId: sessionId),
    );
  }

  Future<Map<String, dynamic>> applyTemporarySpeed({
    required String username,
    required String sessionId,
    required int downloadKbps,
    required int uploadKbps,
    required int durationMinutes,
  }) async {
    final res = await _api.post(
      '/api/v1/sessions/temp-speed',
      body: {
        'username': username,
        'session_id': sessionId,
        'down_kbps': downloadKbps,
        'up_kbps': uploadKbps,
        'duration_minutes': durationMinutes,
      },
    );
    return _mapData(res);
  }

  Future<Map<String, dynamic>> cancelTemporarySpeed({
    required String username,
    required String sessionId,
  }) async {
    final res = await _api.post(
      '/api/v1/sessions/temp-speed/cancel',
      body: _sessionBody(username: username, sessionId: sessionId),
    );
    return _mapData(res);
  }

  Future<List<AccountingSessionHistory>> listHistory({int limit = 50}) async {
    final res = await _api.get(
      '/api/v1/accounting/sessions',
      query: {'limit': limit.toString()},
    );
    final items = (res['data']?['items'] ?? const []) as List;
    return items
        .whereType<Map<String, dynamic>>()
        .map(AccountingSessionHistory.fromJson)
        .toList();
  }

  Map<String, dynamic> _mapData(Map<String, dynamic> res) {
    final data = res['data'];
    if (data is Map<String, dynamic>) return data;
    if (data is Map) {
      return data.map((key, value) => MapEntry(key.toString(), value));
    }
    return const {};
  }
}

final sessionsRepositoryProvider = Provider<SessionsRepository>((ref) {
  return SessionsRepository(ref.watch(apiClientProvider));
});

final onlineSessionsProvider = FutureProvider.autoDispose
    .family<List<OnlineSession>, OnlineSessionsQuery>((ref, query) {
  return ref.watch(sessionsRepositoryProvider).listOnline(
        kind: query.kind,
        search: query.search,
      );
});

final accountingHistoryProvider =
    FutureProvider.autoDispose<List<AccountingSessionHistory>>((ref) {
  return ref.watch(sessionsRepositoryProvider).listHistory();
});
