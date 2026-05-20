import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../domain/tools_models.dart';

class ToolsRepository {
  const ToolsRepository(this._api);

  final ApiClient _api;

  Future<SetSpeedsResult> setSpeeds(Map<String, dynamic> body) async {
    final res = await _api.post('/api/v1/tools/set-speeds', body: body);
    return SetSpeedsResult.fromJson(_data(res));
  }

  Future<Map<String, dynamic>> generalAdjustments(
    Map<String, dynamic> body,
  ) async {
    final res = await _api.post(
      '/api/v1/tools/general-adjustments',
      body: body,
    );
    return _data(res);
  }

  Future<AuthTestDecision> testAuth(Map<String, dynamic> body) async {
    final res = await _api.post('/api/v1/tools/test-auth', body: body);
    final data = _data(res);
    final decision = data['decision'];
    return AuthTestDecision.fromJson(
      decision is Map<String, dynamic> ? decision : const {},
    );
  }

  Future<RadiusLogSnapshot> radiusLog({int limit = 80}) async {
    final res = await _api.get(
      '/api/v1/tools/radius-log',
      query: {'limit': limit},
    );
    return RadiusLogSnapshot.fromJson(_data(res));
  }

  Future<MaintenancePreview> maintenancePreview({
    required String action,
    required int days,
  }) async {
    final res = await _api.post(
      '/api/v1/tools/maintenance/preview',
      body: {'action': action, 'days': days},
    );
    return MaintenancePreview.fromJson(_data(res));
  }

  Future<Map<String, dynamic>> maintenanceRun(MaintenancePreview preview) async {
    final res = await _api.post(
      '/api/v1/tools/maintenance/run',
      body: {
        'action': preview.action,
        'days': preview.days,
        'confirm_phrase': preview.confirmPhrase,
        'confirm_token': preview.confirmToken,
      },
    );
    return _data(res);
  }

  Map<String, dynamic> _data(Map<String, dynamic> response) {
    final data = response['data'];
    return data is Map<String, dynamic> ? data : const {};
  }
}

final toolsRepositoryProvider = Provider<ToolsRepository>((ref) {
  return ToolsRepository(ref.watch(apiClientProvider));
});
