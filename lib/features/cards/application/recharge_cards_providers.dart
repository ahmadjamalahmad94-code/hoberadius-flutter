import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/cards_repository.dart';
import '../domain/card_model.dart';

class RechargeCardsFilters {
  const RechargeCardsFilters({this.page = 1, this.perPage = 25});

  final int page;
  final int perPage;

  RechargeCardsFilters copyWith({int? page, int? perPage}) {
    return RechargeCardsFilters(
      page: page ?? this.page,
      perPage: perPage ?? this.perPage,
    );
  }
}

final rechargeCardsFiltersProvider =
    StateProvider.autoDispose<RechargeCardsFilters>(
  (_) => const RechargeCardsFilters(),
);

final rechargeBatchesProvider =
    FutureProvider.autoDispose<RechargeBatchesPage>((ref) {
  final filters = ref.watch(rechargeCardsFiltersProvider);
  return ref.watch(cardsRepositoryProvider).listRechargeBatches(
        page: filters.page,
        perPage: filters.perPage,
      );
});
