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

  Future<List<SetupWizardPhasePlanner>> phasePlanners() async {
    final res = await _api.get('/api/v1/setup-wizard/phase-planners');
    final data = res['data'];
    final map = data is Map<String, dynamic> ? data : const <String, dynamic>{};
    final phases = map['phases'];
    return phases is List
        ? phases
            .whereType<Map>()
            .map(
              (item) => SetupWizardPhasePlanner.fromJson(
                item.map((key, value) => MapEntry(key.toString(), value)),
              ),
            )
            .toList()
        : const [];
  }

  Future<SetupWizardPhasePlanResponse> phasePlan(
    int runId,
    String phase, {
    required Map<String, dynamic> inputs,
  }) async {
    final res = await _api.post(
      '/api/v1/setup-wizard/runs/$runId/phase-plan/$phase',
      body: {'inputs': inputs},
    );
    final data = res['data'];
    return SetupWizardPhasePlanResponse.fromJson(
      data is Map<String, dynamic> ? data : const {},
    );
  }

  Future<List<SetupWizardDiagnostic>> diagnosticsCatalogue() async {
    final res = await _api.get('/api/v1/setup-wizard/diagnostics-catalogue');
    final data = res['data'];
    final map = data is Map<String, dynamic> ? data : const <String, dynamic>{};
    final catalogue = map['catalogue'];
    return catalogue is List
        ? catalogue
            .whereType<Map>()
            .map(
              (item) => SetupWizardDiagnostic.fromJson(
                item.map((key, value) => MapEntry(key.toString(), value)),
              ),
            )
            .toList()
        : const [];
  }
}

final setupWizardRepositoryProvider = Provider<SetupWizardRepository>((ref) {
  return SetupWizardRepository(ref.watch(apiClientProvider));
});
