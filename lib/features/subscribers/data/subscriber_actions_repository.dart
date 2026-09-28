import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/api/idempotency.dart';
import '../../../core/api/visible_error_message.dart';
import '../domain/subscriber_actions_model.dart';

/// Shown when the server answers 404/405 on one of the new action endpoints:
/// it runs an older build that does not have them yet.
const kServerNotUpdatedMessage = 'هذا الخادم لم يُحدَّث بعد لهذا الإجراء';

/// A user-facing failure of a subscriber action — [message] is Arabic and
/// ready for a toast / the dialog's error box.
class SubscriberActionError implements Exception {
  const SubscriberActionError(
    this.message, {
    this.notUpdated = false,
    this.forbidden = false,
    this.retryable = false,
  });

  final String message;

  /// Busy/unreachable server (503 «الخادم مشغول», timeouts): the dialog
  /// offers «إعادة المحاولة» and resends with the SAME Idempotency-Key.
  final bool retryable;

  /// The server has no such endpoint (old build).
  final bool notUpdated;
  final bool forbidden;

  @override
  String toString() => message;
}

/// Maps an [ApiException] from the action endpoints to what the operator
/// should read: the server's Arabic message when it sent one; 403 → «لا
/// تملك صلاحية …»; a missing route (old server) → [kServerNotUpdatedMessage].
SubscriberActionError mapActionError(Object error, {String what = ''}) {
  if (error is SubscriberActionError) return error;
  if (error is! ApiException) {
    final text = error.toString().trim();
    return SubscriberActionError(
      text.isEmpty ? 'تعذّر تنفيذ الإجراء. حاول مرة أخرى.' : text,
    );
  }
  final status = error.status;
  if (status == 403 || error.code == 'forbidden') {
    final msg = error.message.trim();
    final generic = msg.isEmpty || msg == 'لا تملك صلاحية تنفيذ هذا الإجراء.';
    return SubscriberActionError(
      generic
          ? (what.isEmpty
              ? 'لا تملك صلاحية تنفيذ هذا الإجراء.'
              : 'لا تملك صلاحية $what.')
          : msg,
      forbidden: true,
    );
  }
  if (status == 405 || (status == 404 && _looksLikeMissingRoute(error))) {
    return const SubscriberActionError(
      kServerNotUpdatedMessage,
      notUpdated: true,
    );
  }
  final msg = error.message.trim();
  return SubscriberActionError(
    msg.isEmpty ? 'تعذّر تنفيذ الإجراء. حاول مرة أخرى.' : msg,
    retryable: isRetryableError(error),
  );
}

/// A 404 from Flask's router (no such endpoint) carries no envelope: the
/// client turns its HTML «Not Found» into the generic «العنصر المطلوب غير
/// موجود.». A 404 from the new endpoints has an Arabic, specific message
/// (e.g. «المشترك غير موجود») and keeps it.
bool _looksLikeMissingRoute(ApiException e) {
  final msg = e.message.trim();
  return e.details == null &&
      (msg.isEmpty ||
          msg == 'العنصر المطلوب غير موجود.' ||
          msg == 'تعذّر تنفيذ الطلب.' ||
          !_hasArabic(msg));
}

bool _hasArabic(String s) => s.runes.any((r) => r >= 0x0600 && r <= 0x06FF);

/// The subscriber action endpoints (`/api/v1/accounts/<u>/…`) — same service
/// functions as the web panel's row menus.
class SubscriberActionsRepository {
  SubscriberActionsRepository(this._api);
  final ApiClient _api;

  String _base(String u) => '/api/v1/accounts/${Uri.encodeComponent(u)}';

  Map<String, dynamic> _data(Map<String, dynamic> res) {
    final d = res['data'];
    if (d is Map<String, dynamic>) return d;
    return res;
  }

  Future<Map<String, dynamic>> _post(
    String username,
    String path,
    Object body, {
    String what = '',
    String? idempotencyKey,
  }) async {
    try {
      return _data(
        await _api.post(
          '${_base(username)}/$path',
          body: body,
          headers: idempotencyHeaders(idempotencyKey),
        ),
      );
    } catch (e) {
      throw mapActionError(e, what: what);
    }
  }

  Future<SubscriberActionsContext> actionsContext(String username) async {
    try {
      final res = await _api.get('${_base(username)}/actions-context');
      return SubscriberActionsContext.fromJson(_data(res));
    } catch (e) {
      throw mapActionError(e);
    }
  }

  // Money actions carry an Idempotency-Key (one per dialog submission,
  // reused on «إعادة المحاولة»): a double tap or a retry after a lost answer
  // never records the money twice on updated servers.

