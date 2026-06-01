import 'api_exception.dart';

String visibleErrorMessage(
  Object? error, {
  String fallback = 'تعذر تنفيذ الطلب. حاول مرة أخرى.',
}) {
  if (error is ApiException) {
    return _safeMessage(error.message, fallback);
  }
  return _safeMessage(error?.toString() ?? '', fallback);
}

String _safeMessage(String value, String fallback) {
  var message = value.trim();
  if (message.isEmpty) return fallback;

  for (final prefix in const [
    'Exception:',
    'StateError:',
    'FormatException:',
    'DioException:',
    'ApiException:',
  ]) {
    if (message.startsWith(prefix)) {
      message = message.substring(prefix.length).trim();
    }
  }

  if (_containsArabic(message)) return message;

  final lower = message.toLowerCase();
  if (lower.contains('csrf')) {
    return 'انتهت صلاحية نموذج الحماية. حدّث الصفحة ثم حاول مرة أخرى.';
  }
  if (lower.contains('timeout')) {
    return 'انتهت مهلة الطلب. تحقق من الاتصال ثم حاول مرة أخرى.';
  }
  if (lower.contains('unauthorized') || lower.contains('invalid token')) {
    return 'انتهت الجلسة أو صلاحية الدخول غير صحيحة. سجّل الدخول مرة أخرى.';
  }
  if (lower.contains('forbidden') || lower.contains('permission')) {
    return 'لا تملك صلاحية تنفيذ هذا الإجراء.';
  }
  if (lower.contains('not found')) {
    return 'العنصر المطلوب غير موجود.';
  }
  if (lower.contains('server') || lower.contains('internal')) {
    return 'حدث خطأ داخلي في الخادم.';
  }
  if (lower.contains('connection') || lower.contains('network')) {
    return 'تعذر الاتصال بالخادم. تحقق من العنوان والمنفذ ثم حاول مرة أخرى.';
  }
  return fallback;
}

bool _containsArabic(String value) {
  return value.runes.any(
    (r) =>
        (r >= 0x0600 && r <= 0x06FF) ||
        (r >= 0x0750 && r <= 0x077F) ||
        (r >= 0x08A0 && r <= 0x08FF) ||
        (r >= 0xFB50 && r <= 0xFDFF) ||
        (r >= 0xFE70 && r <= 0xFEFF),
  );
}
