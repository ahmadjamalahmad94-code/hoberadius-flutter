@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/shared/widgets/hub_speed_rules_panel.dart';

import 'golden_harness.dart';

void main() {
  Widget sample() => HubSpeedRulesPanel(
        rules: const [
          SpeedRule(
            name: 'سرعة المساء',
            days: ['sun', 'mon', 'tue'],
            startsAtTime: '18:00',
            endsAtTime: '23:00',
            speedDownKbps: 2048,
            speedUpKbps: 1024,
            enabled: true,
          ),
          SpeedRule(
            name: 'وقت النوم',
            days: ['fri'],
            startsAtTime: '23:00',
            endsAtTime: '06:00',
            speedDownKbps: 512,
            speedUpKbps: 256,
            enabled: false,
          ),
        ],
        onChanged: (_) {},
        helpText: 'ينطبق على كل المشتركين في هذه المجموعة.',
      );

  group('HubSpeedRulesPanel goldens', () {
    testWidgets('light', (tester) async {
      await pumpGolden(
        tester,
        brightness: Brightness.light,
        size: const Size(720, 1200),
        child: SingleChildScrollView(child: sample()),
      );
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(goldenPath('hub_speed_rules_panel_light')),
      );
    });

    testWidgets('dark', (tester) async {
      await pumpGolden(
        tester,
        brightness: Brightness.dark,
        size: const Size(720, 1200),
        child: SingleChildScrollView(child: sample()),
      );
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(goldenPath('hub_speed_rules_panel_dark')),
      );
    });
  });
}