import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';

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
