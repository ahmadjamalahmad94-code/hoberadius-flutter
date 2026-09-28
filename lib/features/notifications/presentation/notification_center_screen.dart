import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/visible_error_message.dart';
import '../../../core/ota/ota_banner_card.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/hub_error_state.dart';
import '../../../shared/widgets/page_header.dart';
import '../application/notifications_providers.dart';
import '../domain/notification_presentation.dart';
import 'package:hoberadius_app/core/format/server_time.dart';
import 'package:hoberadius_app/features/subscribers/domain/subscriber_actions_model.dart'
    show arDays, arHours, arMinutes;

final _kindFilterProvider =
    StateProvider.autoDispose<NotificationKind?>((_) => null);

/// Notification center — the in-app mirror of the web bell/center. Lists the
/// tenant's notifications with read-state, deep-links to the target, mark-as-
/// read (single + all), and «تحميل المزيد» pagination. RTL/Cairo via the app
/// theme. Refresh is a header button + auto-poll (the shell owns a global
/// scroll view, so a nested pull-to-refresh would fight it).
class NotificationCenterScreen extends ConsumerWidget {
  const NotificationCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(notificationCenterProvider);
    final controller = ref.read(notificationCenterProvider.notifier);
    final unread = async.valueOrNull?.unreadCount ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          title: 'الإشعارات',
          subtitle: unread > 0 ? '$unread إشعار غير مقروء' : 'لا إشعارات جديدة',
          inlineActions: true,
          actions: [
            // «تعليم الكل كمقروء» lives up here, away from the filter chips
            // (a tap meant for «الكل» marked 3,045 notifications read), and
            // asks first — it cannot be undone.
            IconButton(
              tooltip: 'تعليم الكل كمقروء',
              icon: const Icon(Icons.done_all, color: AppTokens.textSecondary),
              onPressed: unread == 0
                  ? null
                  : () => _confirmMarkAll(context, controller, unread),
            ),
            IconButton(
              tooltip: 'تحديث',
              icon: const Icon(Icons.refresh, color: AppTokens.textSecondary),
              onPressed: controller.refresh,
            ),
          ],
        ),
        const SizedBox(height: AppTokens.s12),
        // App updates live here too (they come as a push, not from the
        // server's notification list).
        const OtaBannerCard(),
        async.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(AppTokens.s40),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => HubErrorState(
            title: 'تعذّر جلب الإشعارات',
            subtitle: visibleErrorMessage(e),
            onRetry: controller.refresh,
          ),
          data: (page) {
            if (page.items.isEmpty) {
              return const EmptyState(
                icon: Icons.notifications_none_outlined,
                title: 'لا توجد إشعارات',
                subtitle: 'ستظهر هنا تنبيهات الاشتراكات والخدمات والنظام.',
              );
            }
            final groups = groupNotifications(page.items);
            final counts = <NotificationKind, int>{};
            for (final g in groups) {
              final k = classifyNotification(g.latest);
              counts[k] = (counts[k] ?? 0) + 1;
            }
            final filter = ref.watch(_kindFilterProvider);
            final shown = filter == null
                ? groups
                : groups
                    .where((g) => classifyNotification(g.latest) == filter)
                    .toList();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (counts.length > 1) ...[
                  _KindFilter(
                    counts: counts,
                    selected: filter,
                    onSelect: (k) =>
                        ref.read(_kindFilterProvider.notifier).state = k,
                  ),
                  const SizedBox(height: AppTokens.s12),
                ],
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: shown.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final g = shown[i];
                    final link = g.latest.link.trim();
                    final canOpen =
                        link.startsWith('/') && _isKnownAppPath(link);
                    return _NotificationTile(
                      group: g,
                      onRead: () => _markGroupRead(ref, g),
                      onOpen: canOpen
                          ? () {
                              _markGroupRead(ref, g);
                              context.go(link);
                            }
                          : null,
                    );
                  },
                ),
                if (page.hasMore) ...[
                  const SizedBox(height: AppTokens.s12),
                  Center(
                    child: OutlinedButton.icon(
                      onPressed: controller.loadMore,
                      icon: const Icon(Icons.expand_more),
                      label: const Text('تحميل المزيد'),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  Future<void> _confirmMarkAll(
    BuildContext context,
    NotificationCenterController controller,
    int unread,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => AlertDialog(
        title: const Text('تعليم الكل كمقروء؟'),
        content: Text(
          'سيُعلَّم $unread إشعارًا غير مقروء كمقروء لكل الشبكة. '
          'لا يمكن التراجع عن ذلك.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('تعليم الكل'),
          ),
        ],
      ),
    );
    if (ok == true) await controller.markAllRead();
  }

  Future<void> _markGroupRead(WidgetRef ref, NotificationGroup g) async {
    final notifier = ref.read(notificationCenterProvider.notifier);
    for (final id in g.ids) {
      await notifier.markRead(id);
    }
  }
}

