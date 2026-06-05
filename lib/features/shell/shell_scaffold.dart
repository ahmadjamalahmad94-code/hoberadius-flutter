import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/theme/tokens.dart';
import 'navigation_schema.dart';

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
  return mobileNavIndexForLocation(location);
}

class _Mobile extends ConsumerWidget {
  const _Mobile({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final idx = _indexOfRoute(location);
    return Scaffold(
      appBar: _MobileAppBar(title: mobileNavDestinations[idx].label),
      body: SafeArea(
        child: _ContentArea(
          padding: const EdgeInsets.all(AppTokens.s12),
          child: child,
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: idx,
        onDestinationSelected: (i) => _onTap(context, i),
        destinations: mobileNavDestinations
            .map(
              (d) => NavigationDestination(
                icon: Icon(d.icon),
                selectedIcon: Icon(d.icon, color: AppTokens.brand),
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
              selectedIconTheme: const IconThemeData(color: AppTokens.brand),
              unselectedIconTheme:
                  const IconThemeData(color: AppTokens.sidebarText),
              selectedLabelTextStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
              unselectedLabelTextStyle:
                  const TextStyle(color: AppTokens.sidebarText),
              destinations: mobileNavDestinations
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
    final auth = ref.watch(authControllerProvider);
    return Scaffold(
      body: Row(
        children: [
          _WebSidebar(location: location, admin: auth.admin),
          Expanded(
            child: _ContentArea(
              showTopBar: true,
              desktopSurface: true,
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

class _WebSidebar extends StatefulWidget {
  const _WebSidebar({required this.location, this.admin});
  final String location;
  final AuthAdmin? admin;

  @override
  State<_WebSidebar> createState() => _WebSidebarState();
}

class _WebSidebarState extends State<_WebSidebar> {
  static const _sidebarBg = Color(0xFFF5F3FB);
  static const _sidebarBorder = Color(0xFFE5E0F0);
  static const _sidebarText = Color(0xFF201B32);
  static const _sidebarMuted = Color(0xFF82788F);
  static const _activeBg = Color(0xFFEDE9FE);
  static const _iconBg = Color(0xFFEBE7F4);
  static const _brand = Color(0xFF6B5AED);

  bool _collapsed = false;
  final Set<String> _openSections = {
    'subscribers',
    'cards',
    'plans',
  };

  void _toggleSection(AppNavSection section) {
    if (_collapsed) {
      setState(() => _collapsed = false);
      return;
    }
    setState(() {
      if (_openSections.contains(section.id)) {
        _openSections.remove(section.id);
      } else {
        _openSections.add(section.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final width =
        _collapsed ? AppTokens.sidebarWidthCollapsed : AppTokens.sidebarWidth;
    return Container(
      width: width,
      color: _sidebarBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: AppTokens.topbarHeight,
            padding: EdgeInsets.symmetric(
              horizontal: _collapsed ? AppTokens.s8 : AppTokens.s16,
            ),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: _sidebarBorder)),
            ),
            alignment: Alignment.centerRight,
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _brand,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.wifi_tethering,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                if (!_collapsed) ...[
                  const SizedBox(width: AppTokens.s12),
                  const Expanded(
                    child: Text(
                      'Hobe Hub',
                      style: TextStyle(
                        color: _sidebarText,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                IconButton(
                  tooltip: _collapsed ? 'توسيع القائمة' : 'تصغير القائمة',
                  onPressed: () => setState(() => _collapsed = !_collapsed),
                  icon: Icon(
                    _collapsed
                        ? Icons.keyboard_double_arrow_left
                        : Icons.keyboard_double_arrow_right,
                    color: _sidebarMuted,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: AppTokens.s12),
              children: [
                _StandaloneSidebarTile(
                  item: dashboardNavItem,
                  active:
                      navPathMatches(widget.location, dashboardNavItem.path),
                  collapsed: _collapsed,
                  onTap: () => context.goNamed(dashboardNavItem.routeName),
                ),
                const SizedBox(height: AppTokens.s8),
                for (final section in appNavSections)
                  _SidebarSectionBlock(
                    section: section,
                    collapsed: _collapsed,
                    open: _openSections.contains(section.id) ||
                        navSectionIsActive(widget.location, section),
                    active: navSectionIsActive(widget.location, section),
                    location: widget.location,
                    onHeaderTap: () => _toggleSection(section),
                  ),
              ],
            ),
          ),
          if (widget.admin != null)
            Container(
              padding:
                  EdgeInsets.all(_collapsed ? AppTokens.s8 : AppTokens.s16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: _sidebarBorder)),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 16,
                    backgroundColor: _brand,
                    child: Icon(Icons.person, color: Colors.white, size: 16),
                  ),
                  if (!_collapsed) ...[
                    const SizedBox(width: AppTokens.s8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.admin!.fullName.isEmpty
                                ? widget.admin!.username
                                : widget.admin!.fullName,
                            style: const TextStyle(
                              color: _sidebarText,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            widget.admin!.email.isEmpty
                                ? '@${widget.admin!.username}'
                                : widget.admin!.email,
                            style: const TextStyle(
                              color: _sidebarMuted,
                              fontSize: 11,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _StandaloneSidebarTile extends StatelessWidget {
  const _StandaloneSidebarTile({
    required this.item,
    required this.active,
    required this.collapsed,
    required this.onTap,
  });

  final AppNavItem item;
  final bool active;
  final bool collapsed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tile = _SidebarActionTile(
      icon: item.icon,
      label: item.label,
      active: active,
      collapsed: collapsed,
      onTap: onTap,
      weight: FontWeight.w800,
    );
    return collapsed ? Tooltip(message: item.label, child: tile) : tile;
  }
}

class _SidebarSectionBlock extends StatelessWidget {
  const _SidebarSectionBlock({
    required this.section,
    required this.collapsed,
    required this.open,
    required this.active,
    required this.location,
    required this.onHeaderTap,
  });

  final AppNavSection section;
  final bool collapsed;
  final bool open;
  final bool active;
  final String location;
  final VoidCallback onHeaderTap;

  @override
  Widget build(BuildContext context) {
    final header = _SidebarActionTile(
      icon: section.icon,
      label: section.label,
      active: active,
      collapsed: collapsed,
      onTap: onHeaderTap,
      trailing: Icon(
        open ? Icons.expand_less : Icons.expand_more,
        color: _WebSidebarState._sidebarMuted,
        size: 18,
      ),
      weight: FontWeight.w800,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          collapsed ? Tooltip(message: section.label, child: header) : header,
          if (!collapsed && open)
            Padding(
              padding: const EdgeInsetsDirectional.only(start: AppTokens.s12),
              child: Column(
                children: [
                  for (final item in section.items)
                    _SidebarActionTile(
                      icon: item.icon,
                      label: item.label,
                      active: navPathMatches(location, item.path),
                      collapsed: false,
                      compact: true,
                      onTap: () => context.goNamed(item.routeName),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SidebarActionTile extends StatelessWidget {
  const _SidebarActionTile({
    required this.icon,
    required this.label,
    required this.active,
    required this.collapsed,
    required this.onTap,
    this.trailing,
    this.compact = false,
    this.weight = FontWeight.w700,
  });

  final IconData icon;
  final String label;
  final bool active;
  final bool collapsed;
  final VoidCallback onTap;
  final Widget? trailing;
  final bool compact;
  final FontWeight weight;

  @override
  Widget build(BuildContext context) {
    final fg = active ? _WebSidebarState._brand : _WebSidebarState._sidebarText;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTokens.r10),
        onTap: onTap,
        child: Container(
          margin: EdgeInsets.symmetric(
            horizontal: collapsed ? AppTokens.s8 : AppTokens.s12,
            vertical: compact ? 1 : 2,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: collapsed ? AppTokens.s8 : AppTokens.s12,
            vertical: compact ? AppTokens.s8 : AppTokens.s12,
          ),
          decoration: BoxDecoration(
            color: active ? _WebSidebarState._activeBg : Colors.transparent,
            borderRadius: BorderRadius.circular(AppTokens.r10),
            border: active
                ? Border.all(
                    color: _WebSidebarState._brand.withValues(alpha: 0.18),
                  )
                : null,
          ),
          child: Row(
            mainAxisAlignment:
                collapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: active
                      ? _WebSidebarState._brand.withValues(alpha: 0.14)
                      : _WebSidebarState._iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: fg, size: compact ? 17 : 18),
              ),
              if (!collapsed) ...[
                const SizedBox(width: AppTokens.s12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: fg,
                      fontWeight: active ? FontWeight.w900 : weight,
                      fontSize: compact ? 13 : 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ContentArea extends StatelessWidget {
  const _ContentArea({
    required this.child,
    this.showTopBar = false,
    this.desktopSurface = false,
    this.padding = const EdgeInsets.all(AppTokens.s20),
  });
  final Widget child;
  final bool showTopBar;
  final bool desktopSurface;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: desktopSurface ? const Color(0xFFEFEDF5) : AppTokens.bg,
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
      foregroundColor: AppTokens.sidebarBg,
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
              backgroundColor: AppTokens.sidebarBgElev1,
              child: Icon(Icons.person, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

void _onTap(BuildContext context, int i) {
  context.goNamed(mobileNavDestinations[i].routeName);
}
