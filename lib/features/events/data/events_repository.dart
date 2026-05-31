import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../domain/business_event_model.dart';

class EventsRepository {
  EventsRepository(this._api);

  final ApiClient _api;

  Future<BusinessEventsPage> list({
    String category = '',
    String severity = '',
    int limit = 100,
  }) async {
    final res = await _api.get(
      '/api/v1/events',
      query: {
        if (category.isNotEmpty) 'category': category,
        if (severity.isNotEmpty) 'severity': severity,
        'limit': limit,
      },
    );
    return BusinessEventsPage.fromJson(res);
  }

  Future<BusinessSummary> summary() async {
    final res = await _api.get('/api/v1/business/summary');
    return BusinessSummary.fromJson(res);
  }

  Future<BusinessEvent> record({
    required String category,
    required String severity,
    required String eventKey,
    required String message,
    String actorType = '',
    int? actorId,
    String targetType = '',
    int? targetId,
    String correlationId = '',
  }) async {
    final res = await _api.post(
      '/api/v1/events',
      body: {
        'category': category,
        'severity': severity,
        'event_key': eventKey,
        'message': message,
        if (actorType.isNotEmpty) 'actor_type': actorType,
        if (actorId != null) 'actor_id': actorId,
        if (targetType.isNotEmpty) 'target_type': targetType,
        if (targetId != null) 'target_id': targetId,
        if (correlationId.isNotEmpty) 'correlation_id': correlationId,
      },
    );
    final data = res['data'];
    final event = data is Map ? data['event'] : null;
    return BusinessEvent.fromJson(
      event is Map<String, dynamic>
          ? event
          : event is Map
              ? event.map((key, value) => MapEntry(key.toString(), value))
              : const {},
    );
  }
}

final eventsRepositoryProvider = Provider<EventsRepository>((ref) {
  return EventsRepository(ref.watch(apiClientProvider));
});
