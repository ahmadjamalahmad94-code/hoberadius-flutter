import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../domain/router_alerts_model.dart';

class RouterAlertsRepository {
  RouterAlertsRepository(this._api);

  final ApiClient _api;

  Future<RouterAlertsState> load() async {
    final res = await _api.get('/api/v1/router-alerts/settings');
    final data = res['data'];
    return RouterAlertsState.fromJson(
      data is Map<String, dynamic> ? data : const {},
    );
  }

  Future<RouterAlertsState> save({
    RouterAlertSettings? settings,
    List<RouterAlertTarget>? routers,
  }) async {
    final body = <String, dynamic>{};
    if (settings != null) body['settings'] = settings.toJson();
    if (routers != null) {
      body['routers'] = routers.map((router) => router.toJson()).toList();
    }
    final res = await _api.patch('/api/v1/router-alerts/settings', body: body);
    final data = res['data'];
    return RouterAlertsState.fromJson(
      data is Map<String, dynamic> ? data : const {},
    );
  }
}

final routerAlertsRepositoryProvider = Provider<RouterAlertsRepository>((ref) {
  return RouterAlertsRepository(ref.watch(apiClientProvider));
});
