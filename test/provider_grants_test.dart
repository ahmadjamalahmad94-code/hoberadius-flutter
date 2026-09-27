import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/features/provider_grants/domain/provider_gate_decision.dart';
import 'package:hoberadius_app/features/provider_grants/domain/provider_grants_model.dart';
import 'package:hoberadius_app/features/provider_grants/domain/provider_grants_nav_map.dart';
import 'package:hoberadius_app/features/provider_grants/application/nav_visibility.dart';

/// A representative grants payload mirroring the web's schema_version 2 shape.
Map<String, dynamic> samplePayload({
  String licenseState = 'active',
  bool blocksPanel = false,
}) {
  return {
    'license': {
      'state': licenseState,
      'blocks_panel': blocksPanel,
      'status': 'active',
      'reason': 'active',
      'expires_at': '2030-01-01T00:00:00',
      'stale_days': 0,
      'grace_remaining_days': 0,
    },
    'services': [
      {'key': 'cards', 'present': true, 'enabled': false, 'status': 'disabled', 'disabled': true},
      {'key': 'store', 'present': true, 'status': 'locked_upgrade', 'requires_upgrade': true},
      {'key': 'distributors', 'present': true, 'feature_state': 'hidden', 'disabled': true},
      {'key': 'subscribers', 'present': true, 'enabled': true, 'status': 'active'},
    ],
    'limits': {
      'subscribers': {'current': 50, 'limit': 50, 'remaining': 0, 'limit_path': 'subscribers.max_total'},
      'admins': {'current': 1, 'limit': 5, 'remaining': 4, 'limit_path': 'admins.max_total'},
      'cards': {'current': 0, 'limit': null, 'remaining': null, 'limit_path': 'cards.monthly_generated'},
    },
    'has_snapshot': true,
    'sync': {'has_snapshot': true, 'stale': false, 'stale_days': 0, 'grace_days': 7},
    'schema_version': 2,
  };
}

