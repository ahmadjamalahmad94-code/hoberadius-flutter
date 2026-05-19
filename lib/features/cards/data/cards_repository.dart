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

  Future<void> revoke(int cardId) =>
      _api.post('/api/v1/cards/$cardId/revoke');
}

final cardsRepositoryProvider = Provider<CardsRepository>((ref) {
  return CardsRepository(ref.watch(apiClientProvider));
});
