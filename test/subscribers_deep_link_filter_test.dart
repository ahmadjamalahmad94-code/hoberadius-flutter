import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/features/subscribers/domain/subscriber_model.dart';
import 'package:hoberadius_app/features/subscribers/presentation/subscribers_list_screen.dart';

/// Dashboard tiles deep-link to `/subscribers?status=…` (and alerts use the
/// web-style `?attention=…`). These pin how a link becomes the list filter and
/// how the «ينتهي خلال ٣ أيام» window is applied.
void main() {
  group('subscribersFilterFromQuery', () {
    test('status param wins', () {
      expect(subscribersFilterFromQuery({'status': 'suspended'}), 'suspended');
      expect(
        subscribersFilterFromQuery({'status': 'expired', 'attention': 'x'}),
        'expired',
      );
    });

    test('web attention values map to the matching filter', () {
      expect(
        subscribersFilterFromQuery({'attention': 'expiring_3d'}),
        kExpiringSoonFilter,
      );
      expect(
        subscribersFilterFromQuery({'attention': 'expiring'}),
        kExpiringSoonFilter,
      );
      expect(subscribersFilterFromQuery({'attention': 'expired'}), 'expired');
    });

    test('no / unknown params mean «all»', () {
      expect(subscribersFilterFromQuery(const {}), isNull);
      expect(subscribersFilterFromQuery({'status': ''}), isNull);
      expect(subscribersFilterFromQuery({'attention': 'bogus'}), isNull);
    });
  });

  group('filterExpiringSoon', () {
    final now = DateTime.utc(2026, 9, 27, 12);
    Subscriber sub(String u, DateTime? exp) =>
        Subscriber(username: u, expireAt: exp);

    test('keeps only expiries after now and within 3 days', () {
      final out = filterExpiringSoon([
        sub('past', now.subtract(const Duration(hours: 1))),
        sub('soon', now.add(const Duration(hours: 5))),
        sub('edge', now.add(const Duration(days: 3))),
        sub('later', now.add(const Duration(days: 3, minutes: 1))),
        sub('none', null),
      ], now,);
      expect(out.map((s) => s.username), ['soon', 'edge']);
    });

    test('compares instants regardless of UTC vs local representation', () {
      final local = now.add(const Duration(hours: 2)).toLocal();
      expect(filterExpiringSoon([sub('l', local)], now).single.username, 'l');
    });
  });
}
