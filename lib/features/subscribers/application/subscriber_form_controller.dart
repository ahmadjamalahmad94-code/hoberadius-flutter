import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoberadius_app/core/api/visible_error_message.dart';

import '../data/subscribers_repository.dart';
import '../domain/subscriber_model.dart';

/// Loading + error state for the subscriber form action handlers.
class SubscriberFormActionState {
  const SubscriberFormActionState({this.loading = false, this.error});
  final bool loading;
  final String? error;

  SubscriberFormActionState copyWith({bool? loading, Object? error = _none}) =>
      SubscriberFormActionState(
        loading: loading ?? this.loading,
        error: identical(error, _none) ? this.error : error as String?,
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

final subscriberFormActionProvider =
    NotifierProvider<SubscriberFormActionController, SubscriberFormActionState>(
  SubscriberFormActionController.new,
);
