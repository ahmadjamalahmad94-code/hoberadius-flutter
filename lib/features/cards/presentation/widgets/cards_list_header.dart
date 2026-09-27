import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../shared/widgets/hub_layout.dart';
import '../../../../shared/widgets/page_header.dart';
import '../../../provider_grants/application/provider_grants_provider.dart';

class CardsListHeader extends ConsumerWidget {
  const CardsListHeader({super.key, required this.onRefresh});
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // «حزمة جديدة» stays blocked at the provider's card cap (same rule as the
    // old GuardedCreateButton; the cap banner explains it on the page).
    final atCap = ref.watch(grantLimitProvider('cards'))?.atCap ?? false;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          title: 'مركز عمليات حزم البطاقات',
          subtitle:
              'فلاتر، إحصائيات، أرشفة آمنة، وتصدير ملف من الخادم الحقيقي.',
          inlineActions: true,
          actions: [
            IconButton(
              tooltip: 'تحديث',
              icon: const Icon(Icons.refresh, color: AppTokens.textSecondary),
              onPressed: onRefresh,
            ),
          ],
        ),
        const SizedBox(height: AppTokens.s12),
        ActionBar(
          items: [
            ActionItem(
              icon: Icons.add,
              label: 'حزمة جديدة',
              primary: true,
              onPressed: atCap ? null : () => context.goNamed('card-batch-new'),
            ),
            ActionItem(
              icon: Icons.manage_search_outlined,
              label: 'فحص بطاقة',
              onPressed: () => context.goNamed('card-checker'),
            ),
          ],
        ),
      ],
    );
  }
}
