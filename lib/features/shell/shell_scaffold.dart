import 'package:hoberadius_app/core/format/bidi.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/auth/permissions.dart';
import '../../core/format/currency.dart';
import '../../core/ota/ota_dialogs.dart';
import '../../core/router/app_page_transitions.dart';
import '../../core/router/nav_history.dart';
import '../../core/theme/tokens.dart';
import '../../shared/widgets/hub_toast.dart';
import '../../shared/widgets/responsive_layout.dart';
import '../admin_control/application/admin_control_providers.dart';
import '../notifications/presentation/notification_bell.dart';
import '../notifications/push/desktop_notifier.dart';
import '../notifications/push/desktop_toast_bridge.dart';
import '../notifications/push/push_service.dart';
import '../provider_grants/application/nav_visibility.dart';
import 'navigation_schema.dart';
import 'session_gate.dart';
import 'visible_nav_sections.dart';

/// Adaptive shell. The full web-style sidebar persists on desktop AND
/// tablet-landscape; it collapses to an icon rail on narrow desktop / large
/// tablet-portrait, and only genuinely narrow (phone) viewports fall back to
/// the bottom-nav layout. The decision is width-based via
/// [shellLayoutModeForWidth] — shrinking a desktop window somewhat no longer
/// drops the whole sidebar.
class ShellScaffold extends ConsumerStatefulWidget {
  const ShellScaffold({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<ShellScaffold> createState() => _ShellScaffoldState();
}

class _ShellScaffoldState extends ConsumerState<ShellScaffold> {
  DateTime? _lastBackAt;
  AppLifecycleListener? _lifecycle;

  @override
  void initState() {
    super.initState();
    // Back from the background: the owner may have changed this admin's
    // grants meanwhile — re-read them (throttled) so the menus follow.
    _lifecycle = AppLifecycleListener(
      onResume: () {
        // Offline at start-up: try /me again now that the app is back.
        final auth = ref.read(authControllerProvider);
        if (auth.offline) {
          ref.read(authControllerProvider.notifier).retrySession();
          return;
        }
        ref.read(permissionsProvider.notifier).refresh();
      },
    );
  }

  @override
  void dispose() {
    _lifecycle?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Activate the desktop toast bridge (no-op on mobile/web) and route toast
    // taps to the notification center.
    ref.watch(desktopToastBridgeProvider);
    ref.watch(pushBootstrapProvider); // no-op until FCM is enabled
    DesktopNotifier.instance.onOpen = () {
      if (context.mounted) context.goNamed('notifications');
    };

    final location = GoRouterState.of(context).matchedLocation;
    // Record each visited location so the hardware/gesture back button can
    // walk back through the go-history instead of exiting the app.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(navHistoryProvider).record(location);
    });

    final width = MediaQuery.sizeOf(context).width;
    final shell = switch (shellLayoutModeForWidth(width)) {
      ShellLayoutMode.fullSidebar => _Wide(child: widget.child),
      ShellLayoutMode.iconRail => _Wide(compact: true, child: widget.child),
      ShellLayoutMode.drawer => _Mobile(child: widget.child),
    };

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleBack();
      },
      // OTA (Shorebird) update pop-ups — no-op on web / non-Shorebird builds.
      child: OtaDialogHost(child: shell),
    );
  }

  /// Back-button policy (Android hardware/gesture back):
  ///   1. A nested route / pushed page → pop it (e.g. detail → list).
  ///   2. Otherwise walk our own go-history to the previous screen.
  ///   3. No history left but not on home → go to the home tab.
  ///   4. On home with nothing to pop → double-back to exit.
  void _handleBack() {
    final router = GoRouter.of(context);
    if (router.canPop()) {
      router.pop();
      return;
    }
    final prev = ref.read(navHistoryProvider).back();
    if (prev != null) {
      context.go(prev);
      return;
    }
    final location = GoRouterState.of(context).matchedLocation;
    if (location != '/') {
      context.go('/');
      return;
    }
    final now = DateTime.now();
    if (_lastBackAt == null ||
        now.difference(_lastBackAt!) > const Duration(seconds: 2)) {
      _lastBackAt = now;
      HubToaster.info(context, 'اضغط زر الرجوع مرة أخرى للخروج');
      return;
    }
    SystemNavigator.pop();
  }
}

int _indexOfRoute(String location, List<AppNavItem> destinations) {
  return mobileNavIndexForLocation(location, destinations);
}

