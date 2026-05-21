import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/tokens.dart';
import '../../application/cards_list_providers.dart';
import '../../domain/card_model.dart';

class CardsListPagination extends ConsumerWidget {
  const CardsListPagination({
    super.key,
    required this.page,
    required this.filters,
  });
  final CardBatchOperationsPage page;
  final CardBatchOpsFilters filters;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Text(
          'صفحة ${page.page} من ${page.pages} • ${page.total} حزمة',
          style: const TextStyle(color: AppTokens.textMuted),
        ),
        const Spacer(),
        DropdownButton<int>(
          value: filters.perPage,
          items: const [
            DropdownMenuItem(value: 10, child: Text('10')),
            DropdownMenuItem(value: 25, child: Text('25')),
            DropdownMenuItem(value: 50, child: Text('50')),
            DropdownMenuItem(value: 100, child: Text('100')),
          ],
          onChanged: (value) {
            if (value == null) return;
            ref.read(batchOpsFiltersProvider.notifier).state =
                filters.copyWith(perPage: value, page: 1);
          },
        ),
        IconButton(
          tooltip: 'السابق',
          onPressed: page.page <= 1
              ? null
              : () {
                  ref.read(batchOpsFiltersProvider.notifier).state =
                      filters.copyWith(page: page.page - 1);
                },
          icon: const Icon(Icons.chevron_right),
        ),
        IconButton(
          tooltip: 'التالي',
          onPressed: page.page >= page.pages
              ? null
              : () {
                  ref.read(batchOpsFiltersProvider.notifier).state =
                      filters.copyWith(page: page.page + 1);
                },
          icon: const Icon(Icons.chevron_left),
        ),
      ],
    );
  }
}
