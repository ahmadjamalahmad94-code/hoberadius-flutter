import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/core/router/nav_history.dart';

void main() {
  group('NavHistory back-navigation stack', () {
    test('records forward visits and walks back through them', () {
      final h = NavHistory();
      h.record('/');
      h.record('/router-operations');
      h.record('/network-policy');

      expect(h.canGoBack, isTrue);
      expect(h.current, '/network-policy');
      // back returns the previous screen, not an app exit.
      expect(h.back(), '/router-operations');
      expect(h.back(), '/');
      // at the root there is nothing left to pop.
      expect(h.back(), isNull);
      expect(h.canGoBack, isFalse);
    });

    test('ignores duplicate consecutive locations (rebuilds)', () {
      final h = NavHistory();
      h.record('/cards');
      h.record('/cards');
      h.record('/cards');
      expect(h.stack, ['/cards']);
      expect(h.canGoBack, isFalse);
    });

    test('navigating back to an existing location trims the forward trail', () {
      final h = NavHistory();
      h.record('/');
      h.record('/cards');
      h.record('/cards/checker');
      // user goes back to /cards (already in the stack)
      h.record('/cards');
      expect(h.stack, ['/', '/cards']);
      expect(h.back(), '/');
    });

    test('empty history has nothing to go back to', () {
      final h = NavHistory();
      expect(h.canGoBack, isFalse);
      expect(h.current, isNull);
      expect(h.back(), isNull);
    });
  });
}
