import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';

enum PillTone { green, orange, red, cyan, purple, navy, neutral }

class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.text,
    this.tone = PillTone.cyan,
    this.icon,
  });

  final String text;
  final PillTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (tone) {
      PillTone.green => (const Color(0xFFE6F6EC), AppTokens.green),
      PillTone.orange => (const Color(0xFFFFF1DF), AppTokens.orange),
      PillTone.red => (const Color(0xFFFDE9E9), AppTokens.red),
      PillTone.cyan => (AppTokens.cyan100, AppTokens.cyan500),
      PillTone.purple => (const Color(0xFFEEE6FA), AppTokens.purple),
      PillTone.navy => (const Color(0xFFE3E9F4), AppTokens.navy700),
      PillTone.neutral => (const Color(0xFFEFF2F7), AppTokens.textSecondary),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style:
                TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
