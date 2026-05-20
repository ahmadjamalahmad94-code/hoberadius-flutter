import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/theme/tokens.dart';

class _NavDest {
  const _NavDest(this.icon, this.label, this.routeName, this.path);
  final IconData icon;
  final String label;
  final String routeName;
  final String path;
}

const _destinations = <_NavDest>[
  _NavDest(Icons.dashboard_outlined, 'الرئيسية', 'dashboard', '/'),
  _NavDest(Icons.person_outline, 'المشتركون', 'subscribers', '/subscribers'),
  _NavDest(Icons.credit_card_outlined, 'الكروت', 'cards', '/cards'),
  _NavDest(Icons.online_prediction, 'المتصلون', 'sessions', '/sessions'),
  _NavDest(Icons.more_horiz, 'المزيد', 'more', '/more'),
];

/// Adaptive shell: bottom nav on phones, NavigationRail on tablets/desktop,
/// extended rail (sidebar-style) on wide web/desktop screens.
class ShellScaffold extends ConsumerWidget {
  const ShellScaffold({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= AppTokens.bpDesktop) return _Wide(child: child);
    if (width >= AppTokens.bpTablet) return _Rail(child: child);
    return _Mobile(child: child);
  }
}

int _indexOfRoute(String location) {
  for (var i = 0; i < _destinations.length - 1; i++) {
    final p = _destinations[i].path;
    if (p == '/'
        ? location == '/'
        : (location == p || location.startsWith('$p/'))) {
      return i;
    }
  }
  if (location == '/more' ||
      location == '/nas' ||
      location == '/mikrotik' ||
      location == '/plans' ||
      location == '/admins' ||
      location == '/roles' ||
      location == '/audit' ||
      location == '/ledger' ||
      location == '/reports' ||
      location == '/operational-reports' ||
      location == '/saas-modules' ||
      location == '/distributors' ||
      location == '/recycle-bin' ||
      location == '/backups' ||
      location == '/system-operations' ||
      location == '/admin-control' ||
      location == '/tools' ||
      location == '/bandwidth-schedules' ||
      location == '/print-templates') {
    return _destinations.length - 1;
  }
  return 0;
}

class _Mobile extends ConsumerWidget {
  const _Mobile({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final idx = _indexOfRoute(location);
    return Scaffold(
      appBar: _MobileAppBar(title: _destinations[idx].label),
      body: SafeArea(
        child: _ContentArea(
          padding: const EdgeInsets.all(AppTokens.s12),
          child: child,
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: idx,
        onDestinationSelected: (i) => _onTap(context, i),
        destinations: _destinations
            .map(
              (d) => NavigationDestination(
                icon: Icon(d.icon),
                selectedIcon: Icon(d.icon, color: AppTokens.cyan500),
                label: d.label,
              ),
            )
            .toList(),
      ),
    );
  }
}

class _Rail extends StatelessWidget {
  const _Rail({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final idx = _indexOfRoute(location);
    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            NavigationRail(
              extended: false,
              selectedIndex: idx,
              onDestinationSelected: (i) => _onTap(context, i),
              labelType: NavigationRailLabelType.all,
              backgroundColor: AppTokens.sidebarBg,
              selectedIconTheme: const IconThemeData(color: AppTokens.cyan500),
              unselectedIconTheme:
                  const IconThemeData(color: AppTokens.sidebarText),
              selectedLabelTextStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
              unselectedLabelTextStyle:
                  const TextStyle(color: AppTokens.sidebarText),
              destinations: _destinations
                  .map(
                    (d) => NavigationRailDestination(
                      icon: Icon(d.icon),
                      label: Text(d.label),
                    ),
                  )
                  .toList(),
            ),
            const VerticalDivider(width: 1),
            Expanded(child: _ContentArea(child: child)),
          ],
        ),
      ),
    );
  }
}

class _Wide extends ConsumerWidget {
  const _Wide({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final idx = _indexOfRoute(location);
    final auth = ref.watch(authControllerProvider);
    return Scaffold(
      body: Row(
        children: [
          _Sidebar(activeIndex: idx, admin: auth.admin),
          Expanded(
            child: _ContentArea(showTopBar: true, child: child),
          ),
        ],
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.activeIndex, this.admin});
  final int activeIndex;
  final AuthAdmin? admin;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppTokens.sidebarWidth,
      color: AppTokens.sidebarBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: AppTokens.topbarHeight,
            padding: const EdgeInsets.symmetric(horizontal: AppTokens.s20),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0x22FFFFFF))),
            ),
            alignment: Alignment.centerRight,
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppTokens.cyan500,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.wifi_tethering,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: AppTokens.s12),
                const Text(
                  'HobeRadius',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.s12),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: AppTokens.s8),
              itemCount: _destinations.length,
              itemBuilder: (ctx, i) {
                final d = _destinations[i];
                final active = i == activeIndex;
                final fg = active ? Colors.white : AppTokens.sidebarText;
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _onTap(ctx, i),
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
                        color: active
                            ? AppTokens.cyan500.withValues(alpha: 0.18)
                            : null,
                        borderRadius: BorderRadius.circular(AppTokens.r10),
                      ),
                      child: Row(
                        children: [
                          Icon(d.icon, color: fg, size: 18),
                          const SizedBox(width: AppTokens.s12),
                          Expanded(
                            child: Text(
                              d.label,
                              style: TextStyle(
                                color: fg,
                                fontWeight:
                                    active ? FontWeight.w700 : FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (admin != null)
            Container(
              padding: const EdgeInsets.all(AppTokens.s16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0x22FFFFFF))),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 16,
                    backgroundColor: AppTokens.cyan500,
                    child: Icon(Icons.person, color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: AppTokens.s8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          admin!.fullName.isEmpty
                              ? admin!.username
                              : admin!.fullName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          admin!.email.isEmpty
                              ? '@${admin!.username}'
                              : admin!.email,
                          style: const TextStyle(
                            color: AppTokens.sidebarText,
                            fontSize: 11,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ContentArea extends StatelessWidget {
  const _ContentArea({
    required this.child,
    this.showTopBar = false,
    this.padding = const EdgeInsets.all(AppTokens.s20),
  });
  final Widget child;
  final bool showTopBar;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTokens.bg,
      child: Column(
        children: [
          if (showTopBar) const _DesktopTopBar(),
          Expanded(
            child: SingleChildScrollView(
              padding: padding,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1280),
                child: child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _MobileAppBar({required this.title});
  final String title;

  @override
  Size get preferredSize => const Size.fromHeight(AppTokens.topbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppTokens.card,
      foregroundColor: AppTokens.navy900,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, color: AppTokens.border),
      ),
    );
  }
}

class _DesktopTopBar extends ConsumerWidget {
  const _DesktopTopBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: AppTokens.topbarHeight,
      color: AppTokens.card,
      padding: const EdgeInsets.symmetric(horizontal: AppTokens.s20),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTokens.border)),
      ),
      child: Row(
        children: [
          const Spacer(),
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
              backgroundColor: AppTokens.navy800,
              child: Icon(Icons.person, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

void _onTap(BuildContext context, int i) {
  context.goNamed(_destinations[i].routeName);
}
