import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/idempotency.dart';
import '../domain/card_model.dart';

class GenerateResult {
  GenerateResult({required this.batch, required this.cards});
  final CardBatch batch;
  final List<CardItem> cards;
}

class CardsRepository {
  CardsRepository(this._api);
  final ApiClient _api;

  /// [idempotencyKey]: one per «توليد» submission (reused on retry): the
  /// server returns the same batch instead of generating it twice.
  Future<GenerateResult> generate(
    GenerateBatchRequest req, {
    String? idempotencyKey,
  }) async {
    final res = await _api.post(
      '/api/v1/cards/generate',
      body: req.toBody(),
      headers: idempotencyHeaders(idempotencyKey),
    );
    final d = (res['data'] ?? res) as Map<String, dynamic>;
    final batchJson = d['batch'] as Map<String, dynamic>? ?? {};
    final cardsJson = (d['cards'] as List?) ?? const [];
    return GenerateResult(
      batch: CardBatch.fromJson(batchJson),
      cards: cardsJson
          .whereType<Map<String, dynamic>>()
          .map(CardItem.fromJson)
          .toList(),
    );
  }

  Future<CardBatchImportResult> importBatch(
    CardBatchImportRequest req,
  ) async {
    final res = await _api.post(
      '/api/v1/cards/batches/import',
      body: req.toBody(),
    );
    return CardBatchImportResult.fromJson(res);
  }

  Future<List<CardBatch>> listBatches({int limit = 100, int offset = 0}) async {
    final page = (offset ~/ limit) + 1;
    final result = await listBatchOperations(page: page, perPage: limit);
    return result.items;
  }

  Future<CardBatchOperationsPage> listBatchOperations({
    String query = '',
    String code = '',
    String status = '',
    int? planId,
    String manager = '',
    int? distributorId,
    int page = 1,
    int perPage = 25,
    String day = '',
    String month = '',
    String rangeFrom = '',
    String rangeTo = '',
  }) async {
    final res = await _api.get(
      '/api/v1/cards/batches',
      query: {
        if (query.trim().isNotEmpty) 'q': query.trim(),
        // exact batch-code lookup (updated servers; old ones ignore it)
        if (code.trim().isNotEmpty) 'code': code.trim(),
        if (status.isNotEmpty) 'status': status,
        if (planId != null) 'plan_id': planId,
        if (manager.trim().isNotEmpty) 'manager': manager.trim(),
        if (distributorId != null) 'distributor_id': distributorId,
        'page': page,
        'per_page': perPage,
        // the «بطاقات اليوم/الشهر» tiles (older servers ignore them)
        if (day.isNotEmpty) 'day': day,
        if (month.isNotEmpty) 'month': month,
        if (rangeFrom.isNotEmpty) 'from': rangeFrom,
        if (rangeTo.isNotEmpty) 'to': rangeTo,
      },
    );
    return CardBatchOperationsPage.fromJson(res);
  }

  Future<CardBatchBulkResult> bulkBatches({
    required String action,
    required List<int> batchIds,
    String reason = '',
  }) async {
    final res = await _api.post(
      '/api/v1/cards/batches/bulk',
      body: {
        'action': action,
        'batch_ids': batchIds,
        if (reason.trim().isNotEmpty) 'reason': reason.trim(),
      },
    );
    return CardBatchBulkResult.fromJson(res);
  }