class _Mobile extends ConsumerWidget {
  const _Mobile({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    // Tabs the admin may open (a manager without «المتصلون» has no such tab).
    final dests = ref.watch(visibleMobileDestinationsProvider);
    final idx = _indexOfRoute(location, dests);
    return Scaffold(
      // A page outside the bottom tabs (e.g. /notifications) used to show
      // the first tab's title «لوحة التحكم».
      appBar: _MobileAppBar(
        title: mobileTitleForLocation(location, idx, dests),
      ),
      body: SafeArea(
        child: _ContentArea(
          padding: const EdgeInsets.all(AppTokens.s12),
          child: child,
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: idx,
        onDestinationSelected: (i) => _onTap(context, dests[i]),
        destinations: dests
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

class _Wide extends ConsumerWidget {
  const _Wide({required this.child, this.compact = false});
  final Widget child;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final auth = ref.watch(authControllerProvider);
    final sections = ref.watch(visibleNavSectionsProvider);
    return Scaffold(
      body: Row(
        children: [
          _WebSidebar(
            location: location,
            admin: auth.admin,
            compact: compact,
            sections: sections,
          ),
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
  const _WebSidebar({
    required this.location,
    required this.sections,
    this.admin,
    this.compact = false,
  });
  final String location;
  final List<GatedNavSection> sections;
  final AuthAdmin? admin;

  /// When true the sidebar starts collapsed to its icon rail (the shell's
  /// middle-width band). Crossing the breakpoint syncs the collapsed state, but
  /// the user can still toggle manually within a band.
  final bool compact;

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

  late bool _collapsed = widget.compact;
  final Set<String> _openSections = {
    'subscribers',
    'cards',
    'plans',
  };

  @override
  void didUpdateWidget(_WebSidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Crossing the full ⇄ rail breakpoint resyncs the collapsed state so a
    // resized window lands in the right mode; manual toggles inside a band are
    // preserved because `compact` doesn't change within a band.
    if (widget.compact != oldWidget.compact) {
      _collapsed = widget.compact;
    }
  }

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
            alignment: Alignment.center,
            child: _collapsed
                // Collapsed rail: the brand chip itself is the expand button —
                // a separate toggle won't fit in the 72px rail.
                ? IconButton(
                    tooltip: 'توسيع القائمة',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(
                      width: 36,
                      height: 36,
                    ),
                    onPressed: () => setState(() => _collapsed = false),
                    icon: Container(
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
                  )
                : Row(
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
                      IconButton(
                        tooltip: 'تصغير القائمة',
                        onPressed: () => setState(() => _collapsed = true),
                        icon: const Icon(
                          Icons.keyboard_double_arrow_right,
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
                for (final gated in widget.sections)
                  _SidebarSectionBlock(
                    section: gated.section,
                    items: gated.items,
                    collapsed: _collapsed,
                    open: _openSections.contains(gated.section.id) ||
                        navSectionIsActive(widget.location, gated.section),
                    active: navSectionIsActive(widget.location, gated.section),
                    location: widget.location,
                    onHeaderTap: () => _toggleSection(gated.section),
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
                                ? ltrIsolate('@${widget.admin!.username}')
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
    required this.items,
    required this.collapsed,
    required this.open,
    required this.active,
    required this.location,
    required this.onHeaderTap,
  });

  final AppNavSection section;
  final List<GatedNavItem> items;
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
                  for (final gated in items)
                    _SidebarActionTile(
                      icon: gated.item.icon,
                      label: gated.item.label,
                      active: navPathMatches(location, gated.item.path),
                      collapsed: false,
                      compact: true,
                      onTap: () => context.goNamed(gated.item.routeName),
                      trailing:
                          gated.requiresUpgrade ? const _UpgradeBadge() : null,
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

/// «طلب تفعيل» chip shown next to a paid-not-active (locked_upgrade) nav item.
class _UpgradeBadge extends StatelessWidget {
  const _UpgradeBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppTokens.amber.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppTokens.r8),
        border: Border.all(color: AppTokens.amber.withValues(alpha: 0.4)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_outline, size: 12, color: AppTokens.amber),
          SizedBox(width: 3),
          Text(
            'تفعيل',
            style: TextStyle(
              color: AppTokens.amber,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContentArea extends StatefulWidget {
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
  State<_ContentArea> createState() => _ContentAreaState();
}

/// Remembers the scroll offset of every page (by its URI) so going back to
/// «المزيد» or a list lands where the operator left it, while a page opened
/// for the first time starts at the top. The shell's single scroll view wraps
/// the whole inner navigator, so a PageStorageKey restore gets clamped to 0
/// before the page lays out — hence the explicit, retried restore here.
class _ContentAreaState extends State<_ContentArea> {
  static final Map<String, double> _offsets = {};
  final ScrollController _controller = ScrollController();
  String? _location;
  int _restoreGen = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final location = GoRouterState.of(context).uri.toString();
    if (location == _location) return;
    final previous = _location;
    if (previous != null && _controller.hasClients) {
      _offsets[previous] = _controller.offset;
    }
    _location = location;
    _restoreStarted = DateTime.now();
    _restore(_offsets[location] ?? 0, ++_restoreGen);
  }

  DateTime _restoreStarted = DateTime.now();

  /// Jump to [target] once the new page is tall enough. Pages whose list
  /// comes from the network (التذاكر، الموزعون) grow only after the fetch:
  /// a fixed 12 frames ran out while the spinner animated and the page came
  /// back ~150 px off. It now keeps trying for [kScrollRestoreWindow] and
  /// stops as soon as the operator scrolls himself.
  void _restore(double target, int gen) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || gen != _restoreGen || !_controller.hasClients) return;
      final step = scrollRestoreStep(
        target: target,
        maxExtent: _controller.position.maxScrollExtent,
        elapsed: DateTime.now().difference(_restoreStarted),
      );
      _controller.jumpTo(step.jumpTo);
      if (!step.done) {
        WidgetsBinding.instance.scheduleFrame();
        _restore(target, gen);
      }
    });
  }

  bool _onUserScroll(ScrollNotification n) {
    // A drag by the operator ends any pending restore.
    if (n is ScrollStartNotification && n.dragDetails != null) _restoreGen++;
    return false;
  }

  @override
  void dispose() {
    if (_location != null && _controller.hasClients) {
      _offsets[_location!] = _controller.offset;
    }
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: widget.desktopSurface ? const Color(0xFFEFEDF5) : AppTokens.bg,
      child: Column(
        children: [
          if (widget.showTopBar) const _DesktopTopBar(),
          const SessionOfflineBanner(),
          Expanded(
            child: NotificationListener<ScrollNotification>(
              onNotification: _onUserScroll,
              child: SingleChildScrollView(
                controller: _controller,
                padding: widget.padding,
                // Center + cap the content column so wide desktops don't stretch
                // content edge-to-edge (shared density rule — propagates to every
                // screen via the shell).
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppTokens.contentMaxWidth,
                    ),
                    child: Consumer(
                      builder: (context, ref, child) => TenantCurrencyScope(
                        code: ref.watch(tenantCurrencyProvider),
                        child: child!,
                      ),
                      child: ShellContentScope(
                        child: SessionContentGate(child: widget.child),
                      ),
                    ),
                  ),
                ),
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
      actions: const [
        NotificationBell(color: AppTokens.sidebarBg),
        SizedBox(width: AppTokens.s4),
      ],
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
      padding: const EdgeInsets.symmetric(horizontal: AppTokens.s20),
      decoration: const BoxDecoration(
        color: AppTokens.card,
        border: Border(bottom: BorderSide(color: AppTokens.border)),
      ),
      child: Row(
        children: [
          const Spacer(),
          const NotificationBell(),
          const SizedBox(width: AppTokens.s8),
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

void _onTap(BuildContext context, AppNavItem item) {
  // mobileNavDestinations filtered by permissions (visibleMobileDestinations).
  context.goNamed(item.routeName);
}

/// How long the shell keeps trying to restore a page's scroll offset while
/// the page is still loading.
const Duration kScrollRestoreWindow = Duration(seconds: 4);

/// One restore step: where to jump now, and whether restoring is over.
({double jumpTo, bool done}) scrollRestoreStep({
  required double target,
  required double maxExtent,
  required Duration elapsed,
  Duration window = kScrollRestoreWindow,
}) {
  if (target <= maxExtent) return (jumpTo: target < 0 ? 0 : target, done: true);
  if (elapsed >= window) return (jumpTo: maxExtent, done: true);
  return (jumpTo: maxExtent, done: false);
}
