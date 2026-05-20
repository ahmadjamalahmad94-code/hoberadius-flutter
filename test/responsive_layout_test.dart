import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/shared/widgets/page_header.dart';

void main() {
  testWidgets('page header keeps Arabic title and actions usable on phones', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(12),
              child: PageHeader(
                title: 'مركز عمليات حزم البطاقات',
                subtitle:
                    'فلاتر وإحصائيات وأرشفة آمنة وتصدير من الخادم الحقيقي.',
                actions: [
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.manage_search_outlined),
                    label: const Text('فحص بطاقة'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.add),
                    label: const Text('حزمة جديدة'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('مركز عمليات حزم البطاقات'), findsOneWidget);
    expect(find.text('فحص بطاقة'), findsOneWidget);
    expect(find.text('حزمة جديدة'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