/// Conservatively allow navigation only to top-level app paths we know exist,
/// so a web-only link never lands on the not-found screen.
bool _isKnownAppPath(String link) {
  const known = {
    '/subscribers',
    '/cards',
    '/card-users',
    '/sessions',
    '/plans',
    '/nas',
    '/revenue',
    '/wallets',
    '/invoices',
    '/vouchers',
    '/ledger',
    '/payment-collection',
    '/communications',
    '/tickets',
    '/events',
    '/reports',
    '/operational-reports',
    '/backups',
    '/distributors',
    '/admins',
    '/audit',
  };
  for (final p in known) {
    if (link == p || link.startsWith('$p/')) return true;
  }
  return false;
}

/// One notification (or a group of identical ones): a coloured strip and icon
/// per kind, a kind label, a bold title, one plain headline, then the
/// «label: value» facts each on its own line — instead of every body line
/// glued into one run-on string. Tap to expand (list items / extra lines);
/// «فتح» goes to the target when the app has that page.
class _NotificationTile extends StatefulWidget {
  const _NotificationTile({
    required this.group,
    required this.onOpen,
    required this.onRead,
  });
  final NotificationGroup group;
  final VoidCallback? onOpen;
  final VoidCallback onRead;

  @override
  State<_NotificationTile> createState() => _NotificationTileState();
}

