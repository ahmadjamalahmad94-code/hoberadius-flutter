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

  Future<List<SetupWizardRouterServiceCard>> routerServiceCatalogue() async {
    final res =
        await _api.get('/api/v1/setup-wizard/router-services/catalogue');
    final data = res['data'];
    final map = data is Map<String, dynamic> ? data : const <String, dynamic>{};
    final services = map['services'];
    return services is List
        ? services
            .whereType<Map>()
            .map(
              (item) => SetupWizardRouterServiceCard.fromJson(
                item.map((key, value) => MapEntry(key.toString(), value)),
              ),
            )
            .toList()
        : const [];
  }

  Future<SetupWizardRouterServicesStatus> routerServicesStatus(
    int routerId,
  ) async {
    final res = await _api.get(
      '/api/v1/setup-wizard/routers/$routerId/services/status',
    );
    final data = res['data'];
    return SetupWizardRouterServicesStatus.fromJson(
      data is Map<String, dynamic> ? data : const {},
    );
  }

  Future<SetupWizardRun> submitRouterInfo(
    int runId, {
    required String routerName,
    required String routerType,
  }) async {
    final res = await _api.post(
      '/api/v1/setup-wizard/runs/$runId/router-info',
      body: {'router_name': routerName, 'router_type': routerType},
    );
    return _runFromResponse(res);
  }

  Future<SetupWizardScriptResult> generateScript(
    int runId, {
    required String endpoint,
    required String serverPublicKey,
    int wgListenPort = 13231,
    int endpointPort = 51820,
  }) async {
    final res = await _api.post(
      '/api/v1/setup-wizard/runs/$runId/generate-script',
      body: {
        'vps_public_endpoint': endpoint,
        'vps_wg_pubkey': serverPublicKey,
        'wg_listen_port': wgListenPort,
        'vps_endpoint_port': endpointPort,
      },
    );
    final data = res['data'];
    return SetupWizardScriptResult.fromJson(
      data is Map<String, dynamic> ? data : const {},
    );
  }

  Future<SetupWizardRun> submitPublicKey(
    int runId, {
    required String publicKeyOrOutput,
  }) async {
    final res = await _api.post(
      '/api/v1/setup-wizard/runs/$runId/submit-key',
      body: {'pasted_output': publicKeyOrOutput},
    );
    return _runFromResponse(res);
  }

  Future<SetupWizardRun> applyServerPeer(int runId) async {
    final res = await _api.post(
      '/api/v1/setup-wizard/runs/$runId/apply-server-peer',
      body: {},
    );
    return _runFromResponse(res);
  }

  Future<SetupWizardRun> markHandshake(int runId) async {
    final res = await _api.post(
      '/api/v1/setup-wizard/runs/$runId/mark-handshake',
      body: {},
    );
    return _runFromResponse(res);
  }

  Future<SetupWizardRun> registerRouter(
    int runId, {
    required String apiUser,
    required String apiPassword,
  }) async {
    final res = await _api.post(
      '/api/v1/setup-wizard/runs/$runId/register',
      body: {'api_user': apiUser, 'api_password': apiPassword},
    );
    return _runFromResponse(res);
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

  SetupWizardRun _runFromResponse(Map<String, dynamic> res) {
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
