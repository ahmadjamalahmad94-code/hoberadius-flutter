import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';

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

/// id → name of the subscriber groups, to label `subscriber_group` rules
/// (made in the web speed-rule panels). Best effort: a manager without the
/// groups permission just sees «#id».
final bandwidthGroupNamesProvider =
    FutureProvider.autoDispose<Map<int, String>>((ref) async {
  try {
    final res = await ref.watch(apiClientProvider).get(
          '/api/v1/subscriber-groups',
        );
    final data = res['data'];
    final items = data is Map ? data['items'] : null;
    if (items is! List) return const {};
    return {
      for (final g in items.whereType<Map>())
        if (int.tryParse('${g['id']}') != null)
          int.parse('${g['id']}'): '${g['name'] ?? ''}',
    };
  } catch (_) {
    return const {};
  }
});
