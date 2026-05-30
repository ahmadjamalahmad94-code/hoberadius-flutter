import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/tickets_repository.dart';
import '../domain/ticket_model.dart';

final ticketStatusFilterProvider = StateProvider.autoDispose<String>((ref) {
  return '';
});

final ticketsPageProvider = FutureProvider.autoDispose<TicketsPage>((ref) {
  final status = ref.watch(ticketStatusFilterProvider);
  return ref.watch(ticketsRepositoryProvider).list(status: status);
});

final ticketDetailProvider =
    FutureProvider.autoDispose.family<TicketDetail, int>((ref, ticketId) {
  return ref.watch(ticketsRepositoryProvider).get(ticketId);
});
