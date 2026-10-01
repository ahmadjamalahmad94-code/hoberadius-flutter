import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../domain/plan_model.dart';
import '../domain/plan_option.dart';

class PlansRepository {
  PlansRepository(this._api);
  final ApiClient _api;

  Future<List<Plan>> list() async {
    final res = await _api.get('/api/v1/profiles');
    final items = (res['data']?['items'] ?? res['items'] ?? const []) as List;
    return items.whereType<Map<String, dynamic>>().map(Plan.fromJson).toList();
  }

  /// fix3: `GET /api/v1/plans/options` — a lightweight, active-only plan
  /// list readable by `plans.view` OR `users.create` OR `cards.generate`.
  Future<List<PlanOption>> listOptions() async {
    final res = await _api.get('/api/v1/plans/options');
    final items = (res['data']?['items'] ?? res['items'] ?? const []) as List;
    return items
        .whereType<Map<String, dynamic>>()
        .map(PlanOption.fromJson)
        .toList();
  }

  /// The picker's source of truth for a create form (new-subscriber /
  /// card-batch): tries the lite `plans/options` endpoint first, and falls
  /// back to the full `/api/v1/profiles` list (mapped down to
  /// [PlanOption]) on an older server that does not have the new route yet.
  Future<List<PlanOption>> listForPicker() async {
    try {
      return await listOptions();
    } on ApiException catch (e) {
      // Only an old server missing the route falls back; a real 403/500 on
      // the lite endpoint should surface as-is (falling back would just
      // repeat the same denial against `/profiles`, minus the specific
      // server message).
      if (!_looksLikeMissingRoute(e)) rethrow;
      final full = await list();
      return full
          .where((p) => p.id != null && p.enabled)
          .map(
            (p) => PlanOption(
              id: p.id!,
              name: p.name,
              price: p.priceCard > 0 ? p.priceCard : p.price,
              currency: p.currency,
              durationMinutes: p.durationMinutes,
              durationValue: p.durationValue,
              durationUnit: p.durationUnit,
              validityDays: p.validityDays,
              periodMinutes: p.serverPeriodMinutes ?? p.durationMinutes,
              planType: p.planType,
            ),
          )
          .toList();
    }
  }

  /// `/api/v1/plans/options` is a collection route with no path parameter,
  /// so it has no record that could be "not found": the only thing a 404
  /// from it can mean is that the server does not have the fix3 route yet.
  /// A denial is 403 and a failure is 5xx — both still surface as-is.
  ///
  /// Do NOT try to recognise an old server by the body: HobeRadius installs
  /// answer an unknown `/api/v1/...` path with the very same Arabic error
  /// envelope they use for a missing record (`not_found` + `details: {}`),
  /// and [ApiClient] localises a bodyless 404 to that same Arabic sentence —
  /// so any body/message test here is never true in the field.
  static bool _looksLikeMissingRoute(ApiException e) => e.status == 404;

  Future<Plan> get(int id) async {
    final res = await _api.get('/api/v1/profiles/$id');
    final d = res['data'];
    return Plan.fromJson(d is Map<String, dynamic> ? d : res);
  }

  Future<Plan> create(Plan p) async {
    final res = await _api.post('/api/v1/profiles', body: p.toBody());
    final d = res['data'];
    return Plan.fromJson(d is Map<String, dynamic> ? d : res);
  }

  Future<Plan> update(int id, Plan p) async {
    final res = await _api.patch('/api/v1/profiles/$id', body: p.toBody());
    final d = res['data'];
    return Plan.fromJson(d is Map<String, dynamic> ? d : res);
  }

  Future<void> delete(int id) => _api.delete('/api/v1/profiles/$id');
}

final plansRepositoryProvider = Provider<PlansRepository>((ref) {
  return PlansRepository(ref.watch(apiClientProvider));
});
