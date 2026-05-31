import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/communications_repository.dart';
import '../domain/communications_model.dart';

final communicationsTabProvider = StateProvider<String>((ref) => 'overview');

final communicationsHomeProvider =
    FutureProvider.autoDispose<CommunicationsHome>((ref) {
  return ref.watch(communicationsRepositoryProvider).summary();
});

final messageTemplatesProvider =
    FutureProvider.autoDispose<MessageTemplatePage>((ref) {
  return ref.watch(communicationsRepositoryProvider).templates();
});

final audienceSegmentsProvider =
    FutureProvider.autoDispose<AudienceSegmentPage>((ref) {
  return ref.watch(communicationsRepositoryProvider).segments();
});

final messageDeliveriesProvider =
    FutureProvider.autoDispose<MessageDeliveryPage>((ref) {
  return ref.watch(communicationsRepositoryProvider).deliveries();
});

final campaignsProvider = FutureProvider.autoDispose<CampaignPage>((ref) {
  return ref.watch(communicationsRepositoryProvider).campaigns();
});
