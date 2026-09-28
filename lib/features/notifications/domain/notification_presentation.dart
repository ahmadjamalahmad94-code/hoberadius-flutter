import 'package:flutter/material.dart';

import '../../../core/theme/tokens.dart';
import 'notification_model.dart';

/// What a notification is about — drives its colour, icon and label so the
/// center isn't a wall of identical cards (owner report 2026-09-28).
enum NotificationKind {
  deviceDown,
  deviceUp,
  healthCheck,
  subscriber,
  finance,
  cards,
  license,
  support,
  appUpdate,
  system,
}

class KindStyle {
  const KindStyle(this.label, this.icon, this.color, this.soft);
  final String label;
  final IconData icon;

  /// Strong colour (side strip, icon) and its soft background.
  final Color color;
  final Color soft;
}

KindStyle kindStyle(NotificationKind k) => switch (k) {
      NotificationKind.deviceDown => const KindStyle(
          'جهاز مفصول',
          Icons.wifi_off_rounded,
          Color(0xFFDC2626),
          Color(0xFFFEE2E2),
        ),
      NotificationKind.deviceUp => const KindStyle(
          'جهاز عاد',
          Icons.wifi_rounded,
          Color(0xFF16A34A),
          Color(0xFFDCFCE7),
        ),
      NotificationKind.healthCheck => const KindStyle(
          'فحص دوري',
          Icons.monitor_heart_outlined,
          Color(0xFFD97706),
          Color(0xFFFEF3C7),
        ),
      NotificationKind.subscriber => const KindStyle(
          'مشتركون',
          Icons.person_outline,
          AppTokens.brand,
          AppTokens.brandSoft,
        ),
      NotificationKind.finance => const KindStyle(
          'مالية',
          Icons.payments_outlined,
          Color(0xFF059669),
          Color(0xFFD1FAE5),
        ),
      NotificationKind.cards => const KindStyle(
          'البطاقات',
          Icons.credit_card,
          Color(0xFF7C3AED),
          Color(0xFFEDE9FE),
        ),
      NotificationKind.license => const KindStyle(
          'الترخيص',
          Icons.verified_outlined,
          Color(0xFFB45309),
          Color(0xFFFEF3C7),
        ),
      NotificationKind.support => const KindStyle(
          'الدعم',
          Icons.support_agent,
          Color(0xFF2563EB),
          Color(0xFFDBEAFE),
        ),
      NotificationKind.appUpdate => const KindStyle(
          'تحديث التطبيق',
          Icons.system_update,
          AppTokens.brand,
          AppTokens.brandSoft,
        ),
      NotificationKind.system => const KindStyle(
          'النظام',
          Icons.settings_outlined,
          Color(0xFF475569),
          Color(0xFFF1F5F9),
        ),
    };

NotificationKind classifyNotification(AppNotification n) {
  final type = n.type.toLowerCase();
  final link = n.link.toLowerCase();
  final title = n.title;
  if (type.contains('app_update')) return NotificationKind.appUpdate;
  if (link.contains('device-health') ||
      type.contains('device') ||
      type.contains('router') ||
      title.contains('الراوتر')) {
    if (title.contains('الفحص')) return NotificationKind.healthCheck;
    if (title.contains('عاد') ||
        title.contains('رجع') ||
        (title.contains('متصل') && !title.contains('غير'))) {
      return NotificationKind.deviceUp;
    }
    if (title.contains('مفصول') ||
        title.contains('انقطاع') ||
        title.contains('غير متصل') ||
        n.severity == 'critical') {
      return NotificationKind.deviceDown;
    }
    return NotificationKind.healthCheck;
  }
  if (type.contains('subscri') || type.contains('account')) {
    return NotificationKind.subscriber;
  }
  if (type.contains('pay') ||
      type.contains('financ') ||
      type.contains('wallet') ||
      type.contains('loan') ||
      type.contains('invoice') ||
      type.contains('billing')) {
    return NotificationKind.finance;
  }
  if (type.contains('card') ||
      type.contains('store') ||
      type.contains('batch')) {
    return NotificationKind.cards;
  }
  if (type.contains('licen')) return NotificationKind.license;
  if (type.contains('ticket') || type.contains('support')) {
    return NotificationKind.support;
  }
  return NotificationKind.system;
}

