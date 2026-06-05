import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/features/hotspot_cards_portal/domain/hotspot_cards_portal_model.dart';

void main() {
  test('parses hotspot cards portal login and catalog payloads', () {
    final login = HotspotPortalLoginResult.fromJson({
      'ok': true,
      'token': 'portal-token',
      'expires_in': 900,
      'user': {
        'id': 'card_user:7',
        'username': 'card-owner',
        'display_name': 'صاحب المحفظة',
        'phone': '0599000000',
        'wallet_balance': '42.50',
        'currency': 'ILS',
      },
    });

    expect(login.token, 'portal-token');
    expect(login.user.title, 'صاحب المحفظة');
    expect(login.user.walletLabel, '42.50 ILS');

    final item = HotspotCatalogItem.fromJson({
      'id': '12',
      'name': 'كرت ساعة',
      'description': '10 Mbps / 5 Mbps',
      'price': '5.00',
      'currency': 'ILS',
      'profile_name': 'ساعة سريعة',
      'duration_label': '1 ساعة',
      'quota_label': 'غير محددة',
      'available': true,
    });

    expect(item.title, 'كرت ساعة');
    expect(item.priceLabel, '5.00 ILS');
    expect(item.available, isTrue);
  });

  test('parses owned cards and derives Arabic card status', () {
    final owned = HotspotOwnedCard.fromJson({
      'purchase_id': '44',
      'package_id': '12',
      'package_name': 'كرت ساعة',
      'purchased_at': '2026-06-05T12:00:00Z',
      'amount': '5.00',
      'currency': 'ILS',
      'card': {
        'username': 'HP-001',
        'password': '123456',
        'profile_name': 'ساعة سريعة',
        'duration_label': '1 ساعة',
        'quota_label': 'غير محددة',
        'expires_at': '2099-06-05T12:00:00Z',
        'used': false,
        'revoked': false,
      },
    });

    expect(owned.amountLabel, '5.00 ILS');
    expect(owned.card.username, 'HP-001');
    expect(owned.card.statusLabel, 'جاهزة');

    final used = HotspotPortalCard.fromJson({
      'username': 'HP-002',
      'password': '123456',
      'used': true,
    });
    expect(used.statusLabel, 'مستخدمة');
  });
}