class _NotificationTileState extends State<_NotificationTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final g = widget.group;
    final n = g.latest;
    final kind = classifyNotification(n);
    final style = kindStyle(kind);
    final parsed = parseNotificationBody(n.body, title: n.title);
    final unread = g.anyUnread;
    final text = Theme.of(context).textTheme;
    final facts = _expanded ? parsed.facts : parsed.facts.take(2).toList();
    final hasMore = parsed.facts.length > 2 ||
        parsed.bullets.isNotEmpty ||
        parsed.notes.isNotEmpty;

    return Material(
      color: unread ? Colors.white : const Color(0xFFFBFBFD),
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          if (unread) widget.onRead();
          if (hasMore) setState(() => _expanded = !_expanded);
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: unread
                  ? style.color.withValues(alpha: 0.35)
                  : AppTokens.border,
            ),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Kind colour strip (start side).
                Container(width: 5, color: style.color),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: style.soft,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                style.icon,
                                size: 19,
                                color: style.color,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      _Pill(
                                        label: style.label,
                                        fg: style.color,
                                        bg: style.soft,
                                      ),
                                      if (g.count > 1) ...[
                                        const SizedBox(width: 6),
                                        _Pill(
                                          label: g.count == 2
                                              ? 'تكرّر مرتين'
                                              : g.count <= 10
                                                  ? 'تكرّر ${g.count} مرات'
                                                  : 'تكرّر ${g.count} مرة',
                                          fg: AppTokens.textSecondary,
                                          bg: const Color(0xFFF1F5F9),
                                        ),
                                      ],
                                      const Spacer(),
                                      Text(
                                        notificationTimeAgo(n.createdAt),
                                        style: text.labelSmall?.copyWith(
                                          color: AppTokens.textMuted,
                                        ),
                                      ),
                                      if (unread) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: style.color,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    n.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: text.titleSmall?.copyWith(
                                      fontWeight: unread
                                          ? FontWeight.w800
                                          : FontWeight.w700,
                                      color: AppTokens.sidebarBg,
                                      height: 1.25,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (parsed.headline.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            parsed.headline,
                            maxLines: _expanded ? null : 2,
                            overflow: _expanded ? null : TextOverflow.ellipsis,
                            style: text.bodyMedium?.copyWith(
                              color: AppTokens.textSecondary,
                              height: 1.35,
                            ),
                          ),
                        ],
                        if (facts.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              children: [
                                for (final (label, value) in facts)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 2,
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(
                                          width: 92,
                                          child: Text(
                                            label,
                                            style: text.bodySmall?.copyWith(
                                              color: AppTokens.textMuted,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            value,
                                            style: text.bodySmall?.copyWith(
                                              color: AppTokens.sidebarBg,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                        if (_expanded && parsed.bullets.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          for (final b in parsed.bullets)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 3),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(top: 7),
                                    child: Container(
                                      width: 5,
                                      height: 5,
                                      decoration: BoxDecoration(
                                        color: style.color,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      b,
                                      style: text.bodySmall?.copyWith(
                                        color: AppTokens.textSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                        if (_expanded)
                          for (final line in parsed.notes)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                line,
                                style: text.bodySmall?.copyWith(
                                  color: AppTokens.textSecondary,
                                ),
                              ),
                            ),
                        if (hasMore || widget.onOpen != null) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              if (hasMore)
                                Text(
                                  _expanded ? 'عرض أقل' : 'التفاصيل',
                                  style: text.labelMedium?.copyWith(
                                    color: style.color,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              if (hasMore)
                                Icon(
                                  _expanded
                                      ? Icons.expand_less
                                      : Icons.expand_more,
                                  size: 18,
                                  color: style.color,
                                ),
                              const Spacer(),
                              if (widget.onOpen != null)
                                TextButton.icon(
                                  onPressed: widget.onOpen,
                                  style: TextButton.styleFrom(
                                    visualDensity: VisualDensity.compact,
                                    foregroundColor: style.color,
                                  ),
                                  icon: const Icon(Icons.open_in_new, size: 16),
                                  label: const Text('فتح'),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.fg, required this.bg});
  final String label;
  final Color fg;
  final Color bg;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: fg,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
}

/// Kind filter chips with counts; «الكل» first.
class _KindFilter extends StatelessWidget {
  const _KindFilter({
    required this.counts,
    required this.selected,
    required this.onSelect,
  });
  final Map<NotificationKind, int> counts;
  final NotificationKind? selected;
  final ValueChanged<NotificationKind?> onSelect;

  @override
  Widget build(BuildContext context) {
    final total = counts.values.fold<int>(0, (a, b) => a + b);
    Widget chip(String label, int n, Color color, bool on, VoidCallback tap) {
      return Padding(
        padding: const EdgeInsetsDirectional.only(end: 8),
        child: Material(
          color: on ? color : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
            side: BorderSide(color: on ? color : AppTokens.borderStrong),
          ),
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: tap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              child: Text(
                '$label  $n',
                style: TextStyle(
                  color: on ? Colors.white : AppTokens.textSecondary,
                  fontWeight: FontWeight.w800,
                  fontSize: 12.5,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          chip(
            'الكل',
            total,
            AppTokens.brand,
            selected == null,
            () => onSelect(null),
          ),
          for (final e in counts.entries)
            chip(
              kindStyle(e.key).label,
              e.value,
              kindStyle(e.key).color,
              selected == e.key,
              () => onSelect(e.key),
            ),
        ],
      ),
    );
  }
}

/// Arabic relative time for an ISO timestamp; falls back to the raw date.
String notificationTimeAgo(String iso) {
  if (iso.trim().isEmpty) return '';
  final dt = parseServerDateTime(iso);
  if (dt == null) return iso;
  final diff = DateTime.now().difference(dt);
  if (diff.inSeconds < 60) return 'الآن';
  // Arabic number agreement («منذ 3 ساعات», not «منذ 3 ساعة»).
  if (diff.inMinutes < 60) return 'منذ ${arMinutes(diff.inMinutes)}';
  if (diff.inHours < 24) return 'منذ ${arHours(diff.inHours)}';
  if (diff.inDays < 30) return 'منذ ${arDays(diff.inDays)}';
  final months = diff.inDays ~/ 30;
  if (months < 12) return 'منذ $months شهر';
  return 'منذ ${diff.inDays ~/ 365} سنة';
}
