import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../cards/data/cards_repository.dart';
import '../../cards/domain/card_model.dart';
import '../../plans/data/plans_repository.dart';
import '../../plans/domain/plan_model.dart';
import '../../subscribers/data/subscribers_repository.dart';
import '../../subscribers/domain/subscriber_model.dart';
import '../data/bandwidth_schedules_repository.dart';
import '../domain/bandwidth_schedule_model.dart';

final bandwidthSchedulesProvider =
    FutureProvider.autoDispose<List<BandwidthSchedule>>((ref) {
  return ref.watch(bandwidthSchedulesRepositoryProvider).list();
});

final bandwidthPlansProvider = FutureProvider.autoDispose<List<Plan>>((ref) {
  return ref.watch(plansRepositoryProvider).list();
});

final bandwidthSubscribersProvider =
    FutureProvider.autoDispose<List<Subscriber>>((ref) {
  return ref.watch(subscribersRepositoryProvider).list(limit: 500);
});

final bandwidthCardBatchesProvider =
    FutureProvider.autoDispose<List<CardBatch>>((ref) {
  return ref.watch(cardsRepositoryProvider).listBatches(limit: 500);
});
