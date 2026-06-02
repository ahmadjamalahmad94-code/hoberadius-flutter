import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoberadius_app/core/api/visible_error_message.dart';

import '../data/cards_repository.dart';
import '../domain/card_model.dart';

class CardCheckerState {
  const CardCheckerState({
    this.loading = false,
    this.actionLoading = false,
    this.error,
    this.result,
  });

  final bool loading;
  final bool actionLoading;
  final String? error;
  final CardCheckResult? result;

  CardCheckerState copyWith({
    bool? loading,
    bool? actionLoading,
    Object? error = _none,
    Object? result = _none,
  }) =>
      CardCheckerState(
        loading: loading ?? this.loading,
        actionLoading: actionLoading ?? this.actionLoading,
        error: identical(error, _none) ? this.error : error as String?,
        result: identical(result, _none)
            ? this.result
            : result as CardCheckResult?,
      );

  static const _none = Object();
}

/// Result returned by action runners — non-null `success` triggers
/// the screen-level snackbar, `error` adds a failure snackbar on top
/// of being persisted in the state's error field.
class CardCheckerActionOutcome {
  const CardCheckerActionOutcome({this.success, this.error});
  final String? success;
  final String? error;
}

class CardCheckerController extends Notifier<CardCheckerState> {
  @override
  CardCheckerState build() => const CardCheckerState();

  /// Returns the validation/runtime error (or null on success).
  Future<String?> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      const msg = 'اكتب رقم البطاقة أو اسم الدخول أولًا.';
      state = state.copyWith(error: msg);
      return msg;
    }
    state = state.copyWith(loading: true, error: null);
    try {
      final card =
          await ref.read(cardsRepositoryProvider).checkCard(trimmed);
      state = state.copyWith(result: card);
      return null;
    } catch (e) {
      final message = visibleErrorMessage(e);
      state = state.copyWith(error: message);
      return message;
    } finally {
      state = state.copyWith(loading: false);
    }
  }

  Future<CardCheckerActionOutcome> runAction(
    Future<CardCheckResult> Function(CardsRepository repo) call, {
    required String success,
  }) async {
    state = state.copyWith(actionLoading: true, error: null);
    try {
      final updated = await call(ref.read(cardsRepositoryProvider));
      state = state.copyWith(result: updated);
      return CardCheckerActionOutcome(success: success);
    } catch (e) {
      final message = visibleErrorMessage(e);
      state = state.copyWith(error: message);
      return CardCheckerActionOutcome(error: message);
    } finally {
      state = state.copyWith(actionLoading: false);
    }
  }
}

final cardCheckerControllerProvider =
    NotifierProvider<CardCheckerController, CardCheckerState>(
  CardCheckerController.new,
);
