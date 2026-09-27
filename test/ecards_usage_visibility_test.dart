import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/features/shell/visible_nav_sections.dart';

/// «البطاقات الإلكترونية» shows only for a network that actually uses them
/// (owner review): any card-store user, store package or recharge batch.
void main() {
  Map<String, dynamic> env(Map<String, dynamic> data) =>
      {'ok': true, 'data': data};

  final noUsers = env({'items': [], 'summary': {'users': 0}});
  final noPkgs = env({'items': [], 'count': 0});
  final noRecharge = env({'items': [], 'total': 0});

  test('an unused network hides the section', () {
    expect(eCardsUsageFromResponses(noUsers, noPkgs, noRecharge), isFalse);
  });

  test('any one signal is enough to show it', () {
    expect(
      eCardsUsageFromResponses(
        env({'items': [], 'summary': {'users': 3}}),
        noPkgs,
        noRecharge,
      ),
      isTrue,
    );
    expect(
      eCardsUsageFromResponses(noUsers, env({'items': [], 'count': 2}), noRecharge),
      isTrue,
    );
    expect(
      eCardsUsageFromResponses(noUsers, noPkgs, env({'items': [], 'total': 1})),
      isTrue,
    );
  });

  test('item lists count even when a total field is missing', () {
    expect(
      eCardsUsageFromResponses(
        noUsers,
        env({'items': [{'id': 1}]}),
        noRecharge,
      ),
      isTrue,
    );
  });

  test('tolerates flat (non-envelope) payloads and string numbers', () {
    expect(
      eCardsUsageFromResponses(
        {'summary': {'users': '0'}},
        {'count': '0'},
        {'total': '5'},
      ),
      isTrue,
    );
    expect(
      eCardsUsageFromResponses(const {}, const {}, const {}),
      isFalse,
    );
  });

  test('e-cards is the usage-gated section id', () {
    expect(kUsageGatedSectionIds, contains('electronic-cards'));
  });
}