void main() {
  group('ProviderGrants parsing', () {
    final grants = ProviderGrants.fromJson(samplePayload());

    test('license parses state + blocksPanel', () {
      expect(grants.license.state, LicenseState.active);
      expect(grants.license.blocksPanel, isFalse);
      expect(grants.schemaVersion, 2);
    });

    test('service flags decode', () {
      expect(grants.isDisabled('cards'), isTrue);
      expect(grants.requiresUpgrade('store'), isTrue);
      expect(grants.isDisabled('store'), isFalse); // upgrade != disabled
      expect(grants.isFullyHidden('distributors'), isTrue);
      expect(grants.isDisabled('subscribers'), isFalse);
      expect(grants.isDisabled('unknown_key'), isFalse); // default allow
    });

    test('limits decode cap / at-cap / remaining', () {
      final subs = grants.limit('subscribers')!;
      expect(subs.hasCap, isTrue);
      expect(subs.atCap, isTrue);
      final admins = grants.limit('admins')!;
      expect(admins.atCap, isFalse);
      expect(admins.remaining, 4);
      final cards = grants.limit('cards')!;
      expect(cards.hasCap, isFalse); // null limit = no cap
      expect(cards.atCap, isFalse);
    });
  });

  group('LicenseState.blocksPanel', () {
    test('definitive lockouts block, in-grace does not', () {
      expect(LicenseState.expired.blocksPanel, isTrue);
      expect(LicenseState.neverActivated.blocksPanel, isTrue);
      expect(LicenseState.syncOutageBeyondGrace.blocksPanel, isTrue);
      expect(LicenseState.syncOutageInGrace.blocksPanel, isFalse);
      expect(LicenseState.active.blocksPanel, isFalse);
    });
  });

  group('serviceKeyForLocation', () {
    test('maps locations to provider keys', () {
      expect(serviceKeyForLocation('/subscribers'), 'subscribers');
      expect(serviceKeyForLocation('/sessions'), 'subscribers');
      expect(serviceKeyForLocation('/cards'), 'cards');
      expect(serviceKeyForLocation('/cards/recharge'), 'cards_recharge');
      expect(serviceKeyForLocation('/card-users/5'), 'card_users');
      expect(serviceKeyForLocation('/plans/new'), 'profiles');
      expect(serviceKeyForLocation('/nas'), 'nas');
    });

    test('never-gated + unmapped return null', () {
      expect(serviceKeyForLocation('/'), isNull);
      expect(serviceKeyForLocation('/license-file'), isNull);
      expect(serviceKeyForLocation('/system-operations'), isNull);
      expect(serviceKeyForLocation('/account'), isNull);
      expect(serviceKeyForLocation('/tools'), isNull);
    });
  });

  group('providerGateRedirect', () {
    test('fail-open when no grants', () {
      expect(providerGateRedirect(null, '/cards'), isNull);
    });

    test('active license + allowed service passes', () {
      final g = ProviderGrants.fromJson(samplePayload());
      expect(providerGateRedirect(g, '/subscribers'), isNull);
    });

    test('disabled service redirects to blocked', () {
      final g = ProviderGrants.fromJson(samplePayload());
      expect(
        providerGateRedirect(g, '/cards'),
        '/service-blocked?service=cards',
      );
    });

    test('locked_upgrade service redirects to upgrade', () {
      final g = ProviderGrants.fromJson(samplePayload());
      expect(
        providerGateRedirect(g, '/store-admin'),
        '/service-upgrade?service=store',
      );
    });

    test('expired license blocks all but license/bridge/account', () {
      final g = ProviderGrants.fromJson(
        samplePayload(licenseState: 'expired', blocksPanel: true),
      );
      expect(providerGateRedirect(g, '/'), '/license-expired');
      expect(providerGateRedirect(g, '/subscribers'), '/license-expired');
      expect(providerGateRedirect(g, '/license-file'), isNull);
      expect(providerGateRedirect(g, '/system-operations'), isNull);
      expect(providerGateRedirect(g, '/account'), isNull);
      expect(providerGateRedirect(g, '/license-expired'), isNull);
    });

    test('never_activated routes to activate screen', () {
      final g = ProviderGrants.fromJson(
        samplePayload(licenseState: 'never_activated', blocksPanel: true),
      );
      expect(providerGateRedirect(g, '/subscribers'), '/license-activate');
      expect(providerGateRedirect(g, '/license-activate'), isNull);
    });

    test('sync outage in grace stays open (fail-open)', () {
      final g = ProviderGrants.fromJson(
        samplePayload(licenseState: 'sync_outage_in_grace'),
      );
      expect(g.license.blocksPanel, isFalse);
      expect(providerGateRedirect(g, '/subscribers'), isNull);
    });
  });

  group('gatedNavSections', () {
    test('drops disabled/hidden items, keeps locked_upgrade flagged', () {
      final g = ProviderGrants.fromJson(samplePayload());
      final sections = gatedNavSections(g);

      // No visible item should map to a disabled/hidden service.
      final cards = sections.where((s) => s.section.id == 'cards').toList();
      // 'cards' section item «حزم البطاقات» (/cards) is disabled → removed,
      // but other items (checker/print-templates) remain.
      final cardPaths = cards.isEmpty
          ? <String>[]
          : cards.first.items.map((i) => i.item.path).toList();
      expect(cardPaths, isNot(contains('/cards')));

      // distributors (fully hidden) removed from administration section.
      final admin =
          sections.firstWhere((s) => s.section.id == 'administration');
      expect(
        admin.items.map((i) => i.item.path),
        isNot(contains('/distributors')),
      );

      // store-admin (locked_upgrade) stays, flagged requiresUpgrade.
      final eCards =
          sections.firstWhere((s) => s.section.id == 'electronic-cards');
      final store = eCards.items
          .firstWhere((i) => i.item.path == '/store-admin');
      expect(store.requiresUpgrade, isTrue);
    });

    test('permissive grants keep every section', () {
      final sections = gatedNavSections(ProviderGrants.permissive);
      expect(sections.length, greaterThanOrEqualTo(10));
    });
  });
}
