/// Small shared form rules (Arabic messages).
library;

final RegExp _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');

/// Empty is fine (optional field); otherwise it must look like an e-mail.
String? validateOptionalEmail(String? value) {
  final v = (value ?? '').trim();
  if (v.isEmpty) return null;
  return _email.hasMatch(v) ? null : 'البريد الإلكتروني غير صحيح.';
}

/// Optional whole number (ids in event dialogs…): empty or digits only.
String? validateOptionalId(String? value) {
  final v = (value ?? '').trim();
  if (v.isEmpty) return null;
  final n = int.tryParse(v);
  return n == null || n <= 0 ? 'اكتب رقمًا صحيحًا.' : null;
}
