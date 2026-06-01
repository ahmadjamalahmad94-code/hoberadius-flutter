import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/status_pill.dart';

/// Section enum shared between the picker and the screen-level switch.
enum AdminSection { settings, tokens, tenants, webhooks }

/// Compact ListView.separated used by every panel as the scrollable
/// body of an [AppCard] — wraps the same shrink-wrap + dividers
/// repeated across settings / tokens / tenants / webhook deliveries.
class AdminListSection extends StatelessWidget {
  const AdminListSection({
    super.key,
    required this.count,
    required this.itemBuilder,
  });

  final int count;
  final IndexedWidgetBuilder itemBuilder;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: count,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: itemBuilder,
    );
  }
}

/// Loading placeholder used by every async section while its provider
/// is in `loading` state.
class AdminLoadingCard extends StatelessWidget {
  const AdminLoadingCard({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      title: title,
      child: const Padding(
        padding: EdgeInsets.all(AppTokens.s20),
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

String tenantStatusLabel(String value) {
  return switch (value) {
    'active' => 'مفعّل',
    'trial' => 'تجريبي',
    'suspended' => 'موقوف',
    'closed' => 'مغلق',
    _ => value.isEmpty ? 'غير معروف' : 'حالة غير معروفة',
  };
}

PillTone tenantStatusTone(String value) {
  return switch (value) {
    'active' => PillTone.green,
    'trial' => PillTone.cyan,
    'suspended' => PillTone.orange,
    'closed' => PillTone.red,
    _ => PillTone.neutral,
  };
}

String deliveryLabel(String value) {
  return switch (value) {
    'queued' => 'بالانتظار',
    'retrying' => 'إعادة محاولة',
    'delivered' => 'تم الإرسال',
    'failed' => 'فشل',
    _ => value.trim().isEmpty ? 'غير محدد' : 'حالة إرسال غير معروفة',
  };
}

PillTone deliveryTone(String value) {
  return switch (value) {
    'delivered' => PillTone.green,
    'failed' => PillTone.red,
    'queued' || 'retrying' => PillTone.orange,
    _ => PillTone.neutral,
  };
}
