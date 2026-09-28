import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/paging.dart';
import '../data/tickets_repository.dart';
import '../domain/ticket_model.dart';

final ticketStatusFilterProvider = StateProvider.autoDispose<String>((ref) {
  return '';
});

/// Tickets list with «تحميل المزيد» / infinite scroll (50 per page).
class TicketsListController
    extends AutoDisposeAsyncNotifier<PagedList<SupportTicket>> {
  static const pageSize = 50;

  @override
  Future<PagedList<SupportTicket>> build() async {
    final status = ref.watch(ticketStatusFilterProvider);
    final page = await ref
        .watch(ticketsRepositoryProvider)
        .list(status: status, limit: pageSize);
    return PagedList<SupportTicket>(
      items: page.items,
      hasMore: page.hasMore,
      nextOffset: page.items.length,
    );
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.loadingMore) return;
    state = AsyncData(current.copyWith(loadingMore: true, loadMoreError: null));
    try {
      final page = await ref.read(ticketsRepositoryProvider).list(
            status: ref.read(ticketStatusFilterProvider),
            limit: pageSize,
            offset: current.nextOffset,
          );
      final (merged, added) =
          mergeUniqueBy(current.items, page.items, (t) => t.id);
      state = AsyncData(
        current.copyWith(
          items: merged,
          hasMore: page.hasMore && added > 0,
          nextOffset: current.nextOffset + page.items.length,
          loadingMore: false,
        ),
      );
    } catch (e) {
      state = AsyncData(current.copyWith(loadingMore: false, loadMoreError: e));
    }
  }
}

final ticketsPageProvider = AsyncNotifierProvider.autoDispose<
    TicketsListController, PagedList<SupportTicket>>(
  TicketsListController.new,
);

final ticketDetailProvider =
    FutureProvider.autoDispose.family<TicketDetail, int>((ref, ticketId) {
  return ref.watch(ticketsRepositoryProvider).get(ticketId);
});
