import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../shared/widgets/page_header.dart';

class CardsListHeader extends StatelessWidget {
  const CardsListHeader({super.key, required this.onRefresh});
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return PageHeader(
      title: 'مركز عمليات حزم البطاقات',
      subtitle: 'فلاتر، إحصائيات، أرشفة آمنة، وتصدير ملف من الخادم الحقيقي.',
      actions: [
        IconButton(
          tooltip: 'تحديث',
          icon: const Icon(Icons.refresh, color: AppTokens.textSecondary),
          onPressed: onRefresh,
        ),
        OutlinedButton.icon(
          onPressed: () => context.goNamed('card-checker'),
          icon: const Icon(Icons.manage_search_outlined),
          label: const Text('فحص بطاقة'),
        ),
        OutlinedButton.icon(
          onPressed: () => context.goNamed('card-batch-import'),
          icon: const Icon(Icons.file_upload_outlined),
          label: const Text('استيراد ملف'),
        ),
        ElevatedButton.icon(
          onPressed: () => context.goNamed('card-batch-new'),
          icon: const Icon(Icons.add),
          label: const Text('حزمة جديدة'),
        ),
      ],
    );
  }
}
