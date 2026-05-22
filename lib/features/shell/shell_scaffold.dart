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

class _SidebarItem {
  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.routeName,
    required this.path,
  });

  final IconData icon;
  final String label;
  final String routeName;
  final String path;
}

class _SidebarSection {
  const _SidebarSection({
    required this.id,
    required this.icon,
    required this.label,
    required this.items,
  });

  final String id;
  final IconData icon;
  final String label;
  final List<_SidebarItem> items;
}

const _dashboardSidebarItem = _SidebarItem(
  icon: Icons.dashboard_outlined,
  label: 'لوحة التحكم',
  routeName: 'dashboard',
  path: '/',
);

const _sidebarSections = <_SidebarSection>[
  _SidebarSection(
    id: 'subscribers',
    icon: Icons.groups_2_outlined,
    label: 'المشتركون',
    items: [
      _SidebarItem(
        icon: Icons.list_alt_outlined,
        label: 'قائمة المشتركين',
        routeName: 'subscribers',
        path: '/subscribers',
      ),
      _SidebarItem(
        icon: Icons.person_add_alt_1_outlined,
        label: 'إضافة مشترك',
        routeName: 'subscriber-new',
        path: '/subscribers/new',
      ),
      _SidebarItem(
        icon: Icons.online_prediction,
        label: 'المتصلون الآن',
        routeName: 'sessions',
        path: '/sessions',
      ),
    ],
  ),
  _SidebarSection(
    id: 'cards',
    icon: Icons.credit_card_outlined,
    label: 'الكروت',
    items: [
      _SidebarItem(
        icon: Icons.inventory_2_outlined,
        label: 'حزم البطاقات',
        routeName: 'cards',
        path: '/cards',
      ),
      _SidebarItem(
        icon: Icons.fact_check_outlined,
        label: 'فحص بطاقة',
        routeName: 'card-checker',
        path: '/cards/checker',
      ),
      _SidebarItem(
        icon: Icons.add_card_outlined,
        label: 'حزمة جديدة',
        routeName: 'cards-new',
        path: '/cards/new',
      ),
      _SidebarItem(
        icon: Icons.upload_file_outlined,
        label: 'استيراد ملف',
        routeName: 'cards-import',
        path: '/cards/import',
      ),
      _SidebarItem(
        icon: Icons.print_outlined,
        label: 'تصميم وتصدير',
        routeName: 'print-templates',
        path: '/print-templates',
      ),
    ],
  ),
  _SidebarSection(
    id: 'plans',
    icon: Icons.local_offer_outlined,
    label: 'العروض والسرعات',
    items: [
      _SidebarItem(
        icon: Icons.sell_outlined,
        label: 'قائمة العروض',
        routeName: 'plans',
        path: '/plans',
      ),
      _SidebarItem(
        icon: Icons.add_business_outlined,
        label: 'إضافة عرض',
        routeName: 'plan-new',
        path: '/plans/new',
      ),
      _SidebarItem(
        icon: Icons.speed_outlined,
        label: 'جدولة السرعات',
        routeName: 'bandwidth-schedules',
        path: '/bandwidth-schedules',
      ),
    ],
  ),
  _SidebarSection(
    id: 'network',
    icon: Icons.router_outlined,
    label: 'الشبكة',
    items: [
      _SidebarItem(
        icon: Icons.dns_outlined,
        label: 'أجهزة الشبكة',
        routeName: 'nas',
        path: '/nas',
      ),
      _SidebarItem(
        icon: Icons.wifi_tethering,
        label: 'MikroTik',
        routeName: 'mikrotik',
        path: '/mikrotik',
      ),
      _SidebarItem(
        icon: Icons.fingerprint_outlined,
        label: 'بصمات الأجهزة',
        routeName: 'device-fingerprints',
        path: '/device-fingerprints',
      ),
    ],
  ),
  _SidebarSection(
    id: 'finance',
    icon: Icons.account_balance_wallet_outlined,
    label: 'المحاسبة',
    items: [
      _SidebarItem(
        icon: Icons.receipt_long_outlined,
        label: 'السجل المالي',
        routeName: 'ledger',
        path: '/ledger',
      ),
      _SidebarItem(
        icon: Icons.bar_chart_outlined,
        label: 'التقارير المالية',
        routeName: 'reports',
        path: '/reports',
      ),
      _SidebarItem(
        icon: Icons.query_stats_outlined,
        label: 'تقارير التشغيل',
        routeName: 'operational-reports',
        path: '/operational-reports',
      ),
    ],
  ),
  _SidebarSection(
    id: 'admin',
    icon: Icons.admin_panel_settings_outlined,
    label: 'الإدارة',
    items: [
      _SidebarItem(
        icon: Icons.manage_accounts_outlined,
        label: 'المدراء',
        routeName: 'admins',
        path: '/admins',
      ),
      _SidebarItem(
        icon: Icons.security_outlined,
        label: 'الأدوار',
        routeName: 'roles',
        path: '/roles',
      ),
      _SidebarItem(
        icon: Icons.storefront_outlined,
        label: 'الموزعون',
        routeName: 'distributors',
        path: '/distributors',
      ),
      _SidebarItem(
        icon: Icons.restore_from_trash_outlined,
        label: 'سلة المحذوفات',
        routeName: 'recycle-bin',
        path: '/recycle-bin',
      ),
      _SidebarItem(
        icon: Icons.event_repeat_outlined,
        label: 'الأرشفة التلقائية',
        routeName: 'lifecycle',
        path: '/lifecycle',
      ),
      _SidebarItem(
        icon: Icons.backup_outlined,
        label: 'النسخ الاحتياطي',
        routeName: 'backups',
        path: '/backups',
      ),
    ],
  ),
  _SidebarSection(
    id: 'tools',
    icon: Icons.tune_outlined,
    label: 'التكامل والأدوات',
    items: [
      _SidebarItem(
        icon: Icons.monitor_heart_outlined,
        label: 'عمليات النظام',
        routeName: 'system-operations',
        path: '/system-operations',
      ),
      _SidebarItem(
        icon: Icons.settings_outlined,
        label: 'التحكم الإداري',
        routeName: 'admin-control',
        path: '/admin-control',
      ),
      _SidebarItem(
        icon: Icons.build_outlined,
        label: 'الأدوات',
        routeName: 'tools',
        path: '/tools',
      ),
      _SidebarItem(
        icon: Icons.widgets_outlined,
        label: 'الوحدات التجارية',
        routeName: 'saas-modules',
        path: '/saas-modules',
      ),
    ],
  ),
];

bool _matchesPath(String location, String path) {
  if (path == '/') return location == '/';
  return location == path || location.startsWith('$path/');
}

bool _sectionIsActive(String location, _SidebarSection section) {
  return section.items.any((item) => _matchesPath(location, item.path));
}

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
      location == '/device-fingerprints' ||
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
      location == '/lifecycle' ||
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

  void _toggleSection(_SidebarSection section) {
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
                      'HobeRadius',
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
                  item: _dashboardSidebarItem,
                  active:
                      _matchesPath(widget.location, _dashboardSidebarItem.path),
                  collapsed: _collapsed,
                  onTap: () => context.goNamed(_dashboardSidebarItem.routeName),
                ),
                const SizedBox(height: AppTokens.s8),
                for (final section in _sidebarSections)
                  _SidebarSectionBlock(
                    section: section,
                    collapsed: _collapsed,
                    open: _openSections.contains(section.id) ||
                        _sectionIsActive(widget.location, section),
                    active: _sectionIsActive(widget.location, section),
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

  final _SidebarItem item;
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

  final _SidebarSection section;
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
                      active: _matchesPath(location, item.path),
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
  context.goNamed(_destinations[i].routeName);
}
