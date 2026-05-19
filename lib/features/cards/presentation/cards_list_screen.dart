import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/empty_state.dart';

class CardsListScreen extends ConsumerWidget {
  const CardsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              'الكروت',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppTokens.navy900,
                  ),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: () => context.goNamed('card-batch-new'),
              icon: const Icon(Icons.add),
              label: const Text('دفعة جديدة'),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.s16),
        const EmptyState(
          icon: Icons.credit_card_outlined,
          title: 'قائمة الدفعات قادمة',
          subtitle:
              'الـ endpoint GET /api/v1/cards/batches لم يُعرَض بعد على Flask. استخدم زرّ "دفعة جديدة" لتوليد كروت الآن.',
        ),
      ],
    );
  }
}
