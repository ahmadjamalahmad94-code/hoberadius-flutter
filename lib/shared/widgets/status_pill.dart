import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';

/// Semantic status pill matching the web `.hub-pill` look.
///
/// Each tone uses a soft tinted background + matching ink color +
/// matching border. Visual parity with the cards_checker_v2 pills.
enum PillTone {
  green, // success / online
  amber, // warning / pending
  red, // danger / error
  blue, // info
  brand, // brand purple
  navy, // legacy alias → brand
  cyan, // legacy alias → brand
  purple, // legacy alias → brand
  orange, // legacy alias → amber
  neutral, // grey
}

/// Background / foreground / border for a [PillTone] — the single colour
/// source shared by [StatusPill] and the count/action widgets, so a status
/// reads the same colour everywhere in the app.
(Color, Color, Color) pillToneColors(PillTone tone) => switch (tone) {
      PillTone.green => (
          AppTokens.greenSoft,
          AppTokens.greenInk,
          AppTokens.successMed,
        ),
      PillTone.amber || PillTone.orange => (
          AppTokens.amberSoft,
          AppTokens.amberInk,
          AppTokens.warningMed,
        ),
      PillTone.red => (
          AppTokens.redSoft,
          AppTokens.redInk,
          AppTokens.dangerMed,
        ),
      PillTone.blue => (
          AppTokens.blueSoft,
          AppTokens.blueInk,
          AppTokens.infoMed,
        ),
      PillTone.brand || PillTone.cyan || PillTone.purple || PillTone.navy => (
          AppTokens.brandSoft,
          AppTokens.brandInk,
          AppTokens.borderStrong,
        ),
      PillTone.neutral => (
          AppTokens.slate100,
          AppTokens.slate500,
          AppTokens.slate200,
        ),
    };

/// One meaning per colour, app-wide (owner review: متاح / منتهي / متصل /
/// مستخدم must be told apart at a glance):
///   green  = online / active / live (متصل، نشط)
///   blue   = available, ready to use (متاح)
///   brand  = used / consumed (مستخدم)
///   amber  = expired / suspended / exhausted (منتهي، موقوف، مستهلك)
///   red    = revoked / disabled / banned (ملغى، معطّل، محظور)
///   neutral= archived / totals / pending (مؤرشف، الإجمالي)
PillTone toneForStatus(String status) => switch (status.trim().toLowerCase()) {
      'online' ||
      'active' ||
      'connected' ||
      'enabled' ||
      'live' ||
      'متصل' ||
      'متصلة' ||
      'نشط' ||
      'نشطة' ||
      'مفعّل' ||
      'مفعل' =>
        PillTone.green,
      'available' || 'unused' || 'متاح' || 'متاحة' => PillTone.blue,
      'used' || 'consumed' || 'مستخدم' || 'مستخدمة' => PillTone.brand,
      'expired' ||
      'exhausted' ||
      'suspended' ||
      'ended' ||
      'stopped' ||
      'منتهي' ||
      'منتهية' ||
      'مستهلكة' ||
      'موقوف' =>
        PillTone.amber,
      'revoked' ||
      'disabled' ||
      'banned' ||
      'cancelled' ||
      'canceled' ||
      'blocked' ||
      'ملغى' ||
      'معطّل' ||
      'معطل' ||
      'محظور' =>
        PillTone.red,
      _ => PillTone.neutral,
    };

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
    final (bg, fg, border) = pillToneColors(tone);
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
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: fg,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
