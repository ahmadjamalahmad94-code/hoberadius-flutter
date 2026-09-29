import '../l10n/arabic_labels.dart';
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

/// Rewrites the Python / OS error fragments the server passes through
/// («تعذّر الاتصال بـ 10.10.0.1:8728 — [Errno 111] Connection refused»,
/// R11 L-1) into Arabic, inside Arabic or English messages alike. Text
/// without such a fragment is returned unchanged.
String humanizeTechnicalError(String message) {
  var out = message;
  if (out.isEmpty) return out;
  // Exception class names in front of the OS text
  // («ConnectionRefusedError: …», «socket.timeout: …»).
  out = out.replaceAll(
    RegExp(
      r'\b(?:(?:[A-Za-z_]+\.)*[A-Z][A-Za-z]*(?:Error|Exception)|socket\.timeout)\s*:\s*',
    ),
    '',
  );
  // «[Errno 111] Connection refused» and friends: the code decides, the
  // English words after it are dropped.
  out = out.replaceAllMapped(
    RegExp(r"\[(?:Errno|WinError)\s*(-?\d+)\]\s*(?:[A-Za-z][A-Za-z '\-]*)?"),
    (m) => _errnoLabel(int.parse(m.group(1)!), m.group(0)!),
  );
  // Bare English fragments without an errno.
  const phrases = <String, String>{
    'connection refused': _kRefused,
    'connection timed out': _kTimedOut,
    'timed out': _kTimedOut,
    'no route to host': _kNoRoute,
    'connection reset by peer': _kReset,
    'name or service not known': _kUnknownHost,
    'temporary failure in name resolution': _kUnknownHost,
    'network is unreachable': _kNoRoute,
  };
  phrases.forEach((english, arabic) {
    out = out.replaceAll(
      RegExp(RegExp.escape(english), caseSensitive: false),
      arabic,
    );
  });
  return out.trim();
}

const _kRefused = 'رفض الراوتر الاتصال (المنفذ مغلق أو خدمة API معطّلة)';
const _kTimedOut = 'انتهت مهلة الاتصال';
const _kNoRoute = 'لا يوجد مسار إلى الراوتر';
const _kReset = 'قطع الطرف الآخر الاتصال';
const _kUnknownHost = 'اسم المضيف غير معروف';

String _errnoLabel(int code, String original) {
  final lower = original.toLowerCase();
  if (code == 111 || code == 10061 || lower.contains('refused')) {
    return _kRefused;
  }
  if (code == 110 || code == 10060 || lower.contains('timed out')) {
    return _kTimedOut;
  }
  if (code == 113 || code == 101 || lower.contains('no route')) {
    return _kNoRoute;
  }
  if (code == 104 || code == 10054 || lower.contains('reset by peer')) {
    return _kReset;
  }
  if (code == -2 ||
      code == -3 ||
      code == 11001 ||
      lower.contains('not known')) {
    return _kUnknownHost;
  }
  return 'خطأ اتصال (رمز $code)';
}

/// A free-text status / message the server stores for the operator (backup
/// `last_message`, delivery `error`, job notes…) as Arabic: an Arabic text
/// is kept (its OS fragments humanized), a known raw token is translated,
/// and anything else in English becomes [fallback] — never raw English.
String serverTextOrFallback(String? value, {required String fallback}) {
  final text = humanizeTechnicalError((value ?? '').trim());
  if (text.isEmpty) return fallback;
  if (_containsArabic(text)) return text;
  final token = rawTokenLabel(text);
  if (token != text) return token;
  final known = _knownEnglishMessages[text.toLowerCase().replaceAll(
        RegExp(r'[.!]+$'),
        '',
      )];
  return known ?? fallback;
}

const _knownEnglishMessages = <String, String>{
  'no local backup has been run yet': 'لم يتم تشغيل نسخة محلية بعد',
  'backup completed': 'اكتملت النسخة الاحتياطية',
  'backup failed': 'فشلت النسخة الاحتياطية',
};

String _safeMessage(String value, String fallback) {
  var message = humanizeTechnicalError(value.trim());
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
