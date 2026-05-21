import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/theme/tokens.dart';

class AppTopbar extends ConsumerWidget implements PreferredSizeWidget {
  const AppTopbar({super.key, this.onMenuTap});
  final VoidCallback? onMenuTap;

  @override
  Size get preferredSize => const Size.fromHeight(AppTokens.topbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: AppTokens.card,
      elevation: 0,
      child: Container(
        height: AppTokens.topbarHeight,
        padding: const EdgeInsets.symmetric(horizontal: AppTokens.s20),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppTokens.border)),
        ),
        child: Row(
          children: [
            if (onMenuTap != null)
              IconButton(
                icon: const Icon(Icons.menu, color: AppTokens.sidebarBgElev1),
                onPressed: onMenuTap,
              ),
            const Spacer(),
            IconButton(
              tooltip: 'تحديث',
              icon: const Icon(Icons.refresh, color: AppTokens.textSecondary),
              onPressed: () {},
            ),
            const SizedBox(width: AppTokens.s4),
            PopupMenuButton<String>(
              tooltip: 'الحساب',
              onSelected: (v) async {
                if (v == 'logout') {
                  await ref.read(authControllerProvider.notifier).logout();
                }
              },
              itemBuilder: (ctx) => const [
                PopupMenuItem(value: 'logout', child: Text('تسجيل خروج')),
              ],
              child: const CircleAvatar(
                radius: 18,
                backgroundColor: AppTokens.sidebarBgElev1,
                child: Icon(Icons.person, color: Colors.white, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
