import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../domain/card_users_model.dart';

class CardUsersRepository {
  CardUsersRepository(this._api);

  final ApiClient _api;

  Future<CardUsersPage> listUsers({String status = '', int limit = 200}) async {
    final res = await _api.get(
      '/api/v1/card-users',
      query: {
        if (status.isNotEmpty) 'status': status,
        'limit': limit,
      },
    );
    return CardUsersPage.fromJson(res);
  }

  Future<CardUser> createUser({
    required String displayName,
    String mobile = '',
    String email = '',
    String password = '',
  }) async {
    final res = await _api.post(
      '/api/v1/card-users',
      body: {
        'display_name': displayName,
        if (mobile.trim().isNotEmpty) 'mobile': mobile.trim(),
        if (email.trim().isNotEmpty) 'email': email.trim(),
        if (password.trim().isNotEmpty) 'password': password,
      },
    );
    final data = res['data'];
    final json = data is Map<String, dynamic> ? data['card_user'] : null;
    return CardUser.fromJson(json is Map<String, dynamic> ? json : const {});
  }

  Future<List<MarketplacePackage>> listPackages({bool active = true}) async {
    final res = await _api.get(
      '/api/v1/card-marketplace/packages',
      query: {'active': active ? 1 : 0, 'limit': 200},
    );
    final items = (res['data']?['items'] ?? const []) as List;
    return items
        .whereType<Map<String, dynamic>>()
        .map(MarketplacePackage.fromJson)
        .toList();
  }

  Future<CardUser360> get360(int cardUserId) async {
    final res = await _api.get('/api/v1/card-users/$cardUserId/360');
    return CardUser360.fromJson(res);
  }

  Future<void> recharge(int cardUserId, {required String amount}) {
    return _api.post(
      '/api/v1/card-users/$cardUserId/recharge',
      body: {'amount': amount},
    );
  }

  Future<void> updatePassword(int cardUserId, {required String password}) {
    return _api.post(
      '/api/v1/card-users/$cardUserId/password',
      body: {'password': password},
    );
  }

  Future<void> purchase(int cardUserId, {required int packageId}) {
    return _api.post(
      '/api/v1/card-users/$cardUserId/purchase',
      body: {'package_id': packageId},
    );
  }
}

final cardUsersRepositoryProvider = Provider<CardUsersRepository>((ref) {
  return CardUsersRepository(ref.watch(apiClientProvider));
});
