import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/status_pill.dart';
import '../../domain/system_operations_model.dart';

class SystemBridgeEventsPanel extends StatelessWidget {
  const SystemBridgeEventsPanel({super.key, required this.state});

  final BridgeEventsState state;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      title: 'آخر أحداث الربط',
      icon: Icons.history,
      padding: EdgeInsets.zero,
      child: state.items.isEmpty
          ? const EmptyState(
              icon: Icons.history_toggle_off,
              title: 'لا توجد أحداث ربط بعد',
              subtitle: 'ستظهر هنا نتائج المزامنة والنبض وطلبات التشغيل.',
            )
          : Column(
              children: [
                for (final event in state.items.take(8)) _EventRow(event),
              ],
            ),
    );
  }
}

class _EventRow extends StatelessWidget {
  const _EventRow(this.event);

  final BridgeEventItem event;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: StatusPill(
            text: _severityLabel(event.severity),
            tone: _severityTone(event.severity),
          ),
          title: Text(
            event.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppTokens.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          subtitle: Text(
            [
              if (event.createdAt.isNotEmpty) event.createdAt,
              if (event.reference.isNotEmpty) 'المرجع: ${event.reference}',
              if (event.status.isNotEmpty)
                'الحالة: ${_eventStatusLabel(event.status)}',
            ].join(' • '),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: const Icon(Icons.chevron_left, color: AppTokens.textMuted),
        ),
        const Divider(height: 1),
      ],
    );
  }
}

String _severityLabel(String value) {
  return switch (value) {
    'critical' => 'حرج',
    'error' => 'خطأ',
    'warning' => 'تنبيه',
    _ => 'معلومة',
  };
}

PillTone _severityTone(String value) {
  return switch (value) {
    'critical' || 'error' => PillTone.red,
    'warning' => PillTone.orange,
    _ => PillTone.blue,
  };
}

String _eventStatusLabel(String value) {
  return switch (value) {
    'recorded' => 'مسجل',
    'sent' => 'مرسل',
    'failed' => 'فشل',
    'pending' => 'بالانتظار',
    'done' => 'منتهي',
    _ => 'مسجل',
  };
}
