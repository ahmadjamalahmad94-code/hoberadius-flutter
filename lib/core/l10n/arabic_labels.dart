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
  // Ledger entry types (server `entry_type`).
  'time_extension': 'تمديد وقت',
  'debt_settlement': 'تسديد دين',
  'writeoff': 'مسامحة / إعفاء',
  'on_account_credit': 'رصيد على الحساب',
  'cash_balance': 'رصيد نقدي',
  'correction': 'تصحيح',
  'card_sale': 'بيع بطاقة',
  'wallet_recharge': 'شحن محفظة',
  'batch_creation': 'إنشاء حزمة بطاقات',
  'reversal': 'قيد عكسي',
  'refund': 'استرداد',
  'discount': 'خصم',
  'topup': 'شحن رصيد',
  'invoice': 'فاتورة',
  // Ledger sources (server `source_type`).
  'payment_void': 'إلغاء دفعة',
  'payment_balance_settlement': 'تسوية رصيد من دفعة',
  'payment_collection_request': 'طلب تحصيل',
  'loan_writeoff': 'مسامحة سلفة',
  'ledger_void': 'عكس قيد',
  'subscriber_time_extension': 'تمديد وقت المشترك',
  'subscriber_quota_topup': 'شحن كوتة المشترك',
  'subscriber_plan_change': 'تغيير عرض المشترك',
  'subscriber_daily_quota_reset': 'استعادة الكوتة اليومية',
  'subscriber_cash_balance': 'رصيد نقدي للمشترك',
  'subscriber_payment': 'دفعة مشترك',
  'external': 'مصدر خارجي',
  'imported': 'مستورد',
  'accounting_ledger_entries': 'دفتر القيود',
  // Operational report tokens (speed changes, login states, attempts).
  'temporary_speed': 'سرعة مؤقتة',
  'all_failed': 'فشل الكل',
  'partial': 'جزئي',
  'no_active_session': 'لا توجد جلسة نشطة',
  'router_not_configured': 'الراوتر غير مهيّأ',
  'apply': 'تطبيق',
  'revert': 'إرجاع',
  'panel': 'لوحة التحكم',
  'network': 'الشبكة',
  'unknown': 'غير معروف',
  'provider_active_cap': 'تجاوز حدّ الاشتراكات النشطة للمزوّد',
  'skipped': 'تم التخطّي',
  'never_run': 'لم يُشغَّل بعد',
  'running': 'قيد التشغيل',
  'queued': 'بالانتظار',
  'cancelled': 'أُلغي',
  'wallet': 'محفظة',
  'sent': 'أُرسل',
  'delivered': 'سُلِّم',
  'read': 'مقروء',
  'sms': 'رسالة SMS',
  'whatsapp': 'واتساب',
  'telegram': 'تيليجرام',
  'email': 'بريد إلكتروني',
  'push': 'إشعار',
};

String rawTokenLabel(String value) {
  final key = value.trim().toLowerCase();
  final known = kRawTokenLabels[key];
  if (known != null) return known;
  // «wallet:4» / «distributor #1» (business-ops ledger parties).
  final party = RegExp(r'^(wallet|distributor|subscriber|card|admin)\s*[:#]\s*(\d+)$')
      .firstMatch(key);
  if (party != null) {
    return '${kRawTokenLabels[party.group(1)!]} #${party.group(2)}';
  }
  return value;
}

/// Arabic for a ledger `entry_type` — never «نوع غير معروف» for a type the
/// server writes (debt, settlement, writeoff…); an unseen one → «قيد مالي».
String ledgerTypeLabel(String value) {
  final key = value.trim().toLowerCase();
  if (key.isEmpty) return 'غير محدد';
  if (key == 'void') return 'قيد عكسي';
  if (key == 'adjustment') return 'تعديل مالي';
  if (key == 'settlement') return 'تسوية سلفة';
  if (key == 'debt') return 'دين';
  return kRawTokenLabels[key] ?? 'قيد مالي';
}

/// Arabic for a ledger `source_type`; an unseen one → «مصدر آخر».
String ledgerSourceLabel(String value) {
  final key = value.trim().toLowerCase();
  if (key.isEmpty) return '—';
  if (key == 'void') return 'قيد عكسي';
  return kRawTokenLabels[key] ?? 'مصدر آخر';
}
