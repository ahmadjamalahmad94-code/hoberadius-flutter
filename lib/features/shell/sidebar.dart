import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/tokens.dart';

class _NavItem {
  const _NavItem(this.icon, this.label, this.routeName);
  final IconData icon;
  final String label;
  final String routeName;
}

const _navItems = <_NavItem>[
  _NavItem(Icons.dashboard_outlined, 'لوحة التحكم', 'dashboard'),
  _NavItem(Icons.person_outline, 'المشتركون', 'subscribers'),
  _NavItem(Icons.workspace_premium_outlined, 'الباقات', 'plans'),
  _NavItem(Icons.credit_card_outlined, 'الكروت', 'cards'),
  _NavItem(Icons.manage_search_outlined, 'فحص بطاقة', 'card-checker'),
  _NavItem(Icons.online_prediction, 'المتصلون الآن', 'sessions'),
  _NavItem(Icons.router_outlined, 'أجهزة الشبكة', 'nas'),
  _NavItem(Icons.admin_panel_settings_outlined, 'المدراء', 'admins'),
  _NavItem(Icons.people_alt_outlined, 'الموزعون', 'distributors'),
  _NavItem(Icons.account_balance_wallet_outlined, 'السجل المالي', 'ledger'),
  _NavItem(
    Icons.insert_chart_outlined,
    'التقارير المالية',
    'financial-reports',
  ),
  _NavItem(Icons.inventory_2_outlined, 'سلة المحذوفات', 'recycle-bin'),
  _NavItem(Icons.storage_outlined, 'النسخ الاحتياطي', 'backups'),
  _NavItem(Icons.speed_outlined, 'جدولة السرعات', 'bandwidth-schedules'),
  _NavItem(Icons.print_outlined, 'قوالب الطباعة', 'print-templates'),
  _NavItem(Icons.shield_outlined, 'الأدوار', 'roles'),
];

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
          const Divider(color: Color(0x33FFFFFF), height: 1),
          Padding(
            padding: const EdgeInsets.all(AppTokens.s16),
            child: Text(
              'HobeRadius • v0.1',
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
    final pathMap = {
      'dashboard': '/',
      'subscribers': '/subscribers',
      'plans': '/plans',
      'cards': '/cards',
      'card-checker': '/cards/checker',
      'sessions': '/sessions',
      'nas': '/nas',
      'admins': '/admins',
      'distributors': '/distributors',
      'ledger': '/ledger',
      'financial-reports': '/reports',
      'recycle-bin': '/recycle-bin',
      'backups': '/backups',
      'bandwidth-schedules': '/bandwidth-schedules',
      'print-templates': '/print-templates',
      'roles': '/roles',
    };
    final base = pathMap[routeName];
    if (base == null) return false;
    if (base == '/') return currentPath == '/';
    return currentPath == base || currentPath.startsWith('$base/');
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
          bottom: BorderSide(color: Color(0x22FFFFFF), width: 1),
        ),
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
            child:
                const Icon(Icons.wifi_tethering, color: Colors.white, size: 18),
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
    );
  }
}

class _SidebarTile extends StatelessWidget {
  const _SidebarTile({
    required this.item,
    required this.active,
    required this.onTap,
  });
  final _NavItem item;
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
            color: active ? AppTokens.cyan500.withValues(alpha: 0.18) : null,
            borderRadius: BorderRadius.circular(AppTokens.r10),
            border: active
                ? Border.all(color: AppTokens.cyan500.withValues(alpha: 0.3))
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
