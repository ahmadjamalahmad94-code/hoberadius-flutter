import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/cards_repository.dart';
import '../domain/card_model.dart';

final batchEditProvider =
    FutureProvider.autoDispose.family<CardBatch, int>((ref, id) {
  return ref.watch(cardsRepositoryProvider).getBatch(id);
});
