import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/theme/tokens.dart';
import '../../shell/navigation_schema.dart';
import '../../shell/visible_nav_sections.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final admin = auth.admin;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (admin != null) _AdminSummaryCard(admin: admin),
        const SizedBox(height: AppTokens.s12),
        _SectionCard(
          title: 'لوحة التحكم',
          icon: dashboardNavItem.icon,
          items: const [dashboardNavItem],
        ),
        // Licence-gated + usage-gated (was the raw, ungated schema, so a
        // section the provider disabled still showed on phones).
        for (final gated in ref.watch(visibleNavSectionsProvider)) ...[
          const SizedBox(height: AppTokens.s8 + 2),
          _SectionCard(
            title: gated.section.label,
            icon: gated.section.icon,
            items: [for (final g in gated.items) g.item],
          ),
        ],
        const SizedBox(height: AppTokens.s12),
        Card(
          color: AppTokens.dangerBg,
          child: ListTile(
            leading: const Icon(Icons.logout, color: AppTokens.red),
            title: const Text(
              'تسجيل خروج',
              style:
                  TextStyle(color: AppTokens.red, fontWeight: FontWeight.w700),
            ),
            onTap: () => ref.read(authControllerProvider.notifier).logout(),
          ),
        ),
      ],
    );
  }
}

class _AdminSummaryCard extends StatelessWidget {
  const _AdminSummaryCard({required this.admin});

  final AuthAdmin admin;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.s12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppTokens.brand,
              child: Text(
                admin.username.isEmpty ? '?' : admin.username[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: AppTokens.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    admin.fullName.isEmpty ? admin.username : admin.fullName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppTokens.sidebarBg,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    admin.email.isEmpty ? '@${admin.username}' : admin.email,
                    style: const TextStyle(
                      color: AppTokens.textMuted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            if (admin.isSuperAdmin)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTokens.brandSoft,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'مدير عام',
                  style: TextStyle(
                    color: AppTokens.brand,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.items,
  });

  final String title;
  final IconData icon;
  final List<AppNavItem> items;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTokens.s12,
              AppTokens.s8 + 2,
              AppTokens.s12,
              AppTokens.s4,
            ),
            child: Row(
              children: [
                Icon(icon, color: AppTokens.brand, size: 18),
                const SizedBox(width: AppTokens.s8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: AppTokens.sidebarBg,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            _NavTile(item: items[i]),
          ],
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({required this.item});

  final AppNavItem item;

  @override
  Widget build(BuildContext context) {
    // Compact row: one-line description with an ellipsis (descriptions used
    // to wrap to 2–3 lines and made the page very long).
    return InkWell(
      onTap: () => context.goNamed(item.routeName),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.s12,
          vertical: AppTokens.s8,
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppTokens.brandSoft,
                borderRadius: BorderRadius.circular(AppTokens.r10),
                border: Border.all(color: AppTokens.brandLine),
              ),
              alignment: Alignment.center,
              child: Icon(item.icon, color: AppTokens.brand, size: 18),
            ),
            const SizedBox(width: AppTokens.s8 + 2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppTokens.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                  if (item.description != null)
                    Text(
                      item.description!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTokens.textMuted,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: AppTokens.s4),
            const Icon(
              Icons.chevron_left,
              size: 20,
              color: AppTokens.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
