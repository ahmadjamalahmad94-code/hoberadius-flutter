import 'package:hoberadius_app/core/format/currency.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/status_pill.dart';
import '../data/cards_repository.dart';
import '../domain/card_model.dart';

class CardBatchOpsFilters {
  const CardBatchOpsFilters({
    this.query = '',
    this.status = '',
    this.page = 1,
    this.perPage = 25,
  });

  final String query;
  final String status;
  final int page;
  final int perPage;

  CardBatchOpsFilters copyWith({
    String? query,
    String? status,
    int? page,
    int? perPage,
  }) =>
      CardBatchOpsFilters(
        query: query ?? this.query,
        status: status ?? this.status,
        page: page ?? this.page,
        perPage: perPage ?? this.perPage,
      );
}

final batchOpsFiltersProvider = StateProvider.autoDispose<CardBatchOpsFilters>(
  (_) => const CardBatchOpsFilters(),
);

final selectedBatchIdsProvider =
    StateProvider.autoDispose<Set<int>>((_) => <int>{});

final batchesOperationsProvider =
    FutureProvider.autoDispose<CardBatchOperationsPage>((ref) {
  final filters = ref.watch(batchOpsFiltersProvider);
  return ref.watch(cardsRepositoryProvider).listBatchOperations(
        query: filters.query,
        status: filters.status,
        page: filters.page,
        perPage: filters.perPage,
      );
});

final batchesListProvider = FutureProvider.autoDispose<List<CardBatch>>((ref) {
  return ref.watch(cardsRepositoryProvider).listBatchOperations().then(
        (page) => page.items,
      );
});

String distributorLabel(CardBatch batch) {
  if (batch.distributorDisplayName.isNotEmpty) {
    return batch.distributorDisplayName;
  }
  if (batch.distributorName.isNotEmpty) return batch.distributorName;
  if (batch.distributorId != null) return '#${batch.distributorId}';
  return 'غير مخصص';
}

String batchStatusLabel(String status) => switch (status) {
      'active' => 'نشطة',
      'available' => 'متاحة',
      'used' => 'مستخدمة',
      'expired' => 'منتهية',
      'exhausted' => 'مستهلكة',
      'deleted' || 'archived' => 'مؤرشفة',
      'revoked' || 'cancelled' || 'canceled' => 'ملغاة',
      _ => status.trim().isEmpty ? 'غير محددة' : 'حالة غير معروفة',
    };

/// Batch status colour, following the app-wide meaning in [toneForStatus]
/// (active=green, available=blue, used=brand, expired=amber, revoked=red,
/// archived=neutral).
PillTone batchStatusTone(String status) => switch (status) {
      'deleted' || 'archived' => PillTone.neutral,
      _ => toneForStatus(status),
    };

/// Amount + the tenant currency (was a hardcoded «₪»).
String formatMoney(num value, [String currency = '']) =>
    formatWithCurrency(value, currency);
