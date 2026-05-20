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
    final accounts =
        await _safe(() => _api.get('/api/v1/accounts', query: {'limit': 1}));
    final nas = await _safe(() => _api.get('/api/v1/nas'));
    final plans = await _safe(() => _api.get('/api/v1/profiles'));
    return DashboardMetrics(
      subscribers: _count(accounts?['data']),
      nasDevices: _count(nas?['data']),
      plans: _count(plans?['data']),
    );
  }

  Future<Map<String, dynamic>?> _safe(
    Future<Map<String, dynamic>> Function() f,
  ) async {
    try {
      return await f();
    } catch (_) {
      return null;
    }
  }

  int _count(Object? v) {
    if (v is Map) {
      final raw = v['count'] ?? v['total'] ?? v['total_count'];
      if (raw is int) return raw;
      final parsed = int.tryParse((raw ?? '').toString());
      if (parsed != null) return parsed;
      final items = v['items'];
      if (items is List) return items.length;
    }
    if (v is List) return v.length;
    return 0;
  }
}

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(ref.watch(apiClientProvider));
});
