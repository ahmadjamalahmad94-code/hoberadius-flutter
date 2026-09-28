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

/// Arabic for the raw status / type / direction tokens the API returns in
/// report rows and logs (`posted`, `credit`, `password_wrong`, `enabled`…).
/// Unknown tokens are returned unchanged.
const Map<String, String> kRawTokenLabels = {
  'posted': 'مرحّل',
  'voided': 'معكوس',
  'reversed': 'معكوس',
  'pending': 'قيد الانتظار',
  'open': 'مفتوح',
  'settled': 'مسدّد',
  'failed': 'فشل',
  'success': 'نجاح',
  'ok': 'ناجح',
  'credit': 'دائن (إيداع)',
  'debit': 'مدين (خصم)',
  'settlement': 'تسوية',
  'loan': 'سلفة',
  'payment': 'دفعة',
  'payment_to_balance': 'دفعة — إضافة للرصيد',
  'payment_to_debt': 'دفعة — خصم من الدين',
  'debt_settle': 'تسديد دين',
  'debt': 'دين',
  'balance': 'رصيد',
  'adjustment': 'تعديل',
  'void': 'قيد عكسي',
  'general': 'عام',
  'extension': 'تمديد وقت',
  'quota_topup': 'إضافة كوتة',
  'subscriber': 'مشترك',
  'distributor': 'موزّع',
  'manager': 'مدير',
  'admin': 'مدير',
  'card': 'كرت',
  'enabled': 'مفعّل',
  'disabled': 'معطّل',
  'active': 'نشط',
  'inactive': 'غير نشط',
  'expired': 'منتهي',
  'suspended': 'موقوف',
  'banned': 'محظور',
  'password_wrong': 'كلمة مرور خاطئة',
  'user_not_found': 'مستخدم غير موجود',
  'not_found': 'غير موجود',
  'manual': 'يدوي',
  'cash': 'نقدًا',
  'bank': 'تحويل بنكي',
};

String rawTokenLabel(String value) {
  final key = value.trim().toLowerCase();
  return kRawTokenLabels[key] ?? value;
}
