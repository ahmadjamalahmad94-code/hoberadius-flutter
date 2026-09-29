import 'package:hoberadius_app/core/api/api_exception.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoberadius_app/core/api/visible_error_message.dart';

import '../data/subscribers_repository.dart';
import '../domain/subscriber_model.dart';

/// Loading + error state for the subscriber form action handlers.
class SubscriberFormActionState {
  const SubscriberFormActionState({
    this.loading = false,
    this.error,
    this.errorField,
  });
  final bool loading;
  final String? error;

  /// The form field [error] is about (`email`, `mobile`, `expire_at`…), so
  /// the form can show it under that input; null = a general error.
  final String? errorField;

  SubscriberFormActionState copyWith({
    bool? loading,
    Object? error = _none,
    Object? errorField = _none,
  }) =>
      SubscriberFormActionState(
        loading: loading ?? this.loading,
        error: identical(error, _none) ? this.error : error as String?,
        errorField: identical(errorField, _none)
            ? (identical(error, _none) ? this.errorField : null)
            : errorField as String?,
      );

  static const _none = Object();
}

/// Result for [SubscriberFormActionController.load] — `subscriber` is
/// non-null on success, `error` on failure.
class LoadSubscriberResult {
  const LoadSubscriberResult({this.subscriber, this.error});
  final Subscriber? subscriber;
  final String? error;
}

/// Result for [SubscriberFormActionController.extendTime] — `newExpire`
/// is the server-returned expiry on success.
class ExtendTimeResult {
  const ExtendTimeResult({this.newExpire, this.error});
  final DateTime? newExpire;
  final String? error;
}

