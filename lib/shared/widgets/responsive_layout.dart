import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';

/// Which navigation chrome the app shell renders for a given viewport width.
///
/// The decision is purely width-based (the owner's requirement): a desktop
/// window shrunk somewhat — or a tablet in landscape — keeps the full web-style
/// sidebar, and only genuinely narrow viewports fall back to the phone layout.
enum ShellLayoutMode {
  /// Full expanded sidebar (desktop + tablet-landscape).
  fullSidebar,

  /// Same sidebar component, collapsed to an icon rail (narrow desktop /
  /// large tablet-portrait). All groups stay reachable via tooltips.
  iconRail,

  /// Phone layout — bottom navigation bar.
  drawer,
}

/// Maps a viewport [width] to the shell navigation mode using the
/// `AppTokens.bpSidebar*` breakpoints. Pure + side-effect free so the shell
/// decision is unit-testable without pumping a widget tree.
ShellLayoutMode shellLayoutModeForWidth(double width) {
  if (width >= AppTokens.bpSidebarFull) return ShellLayoutMode.fullSidebar;
  if (width >= AppTokens.bpSidebarRail) return ShellLayoutMode.iconRail;
  return ShellLayoutMode.drawer;
}

/// Lightweight responsive helper for list/detail-style screens.
///
/// On phones (≤ AppTokens.bpTablet) renders [list] full-width.
/// On tablets/desktops it puts [list] on the start side at the
/// configured [listWidth] and lets the optional [detail] take the
/// remaining space — the master-detail layout the J6.3 plan calls for
/// without forcing each screen to roll its own LayoutBuilder.
class HubMasterDetail extends StatelessWidget {
  const HubMasterDetail({
    super.key,
    required this.list,
    this.detail,
    this.listWidth = 420,
    this.gap = AppTokens.s16,
  });

  final Widget list;
  final Widget? detail;
  final double listWidth;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final isWide = c.maxWidth >= AppTokens.bpTablet && detail != null;
        if (!isWide) return list;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: listWidth, child: list),
            SizedBox(width: gap),
            Expanded(child: detail!),
          ],
        );
      },
    );
  }
}
