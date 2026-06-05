String currencyLabel(String code) {
  return switch (code.trim().toUpperCase()) {
    'ILS' => 'شيكل إسرائيلي',
    'JOD' => 'دينار أردني',
    'USD' => 'دولار أمريكي',
    '' => 'عملة غير محددة',
    _ => 'عملة غير معروفة',
  };
}

String amountWithCurrency(String amount, String code) {
  final value = amount.trim().isEmpty ? '0' : amount.trim();
  return '$value ${currencyLabel(code)}';
}

String unknownStatusLabel(
  String value, {
  String emptyLabel = 'غير محدد',
  String unknownLabel = 'حالة غير معروفة',
}) {
  return value.trim().isEmpty ? emptyLabel : unknownLabel;
}

String unknownActionLabel(
  String value, {
  String emptyLabel = 'عملية',
  String unknownLabel = 'عملية غير معروفة',
}) {
  return value.trim().isEmpty ? emptyLabel : unknownLabel;
}
