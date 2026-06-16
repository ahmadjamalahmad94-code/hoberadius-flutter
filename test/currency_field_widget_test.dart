import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/features/admin_control/application/admin_control_providers.dart';
import 'package:hoberadius_app/features/admin_control/domain/admin_control_model.dart';
import 'package:hoberadius_app/shared/widgets/currency_field.dart';

/// A minimal money form that reads the central tenant currency, standing in for
/// the wallet / payment / ticket dialogs which now all use [CurrencyField].
class _MoneyForm extends ConsumerWidget {
  const _MoneyForm();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = ref.watch(tenantCurrencyProvider);
    return CurrencyField(currency: currency);
  }
}

Future<void> _pump(WidgetTester tester, Map<String, String> settings) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        settingsProvider.overrideWith(
          (ref) async => SettingsSnapshot(items: const [], settings: settings),
        ),
      ],
      child: const MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(body: _MoneyForm()),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('money form shows the tenant currency (JOD)', (tester) async {
    await _pump(tester, {'billing.currency': 'JOD'});
    expect(find.textContaining('JOD'), findsOneWidget);
    expect(find.textContaining('دينار أردني'), findsOneWidget);
  });

  testWidgets('changing tenant currency propagates to the money form',
      (tester) async {
    await _pump(tester, {'billing.currency': 'ILS'});
    expect(find.textContaining('ILS'), findsOneWidget);
    expect(find.textContaining('شيكل'), findsOneWidget);
    // No JOD leakage when the tenant is configured for ILS.
    expect(find.textContaining('JOD'), findsNothing);
  });

  testWidgets('absent currency setting falls back to JOD, never ILS',
      (tester) async {
    await _pump(tester, {});
    expect(find.textContaining('JOD'), findsOneWidget);
  });
}
