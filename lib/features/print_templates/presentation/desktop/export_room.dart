/// The Windows-only 3-column export room.
///
/// Mirror of the web admin's `<section id="export">` 3-column shell.
/// Used by [PrintTemplatesScreen] when
/// `MediaQuery.width >= AppTokens.bpDesktop`. Below that breakpoint
/// the mobile / web-narrow layout takes over — mobile-safety
/// contract preserved.
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';
import 'export_room_shortcuts.dart';
import 'preview_column.dart';
import 'settings_column.dart';
import 'template_chips_column.dart';

class ExportRoom extends StatelessWidget {
  const ExportRoom({super.key});

  @override
  Widget build(BuildContext context) {
    return ExportRoomShortcuts(
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 480),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left  — settings (batch + overrides + actions)
            SizedBox(width: 360, child: SettingsColumn()),
            SizedBox(width: AppTokens.s12),
            // Center — live SVG preview (fit-to-viewport)
            Expanded(child: PreviewColumn()),
            SizedBox(width: AppTokens.s12),
            // Right — template chips list + star + sample PDF + delete
            SizedBox(width: 320, child: TemplateChipsColumn()),
          ],
        ),
      ),
    );
  }
}
