import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../application/card_checker_format.dart';
import '../../domain/card_model.dart';

class CardCheckerDetails extends StatelessWidget {
  const CardCheckerDetails({super.key, required this.card});
  final CardCheckResult card;

  @override
  Widget build(BuildContext context) {
    final items = <_InfoItem>[
      _InfoItem('الحزمة', card.batch?.batchCode ?? 'غير معروف'),
      _InfoItem('اسم الحزمة', card.batch?.packageName ?? 'غير معروف'),
      _InfoItem('العرض', card.profile?.name ?? 'غير معروف'),
      _InfoItem(
        'كلمة المرور',
        card.hasPassword ? 'موجودة ومخفية' : 'غير موجودة',
      ),
      _InfoItem('أول استخدام', formatCheckDate(card.startedAt)),
      _InfoItem('آخر ظهور', formatCheckDate(card.lastSeenAt)),
      _InfoItem('تنتهي في', formatCheckDate(card.expiresAt)),
      _InfoItem(
        'المتبقي',
        formatCheckDuration(card.remainingSeconds ?? 0),
      ),
      _InfoItem('MAC الحالي', card.macAddress ?? 'غير معروف'),
      _InfoItem('MAC مثبت', card.lockedMac ?? 'غير مثبت'),
      _InfoItem('IP', card.ipAddress ?? 'غير معروف'),
      _InfoItem('جهاز الشبكة', card.nasAddress ?? 'غير معروف'),
      _InfoItem('مصادر البيانات', joinLocalizedFields(card.dataSources)),
      _InfoItem(
        'حقول ناقصة',
        card.missingFields.isEmpty
            ? 'لا يوجد'
            : joinLocalizedFields(card.missingFields),
      ),
    ];
    return AppCard(
      title: 'بيانات البطاقة',
      icon: Icons.info_outline,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth > 900
              ? 3
              : constraints.maxWidth < 620
                  ? 1
                  : 2;
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisSpacing: AppTokens.s8,
              crossAxisSpacing: AppTokens.s8,
              childAspectRatio: constraints.maxWidth < 620 ? 4.1 : 4.2,
            ),
            itemBuilder: (_, i) => _InfoTile(item: items[i]),
          );
        },
      ),
    );
  }
}

class _InfoItem {
  const _InfoItem(this.label, this.value);
  final String label;
  final String value;
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.item});
  final _InfoItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTokens.s12),
      decoration: BoxDecoration(
        color: AppTokens.surfaceMuted,
        borderRadius: BorderRadius.circular(AppTokens.r10),
        border: Border.all(color: AppTokens.borderNeutral),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            item.label,
            style: const TextStyle(color: AppTokens.textMuted, fontSize: 11),
          ),
          const SizedBox(height: 2),
          Text(
            item.value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppTokens.sidebarBg,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
