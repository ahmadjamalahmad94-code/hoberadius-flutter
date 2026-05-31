import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/features/tickets/domain/ticket_model.dart';

void main() {
  test('Tickets page and detail parse support API payloads', () {
    final page = TicketsPage.fromJson({
      'data': {
        'items': [
          {
            'id': 3,
            'subscriber_id': 12,
            'subject': 'طلب تفعيل خدمة',
            'category': 'service',
            'priority': 'high',
            'status': 'open',
            'body': 'أريد تفعيل كروت إضافية',
            'created_at': '2026-05-30T10:00:00',
            'updated_at': '2026-05-30T11:00:00',
          },
        ],
        'count': 1,
      },
    });

    expect(page.count, 1);
    expect(page.items.single.priorityLabel, 'مرتفعة');
    expect(page.items.single.statusLabel, 'مفتوحة');

    final detail = TicketDetail.fromJson({
      'data': {
        'ticket': {
          'id': 3,
          'subscriber_id': 12,
          'subject': 'طلب تفعيل خدمة',
          'category': 'service',
          'priority': 'normal',
          'status': 'pending',
          'body': 'بانتظار الدفع',
        },
        'replies': [
          {
            'id': 8,
            'ticket_id': 3,
            'body': 'تم استلام الطلب',
            'author_type': 'admin',
            'author_id': 1,
          },
        ],
      },
    });

    expect(detail.ticket.statusLabel, 'بانتظار متابعة');
    expect(detail.replies.single.authorLabel, 'الإدارة');
    expect(detail.replies.single.body, 'تم استلام الطلب');

    final inProgress = SupportTicket.fromJson({
      'id': 9,
      'subscriber_id': 12,
      'status': 'in_progress',
      'priority': 'normal',
    });
    expect(inProgress.statusLabel, 'قيد التنفيذ');
  });

  test('Service request result parses ticket and optional payment request', () {
    final result = ServiceRequestResult.fromJson({
      'data': {
        'service_request': {
          'reference': 'SR-44',
          'ticket_id': 44,
          'payment_request_id': 12,
          'service_label': 'خدمة تغيير IP / VPN',
          'request_label': 'تفعيل',
        },
        'ticket': {
          'id': 44,
          'subscriber_id': 7,
          'subject': 'طلب خدمة: خدمة تغيير IP / VPN',
          'category': 'service_request',
          'priority': 'normal',
          'status': 'open',
          'body': 'الخدمة المطلوبة: خدمة تغيير IP / VPN',
        },
        'payment_request': {
          'id': 12,
          'amount': 35,
          'currency': 'ILS',
          'reference_code': 'PAY-ABC123',
          'status': 'pending',
        },
      },
    });

    expect(result.reference, 'SR-44');
    expect(result.ticketId, 44);
    expect(result.paymentRequestId, 12);
    expect(result.serviceLabel, 'خدمة تغيير IP / VPN');
    expect(result.ticket.category, 'service_request');
    expect(result.paymentRequest?.amountLabel, '35 ILS');
  });

  test('Service request decision without payment still parses safely', () {
    final result = ServiceRequestResult.fromJson({
      'data': {
        'service_request': {
          'reference': 'SR-45',
          'ticket_id': 45,
          'payment_request_id': null,
          'decision_label': 'موافقة مبدئية',
        },
        'ticket': {
          'id': 45,
          'subscriber_id': 8,
          'subject': 'طلب خدمة',
          'category': 'service_request',
          'priority': 'normal',
          'status': 'in_progress',
        },
        'payment_request': null,
      },
    });

    expect(result.ticketId, 45);
    expect(result.paymentRequestId, 0);
    expect(result.ticket.statusLabel, 'قيد التنفيذ');
    expect(result.paymentRequest, isNull);
  });
}
