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

  Future<List<CardBatch>> listBatches({int limit = 100, int offset = 0}) async {
    final res = await _api.get(
      '/api/v1/cards/batches',
      query: {'limit': limit, 'offset': offset},
    );
    final items = (res['data']?['items'] ?? const []) as List;
    return items
        .whereType<Map<String, dynamic>>()
        .map(CardBatch.fromJson)
        .toList();
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
}

final cardsRepositoryProvider = Provider<CardsRepository>((ref) {
  return CardsRepository(ref.watch(apiClientProvider));
});
