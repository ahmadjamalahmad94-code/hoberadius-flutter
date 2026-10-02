import 'package:hoberadius_app/core/format/money_limits.dart';
import 'package:hoberadius_app/core/format/number_input.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/api/paging.dart';
import '../domain/subscriber_360_model.dart';
import '../domain/subscriber_model.dart';
import 'package:hoberadius_app/core/format/server_time.dart';

class SubscribersRepository {
  SubscribersRepository(this._api);
  final ApiClient _api;

  Future<List<Subscriber>> list({
    String? status,
    int? expiringWithinDays,
    String search = '',
    int limit = 100,
    int offset = 0,
  }) async =>
      (await listPage(
        status: status,
        expiringWithinDays: expiringWithinDays,
        search: search,
        limit: limit,
        offset: offset,
      ))
          .items;

  /// One page of `GET /api/v1/accounts` searched and filtered ON THE SERVER
  /// (the whole tenant, not the newest 100). `search` is sent as both `q`
  /// (new contract) and `search` (older servers). `total`/`has_more` are read
  /// when the server sends them; an old server's missing total falls back to
  /// «a full page means there may be more».
  Future<SubscribersPage> listPage({
    String? status,
    int? expiringWithinDays,
    String search = '',
    String? access,
    int limit = 50,
    int offset = 0,
  }) async {
    // Arabic keyboards type «٠٥٩٩…»: the server stores Latin digits.
    final q = latinizeDigits(search.trim());
    final res = await _api.get(
      '/api/v1/accounts',
      query: {
        if (status != null && status.isNotEmpty) 'status': status,
        if (expiringWithinDays != null)
          'expiring_within_days': expiringWithinDays,
        if (q.isNotEmpty) 'q': q,
        if (q.isNotEmpty) 'search': q,
        // hotspot | broadband (older servers ignore it)
        if (access != null && access.isNotEmpty) 'access': access,
        'limit': limit,
        'offset': offset,
      },
    );
    final data = res['data'] is Map<String, dynamic>
        ? res['data'] as Map<String, dynamic>
        : res;
    final raw = (data['items'] ?? res['items'] ?? const []) as List;
    final items = raw
        .whereType<Map>()
        .map((m) => Subscriber.fromJson(Map<String, dynamic>.from(m)))
        .toList();
    final info = readPageInfo(
      data,
      requestedLimit: limit,
      offset: offset,
      itemCount: raw.length,
    );
    return SubscribersPage(
      items: items,
      rawCount: raw.length,
      total: info.total,
      hasMore: info.hasMore,
    );
  }

  Future<Subscriber> get(String username) async {
    final res = await _api.get('/api/v1/accounts/$username');
    return Subscriber.fromJson(_payload(res));
  }

  Future<Subscriber360> get360(String username) async {
    final res = await _api.get('/api/v1/accounts/$username/360');
    return Subscriber360.fromJson(_payload(res));
  }

  Future<Subscriber> create(Subscriber s, {bool explicitNoExpiry = false}) async {
    // The form validates first; this guards every other caller too.
    final problem = validateNewSubscriberUsername(s.username) ??
        validateNewSubscriberPassword(s.password);
    if (problem != null) {
      throw ApiException(code: 'validation_error', message: problem);
    }
    // Older servers UPSERT on an existing username (the whole subscriber was
    // silently overwritten: plan, expiry, debt, password). Refuse up front;
    // updated servers answer 409 on their own.
    if (await _exists(s.username.trim())) {
      throw ApiException(
        code: 'conflict',
        message: 'اسم المستخدم مستخدم مسبقًا.',
        status: 409,
      );
    }
    final res = await _api.post(
      '/api/v1/accounts',
      body: s.toCreateBody(explicitNoExpiry: explicitNoExpiry),
    );
    return Subscriber.fromJson(_payload(res));
  }

  Future<bool> _exists(String username) async {
    try {
      await _api.get('/api/v1/accounts/${Uri.encodeComponent(username)}');
      return true;
    } catch (_) {
      // 404 = free. Any other failure: let the server decide (409 there).
      return false;
    }
  }

  Future<Subscriber> update(Subscriber s) async {
    final res = await _api.patch(
      '/api/v1/accounts/${s.username}',
      body: s.toPatchBody(),
    );
    return Subscriber.fromJson(_payload(res));
  }

  /// PATCH with only the fields the operator changed (see
  /// [Subscriber.toPatchDiff]). Nothing changed → no request at all.
  Future<Subscriber?> updateChanged(
    String username,
    Map<String, dynamic> changes,
  ) async {
    if (changes.isEmpty) return null;
    final res = await _api.patch(
      '/api/v1/accounts/${Uri.encodeComponent(username)}',
      body: changes,
    );
    return Subscriber.fromJson(_payload(res));
  }

  Future<void> delete(String username) =>
      _api.delete('/api/v1/accounts/$username');

  Future<void> disable(String username) =>
      _api.post('/api/v1/accounts/$username/disable');

  Future<void> enable(String username) =>
      _api.post('/api/v1/accounts/$username/enable');

  Future<DateTime?> extendTime(String username, int minutes) async {
    // Owner rule: at most a year per extension — refused before sending.
    final tooLong = validateExtendSpan(minutes);
    if (tooLong != null) {
      throw ApiException(code: 'validation_error', message: tooLong);
    }
    final res = await _api.post(
      '/api/v1/accounts/$username/extend_time',
      body: {'minutes': minutes},
    );
    final raw = (res['data'] ?? const {})['new_expire_at'];
    if (raw == null) return null;
    try {
      return parseServerDateTime(raw);
    } catch (_) {
      return null;
    }
  }

  Future<void> resetPassword(String username, String newPassword) => _api.post(
        '/api/v1/accounts/$username/reset_password',
        body: {'new_password': newPassword},
      );

  /// Names of the subscriber groups (`GET /api/v1/subscriber-groups`) — the
  /// web form's «المجموعة» is a dropdown of exactly these.
  Future<List<String>> groupNames() async {
    final res = await _api.get('/api/v1/subscriber-groups');
    final d = _payload(res);
    final items = d['items'];
    if (items is! List) return const [];
    final out = <String>[];
    for (final g in items) {
      final name = g is Map ? '${g['name'] ?? ''}'.trim() : '';
      if (name.isNotEmpty && !out.contains(name)) out.add(name);
    }
    return out;
  }

  Map<String, dynamic> _payload(Map<String, dynamic> res) {
    final d = res['data'];
    if (d is Map<String, dynamic>) return d;
    return res;
  }
}

class SubscribersPage {
  const SubscribersPage({
    required this.items,
    required this.hasMore,
    this.rawCount = 0,
    this.total,
  });

  final List<Subscriber> items;

  /// Rows the server returned for this page (before any client-side guard);
  /// the next page starts at offset + rawCount.
  final int rawCount;
  final bool hasMore;
  final int? total;
}

final subscribersRepositoryProvider = Provider<SubscribersRepository>((ref) {
  return SubscribersRepository(ref.watch(apiClientProvider));
});

/// «المجموعة» choices of the subscriber form.
final subscriberGroupNamesProvider =
    FutureProvider.autoDispose<List<String>>((ref) {
  return ref.watch(subscribersRepositoryProvider).groupNames();
});