  Future<Uint8List> exportBatchesCsv({
    String query = '',
    String status = '',
    int? planId,
    String manager = '',
    int? distributorId,
  }) async {
    final res = await _api.dio.get<List<int>>(
      '/api/v1/cards/batches/export.csv',
      queryParameters: {
        if (query.trim().isNotEmpty) 'q': query.trim(),
        if (status.isNotEmpty) 'status': status,
        if (planId != null) 'plan_id': planId,
        if (manager.trim().isNotEmpty) 'manager': manager.trim(),
        if (distributorId != null) 'distributor_id': distributorId,
      },
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(res.data ?? const []);
  }

  Future<Uint8List> exportBatchesXlsx({
    String query = '',
    String status = '',
    int? planId,
    String manager = '',
    int? distributorId,
  }) async {
    final res = await _api.dio.get<List<int>>(
      '/api/v1/cards/batches/export.xlsx',
      queryParameters: {
        if (query.trim().isNotEmpty) 'q': query.trim(),
        if (status.isNotEmpty) 'status': status,
        if (planId != null) 'plan_id': planId,
        if (manager.trim().isNotEmpty) 'manager': manager.trim(),
        if (distributorId != null) 'distributor_id': distributorId,
      },
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(res.data ?? const []);
  }

  Future<Uint8List> exportBatchesPdf({
    String query = '',
    String status = '',
    int? planId,
    String manager = '',
    int? distributorId,
  }) async {
    final res = await _api.dio.get<List<int>>(
      '/api/v1/cards/batches/export.pdf',
      queryParameters: {
        if (query.trim().isNotEmpty) 'q': query.trim(),
        if (status.isNotEmpty) 'status': status,
        if (planId != null) 'plan_id': planId,
        if (manager.trim().isNotEmpty) 'manager': manager.trim(),
        if (distributorId != null) 'distributor_id': distributorId,
      },
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(res.data ?? const []);
  }

  Future<CardBatch> getBatch(int batchId) async {
    final res = await _api.get('/api/v1/cards/batches/$batchId');
    final d = res['data'];
    return CardBatch.fromJson(d is Map<String, dynamic> ? d : res);
  }

  Future<CardBatch> updateBatch(int batchId, UpdateBatchRequest req) async {
    final res = await _api.patch(
      '/api/v1/cards/batches/$batchId',
      body: req.toBody(),
    );
    final d = (res['data'] ?? res) as Map<String, dynamic>;
    final batchJson = d['batch'] as Map<String, dynamic>? ?? d;
    return CardBatch.fromJson(batchJson);
  }

  Future<List<CardItem>> cardsOfBatch(
    int batchId, {
    bool? used,
    bool? revoked,
    int limit = 500,
    int offset = 0,
  }) async {
    final res = await _api.get(
      '/api/v1/cards/batches/$batchId/cards',
      query: {
        if (used != null) 'used': used,
        if (revoked != null) 'revoked': revoked,
        'limit': limit,
        'offset': offset,
      },
    );
    final items = (res['data']?['items'] ?? const []) as List;
    return items
        .whereType<Map<String, dynamic>>()
        .map(CardItem.fromJson)
        .toList();
  }

  /// EVERY card of a batch (the list endpoint caps a page): pages of
  /// [pageSize] until a short page; a page that brings nothing new ends it
  /// (servers that ignore offset). The «تصدير ملف» used to write 500 of
  /// 1,000,000 cards.
  Future<List<CardItem>> allCardsOfBatch(
    int batchId, {
    bool? used,
    bool? revoked,
    int pageSize = 2000,
    int maxPages = 200,
  }) async {
    final out = <CardItem>[];
    final seen = <String>{};
    for (var page = 0; page < maxPages; page++) {
      final chunk = await cardsOfBatch(
        batchId,
        used: used,
        revoked: revoked,
        limit: pageSize,
        offset: page * pageSize,
      );
      var added = 0;
      for (final c in chunk) {
        final key = c.id != null ? 'id:${c.id}' : 'u:${c.username}';
        if (seen.add(key)) {
          out.add(c);
          added++;
        }
      }
      if (chunk.length < pageSize || added == 0) break;
    }
    return out;
  }

  Future<RechargeBatchesPage> listRechargeBatches({
    int page = 1,
    int perPage = 25,
  }) async {
    final res = await _api.get(
      '/api/v1/cards/recharge',
      query: {'page': page, 'per_page': perPage},
    );
    return RechargeBatchesPage.fromJson(res);
  }

  Future<RechargeBatchCreateResult> createRechargeBatch(
    CreateRechargeBatchRequest request,
  ) async {
    final res = await _api.post(
      '/api/v1/cards/recharge',
      body: request.toBody(),
    );
    return RechargeBatchCreateResult.fromJson(res);
  }

  Future<RechargeBatchDetail> getRechargeBatch(
    int batchId, {
    int page = 1,
    int perPage = 25,
  }) async {
    final res = await _api.get(
      '/api/v1/cards/recharge/$batchId',
      query: {'page': page, 'per_page': perPage},
    );
    return RechargeBatchDetail.fromJson(res);
  }

  Future<void> deleteRechargeBatch(int batchId) async {
    await _api.delete('/api/v1/cards/recharge/$batchId');
  }

  Future<void> revoke(int cardId) => _api.post('/api/v1/cards/$cardId/revoke');

  /// The checker matches the card USERNAME only on updated servers. A card
  /// id is asked explicitly: «#123» or «id:123» → `card_id=123` (plus
  /// `query=123`, which older servers matched as username-or-id).
  Future<CardCheckResult> checkCard(String query) async {
    final res = await _api.get(
      '/api/v1/cards/check',
      query: cardCheckQueryParams(query),
    );
    final data = (res['data'] ?? res) as Map<String, dynamic>;
    final card = data['card'] as Map<String, dynamic>? ?? {};
    return CardCheckResult.fromJson(card);
  }

  Future<CardCheckResult> enableCard(int cardId) =>
      _cardAction(cardId, 'enable');

  Future<CardCheckResult> disableCard(int cardId, {String reason = ''}) =>
      _cardAction(cardId, 'disable', body: {'reason': reason});

  Future<CardCheckResult> lockCardMac(int cardId, String mac) =>
      _cardAction(cardId, 'lock-mac', body: {'mac': mac});

  Future<CardCheckResult> unlockCardMac(int cardId) =>
      _cardAction(cardId, 'unlock-mac');

  Future<CardCheckResult> resetCardUsage(int cardId) =>
      _cardAction(cardId, 'reset-usage');

  Future<CardCheckResult> disconnectCard(int cardId, {String sessionId = ''}) =>
      _cardAction(cardId, 'disconnect', body: {'session_id': sessionId});

  Future<CardCheckResult> deleteCardPermanently(
    int cardId, {
    required String username,
  }) =>
      _cardAction(
        cardId,
        'delete-permanent',
        body: {'confirm': 'DELETE:$username'},
      );

  /// «تغيير الوقت»: add or subtract [amount] [unit] (`minutes|hours|days`)
  /// from the card's time — the web checker's set_time, enforced by the
  /// authenticator. [subtract] beyond the remaining time ends the card.
  Future<CardCheckResult> adjustCardTime(
    int cardId, {
    required int amount,
    required String unit,
    bool subtract = false,
  }) =>
      _cardAction(
        cardId,
        'adjust-time',
        body: {
          'amount': amount,
          'unit': unit,
          'op': subtract ? 'subtract' : 'add',
        },
      );

  Future<CardCheckResult> _cardAction(
    int cardId,
    String action, {
    Map<String, dynamic>? body,
  }) async {
    final res = await _api.post('/api/v1/cards/$cardId/$action', body: body);
    final data = (res['data'] ?? res) as Map<String, dynamic>;
    final card = data['card'] as Map<String, dynamic>? ?? {};
    return CardCheckResult.fromJson(card);
  }
}

/// Query parameters of `GET /cards/check` for what the operator typed.
Map<String, String> cardCheckQueryParams(String input) {
  final text = input.trim();
  final byId =
      RegExp(r'^(?:#|id:)\s*(\d+)$', caseSensitive: false).firstMatch(text);
  if (byId != null) {
    final id = byId.group(1)!;
    return {'card_id': id, 'query': id};
  }
  return {'query': text};
}

final cardsRepositoryProvider = Provider<CardsRepository>((ref) {
  return CardsRepository(ref.watch(apiClientProvider));
});
