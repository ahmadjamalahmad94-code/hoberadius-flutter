import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/tokens.dart';
import 'navigation_schema.dart';

final _navItems = appNavigationItems
    .where((item) => item.routeName != moreNavItem.routeName)
    .toList(growable: false);

class AppSidebar extends StatelessWidget {
  const AppSidebar({super.key, this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final route = GoRouterState.of(context).matchedLocation;
    return Container(
      width: AppTokens.sidebarWidth,
      color: AppTokens.sidebarBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Brand(),
          const SizedBox(height: AppTokens.s12),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: AppTokens.s8),
              children: _navItems.map((it) {
                final active = _isActive(route, it.routeName);
                return _SidebarTile(
                  item: it,
                  active: active,
                  onTap: () {
                    context.goNamed(it.routeName);
                    onTap?.call();
                  },
                );
              }).toList(),
            ),
          ),
          const Divider(color: AppTokens.overlayLightLg, height: 1),
          Padding(
            padding: const EdgeInsets.all(AppTokens.s16),
            child: Text(
              'Hobe Hub • v0.1',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTokens.sidebarText,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isActive(String currentPath, String routeName) {
    final base = navItemByRouteName(routeName)?.path;
    if (base == null) return false;
    return navPathMatches(currentPath, base);
  }
}

class _Brand extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppTokens.topbarHeight,
      padding: const EdgeInsets.symmetric(horizontal: AppTokens.s20),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppTokens.overlayLightSm, width: 1),
        ),
      ),
      alignment: Alignment.centerRight,
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppTokens.brand,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child:
                const Icon(Icons.wifi_tethering, color: Colors.white, size: 18),
          ),
          const SizedBox(width: AppTokens.s12),
          const Text(
            'Hobe Hub',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarTile extends StatelessWidget {
  const _SidebarTile({
    required this.item,
    required this.active,
    required this.onTap,
  });
  final AppNavItem item;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = active ? AppTokens.sidebarActive : AppTokens.sidebarText;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(
            horizontal: AppTokens.s8,
            vertical: 2,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.s12,
            vertical: AppTokens.s12,
          ),
          decoration: BoxDecoration(
            color: active ? AppTokens.brand.withValues(alpha: 0.18) : null,
            borderRadius: BorderRadius.circular(AppTokens.r10),
            border: active
                ? Border.all(color: AppTokens.brand.withValues(alpha: 0.3))
                : null,
          ),
          child: Row(
            children: [
              Icon(item.icon, color: fg, size: 18),
              const SizedBox(width: AppTokens.s12),
              Expanded(
                child: Text(
                  item.label,
                  style: TextStyle(
                    color: fg,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
