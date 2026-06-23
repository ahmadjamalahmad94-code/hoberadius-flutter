import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/visible_error_message.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/hub_error_state.dart';
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
          actions: [
            IconButton(
              tooltip: 'تحديث',
              icon: const Icon(Icons.refresh, color: AppTokens.textSecondary),
              onPressed: controller.refresh,
            ),
            TextButton.icon(
              onPressed: unread == 0 ? null : controller.markAllRead,
              icon: const Icon(Icons.done_all),
              label: const Text('تعليم الكل كمقروء'),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.s16),
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
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppTokens.s8),
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
    '/subscribers', '/cards', '/card-users', '/sessions', '/plans',
    '/nas', '/revenue', '/wallets', '/invoices', '/vouchers', '/ledger',
    '/payment-collection', '/communications', '/tickets', '/events',
    '/reports', '/operational-reports', '/backups', '/license-file',
    '/system-operations', '/distributors', '/admins', '/audit',
  };
  for (final p in known) {
    if (link == p || link.startsWith('$p/')) return true;
  }
  return false;
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.onTap});
  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final sev = _severityStyle(notification.severity);
    final unread = !notification.isRead;
    return Material(
      color: unread ? AppTokens.brandSoft : AppTokens.card,
      borderRadius: BorderRadius.circular(AppTokens.r12),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTokens.r12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppTokens.s12),
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
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: sev.$2,
                  borderRadius: BorderRadius.circular(AppTokens.r10),
                ),
                alignment: Alignment.center,
                child: Icon(sev.$1, size: 19, color: sev.$3),
              ),
              const SizedBox(width: AppTokens.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title.isEmpty
                                ? '(بدون عنوان)'
                                : notification.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight:
                                  unread ? FontWeight.w900 : FontWeight.w700,
                              color: AppTokens.sidebarBg,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        if (unread)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsetsDirectional.only(
                              start: AppTokens.s8,
                              top: 4,
                            ),
                            decoration: const BoxDecoration(
                              color: AppTokens.brand,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    if (notification.body.trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        notification.body,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppTokens.textSecondary,
                          fontSize: 13,
                          height: 1.35,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          notificationTimeAgo(notification.createdAt),
                          style: const TextStyle(
                            color: AppTokens.textMuted,
                            fontSize: 11,
                          ),
                        ),
                        if (notification.hasLink) ...[
                          const SizedBox(width: AppTokens.s8),
                          const Icon(
                            Icons.open_in_new,
                            size: 12,
                            color: AppTokens.textMuted,
                          ),
                        ],
                      ],
                    ),
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
      return (Icons.warning_amber_outlined, const Color(0xFFFEF3C7),
          const Color(0xFF92670B));
    case 'success':
      return (Icons.check_circle_outline, AppTokens.greenSoft,
          AppTokens.greenInk);
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
