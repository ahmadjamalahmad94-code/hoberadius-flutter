import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';

/// Semantic status pill matching the web `.hub-pill` look.
///
/// Each tone uses a soft tinted background + matching ink color +
/// matching border. Visual parity with the cards_checker_v2 pills.
enum PillTone {
  green,    // success / online
  amber,    // warning / pending
  red,      // danger / error
  blue,     // info
  brand,    // brand purple
  navy,     // legacy alias → brand
  cyan,     // legacy alias → brand
  purple,   // legacy alias → brand
  orange,   // legacy alias → amber
  neutral,  // grey
}

class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.text,
    this.tone = PillTone.brand,
    this.icon,
    this.dot = false,
  });

  final String text;
  final PillTone tone;
  final IconData? icon;

  /// Show a small color dot before the label (matches `.hub-pill .dot`).
  final bool dot;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, border) = switch (tone) {
      PillTone.green
          => (AppTokens.greenSoft, AppTokens.greenInk, const Color(0xFF86EFAC)),
      PillTone.amber
      || PillTone.orange
          => (AppTokens.amberSoft, AppTokens.amberInk, const Color(0xFFFCD34D)),
      PillTone.red
          => (AppTokens.redSoft, AppTokens.redInk, const Color(0xFFFCA5A5)),
      PillTone.blue
          => (AppTokens.blueSoft, AppTokens.blueInk, const Color(0xFFBFDBFE)),
      PillTone.brand
      || PillTone.cyan
      || PillTone.purple
      || PillTone.navy
          => (AppTokens.brandSoft, AppTokens.brandInk, AppTokens.borderStrong),
      PillTone.neutral
          => (const Color(0xFFF1F5F9), const Color(0xFF64748B), const Color(0xFFCBD5E1)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
          ],
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: fg,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
