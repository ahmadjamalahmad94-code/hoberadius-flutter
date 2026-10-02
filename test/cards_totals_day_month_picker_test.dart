// Owner 2026-10-02: «بطاقات اليوم/الشهر» for ANY day / month; the value
// tile says what it is and its number is never cut.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/features/cards/domain/card_batch_operations.dart';
import 'package:hoberadius_app/features/cards/presentation/widgets/cards_list_totals.dart';

Widget _wrap(Widget child) => MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );

void main() {
  testWidgets('day tile opens a date picker and reports the picked day',
      (tester) async {
    String? day;
    await tester.pumpWidget(_wrap(CardsListTotals(
      totals: CardBatchOperationsTotals(usedToday: 3, valueToday: 15),
      onPickDay: (d) => day = d,
      onPickMonth: (_) {},
    ),),);
    await tester.tap(find.text('بطاقات اليوم'));
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerDialog), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    final now = DateTime.now();
    expect(day,
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',);
  });

  testWidgets('month tile opens a month grid and reports YYYY-MM',
      (tester) async {
    String? month;
    await tester.pumpWidget(_wrap(CardsListTotals(
      totals: CardBatchOperationsTotals(usedMonth: 9, valueMonth: 45),
      onPickDay: (_) {},
      onPickMonth: (m) => month = m,
    ),),);
    await tester.tap(find.text('بطاقات الشهر'));
    await tester.pumpAndSettle();
    expect(find.text('اختر الشهر'), findsOneWidget);
    await tester.tap(find.text('يناير'));
    await tester.pumpAndSettle();
    expect(month, '${DateTime.now().year}-01');
  });

  testWidgets('a picked past day/month is named on the tile', (tester) async {
    await tester.pumpWidget(_wrap(CardsListTotals(
      totals: CardBatchOperationsTotals(day: '2026-09-10', month: '2026-08'),
      onPickDay: (_) {},
      onPickMonth: (_) {},
    ),),);
    expect(find.text('بطاقات 2026-09-10'), findsOneWidget);
    expect(find.text('بطاقات أغسطس 2026'), findsOneWidget);
  });

  testWidgets('value tile is labelled clearly and the number is not cut',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_wrap(CardsListTotals(
      totals: CardBatchOperationsTotals(configuredValue: 102815.4),
    ),),);
    expect(find.text('قيمة كل كروت الحزم'), findsOneWidget);
    expect(find.text('بسعر البيع، المباع وغير المباع'), findsOneWidget);
    final value = tester.widget<Text>(find.textContaining('102,815.4'));
    expect(value.overflow, isNot(TextOverflow.ellipsis));
    expect(tester.takeException(), isNull);
  });
}
