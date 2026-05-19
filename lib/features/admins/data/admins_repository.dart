import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../domain/admin_model.dart';

/// Admins/Roles endpoints aren't part of the existing /api/v1 surface yet.
/// We hit /api/admin/* paths and gracefully degrade when they 404.
class AdminsRepository {
  AdminsRepository(this._api);
  final ApiClient _api;

  Future<List<Admin>> listAdmins() async {
    final res = await _api.get('/api/admin/admins');
    final items = (res['data']?['items'] ?? res['items'] ?? []) as List;
    return items.whereType<Map<String, dynamic>>().map(Admin.fromJson).toList();
  }

  Future<List<Role>> listRoles() async {
    final res = await _api.get('/api/admin/roles');
    final items = (res['data']?['items'] ?? res['items'] ?? []) as List;
    return items.whereType<Map<String, dynamic>>().map(Role.fromJson).toList();
  }
}

final adminsRepositoryProvider = Provider<AdminsRepository>((ref) {
  return AdminsRepository(ref.watch(apiClientProvider));
});
