import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../domain/bandwidth_schedule_model.dart';

class BandwidthSchedulesRepository {
  BandwidthSchedulesRepository(this._api);

  final ApiClient _api;

  Future<List<BandwidthSchedule>> list() async {
    final res = await _api.get('/api/v1/bandwidth-schedules');
    final data = res['data'];
    final items = data is Map ? data['items'] : null;
    if (items is! List) return const [];
    return items
        .whereType<Map>()
        .map(
          (item) => BandwidthSchedule.fromJson(
            item.map((key, value) => MapEntry(key.toString(), value)),
          ),
        )
        .toList();
  }

  Future<BandwidthSchedule> create({
    required int planId,
    required String name,
    required String startsAtTime,
    required String endsAtTime,
    required int speedDownKbps,
    required int speedUpKbps,
    int cirDownKbps = 0,
    int cirUpKbps = 0,
    String restoreMode = 'profile_default',
    bool enabled = true,
    String notes = '',
  }) async {
    final res = await _api.post(
      '/api/v1/bandwidth-schedules',
      body: {
        'plan_id': planId,
        'name': name,
        'starts_at_time': startsAtTime,
        'ends_at_time': endsAtTime,
        'speed_down_kbps': speedDownKbps,
        'speed_up_kbps': speedUpKbps,
        'cir_down_kbps': cirDownKbps,
        'cir_up_kbps': cirUpKbps,
        'restore_mode': restoreMode,
        'enabled': enabled,
        'notes': notes,
      },
    );
    final data = res['data'];
    final schedule = data is Map ? data['schedule'] : null;
    if (schedule is Map<String, dynamic>) {
      return BandwidthSchedule.fromJson(schedule);
    }
    if (schedule is Map) {
      return BandwidthSchedule.fromJson(
        schedule.map((key, value) => MapEntry(key.toString(), value)),
      );
    }
    return const BandwidthSchedule(
      id: 0,
      planId: 0,
      name: '',
      startsAtTime: '',
      endsAtTime: '',
      speedDownKbps: 0,
      speedUpKbps: 0,
      cirDownKbps: 0,
      cirUpKbps: 0,
      restoreMode: 'profile_default',
      enabled: false,
      notes: '',
      createdAt: null,
    );
  }

  Future<BandwidthApplyResult> applyDryRun(int scheduleId) async {
    final res =
        await _api.post('/api/v1/bandwidth-schedules/$scheduleId/apply');
    final data = res['data'];
    return BandwidthApplyResult.fromJson(
      data is Map<String, dynamic>
          ? data
          : data is Map
              ? data.map((key, value) => MapEntry(key.toString(), value))
              : const {},
    );
  }
}

final bandwidthSchedulesRepositoryProvider =
    Provider<BandwidthSchedulesRepository>((ref) {
  return BandwidthSchedulesRepository(ref.watch(apiClientProvider));
});
