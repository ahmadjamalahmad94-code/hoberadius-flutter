import 'api_exception.dart';

/// The ONE error → Arabic text helper for every screen and dialog: the
/// server's Arabic message when it sent one (422 validation, 409 conflict,
/// 503 «الخادم مشغول»…), else a safe Arabic fallback — never an empty box or
/// raw English/HTML.
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

/// `true` when the same request may simply be sent again: the server was busy
/// or unreachable (503 «الخادم مشغول» with Retry-After, 502/504, timeouts,
/// connection errors) or a duplicate of this submission is still running
/// (409 `idempotency_in_progress`). Validation/permission errors are final.
bool isRetryableError(Object? error) {
  if (error is! ApiException) return false;
  const retryCodes = {
    'server_busy',
    'server_unavailable',
    'idempotency_in_progress',
    'connectionTimeout',
    'receiveTimeout',
    'sendTimeout',
    'connectionError',
  };
  if (retryCodes.contains(error.code)) return true;
  final status = error.status;
  if (status == 502 || status == 503 || status == 504) return true;
  final details = error.details;
  return details is Map && details['retryable'] == true;
}

/// [visibleErrorMessage] plus a «أعد المحاولة» hint for retryable failures.
String visibleErrorWithRetryHint(Object? error, {String? fallback}) {
  final msg = fallback == null
      ? visibleErrorMessage(error)
      : visibleErrorMessage(error, fallback: fallback);
  if (!isRetryableError(error) || msg.contains('أعد المحاولة')) return msg;
  return '$msg — اضغط «إعادة المحاولة».';
}
