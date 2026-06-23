import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/tokens.dart';
import '../application/notifications_providers.dart';

/// Top-bar bell with an unread badge. Watching [unreadCountProvider] also
/// activates the poller (lazy), so the badge stays fresh on its interval.
/// Tapping opens the notification center.
class NotificationBell extends ConsumerWidget {
  const NotificationBell({super.key, this.color});

  /// Icon colour (defaults to the desktop top-bar's muted tone).
  final Color? color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadCountProvider);
    final iconColor = color ?? AppTokens.textSecondary;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          tooltip: 'الإشعارات',
          icon: Icon(Icons.notifications_outlined, color: iconColor),
          onPressed: () => context.goNamed('notifications'),
        ),
        if (unread > 0)
          PositionedDirectional(
            top: 6,
            end: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              decoration: BoxDecoration(
                color: AppTokens.red,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: AppTokens.card, width: 1.5),
              ),
              alignment: Alignment.center,
              child: Text(
                unread > 99 ? '99+' : '$unread',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
