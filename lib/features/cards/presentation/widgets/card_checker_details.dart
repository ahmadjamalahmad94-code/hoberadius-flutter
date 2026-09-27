import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/hub_layout.dart';
import '../../application/card_checker_format.dart';
import '../../domain/card_model.dart';

class CardCheckerDetails extends StatelessWidget {
  const CardCheckerDetails({super.key, required this.card});
  final CardCheckResult card;

  @override
  Widget build(BuildContext context) {
    final items = <InfoItem>[
      InfoItem(
        icon: Icons.inventory_2_outlined,
        label: 'الحزمة',
        value: card.batch?.batchCode ?? 'غير معروف',
      ),
      InfoItem(
        icon: Icons.workspace_premium_outlined,
        label: 'اسم الحزمة',
        value: card.batch?.packageName ?? 'غير معروف',
      ),
      InfoItem(
        icon: Icons.local_offer_outlined,
        label: 'العرض',
        value: card.profile?.name ?? 'غير معروف',
      ),
      InfoItem(
        icon: Icons.password,
        label: 'كلمة المرور',
        value: card.hasPassword ? 'موجودة ومخفية' : 'غير موجودة',
      ),
      InfoItem(
        icon: Icons.play_circle_outline,
        label: 'أول استخدام',
        value: formatCheckDate(card.startedAt),
      ),
      InfoItem(
        icon: Icons.visibility_outlined,
        label: 'آخر ظهور',
        value: formatCheckDate(card.lastSeenAt),
      ),
      InfoItem(
        icon: Icons.event_busy_outlined,
        label: 'تنتهي في',
        value: formatCheckDate(card.expiresAt),
      ),
      InfoItem(
        icon: Icons.hourglass_bottom,
        label: 'المتبقي',
        value: formatCheckDuration(card.remainingSeconds ?? 0),
      ),
      InfoItem(
        icon: Icons.devices_outlined,
        label: 'MAC الحالي',
        value: card.macAddress ?? 'غير معروف',
      ),
      InfoItem(
        icon: Icons.lock_outline,
        label: 'MAC مثبت',
        value: card.lockedMac ?? 'غير مثبت',
      ),
      InfoItem(
        icon: Icons.dns_outlined,
        label: 'IP',
        value: card.ipAddress ?? 'غير معروف',
      ),
      InfoItem(
        icon: Icons.router_outlined,
        label: 'جهاز الشبكة',
        value: card.nasAddress ?? 'غير معروف',
      ),
    ];
    return AppCard(
      title: 'بيانات البطاقة',
      icon: Icons.info_outline,
      padding: const EdgeInsets.all(AppTokens.s12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth > 900 ? 3 : 2;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InfoGrid(items: items, columns: columns),
              const SizedBox(height: AppTokens.s8),
              // Lists can be long — full-width lines so nothing is cut off.
              _WideLine(
                label: 'مصادر البيانات',
                value: joinLocalizedFields(card.dataSources),
              ),
              _WideLine(
                label: 'حقول ناقصة',
                value: card.missingFields.isEmpty
                    ? 'لا يوجد'
                    : joinLocalizedFields(card.missingFields),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _WideLine extends StatelessWidget {
  const _WideLine({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppTokens.s4),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(
                color: AppTokens.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(
                color: AppTokens.sidebarBg,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
