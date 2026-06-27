@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/shared/widgets/hub_unit_input.dart';

import 'golden_harness.dart';

void main() {
  Widget sample() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HubUnitInput(
            value: 1024,
            kind: HubUnitKind.speed,
            onChanged: (_) {},
          ),
          const SizedBox(height: 10),
          HubUnitInput(
            value: 5120,
            kind: HubUnitKind.quota,
            onChanged: (_) {},
          ),
          const SizedBox(height: 10),
          HubUnitInput(
            value: 60,
            kind: HubUnitKind.time,
            onChanged: (_) {},
          ),
          const SizedBox(height: 10),
          HubUnitInput(
            value: 0,
            kind: HubUnitKind.speed,
            units: const ['kbps', 'Mbps'],
            enabled: false,
            onChanged: (_) {},
          ),
        ],
      );

  group('HubUnitInput goldens', () {
    testWidgets('light', (tester) async {
      await pumpGolden(
        tester,
        brightness: Brightness.light,
        size: const Size(420, 320),
        child: sample(),
      );
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(goldenPath('hub_unit_input_light')),
      );
    });

    testWidgets('dark', (tester) async {
      await pumpGolden(
        tester,
        brightness: Brightness.dark,
        size: const Size(420, 320),
        child: sample(),
      );
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(goldenPath('hub_unit_input_dark')),
      );
    });
  });
}