/// A notification body split into readable parts. The server writes lines
/// such as «🔴 «X» — الراوتر ما زال غير متصل», «⏳ المدّة: 22 ساعة»,
/// «• «MT-HQ-Core» (راوتر) — منذ …» — the app used to glue them into one
/// run-on line.
class ParsedBody {
  const ParsedBody({
    required this.headline,
    required this.facts,
    required this.bullets,
    required this.notes,
  });

  /// First plain sentence (no «label: value»).
  final String headline;

  /// «label: value» lines, in order.
  final List<(String, String)> facts;

  /// «• …» list lines.
  final List<String> bullets;

  /// Any other text lines.
  final List<String> notes;
}

final _leadingSymbols = RegExp(
  r'^[\s\u2066-\u2069\u200E\u200F\u2022\u00B7\-\u2013\u2014'
  r'\u2190-\u21FF\u2300-\u27BF\u2B00-\u2BFF\uFE0F\u200D'
  r'\u{1F000}-\u{1FAFF}]+',
  unicode: true,
);
final _isolates = RegExp(r'[\u2066-\u2069\u200E\u200F]', unicode: true);

String _clean(String s) =>
    s.replaceAll(_isolates, '').replaceFirst(_leadingSymbols, '').trim();

/// Lines that repeat on every device alert and say nothing new.
bool _isBoilerplate(String line) =>
    line.contains('تنبيهات تلجرام') || line.startsWith('\u{1F515}');

ParsedBody parseNotificationBody(String body, {String title = ''}) {
  final facts = <(String, String)>[];
  final bullets = <String>[];
  final notes = <String>[];
  var headline = '';
  for (final raw in body.split('\n')) {
    final line = raw.trim();
    if (line.isEmpty || _isBoilerplate(line)) continue;
    final isBullet = line.replaceAll(_isolates, '').trimLeft().startsWith('\u2022');
    final text = _clean(line);
    if (text.isEmpty) continue;
    if (isBullet) {
      bullets.add(text);
      continue;
    }
    final colon = text.indexOf(':');
    if (colon > 0 && colon < 28 && colon < text.length - 1) {
      final label = text.substring(0, colon).trim();
      final value = text.substring(colon + 1).trim();
      if (value.isNotEmpty) {
        facts.add((label, value));
        continue;
      }
      // «الحالة:» heading with the values on the next lines.
      continue;
    }
    if (headline.isEmpty && text != _clean(title)) {
      headline = text;
    } else if (text != headline) {
      notes.add(text);
    }
  }
  return ParsedBody(
    headline: headline,
    facts: facts,
    bullets: bullets,
    notes: notes,
  );
}

/// Consecutive-or-not duplicates (same type + title) collapse into one row
/// with a count — a router that stays down re-alerts every half hour.
class NotificationGroup {
  NotificationGroup(this.latest) : ids = [latest.id];
  final AppNotification latest;

  /// Every notification folded into this row (newest first).
  final List<int> ids;
  int get count => ids.length;
  bool get anyUnread => _unread;
  bool _unread = false;
}

List<NotificationGroup> groupNotifications(List<AppNotification> items) {
  final byKey = <String, NotificationGroup>{};
  final out = <NotificationGroup>[];
  for (final n in items) {
    final key = '${n.type}|${n.title.trim()}';
    final g = byKey[key];
    if (g == null) {
      final ng = NotificationGroup(n).._unread = !n.isRead;
      byKey[key] = ng;
      out.add(ng);
    } else {
      g.ids.add(n.id);
      if (!n.isRead) g._unread = true;
    }
  }
  return out;
}
