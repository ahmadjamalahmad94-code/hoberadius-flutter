import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../domain/ticket_model.dart';

class TicketsRepository {
  TicketsRepository(this._api);

  final ApiClient _api;

  Future<TicketsPage> list({String status = '', int limit = 200}) async {
    final res = await _api.get(
      '/api/v1/tickets',
      query: {
        if (status.isNotEmpty) 'status': status,
        'limit': limit,
      },
    );
    return TicketsPage.fromJson(res);
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
