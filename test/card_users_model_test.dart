import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/features/card_users/domain/card_users_model.dart';

void main() {
  test('Card users page and 360 profile parse marketplace API payloads', () {
    final page = CardUsersPage.fromJson({
      'data': {
        'items': [
          {
            'id': 7,
            'display_name': 'مشتري تجريبي',
            'mobile': '0590000000',
            'email': 'buyer@example.test',
            'status': 'active',
            'balance': '12.50',
            'pending_balance': '0',
            'spent': '5.00',
            'wallet_currency': 'ILS',
            'purchase_count': '2',
            'owned_cards_count': '2',
            'has_portal_password': true,
          },
        ],
        'summary': {
          'users': 1,
          'active': 1,
          'cards': 2,
          'purchases': 2,
          'balance': '12.50',
          'currency': 'ILS',
        },
      },
    });

    expect(page.items.single.title, 'مشتري تجريبي');
    expect(page.items.single.statusLabel, 'مفعل');
    expect(page.items.single.balance, 12.5);
    expect(page.items.single.hasPortalPassword, isTrue);
    expect(page.summary.cards, 2);

    final profile = CardUser360.fromJson({
      'data': {
        'card_user': {
          'id': 7,
          'display_name': 'مشتري تجريبي',
          'status': 'active',
          'has_portal_password': true,
        },
        'wallet': {
          'id': 3,
          'balance': '0.00',
          'currency': 'ILS',
          'status': 'active',
        },
        'purchases': [
          {
            'id': 11,
            'package_id': 5,
            'card_id': 99,
            'amount': '5.00',
            'currency': 'ILS',
            'status': 'completed',
          },
        ],
        'cards': [
          {
            'id': 99,
            'username': 'mp000099',
            'password': '12345678',
            'used': 0,
            'revoked': false,
          },
        ],
        'usage': {
          'sessions': [{}, {}],
          'total_seconds': '7200',
          'bytes_in': 100,
          'bytes_out': 200,
        },
      },
    });

    expect(profile.cardUser.id, 7);
    expect(profile.wallet.balance, '0.00');
    expect(profile.purchases.single.status, 'completed');
    expect(profile.purchases.single.statusLabel, 'مكتملة');
    expect(profile.cards.single.statusLabel, 'جاهزة');
    expect(profile.usage.sessionsCount, 2);
    expect(profile.usage.totalSeconds, 7200);
  });

  test('Marketplace package exposes Arabic-friendly labels', () {
    final package = MarketplacePackage.fromJson({
      'id': 5,
      'name': 'كرت 8 ساعات',
      'price': '5.00',
      'currency': 'ILS',
      'display_duration_minutes': 480,
      'display_speed_down_kbps': 2048,
      'display_speed_up_kbps': 512,
      'active': 1,
    });

    expect(package.durationLabel, '8 ساعة');
    expect(package.speedLabel, '2 Mbps / 512 Kbps');
    expect(package.title, 'كرت 8 ساعات');
  });
}
