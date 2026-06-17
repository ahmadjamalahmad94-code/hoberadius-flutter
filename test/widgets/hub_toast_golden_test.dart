@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/shared/widgets/hub_toast.dart';

import 'golden_harness.dart';

void main() {
  Widget sample() => const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HubToast(message: 'تم الحفظ بنجاح'),
          SizedBox(height: 12),
          HubToast(
            message: 'تعذّر إتمام العملية',
            kind: HubToastKind.error,
          ),
          SizedBox(height: 12),
          HubToast(
            message: 'جاري المزامنة…',
            kind: HubToastKind.info,
          ),
        ],
      );

  group('HubToast goldens', () {
    testWidgets('light', (tester) async {
      await pumpGolden(
        tester,
        brightness: Brightness.light,
        size: const Size(420, 320),
        child: sample(),
      );
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(goldenPath('hub_toast_light')),
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
        matchesGoldenFile(goldenPath('hub_toast_dark')),
      );
    });
  });
}