import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoberadius_app/core/api/visible_error_message.dart';

import '../data/plans_repository.dart';
import '../domain/plan_model.dart';
import '../presentation/plans_list_screen.dart' show plansListProvider;

class PlanFormActionState {
  const PlanFormActionState({this.loading = false, this.error});
  final bool loading;
  final String? error;

  PlanFormActionState copyWith({bool? loading, Object? error = _none}) =>
      PlanFormActionState(
        loading: loading ?? this.loading,
        error: identical(error, _none) ? this.error : error as String?,
      );

  static const _none = Object();
}

class LoadPlanResult {
  const LoadPlanResult({this.plan, this.error});
  final Plan? plan;
  final String? error;
}

class PlanFormActionController extends Notifier<PlanFormActionState> {
  @override
  PlanFormActionState build() => const PlanFormActionState();

  Future<LoadPlanResult> load(int id) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final plan = await ref.read(plansRepositoryProvider).get(id);
      return LoadPlanResult(plan: plan);
    } catch (e) {
      final message = visibleErrorMessage(e);
      state = state.copyWith(error: message);
      return LoadPlanResult(error: message);
    } finally {
      state = state.copyWith(loading: false);
    }
  }

  Future<String?> submit(Plan plan, {required int? id}) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final repo = ref.read(plansRepositoryProvider);
      if (id != null) {
        await repo.update(id, plan);
      } else {
        await repo.create(plan);
      }
      ref.invalidate(plansListProvider);
      return null;
    } catch (e) {
      final message = visibleErrorMessage(e);
      state = state.copyWith(error: message);
      return message;
    } finally {
      state = state.copyWith(loading: false);
    }
  }

  Future<String?> delete(int id) async {
    state = state.copyWith(loading: true, error: null);
    try {
      await ref.read(plansRepositoryProvider).delete(id);
      ref.invalidate(plansListProvider);
      return null;
    } catch (e) {
      final message = visibleErrorMessage(e);
      state = state.copyWith(error: message);
      return message;
    } finally {
      state = state.copyWith(loading: false);
    }
  }
}

final planFormActionProvider =
    NotifierProvider<PlanFormActionController, PlanFormActionState>(
  PlanFormActionController.new,
);
