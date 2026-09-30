import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/paging.dart';
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
  }) async =>
      (await listOnlinePage(kind: kind, search: search)).items;

  /// One page of `/sessions/online`. Updated servers page the WHOLE open
  /// set (limit/offset → total, has_more, types); older ones return up to
  /// 500 rows and ignore offset — the controller then stops on a page that
  /// brings nothing new.
  Future<OnlineSessionsPage> listOnlinePage({
    OnlineSessionKind kind = OnlineSessionKind.all,
    String search = '',
    int limit = 100,
    int offset = 0,
  }) async {
    final res = await _api.get(
      '/api/v1/sessions/online',
      query: {
        ...OnlineSessionsQuery(kind: kind, search: search).toApiQuery(),
        'limit': '$limit',
        'offset': '$offset',
      },
    );
    final data = res['data'] is Map
        ? Map<String, dynamic>.from(res['data'] as Map)
        : const <String, dynamic>{};
    final raw = (data['items'] ?? const []) as List;
    final items = raw
        .whereType<Map>()
        .map((m) => OnlineSession.fromJson(Map<String, dynamic>.from(m)))
        .toList();
    final info = readPageInfo(
      data,
      requestedLimit: limit,
      offset: offset,
      itemCount: raw.length,
    );
    final types = data['types'] is Map
        ? (data['types'] as Map).map(
            (k, v) => MapEntry(k.toString(), v is num ? v.toInt() : 0),
          )
        : null;
    return OnlineSessionsPage(
      items: items,
      total: info.total,
      hasMore: info.hasMore,
      typeCounts: types,
    );
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
    required int duration,
    required String durationUnit,
  }) async {
    final res = await _api.post(
      '/api/v1/sessions/temp-speed',
      body: {
        'username': username,
        'session_id': sessionId,
        'down_kbps': downloadKbps,
        'up_kbps': uploadKbps,
        'duration': duration,
        // Server accepts minutes|hours; mirrors the web temp-speed form.
        'duration_unit': durationUnit,
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

class OnlineSessionsPage {
  const OnlineSessionsPage({
    required this.items,
    required this.hasMore,
    this.total,
    this.typeCounts,
  });

  final List<OnlineSession> items;
  final bool hasMore;

  /// Every matching open session on the server (null on older servers).
  final int? total;

  /// `types` counters of the whole filtered result ({subscriber, card}).
  final Map<String, int>? typeCounts;
}

/// Loaded online sessions + the server's whole-result counters.
class OnlineSessionsState {
  const OnlineSessionsState({
    required this.list,
    this.typeCounts,
  });

  final PagedList<OnlineSession> list;
  final Map<String, int>? typeCounts;

  List<OnlineSession> get items => list.items;
}

/// Infinite-scroll controller for «المتصلون الآن». The list was capped at
/// the first 500 open sessions; updated servers page the whole set.
class OnlineSessionsController extends AutoDisposeFamilyAsyncNotifier<
    OnlineSessionsState, OnlineSessionsQuery> {
  static const pageSize = 100;

  static String _key(OnlineSession s) => '${s.username}|${s.sessionId}';

  @override
  Future<OnlineSessionsState> build(OnlineSessionsQuery arg) async {
    final page = await ref.watch(sessionsRepositoryProvider).listOnlinePage(
          kind: arg.kind,
          search: arg.search,
          limit: pageSize,
        );
    return OnlineSessionsState(
      list: PagedList<OnlineSession>(
        items: page.items,
        hasMore: page.hasMore && page.items.isNotEmpty,
        total: page.total,
        nextOffset: page.items.length,
      ),
      typeCounts: page.typeCounts,
    );
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.list.hasMore || current.list.loadingMore) {
      return;
    }
    state = AsyncData(
      OnlineSessionsState(
        list: current.list.copyWith(loadingMore: true, loadMoreError: null),
        typeCounts: current.typeCounts,
      ),
    );
    try {
      final page = await ref.read(sessionsRepositoryProvider).listOnlinePage(
            kind: arg.kind,
            search: arg.search,
            limit: pageSize,
            offset: current.list.nextOffset,
          );
      final (merged, added) =
          mergeUniqueBy(current.list.items, page.items, _key);
      state = AsyncData(
        OnlineSessionsState(
          list: current.list.copyWith(
            items: merged,
            hasMore: page.hasMore && added > 0,
            total: page.total ?? current.list.total,
            nextOffset: current.list.nextOffset + page.items.length,
            loadingMore: false,
          ),
          typeCounts: page.typeCounts ?? current.typeCounts,
        ),
      );
    } catch (e) {
      state = AsyncData(
        OnlineSessionsState(
          list: current.list.copyWith(loadingMore: false, loadMoreError: e),
          typeCounts: current.typeCounts,
        ),
      );
    }
  }
}

final sessionsRepositoryProvider = Provider<SessionsRepository>((ref) {
  return SessionsRepository(ref.watch(apiClientProvider));
});

final onlineSessionsProvider = AsyncNotifierProvider.autoDispose
    .family<OnlineSessionsController, OnlineSessionsState, OnlineSessionsQuery>(
  OnlineSessionsController.new,
);

/// The whole network's online counters, whatever tab / search is on.
class OnlineTotals {
  const OnlineTotals({
    required this.total,
    required this.subscribers,
    required this.cards,
  });
  final int total;
  final int subscribers;
  final int cards;
}

/// One unfiltered `/sessions/online?limit=1` read: `total` + `types`.
final onlineTotalsProvider =
    FutureProvider.autoDispose<OnlineTotals>((ref) async {
  final page =
      await ref.watch(sessionsRepositoryProvider).listOnlinePage(limit: 1);
  final types = page.typeCounts ?? const <String, int>{};
  final subs = types['subscriber'] ?? 0;
  final cards = types['card'] ?? 0;
  return OnlineTotals(
    total: page.total ?? (subs + cards),
    subscribers: subs,
    cards: cards,
  );
});

final accountingHistoryProvider =
    FutureProvider.autoDispose<List<AccountingSessionHistory>>((ref) {
  return ref.watch(sessionsRepositoryProvider).listHistory();
});
