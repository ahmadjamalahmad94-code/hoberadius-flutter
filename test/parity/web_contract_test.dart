/// Replay the JSON / HTML responses captured by
/// `tools/diff_web_admin.sh` into the Dart parsers + renderer, and
/// assert the contracts the Flutter Windows build depends on.
///
/// These tests run with whatever snapshots happen to be present in
/// `tools/web_snapshots/`. If a snapshot is missing the test is
/// skipped rather than failed — re-run the capture script to
/// populate them.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/features/print_templates/data/card_renderer_svg.dart';
import 'package:hoberadius_app/features/print_templates/domain/card_render_model_builder.dart';
import 'package:hoberadius_app/features/print_templates/domain/print_template_model.dart';

File _snap(String name) {
  final dir = Directory.current.path;
  // tests run from project root in `flutter test`.
  return File('$dir/tools/web_snapshots/$name');
}

void main() {
  test('print_templates list response shape', () {
    final file = _snap('print_templates_list.json');
    if (!file.existsSync()) {
      markTestSkipped('snapshot missing — run tools/diff_web_admin.sh');
      return;
    }
    final body = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    expect(body, contains('data'));
    final items = (body['data'] as Map)['items'] as List;
    expect(items, isNotEmpty);
    final firstRaw = (items.first as Map)
        .map((k, v) => MapEntry(k.toString(), v));
    final parsed = CardPrintTemplate.fromJson(firstRaw);
    expect(parsed.id, isPositive);
    expect(parsed.name, isNotEmpty);
  });

  test('preset list parses through PrintTemplatePreset', () {
    final file = _snap('print_template_presets.json');
    if (!file.existsSync()) {
      markTestSkipped('snapshot missing — run tools/diff_web_admin.sh');
      return;
    }
    final body = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    final items = (body['data'] as Map)['items'] as List;
    expect(items, isNotEmpty);
    for (final raw in items) {
      final map = (raw as Map).map((k, v) => MapEntry(k.toString(), v));
      final preset = PrintTemplatePreset.fromJson(map);
      expect(preset.key, isNotEmpty);
      expect(preset.name, isNotEmpty);
    }
  });

  test('list response feeds the unified renderer cleanly', () {
    final file = _snap('print_templates_list.json');
    if (!file.existsSync()) {
      markTestSkipped('snapshot missing — run tools/diff_web_admin.sh');
      return;
    }
    final body = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    final items = (body['data'] as Map)['items'] as List;
    final firstRaw = (items.first as Map)
        .map((k, v) => MapEntry(k.toString(), v));
    final template = {
      'id': firstRaw['id'],
      'username_x': firstRaw['username_x'] ?? 0,
      'username_y': firstRaw['username_y'] ?? 0,
      'password_x': firstRaw['password_x'] ?? 0,
      'password_y': firstRaw['password_y'] ?? 0,
      'qr_x': firstRaw['qr_x'] ?? 0,
      'qr_y': firstRaw['qr_y'] ?? 0,
      'layout_json': firstRaw['layout_json'] ?? firstRaw['layout'] ?? const {},
    };
    final model = buildCardRenderModel(
      template,
      card: const {'id': 1, 'username': 'CARD1234', 'password': 'pw'},
    );
    final svg = renderCardSvg(model);
    expect(svg, startsWith('<svg '));
    expect(svg, contains('viewBox="0 0'));
  });

  test('preview-fragment is plain HTML (no Flutter expects to parse it)', () {
    // The Windows app's primary preview is the local SVG (B3). The
    // backend HTML fragment is only used by parity tests + fall-back
    // paths. We just check the HTML is not empty + carries the
    // viewBox marker — that's enough to confirm the backend renderer
    // is still emitting an SVG-bearing fragment.
    final file = _snap('preview_fragment_1.html');
    if (!file.existsSync()) {
      markTestSkipped('snapshot missing — run tools/diff_web_admin.sh');
      return;
    }
    final body = file.readAsStringSync();
    expect(body, contains('viewBox'));
    expect(body, contains('direction="ltr"'));
  });
}
