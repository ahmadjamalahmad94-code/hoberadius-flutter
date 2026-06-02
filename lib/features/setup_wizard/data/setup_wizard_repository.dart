import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../domain/setup_wizard_model.dart';

class SetupWizardRepository {
  SetupWizardRepository(this._api);

  final ApiClient _api;

  Future<SetupWizardOverview> overview() async {
    final res = await _api.get('/api/v1/setup-wizard/overview');
    final data = res['data'];
    return SetupWizardOverview.fromJson(
      data is Map<String, dynamic> ? data : const {},
    );
  }

  Future<SetupWizardRun> createRun() async {
    final res = await _api.post('/api/v1/setup-wizard/runs', body: {});
    final data = res['data'];
    final map = data is Map<String, dynamic> ? data : const <String, dynamic>{};
    final run = map['run'];
    return SetupWizardRun.fromJson(
      run is Map<String, dynamic> ? run : const {},
    );
  }

  Future<SetupWizardRun> runState(int runId) async {
    final res = await _api.get('/api/v1/setup-wizard/runs/$runId/state');
    final data = res['data'];
    final map = data is Map<String, dynamic> ? data : const <String, dynamic>{};
    final run = map['run'];
    return SetupWizardRun.fromJson(
      run is Map<String, dynamic> ? run : const {},
    );
  }
}

final setupWizardRepositoryProvider = Provider<SetupWizardRepository>((ref) {
  return SetupWizardRepository(ref.watch(apiClientProvider));
});
