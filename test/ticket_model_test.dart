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
  });
}
