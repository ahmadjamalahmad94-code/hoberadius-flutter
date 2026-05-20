import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../domain/saas_module_model.dart';

class SaasModulesRepository {
  SaasModulesRepository(this._api);

  final ApiClient _api;

  Future<SaasModuleSnapshot> list(String path) async {
    final res = await _api.get(path);
    return SaasModuleSnapshot.fromJson(_data(res));
  }

  Future<void> create(String path, Map<String, dynamic> body) async {
    await _api.post(path, body: body);
  }

  Future<void> update(String path, int id, Map<String, dynamic> body) async {
    await _api.patch('$path/$id', body: body);
  }

  Future<void> delete(String path, int id) async {
    await _api.delete('$path/$id');
  }

  Future<void> revokeVoucher(int id) async {
    await _api.post('/api/v1/vouchers/$id/revoke');
  }

  Future<void> updateInvoiceStatus(int id, String status) async {
    await _api.post('/api/v1/invoices/$id/status', body: {'status': status});
  }

  Future<void> addTicketReply(int id, String body) async {
    await _api.post('/api/v1/tickets/$id/replies', body: {'body': body});
  }

  Map<String, dynamic> _data(Map<String, dynamic> response) {
    final data = response['data'];
    return data is Map<String, dynamic> ? data : const {};
  }
}

final saasModulesRepositoryProvider = Provider<SaasModulesRepository>((ref) {
  return SaasModulesRepository(ref.watch(apiClientProvider));
});
