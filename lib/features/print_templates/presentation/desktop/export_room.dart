/// The Windows-only export room.
///
/// Mirror of the web admin's `<section id="export">` 3-column shell.
/// Used by [PrintTemplatesScreen] when
/// `PlatformCapabilities.isDesktop` is true OR
/// `width >= AppTokens.bpTablet` on web. Mobile takes the existing
/// single-column layout instead — mobile-safety contract preserved.
// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';
import 'export_room_shortcuts.dart';
import 'preview_column.dart';
import 'settings_column.dart';
import 'template_chips_column.dart';

/// Windows / desktop export room.
///
/// 3-column layout when the available content width allows
/// (≥ 1100 px). Below that the columns wrap into a vertical
/// stack so the screen still works on a 900 px window after the
/// shell sidebar eats its share of the page.
class ExportRoom extends StatelessWidget {
  const ExportRoom({super.key});

  /// Width below which the 3-column row collapses into a stack.
  /// 360 (settings) + 12 + ~400 (preview min) + 12 + 320 (chips) ≈ 1104.
  static const double _threeColumnThreshold = 1100;

  @override
  Widget build(BuildContext context) {
    return ExportRoomShortcuts(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final canFitThreeColumns =
              constraints.maxWidth >= _threeColumnThreshold;
          if (canFitThreeColumns) {
            return ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 480),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(width: 360, child: SettingsColumn()),
                  SizedBox(width: AppTokens.s12),
                  Expanded(child: PreviewColumn()),
                  SizedBox(width: AppTokens.s12),
                  SizedBox(width: 320, child: TemplateChipsColumn()),
                ],
              ),
            );
          }
          // Narrow desktop window — stack vertically with reasonable
          // heights so each section is usable. Preview gets the most
          // room because it's the visual centerpiece.
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: const [
              SettingsColumn(),
              SizedBox(height: AppTokens.s12),
              SizedBox(height: 380, child: PreviewColumn()),
              SizedBox(height: AppTokens.s12),
              SizedBox(height: 320, child: TemplateChipsColumn()),
            ],
          );
        },
      ),
    );
  }
}
