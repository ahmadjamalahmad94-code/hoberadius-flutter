import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../domain/card_model.dart';

class GenerateResult {
  GenerateResult({required this.batch, required this.cards});
  final CardBatch batch;
  final List<CardItem> cards;
}

class CardsRepository {
  CardsRepository(this._api);
  final ApiClient _api;

  Future<GenerateResult> generate(GenerateBatchRequest req) async {
    final res = await _api.post('/api/v1/cards/generate', body: req.toBody());
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
    String status = '',
    int? planId,
    String manager = '',
    int? distributorId,
    int page = 1,
    int perPage = 25,
  }) async {
    final res = await _api.get(
      '/api/v1/cards/batches',
      query: {
        if (query.trim().isNotEmpty) 'q': query.trim(),
        if (status.isNotEmpty) 'status': status,
        if (planId != null) 'plan_id': planId,
        if (manager.trim().isNotEmpty) 'manager': manager.trim(),
        if (distributorId != null) 'distributor_id': distributorId,
        'page': page,
        'per_page': perPage,
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

  Future<void> revoke(int cardId) => _api.post('/api/v1/cards/$cardId/revoke');

  Future<CardCheckResult> checkCard(String query) async {
    final res = await _api.get('/api/v1/cards/check', query: {'query': query});
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

final cardsRepositoryProvider = Provider<CardsRepository>((ref) {
  return CardsRepository(ref.watch(apiClientProvider));
});
