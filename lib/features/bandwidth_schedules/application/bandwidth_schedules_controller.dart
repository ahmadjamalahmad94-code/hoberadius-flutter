import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/bandwidth_schedules_repository.dart';
import '../domain/bandwidth_schedule_model.dart';
import 'bandwidth_schedules_providers.dart';

class BandwidthSchedulesActionResult {
  const BandwidthSchedulesActionResult({this.message, this.error});
  final String? message;
  final String? error;
}

class BandwidthSchedulesController {
  BandwidthSchedulesController(this._ref);
  final Ref _ref;

  Future<BandwidthSchedulesActionResult> create({
    required String targetType,
    required int? planId,
    required String subscriberUsername,
    required int? cardBatchId,
    required int priority,
    required String name,
    required String startsAtTime,
    required String endsAtTime,
    required int speedDownKbps,
    required int speedUpKbps,
    required int cirDownKbps,
    required int cirUpKbps,
    required String restoreMode,
    required bool enabled,
    required String notes,
  }) async {
    try {
      await _ref.read(bandwidthSchedulesRepositoryProvider).create(
            targetType: targetType,
            planId: planId,
            subscriberUsername: subscriberUsername,
            cardBatchId: cardBatchId,
            priority: priority,
            name: name,
            startsAtTime: startsAtTime,
            endsAtTime: endsAtTime,
            speedDownKbps: speedDownKbps,
            speedUpKbps: speedUpKbps,
            cirDownKbps: cirDownKbps,
            cirUpKbps: cirUpKbps,
            restoreMode: restoreMode,
            enabled: enabled,
            notes: notes,
          );
      _ref.invalidate(bandwidthSchedulesProvider);
      return const BandwidthSchedulesActionResult(
        message: 'تم حفظ جدول السرعة',
      );
    } catch (e) {
      return BandwidthSchedulesActionResult(error: '$e');
    }
  }

  Future<BandwidthSchedulesActionResult> apply(
    BandwidthSchedule item, {
    bool live = false,
  }) async {
    try {
      final result = await _ref
          .read(bandwidthSchedulesRepositoryProvider)
          .apply(item.id, live: live);
      _ref.invalidate(bandwidthSchedulesProvider);
      final msg = result.appliedToRadius
          ? 'تم تطبيق الجدول على RADIUS'
          : 'معاينة بدون تنفيذ: لم يتم تغيير RADIUS فعليًا';
      return BandwidthSchedulesActionResult(message: msg);
    } catch (e) {
      return BandwidthSchedulesActionResult(error: '$e');
    }
  }
}

final bandwidthSchedulesControllerProvider =
    Provider.autoDispose<BandwidthSchedulesController>(
  BandwidthSchedulesController.new,
);
