@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/shared/widgets/hub_toggle_switch.dart';

import 'golden_harness.dart';

void main() {
  group('HubToggleSwitch goldens', () {
    final variants = Builder(
      builder: (_) => Wrap(
        spacing: 14,
        runSpacing: 14,
        children: [
          HubToggleSwitch(value: true, onChanged: (_) {}),
          HubToggleSwitch(value: false, onChanged: (_) {}),
          HubToggleSwitch(
            value: true,
            size: HubToggleSize.sm,
            onChanged: (_) {},
          ),
          HubToggleSwitch(
            value: false,
            size: HubToggleSize.sm,
            onChanged: (_) {},
          ),
          HubToggleSwitch(value: true, bare: true, onChanged: (_) {}),
          const HubToggleSwitch(value: true, onChanged: null),
        ],
      ),
    );

    testWidgets('light', (tester) async {
      await pumpGolden(
        tester,
        brightness: Brightness.light,
        size: const Size(420, 240),
        child: variants,
      );
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(goldenPath('hub_toggle_switch_light')),
      );
    });

    testWidgets('dark', (tester) async {
      await pumpGolden(
        tester,
        brightness: Brightness.dark,
        size: const Size(420, 240),
        child: variants,
      );
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(goldenPath('hub_toggle_switch_dark')),
      );
    });
  });
}