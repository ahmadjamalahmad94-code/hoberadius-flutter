import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/shared/widgets/hub_time_picker_circular.dart';

import 'golden_harness.dart';

void main() {
  Widget sample() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HubTimePickerCircular(value: '08:00', onChanged: (_) {}),
          const SizedBox(height: 10),
          HubTimePickerCircular(
            value: '22:30',
            onChanged: (_) {},
          ),
          const SizedBox(height: 10),
          HubTimePickerCircular(value: null, onChanged: (_) {}),
        ],
      );

  group('HubTimePickerCircular goldens', () {
    testWidgets('light', (tester) async {
      await pumpGolden(
        tester,
        brightness: Brightness.light,
        size: const Size(420, 220),
        child: sample(),
      );
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(goldenPath('hub_time_picker_circular_light')),
      );
    });

    testWidgets('dark', (tester) async {
      await pumpGolden(
        tester,
        brightness: Brightness.dark,
        size: const Size(420, 220),
        child: sample(),
      );
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(goldenPath('hub_time_picker_circular_dark')),
      );
    });
  });
}
