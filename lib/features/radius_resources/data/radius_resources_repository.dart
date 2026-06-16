import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../domain/radius_resources_model.dart';

class RadiusResourcesRepository {
  const RadiusResourcesRepository(this._api);

  final ApiClient _api;

  Future<RadiusResourcesSnapshot> snapshot() async {
    final results = await Future.wait([
      listPools(),
      listShareGroups(),
      listBandwidthProfiles(),
    ]);
    return RadiusResourcesSnapshot(
      pools: results[0] as List<IpPoolResource>,
      shareGroups: results[1] as List<ShareGroupResource>,
      bandwidthProfiles: results[2] as List<BandwidthProfileResource>,
    );
  }

  Future<List<BandwidthProfileResource>> listBandwidthProfiles() async {
    final res = await _api.get('/api/v1/bandwidth-profiles');
    final data = unwrapData(res);
    final items = data['items'];
    if (items is! List) return const [];
    return items
        .whereType<Map<String, dynamic>>()
        .map(BandwidthProfileResource.fromJson)
        .toList();
  }

  Future<BandwidthProfileResource> createBandwidthProfile(
    BandwidthProfileResource profile,
  ) async {
    final res = await _api.post(
      '/api/v1/bandwidth-profiles',
      body: profile.toBody(),
    );
    return BandwidthProfileResource.fromJson(unwrapData(res));
  }

  Future<BandwidthProfileResource> updateBandwidthProfile(
    BandwidthProfileResource profile,
  ) async {
    final res = await _api.patch(
      '/api/v1/bandwidth-profiles/${profile.id}',
      body: profile.toBody(),
    );
    return BandwidthProfileResource.fromJson(unwrapData(res));
  }

  Future<void> deleteBandwidthProfile(int profileId) async {
    await _api.delete('/api/v1/bandwidth-profiles/$profileId');
  }

  Future<List<IpPoolResource>> listPools() async {
    final res = await _api.get('/api/v1/pools');
    final data = unwrapData(res);
    final items = data['items'];
    if (items is! List) return const [];
    return items
        .whereType<Map<String, dynamic>>()
        .map(IpPoolResource.fromJson)
        .toList();
  }

  Future<IpPoolResource> createPool(IpPoolResource pool) async {
    final res = await _api.post('/api/v1/pools', body: pool.toBody());
    return IpPoolResource.fromJson(unwrapData(res));
  }

  Future<IpPoolResource> updatePool(IpPoolResource pool) async {
    final res = await _api.patch(
      '/api/v1/pools/${pool.id}',
      body: pool.toBody(),
    );
    return IpPoolResource.fromJson(unwrapData(res));
  }

  Future<void> deletePool(int poolId) async {
    await _api.delete('/api/v1/pools/$poolId');
  }

  Future<List<ShareGroupResource>> listShareGroups() async {
    final res = await _api.get('/api/v1/share-groups');
    final data = unwrapData(res);
    final items = data['items'];
    if (items is! List) return const [];
    return items
        .whereType<Map<String, dynamic>>()
        .map(ShareGroupResource.fromJson)
        .toList();
  }

  Future<ShareGroupDetails> getShareGroup(int groupId) async {
    final res = await _api.get('/api/v1/share-groups/$groupId');
    return ShareGroupDetails.fromJson(res);
  }

  Future<ShareGroupResource> createShareGroup(ShareGroupResource group) async {
    final res = await _api.post(
      '/api/v1/share-groups',
      body: group.toBody(),
    );
    return ShareGroupResource.fromJson(unwrapData(res));
  }

  Future<ShareGroupResource> updateShareGroup(ShareGroupResource group) async {
    final res = await _api.patch(
      '/api/v1/share-groups/${group.id}',
      body: group.toBody(),
    );
    return ShareGroupResource.fromJson(unwrapData(res));
  }

  Future<void> deleteShareGroup(int groupId) async {
    await _api.delete('/api/v1/share-groups/$groupId');
  }

  Future<void> addMember({
    required int groupId,
    required int subscriberId,
  }) async {
    await _api.post(
      '/api/v1/share-groups/$groupId/members',
      body: {'subscriber_id': subscriberId},
    );
  }

  Future<void> removeMember({
    required int groupId,
    required int subscriberId,
  }) async {
    await _api.delete('/api/v1/share-groups/$groupId/members/$subscriberId');
  }
}

final radiusResourcesRepositoryProvider =
    Provider<RadiusResourcesRepository>((ref) {
  return RadiusResourcesRepository(ref.watch(apiClientProvider));
});
