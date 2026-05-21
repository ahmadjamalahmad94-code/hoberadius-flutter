import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/shared/widgets/hub_access_schedule.dart';

import 'golden_harness.dart';

void main() {
  Widget sample() => HubAccessSchedule(
        value: const AccessSchedule(
          windows: [
            AccessWindow(
              days: ['sat', 'sun', 'mon'],
              from: '09:00',
              to: '17:00',
            ),
          ],
        ),
        onChanged: (_) {},
      );

  group('HubAccessSchedule goldens', () {
    testWidgets('light', (tester) async {
      await pumpGolden(
        tester,
        brightness: Brightness.light,
        size: const Size(560, 720),
        child: sample(),
      );
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(goldenPath('hub_access_schedule_light')),
      );
    });

    testWidgets('dark', (tester) async {
      await pumpGolden(
        tester,
        brightness: Brightness.dark,
        size: const Size(560, 720),
        child: sample(),
      );
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(goldenPath('hub_access_schedule_dark')),
      );
    });
  });
}