  Future<Map<String, dynamic>> extend(
    String username,
    Map<String, dynamic> payload, {
    String? idempotencyKey,
  }) =>
      _post(
        username,
        'extend',
        payload,
        what: 'إضافة الوقت',
        idempotencyKey: idempotencyKey,
      );

  Future<Map<String, dynamic>> changePlan(
    String username, {
    required int planId,
    required String policy,
    String? idempotencyKey,
  }) =>
      _post(
        username,
        'change-plan',
        {'plan_id': planId, 'policy': policy},
        what: 'تغيير العرض',
        idempotencyKey: idempotencyKey,
      );

  Future<Map<String, dynamic>> quotaTopup(
    String username, {
    required double quotaMb,
    required String target,
    required ChargeMode charge,
    double amount = 0,
    String notes = '',
    String? idempotencyKey,
  }) =>
      _post(
        username,
        'quota/topup',
        {
          'quota_mb': quotaMb,
          'quota_target': target,
          ...chargePayload(charge, amount, notes),
        },
        what: 'إضافة الكوتة',
        idempotencyKey: idempotencyKey,
      );

  Future<Map<String, dynamic>> quotaResetDaily(
    String username, {
    required ChargeMode charge,
    double amount = 0,
    String notes = '',
    String? idempotencyKey,
  }) =>
      _post(
        username,
        'quota/reset-daily',
        chargePayload(charge, amount, notes),
        what: 'استعادة الكوتة',
        idempotencyKey: idempotencyKey,
      );

  Future<Map<String, dynamic>> payment(
    String username,
    Map<String, dynamic> payload, {
    String? idempotencyKey,
  }) =>
      _post(
        username,
        'payment',
        payload,
        what: 'تسجيل الدفعات',
        idempotencyKey: idempotencyKey,
      );

  Future<Map<String, dynamic>> balance(
    String username, {
    required double amount,
    String notes = '',
    Map<int, LoanChoice> choices = const {},
    String? idempotencyKey,
  }) =>
      _post(
        username,
        'balance',
        {
          'amount': amount,
          'notes': notes.trim(),
          'loan_actions': loanActionsPayload(choices),
        },
        what: 'إضافة الرصيد',
        idempotencyKey: idempotencyKey,
      );

  Future<Map<String, dynamic>> loan(
    String username,
    Map<String, dynamic> payload, {
    String? idempotencyKey,
  }) =>
      _post(
        username,
        'loan',
        payload,
        what: 'منح السلف',
        idempotencyKey: idempotencyKey,
      );

  Future<Map<String, dynamic>> message(
    String username, {
    required String channel,
    required String message,
  }) =>
      _post(
        username,
        'message',
        {'channel': channel, 'message': message},
        what: 'إرسال الرسائل',
      );

  Future<Map<String, dynamic>> sendCredentials(String username) =>
      _post(username, 'send-credentials', const {}, what: 'إرسال الرسائل');

  Future<Map<String, dynamic>> rename(String username, String newUsername) =>
      _post(
        username,
        'rename',
        {'new_username': newUsername.trim()},
        what: 'تغيير اسم المستخدم',
      );

  Future<Map<String, dynamic>> disconnect(String username) =>
      _post(username, 'disconnect', const {}, what: 'فصل الاتصال');

  // ── Endpoints the older API already had (used by the legacy menu) ──────

  Future<void> enable(String username) =>
      _post(username, 'enable', const {}, what: 'تغيير حالة المشترك');

  Future<void> disable(String username) =>
      _post(username, 'disable', const {}, what: 'تغيير حالة المشترك');

  Future<Map<String, dynamic>> extendTimeLegacy(String username, int minutes) =>
      _post(
        username,
        'extend_time',
        {'minutes': minutes},
        what: 'إضافة الوقت',
      );

  Future<void> resetPassword(String username, String newPassword) => _post(
        username,
        'reset_password',
        {'new_password': newPassword},
        what: 'إعادة كلمة المرور',
      );

  Future<void> archive(String username) async {
    try {
      await _api.delete(_base(username));
    } catch (e) {
      throw mapActionError(e, what: 'أرشفة المشترك');
    }
  }

  /// Old servers: `/sessions/disconnect` by username.
  Future<void> disconnectLegacy(String username) async {
    try {
      await _api.post(
        '/api/v1/sessions/disconnect',
        body: {'username': username},
      );
    } catch (e) {
      throw mapActionError(e, what: 'فصل الاتصال');
    }
  }
}

final subscriberActionsRepositoryProvider =
    Provider<SubscriberActionsRepository>((ref) {
  return SubscriberActionsRepository(ref.watch(apiClientProvider));
});
