import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/visible_error_message.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/hub_error_state.dart';
import '../../../shared/widgets/hub_layout.dart';
import '../../../shared/widgets/page_header.dart';
import '../application/notifications_providers.dart';
import '../domain/notification_model.dart';

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
            IconButton(
              tooltip: 'تحديث',
              icon: const Icon(Icons.refresh, color: AppTokens.textSecondary),
              onPressed: controller.refresh,
            ),
          ],
        ),
        const SizedBox(height: AppTokens.s12),
        ActionBar(
          items: [
            ActionItem(
              icon: Icons.done_all,
              label: 'تعليم الكل كمقروء',
              onPressed: unread == 0 ? null : controller.markAllRead,
            ),
          ],
        ),
        const SizedBox(height: AppTokens.s12),
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
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: page.items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (context, i) => _NotificationTile(
                    notification: page.items[i],
                    onTap: () => _open(context, ref, page.items[i]),
                  ),
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

  Future<void> _open(
    BuildContext context,
    WidgetRef ref,
    AppNotification n,
  ) async {
    if (!n.isRead) {
      await ref.read(notificationCenterProvider.notifier).markRead(n.id);
    }
    if (!context.mounted) return;
    // Deep-link to the target if it's an in-app path. Unknown links are
    // ignored (the web center has links the app may not route).
    final link = n.link.trim();
    if (link.startsWith('/') && _isKnownAppPath(link)) {
      context.go(link);
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

/// Compact notification row: unread dot + tone icon + one-line title with
/// the time at the far edge + the body folded to two lines (its emoji lines
/// joined). Tapping opens the target (and marks it read); a notification
/// without an in-app target expands to show its full body instead.
class _NotificationTile extends StatefulWidget {
  const _NotificationTile({required this.notification, required this.onTap});
  final AppNotification notification;
  final VoidCallback onTap;

  @override
  State<_NotificationTile> createState() => _NotificationTileState();
}

class _NotificationTileState extends State<_NotificationTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final notification = widget.notification;
    final sev = _severityStyle(notification.severity);
    final unread = !notification.isRead;
    final body = notification.body.trim();
    final folded = body
        .split(RegExp(r'\s*\n+\s*'))
        .where((line) => line.trim().isNotEmpty)
        .join('  ·  ');
    return Material(
      color: unread ? AppTokens.brandSoft : AppTokens.card,
      borderRadius: BorderRadius.circular(AppTokens.r12),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTokens.r12),
        onTap: () {
          setState(() => _expanded = !_expanded);
          widget.onTap();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.s8 + 2,
            vertical: AppTokens.s8,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTokens.r12),
            border: Border.all(
              color: unread ? AppTokens.brandLine : AppTokens.border,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: sev.$2,
                  borderRadius: BorderRadius.circular(AppTokens.r8),
                ),
                alignment: Alignment.center,
                child: Icon(sev.$1, size: 17, color: sev.$3),
              ),
              const SizedBox(width: AppTokens.s8 + 2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (unread)
                          Container(
                            width: 7,
                            height: 7,
                            margin: const EdgeInsetsDirectional.only(
                              end: 6,
                            ),
                            decoration: const BoxDecoration(
                              color: AppTokens.brand,
                              shape: BoxShape.circle,
                            ),
                          ),
                        Expanded(
                          child: Text(
                            notification.title.isEmpty
                                ? '(بدون عنوان)'
                                : notification.title,
                            maxLines: _expanded ? 3 : 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight:
                                  unread ? FontWeight.w900 : FontWeight.w700,
                              color: AppTokens.sidebarBg,
                              fontSize: 13.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppTokens.s8),
                        Text(
                          notificationTimeAgo(notification.createdAt),
                          style: const TextStyle(
                            color: AppTokens.textMuted,
                            fontSize: 11,
                          ),
                        ),
                        if (notification.hasLink) ...[
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.open_in_new,
                            size: 12,
                            color: AppTokens.textMuted,
                          ),
                        ],
                      ],
                    ),
                    if (body.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        _expanded ? body : folded,
                        maxLines: _expanded ? null : 2,
                        overflow: _expanded ? null : TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppTokens.textSecondary,
                          fontSize: 12.5,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// (icon, bg, fg) per severity.
(IconData, Color, Color) _severityStyle(String severity) {
  switch (severity.trim().toLowerCase()) {
    case 'critical':
      return (Icons.error_outline, AppTokens.redSoft, AppTokens.redInk);
    case 'warning':
      return (
        Icons.warning_amber_outlined,
        const Color(0xFFFEF3C7),
        const Color(0xFF92670B)
      );
    case 'success':
      return (
        Icons.check_circle_outline,
        AppTokens.greenSoft,
        AppTokens.greenInk
      );
    default:
      return (Icons.info_outline, AppTokens.brandSoft2, AppTokens.brandInk);
  }
}

/// Arabic relative time for an ISO timestamp; falls back to the raw date.
String notificationTimeAgo(String iso) {
  if (iso.trim().isEmpty) return '';
  final dt = DateTime.tryParse(iso.replaceAll('Z', ''));
  if (dt == null) return iso;
  final diff = DateTime.now().difference(dt);
  if (diff.inSeconds < 60) return 'الآن';
  if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
  if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
  if (diff.inDays < 30) return 'منذ ${diff.inDays} يوم';
  final months = diff.inDays ~/ 30;
  if (months < 12) return 'منذ $months شهر';
  return 'منذ ${diff.inDays ~/ 365} سنة';
}
