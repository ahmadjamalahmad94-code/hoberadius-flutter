import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../domain/dashboard_model.dart';

class DashboardRepository {
  DashboardRepository(this._api);
  final ApiClient _api;

  /// Tries /api/v1/dashboard first (when wired) and falls back to a
  /// composed snapshot from individual endpoints if it 404s.
  Future<DashboardMetrics> fetch() async {
    try {
      final res = await _api.get('/api/v1/dashboard');
      final d = res['data'] as Map<String, dynamic>?;
      if (d != null) return DashboardMetrics.fromJson(d);
    } catch (_) {/* fall through */}
    // Compose from health + accounts list count + nas list count.
    final accounts = await _safe(() => _api.get('/api/v1/accounts', query: {'limit': 1}));
    final nas = await _safe(() => _api.get('/api/v1/nas'));
    final plans = await _safe(() => _api.get('/api/v1/profiles'));
    return DashboardMetrics(
      subscribers: _len(accounts?['data']?['items']),
      nasDevices: _len(nas?['data']?['items']),
      plans: _len(plans?['data']?['items']),
    );
  }

  Future<Map<String, dynamic>?> _safe(Future<Map<String, dynamic>> Function() f) async {
    try {
      return await f();
    } catch (_) {
      return null;
    }
  }

  int _len(Object? v) => v is List ? v.length : 0;
}

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(ref.watch(apiClientProvider));
});
