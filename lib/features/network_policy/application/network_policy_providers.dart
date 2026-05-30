import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/network_policy_repository.dart';
import '../domain/network_policy_model.dart';

final selectedNetworkPolicyKindProvider = StateProvider<String>((ref) {
  return networkPolicyKinds.first.slug;
});

final selectedNetworkPolicyProvider = Provider<NetworkPolicyKind>((ref) {
  final slug = ref.watch(selectedNetworkPolicyKindProvider);
  return networkPolicyKindBySlug(slug);
});

final networkPolicyPageProvider =
    FutureProvider.autoDispose<NetworkPolicyPage>((ref) {
  final kind = ref.watch(selectedNetworkPolicyProvider);
  return ref.watch(networkPolicyRepositoryProvider).list(kind);
});

final networkPolicyChildrenProvider = FutureProvider.autoDispose
    .family<NetworkPolicyChildrenPage, NetworkPolicyChildrenRequest>(
  (ref, request) {
    return ref
        .watch(networkPolicyRepositoryProvider)
        .listChildren(request.kind, request.policyId);
  },
);

class NetworkPolicyChildrenRequest {
  const NetworkPolicyChildrenRequest({
    required this.kind,
    required this.policyId,
  });

  final NetworkPolicyKind kind;
  final int policyId;

  @override
  bool operator ==(Object other) {
    return other is NetworkPolicyChildrenRequest &&
        other.kind.slug == kind.slug &&
        other.policyId == policyId;
  }

  @override
  int get hashCode => Object.hash(kind.slug, policyId);
}