class SubscriberFormActionController
    extends Notifier<SubscriberFormActionState> {
  bool _alive = true;

  @override
  SubscriberFormActionState build() {
    _alive = true;
    ref.onDispose(() => _alive = false);
    return const SubscriberFormActionState();
  }

  /// Guards `state =` against the provider being disposed mid-await (e.g. the
  /// user navigates away while a load/submit is in flight) — setting state on a
  /// disposed Notifier throws.
  void _set(SubscriberFormActionState next) {
    if (_alive) state = next;
  }

  /// A fresh form: the provider is app-wide, so an error of an earlier
  /// form («اسم المستخدم مستخدم مسبقًا») must not greet the next one.
  void clearError() {
    if (state.error != null || state.loading) {
      _set(const SubscriberFormActionState());
    }
  }

  Future<LoadSubscriberResult> load(String username) async {
    _set(state.copyWith(loading: true, error: null));
    try {
      final s = await ref.read(subscribersRepositoryProvider).get(username);
      return LoadSubscriberResult(subscriber: s);
    } catch (e) {
      final message = visibleErrorMessage(e);
      _set(state.copyWith(error: message));
      return LoadSubscriberResult(error: message);
    } finally {
      _set(state.copyWith(loading: false));
    }
  }

  Future<String?> submit(Subscriber subscriber, {required bool isEdit}) async {
    _set(state.copyWith(loading: true, error: null));
    try {
      final repo = ref.read(subscribersRepositoryProvider);
      if (isEdit) {
        await repo.update(subscriber);
      } else {
        await repo.create(subscriber);
      }
      return null;
    } catch (e) {
      final message = visibleErrorMessage(e);
      _set(state.copyWith(error: message, errorField: subscriberErrorField(e)));
      return message;
    } finally {
      _set(state.copyWith(loading: false));
    }
  }

  /// Edit-form save: PATCHes only [changes] (already diffed against the row
  /// that was loaded). An empty diff is a successful no-op.
  Future<String?> submitChanges(
    String username,
    Map<String, dynamic> changes,
  ) async {
    _set(state.copyWith(loading: true, error: null));
    try {
      final Subscriber? saved;
      try {
        saved = await ref
            .read(subscribersRepositoryProvider)
            .updateChanged(username, changes);
      } catch (e) {
        _set(
          state.copyWith(
            error: visibleErrorMessage(e),
            errorField: subscriberErrorField(e),
          ),
        );
        return visibleErrorMessage(e);
      }
      // «بدون انتهاء»: an explicit null clears the expiry on updated
      // servers; an older server answers 200 and KEEPS it — say so instead
      // of pretending it worked (r10 N3).
      if (changes.containsKey('expire_at') &&
          changes['expire_at'] == null &&
          saved?.expireAt != null) {
        const message = 'لم يُزِل الخادم تاريخ الانتهاء — هذا الخادم لا يدعم '
            '«بدون انتهاء» بعد. حدّث الخادم أو اختر تاريخًا.';
        _set(state.copyWith(error: message));
        return message;
      }
      return null;
    } catch (e) {
      final message = visibleErrorMessage(e);
      _set(state.copyWith(error: message));
      return message;
    } finally {
      _set(state.copyWith(loading: false));
    }
  }

  Future<String?> toggle(String username, {required bool enable}) async {
    _set(state.copyWith(loading: true, error: null));
    try {
      final repo = ref.read(subscribersRepositoryProvider);
      if (enable) {
        await repo.enable(username);
      } else {
        await repo.disable(username);
      }
      return null;
    } catch (e) {
      final message = visibleErrorMessage(e);
      _set(state.copyWith(error: message));
      return message;
    } finally {
      _set(state.copyWith(loading: false));
    }
  }

  Future<ExtendTimeResult> extendTime(String username, int minutes) async {
    _set(state.copyWith(loading: true, error: null));
    try {
      final dt = await ref
          .read(subscribersRepositoryProvider)
          .extendTime(username, minutes);
      return ExtendTimeResult(newExpire: dt);
    } catch (e) {
      final message = visibleErrorMessage(e);
      _set(state.copyWith(error: message));
      return ExtendTimeResult(error: message);
    } finally {
      _set(state.copyWith(loading: false));
    }
  }

  Future<String?> resetPassword(String username, String pw) async {
    _set(state.copyWith(loading: true, error: null));
    try {
      await ref.read(subscribersRepositoryProvider).resetPassword(username, pw);
      return null;
    } catch (e) {
      final message = visibleErrorMessage(e);
      _set(state.copyWith(error: message));
      return message;
    } finally {
      _set(state.copyWith(loading: false));
    }
  }

  Future<String?> delete(String username) async {
    _set(state.copyWith(loading: true, error: null));
    try {
      await ref.read(subscribersRepositoryProvider).delete(username);
      return null;
    } catch (e) {
      final message = visibleErrorMessage(e);
      _set(state.copyWith(error: message));
      return message;
    } finally {
      _set(state.copyWith(loading: false));
    }
  }
}

/// Which form field a server error concerns: `details.field` when the
/// server names it, else the Arabic wording of the fix2 validation
/// messages (e-mail, mobile, IP, expiry, username, status, balance).
String? subscriberErrorField(Object? e) {
  if (e is! ApiException) return null;
  final d = e.details;
  if (d is Map && d['field'] is String) {
    final f = d['field'] as String;
    return f == 'expiry' ? 'expire_at' : f;
  }
  final m = e.message;
  if (m.contains('البريد')) return 'email';
  if (m.contains('الجوال')) return 'mobile';
  if (m.contains('تاريخ الانتهاء') || m.contains('أقصى تمديد') ||
      m.contains('المدة الناتجة')) {
    return 'expire_at';
  }
  if (m.contains('IP')) return 'static_ip';
  if (m.contains('اسم الدخول') || m.contains('اسم المستخدم')) return 'username';
  if (m.contains('الرصيد')) return 'balance';
  return null;
}

final subscriberFormActionProvider =
    NotifierProvider<SubscriberFormActionController, SubscriberFormActionState>(
  SubscriberFormActionController.new,
);
