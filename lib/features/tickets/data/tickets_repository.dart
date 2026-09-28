import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/format/currency.dart';
import '../domain/ticket_model.dart';

class TicketsRepository {
  TicketsRepository(this._api);

  final ApiClient _api;

  /// One page (limit/offset — both old and new servers honour them; the
  /// updated server adds an exact `has_more`). The list used to stop at 200.
  Future<TicketsPage> list({
    String status = '',
    int limit = 50,
    int offset = 0,
  }) async {
    final res = await _api.get(
      '/api/v1/tickets',
      query: {
        if (status.isNotEmpty) 'status': status,
        'limit': limit,
        'offset': offset,
      },
    );
    return TicketsPage.fromJson(res, requestedLimit: limit, offset: offset);
  }

  Future<TicketDetail> get(int ticketId) async {
    final res = await _api.get('/api/v1/tickets/$ticketId');
    return TicketDetail.fromJson(res);
  }

  Future<SupportTicket> create({
    required int subscriberId,
    required String subject,
    required String category,
    required String priority,
    required String body,
  }) async {
    final res = await _api.post(
      '/api/v1/tickets',
      body: {
        'subscriber_id': subscriberId,
        'subject': subject,
        'category': category,
        'priority': priority,
        'body': body,
        'status': 'open',
      },
    );
    final data = res['data'];
    return SupportTicket.fromJson(
      data is Map<String, dynamic> ? data : const {},
    );
  }

  Future<ServiceRequestResult> createServiceRequest({
    required int subscriberId,
    required String serviceKey,
    required String serviceName,
    required String requestType,
    String priority = 'normal',
    String notes = '',
    double? amount,
    String currency = kDefaultCurrency,
    String purpose = 'monthly_subscription',
  }) async {
    final res = await _api.post(
      '/api/v1/service-requests',
      body: {
        'subscriber_id': subscriberId,
        'service_key': serviceKey,
        'service_name': serviceName,
        'request_type': requestType,
        'priority': priority,
        'notes': notes,
        if (amount != null)
          'payment': {
            'amount': amount,
            'currency': currency,
            'purpose': purpose,
          },
      },
    );
    return ServiceRequestResult.fromJson(res);
  }

  /// [expectedStatus]: the status the operator saw; the updated server
  /// answers 409 when someone else decided meanwhile (no double decision).
  Future<ServiceRequestResult> decideServiceRequest({
    required int ticketId,
    required String decision,
    String? expectedStatus,
    String note = '',
    double? amount,
    int? trialDays,
    String currency = kDefaultCurrency,
    String purpose = 'monthly_subscription',
  }) async {
    final res = await _api.post(
      '/api/v1/service-requests/$ticketId/decision',
      body: {
        'decision': decision,
        if (expectedStatus != null && expectedStatus.isNotEmpty)
          'expected_status': expectedStatus,
        'note': note,
        if (trialDays != null) 'trial_days': trialDays,
        if (amount != null)
          'payment': {
            'amount': amount,
            'currency': currency,
            'purpose': purpose,
          },
      },
    );
    return ServiceRequestResult.fromJson(res);
  }

  Future<SupportTicket> updateStatus(int ticketId, String status) async {
    final res = await _api.patch(
      '/api/v1/tickets/$ticketId',
      body: {'status': status},
    );
    final data = res['data'];
    return SupportTicket.fromJson(
      data is Map<String, dynamic> ? data : const {},
    );
  }

  Future<TicketReply> addReply(int ticketId, String body) async {
    final res = await _api.post(
      '/api/v1/tickets/$ticketId/replies',
      body: {'body': body},
    );
    final data = res['data'];
    return TicketReply.fromJson(data is Map<String, dynamic> ? data : const {});
  }
}

final ticketsRepositoryProvider = Provider<TicketsRepository>((ref) {
  return TicketsRepository(ref.watch(apiClientProvider));
});
