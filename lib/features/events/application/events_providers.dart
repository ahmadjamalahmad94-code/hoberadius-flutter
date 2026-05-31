import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/events_repository.dart';
import '../domain/business_event_model.dart';

final selectedEventCategoryProvider = StateProvider<String>((ref) => '');
final selectedEventSeverityProvider = StateProvider<String>((ref) => '');

final businessEventsProvider =
    FutureProvider.autoDispose<BusinessEventsPage>((ref) {
  final repo = ref.watch(eventsRepositoryProvider);
  return repo.list(
    category: ref.watch(selectedEventCategoryProvider),
    severity: ref.watch(selectedEventSeverityProvider),
  );
});

final businessSummaryProvider =
    FutureProvider.autoDispose<BusinessSummary>((ref) {
  return ref.watch(eventsRepositoryProvider).summary();
});
