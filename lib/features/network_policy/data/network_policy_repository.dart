import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../domain/network_policy_model.dart';

class NetworkPolicyRepository {
  NetworkPolicyRepository(this._api);

  final ApiClient _api;

  String _base(NetworkPolicyKind kind) => '/api/v1/network-policy/${kind.slug}';

  Future<NetworkPolicyPage> list(NetworkPolicyKind kind) async {
    final res = await _api.get('${_base(kind)}/policies');
    return NetworkPolicyPage.fromJson(res);
  }

  Future<NetworkPolicy> create(
    NetworkPolicyKind kind,
    Map<String, dynamic> body,
  ) async {
    final res = await _api.post('${_base(kind)}/policies', body: body);
    return NetworkPolicy.fromJson(_payload(res));
  }

  Future<NetworkPolicy> update(
    NetworkPolicyKind kind,
    int policyId,
    Map<String, dynamic> body,
  ) async {
    final res = await _api.patch(
      '${_base(kind)}/policies/$policyId',
      body: body,
    );
    return NetworkPolicy.fromJson(_payload(res));
  }

  Future<void> delete(NetworkPolicyKind kind, int policyId) async {
    await _api.delete('${_base(kind)}/policies/$policyId');
  }

  Future<NetworkPolicyPreview> preview(
    NetworkPolicyKind kind,
    int policyId,
  ) async {
    final res = await _api.post('${_base(kind)}/policies/$policyId/preview');
    return NetworkPolicyPreview.fromJson(res);
  }

  Future<NetworkPolicyScriptDownload> script(
    NetworkPolicyKind kind,
    int policyId,
  ) async {
    final res = await _api.get('${_base(kind)}/policies/$policyId/preview.rsc');
    return NetworkPolicyScriptDownload.fromJson(res);
  }

  Future<NetworkPolicyActionResult> apply(
    NetworkPolicyKind kind,
    int policyId, {
    String executionMode = 'full',
    List<String> confirmations = const [],
    bool canaryOptIn = false,
  }) async {
    final res = await _api.post(
      '${_base(kind)}/policies/$policyId/apply',
      body: {
        'execution_mode': executionMode,
        'confirmations': confirmations,
        'canary_opt_in': canaryOptIn,
      },
    );
    return NetworkPolicyActionResult.fromJson(res);
  }

  Future<NetworkPolicyChangeSetPage> changes(
    NetworkPolicyKind kind,
    int policyId,
  ) async {
    final res = await _api.get('${_base(kind)}/policies/$policyId/changes');
    return NetworkPolicyChangeSetPage.fromJson(res);
  }

  Future<NetworkPolicyActionResult> rollback(
    NetworkPolicyKind kind,
    int policyId,
    int changeSetId,
  ) async {
    final res = await _api.post(
      '${_base(kind)}/policies/$policyId/changes/$changeSetId/rollback',
    );
    return NetworkPolicyActionResult.fromJson(res);
  }

  Future<NetworkPolicy> duplicate(
    NetworkPolicyKind kind,
    int policyId,
  ) async {
    final res = await _api.post(
      '${_base(kind)}/policies/$policyId/duplicate',
    );
    return NetworkPolicy.fromJson(_payload(res));
  }

  Future<NetworkPolicyChildrenPage> listChildren(
    NetworkPolicyKind kind,
    int policyId,
  ) async {
    if (!kind.hasChildren) {
      return const NetworkPolicyChildrenPage(
        items: [],
        count: 0,
        counts: {},
      );
    }
    final res = await _api.get(
      '${_base(kind)}/policies/$policyId/${kind.childPath}',
    );
    return NetworkPolicyChildrenPage.fromJson(res);
  }

  Future<NetworkPolicyChild> addChild(
    NetworkPolicyKind kind,
    int policyId,
    Map<String, dynamic> body,
  ) async {
    final res = await _api.post(
      '${_base(kind)}/policies/$policyId/${kind.childPath}',
      body: body,
    );
    return NetworkPolicyChild.fromJson(_payload(res));
  }

  Future<void> deleteChild(
    NetworkPolicyKind kind,
    int policyId,
    int childId,
  ) async {
    await _api.delete(
      '${_base(kind)}/policies/$policyId/${kind.childPath}/$childId',
    );
  }
}

Map<String, dynamic> _payload(Map<String, dynamic> res) {
  final data = res['data'];
  if (data is Map<String, dynamic>) return data;
  if (data is Map) {
    return data.map((key, value) => MapEntry(key.toString(), value));
  }
  return const {};
}

final networkPolicyRepositoryProvider =
    Provider<NetworkPolicyRepository>((ref) {
  return NetworkPolicyRepository(ref.watch(apiClientProvider));
});
