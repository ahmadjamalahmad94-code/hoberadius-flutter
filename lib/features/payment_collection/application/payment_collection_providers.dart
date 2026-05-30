import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/payment_collection_repository.dart';
import '../domain/payment_collection_model.dart';

final paymentCollectionModeProvider = StateProvider<String>((ref) => 'review');
final paymentCollectionStatusProvider = StateProvider<String>((ref) => '');

final paymentRequestsProvider =
    FutureProvider.autoDispose<PaymentRequestPage>((ref) {
  final mode = ref.watch(paymentCollectionModeProvider);
  final repo = ref.watch(paymentCollectionRepositoryProvider);
  if (mode == 'review') return repo.reviewQueue();
  final status = ref.watch(paymentCollectionStatusProvider);
  return repo.list(status: status);
});
