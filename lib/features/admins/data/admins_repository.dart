import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../domain/admin_model.dart';

class AdminsRepository {
  AdminsRepository(this._api);
  final ApiClient _api;

  // ── admins ──

  Future<List<Admin>> listAdmins() async {
    final res = await _api.get('/api/v1/admins');
    final items = (res['data']?['items'] ?? const []) as List;
    return items.whereType<Map<String, dynamic>>().map(Admin.fromJson).toList();
  }

  Future<Admin> getAdmin(int id) async {
    final res = await _api.get('/api/v1/admins/$id');
    final d = res['data'];
    return Admin.fromJson(d is Map<String, dynamic> ? d : res);
  }

  Future<Admin> createAdmin(Admin a, String password) async {
    final body = a.toBody(pendingPassword: password);
    body['username'] = a.username;
    body['password'] = password;
    final res = await _api.post('/api/v1/admins', body: body);
    final d = res['data'];
    return Admin.fromJson(d is Map<String, dynamic> ? d : res);
  }

  Future<Admin> updateAdmin(int id, Admin a, {String? pendingPassword}) async {
    final res = await _api.patch(
      '/api/v1/admins/$id',
      body: a.toBody(pendingPassword: pendingPassword),
    );
    final d = res['data'];
    return Admin.fromJson(d is Map<String, dynamic> ? d : res);
  }

  Future<void> deleteAdmin(int id) => _api.delete('/api/v1/admins/$id');

  // ── roles ──

  Future<List<Role>> listRoles() async {
    final res = await _api.get('/api/v1/roles');
    final items = (res['data']?['items'] ?? const []) as List;
    return items.whereType<Map<String, dynamic>>().map(Role.fromJson).toList();
  }

  Future<Role> getRole(int id) async {
    final res = await _api.get('/api/v1/roles/$id');
    final d = res['data'];
    return Role.fromJson(d is Map<String, dynamic> ? d : res);
  }

  Future<Role> createRole(Role r) async {
    final body = r.toBody();
    body['name'] = r.name;
    final res = await _api.post('/api/v1/roles', body: body);
    final d = res['data'];
    return Role.fromJson(d is Map<String, dynamic> ? d : res);
  }

  Future<Role> updateRole(int id, Role r) async {
    final res = await _api.patch('/api/v1/roles/$id', body: r.toBody());
    final d = res['data'];
    return Role.fromJson(d is Map<String, dynamic> ? d : res);
  }

  Future<void> deleteRole(int id) => _api.delete('/api/v1/roles/$id');

  // ── permissions catalog ──

  Future<PermissionCatalog> permissionsCatalog() async {
    final res = await _api.get('/api/v1/permissions');
    final d = res['data'];
    return PermissionCatalog.fromJson(d is Map<String, dynamic> ? d : res);
  }
}

final adminsRepositoryProvider = Provider<AdminsRepository>((ref) {
  return AdminsRepository(ref.watch(apiClientProvider));
});

final adminsListProvider = FutureProvider.autoDispose<List<Admin>>((ref) {
  return ref.watch(adminsRepositoryProvider).listAdmins();
});

final rolesListProvider = FutureProvider.autoDispose<List<Role>>((ref) {
  return ref.watch(adminsRepositoryProvider).listRoles();
});

final permissionsCatalogProvider =
    FutureProvider.autoDispose<PermissionCatalog>((ref) {
  return ref.watch(adminsRepositoryProvider).permissionsCatalog();
});
