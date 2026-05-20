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
        OnlineSessionKind.subscribers => 'المشتركين',
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

final onlineSessionsProvider = FutureProvider.autoDispose
    .family<List<OnlineSession>, OnlineSessionsQuery>((ref, query) {
  return ref.watch(sessionsRepositoryProvider).listOnline(
        kind: query.kind,
        search: query.search,
      );
});
