import 'package:flutter/material.dart';

import '../../core/l10n/arabic_labels.dart';

/// Read-only indicator of the tenant's central currency.
///
/// Money in HobeRadius always uses the tenant currency (web
/// `default_currency()` / `billing.currency`) — operators do not choose an
/// arbitrary currency per request. This replaces the old hardcoded
/// `['ILS','JOD','USD']` dropdowns so every form stays consistent with the
/// configured currency.
class CurrencyField extends StatelessWidget {
  const CurrencyField({
    super.key,
    required this.currency,
    this.label = 'العملة',
  });

  final String currency;
  final String label;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        helperText: 'عملة المنشأة المركزية',
        suffixIcon: const Icon(Icons.lock_outline, size: 16),
      ),
      child: Text(
        '${currencyLabel(currency)} ($currency)',
        textDirection: TextDirection.rtl,
      ),
    );
  }
}
