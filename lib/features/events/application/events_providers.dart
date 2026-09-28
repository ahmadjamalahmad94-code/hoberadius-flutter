import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/events_repository.dart';
import '../domain/business_event_model.dart';

final selectedEventCategoryProvider = StateProvider<String>((ref) => '');
final selectedEventSeverityProvider = StateProvider<String>((ref) => '');

/// Events with «تحميل المزيد» (keyset `before_id` paging; the screen
/// stopped at the newest 100).
class BusinessEventsController
    extends AutoDisposeAsyncNotifier<BusinessEventsPage> {
  bool _loadingMore = false;

  @override
  Future<BusinessEventsPage> build() {
    final repo = ref.watch(eventsRepositoryProvider);
    return repo.list(
      category: ref.watch(selectedEventCategoryProvider),
      severity: ref.watch(selectedEventSeverityProvider),
    );
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || _loadingMore) return;
    _loadingMore = true;
    try {
      final next = await ref.read(eventsRepositoryProvider).loadMore(
            current,
            category: ref.read(selectedEventCategoryProvider),
            severity: ref.read(selectedEventSeverityProvider),
          );
      state = AsyncData(next);
    } catch (e, st) {
      state = AsyncError<BusinessEventsPage>(e, st).copyWithPrevious(state);
    } finally {
      _loadingMore = false;
    }
  }
}

final businessEventsProvider = AsyncNotifierProvider.autoDispose<
    BusinessEventsController, BusinessEventsPage>(
  BusinessEventsController.new,
);

final businessSummaryProvider =
    FutureProvider.autoDispose<BusinessSummary>((ref) {
  return ref.watch(eventsRepositoryProvider).summary();
});
