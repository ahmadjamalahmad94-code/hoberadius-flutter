import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/features/notifications/domain/notification_model.dart';

void main() {
  group('AppNotification.fromJson', () {
    test('parses all fields', () {
      final n = AppNotification.fromJson({
        'id': 7,
        'type': 'subscription',
        'severity': 'warning',
        'title': 'اقتراب انتهاء',
        'body': 'سينتهي اشتراك المشترك خلال يومين',
        'link': '/subscribers',
        'source': 'local',
        'read_at': '',
        'created_at': '2026-06-18T10:00:00',
        'is_read': false,
      });
      expect(n.id, 7);
      expect(n.type, 'subscription');
      expect(n.severity, 'warning');
      expect(n.link, '/subscribers');
      expect(n.hasLink, isTrue);
      expect(n.isRead, isFalse);
    });

    test('is_read falls back to read_at presence when flag absent', () {
      final read = AppNotification.fromJson({
        'id': 1,
        'read_at': '2026-06-18T09:00:00',
      });
      final unread = AppNotification.fromJson({'id': 2, 'read_at': ''});
      expect(read.isRead, isTrue);
      expect(unread.isRead, isFalse);
    });

    test('tolerates missing/extra fields with sane defaults', () {
      final n = AppNotification.fromJson({'id': '3'});
      expect(n.id, 3); // string id coerced
      expect(n.type, 'system');
      expect(n.severity, 'info');
      expect(n.title, '');
      expect(n.hasLink, isFalse);
    });

    test('copyWith flips read state', () {
      final n = AppNotification.fromJson({'id': 1, 'is_read': false});
      final r = n.copyWith(isRead: true);
      expect(r.isRead, isTrue);
      expect(r.id, 1);
    });
  });

  group('NotificationsPage.fromJson', () {
    test('parses items + unread + paging', () {
      final page = NotificationsPage.fromJson({
        'items': [
          {'id': 2, 'is_read': false},
          {'id': 1, 'is_read': true},
        ],
        'unread_count': 1,
        'limit': 30,
        'offset': 0,
        'has_more': true,
      });
      expect(page.items.length, 2);
      expect(page.unreadCount, 1);
      expect(page.hasMore, isTrue);
      expect(page.items.first.id, 2);
    });

    test('empty payload yields empty page', () {
      final page = NotificationsPage.fromJson({});
      expect(page.items, isEmpty);
      expect(page.unreadCount, 0);
      expect(page.hasMore, isFalse);
    });
  });
}
