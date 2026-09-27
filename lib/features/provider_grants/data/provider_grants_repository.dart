import '../../../core/api/api_client.dart';
import '../domain/provider_grants_model.dart';

/// Reads `GET /api/v1/provider/grants` (Bearer admin token, tenant-scoped,
/// read-only). Returns the decoded [ProviderGrants].
class ProviderGrantsRepository {
  ProviderGrantsRepository(this._api);

  final ApiClient _api;

  Future<ProviderGrants> fetch() async {
    final res = await _api.get('/api/v1/provider/grants');
    final data = res['data'];
    if (data is Map) {
      return ProviderGrants.fromJson(
        data.map((k, v) => MapEntry(k.toString(), v)),
      );
    }
    return ProviderGrants.permissive;
  }
}
