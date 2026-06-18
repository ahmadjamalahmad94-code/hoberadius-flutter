/// Maps Flutter routes/nav items to provider service-keys, mirroring the web's
/// `_ENDPOINT_TO_SERVICE` (radius-module: app/radius/auth/provider_gate.py).
///
/// A route's key is looked up against the grants payload to decide hide /
/// block / upgrade. Unmapped routes return null → always allowed (the web's
/// default: "not registered = allowed; internal RBAC handles the rest").
///
/// Some routes are *never* gated regardless of grants — the lifecycle/bridge/
/// tools/diagnostics + account + dashboard surfaces must stay reachable so a
/// blocked owner can still inspect status and renew/activate the license
/// (mirror of the web guard keeping login/license/diagnostics open).
library;

/// Paths that must always be reachable (no service gate, no license block).
/// Matched by exact value or `path/`-prefix.
const Set<String> kNeverGatedPaths = {
  '/',
  '/account',
  '/more',
  '/license-file',
  '/system-operations',
  '/tools',
  '/alerts/telegram',
  // the gate screens themselves
  '/license-expired',
  '/license-activate',
  '/service-blocked',
  '/service-upgrade',
};

/// Longest-prefix-first mapping of route path → provider service-key.
/// Order matters: more specific prefixes precede their parents.
const List<(String, String)> _pathServiceKeys = [
  // subscribers
  ('/subscribers', 'subscribers'),
  ('/sessions', 'subscribers'),
  // cards (specific children before '/cards')
  ('/cards/recharge', 'cards_recharge'),
  ('/cards', 'cards'),
  ('/card-users', 'card_users'),
  ('/print-templates', 'print_templates'),
  ('/store-admin', 'store'),
  // offers / plans
  ('/plans', 'profiles'),
  ('/bandwidth-schedules', 'bandwidth_schedules'),
  // network
  ('/router-operations', 'network'),
  ('/router-programming', 'network'),
  ('/mikrotik', 'network'),
  ('/setup-wizard', 'network'),
  ('/router-alerts', 'network'),
  ('/network-devices', 'network'),
  ('/network-policy', 'network'),
  ('/device-fingerprints', 'network'),
  ('/nas', 'nas'),
  ('/radius-resources', 'pools'),
  ('/audit', 'audit'),
  // finance
  ('/revenue', 'finance'),
  ('/wallets', 'finance'),
  ('/loans', 'finance'),
  ('/ledger', 'finance'),
  ('/invoices', 'finance'),
  ('/vouchers', 'finance'),
  ('/payment-collection', 'finance'),
  // engagement
  ('/communications', 'communications'),
  ('/events', 'events'),
  // reports
  ('/operational-reports', 'reports'),
  ('/reports', 'reports'),
  // support
  ('/tickets', 'tickets'),
  ('/saas-modules', 'service_requests'),
  ('/customer-portals', 'customer_portal'),
  // administration
  ('/admins', 'admins'),
  ('/roles', 'admins'),
  ('/distributors', 'distributors'),
  ('/business-ops', 'business_os'),
  ('/backups', 'backups'),
  ('/recycle-bin', 'recycle_bin'),
  ('/lifecycle', 'lifecycle'),
  ('/admin-control', 'settings'),
];

bool _matches(String location, String path) {
  if (path == '/') return location == '/';
  return location == path || location.startsWith('$path/');
}

/// True when [location] must never be gated.
bool isNeverGated(String location) {
  for (final p in kNeverGatedPaths) {
    if (_matches(location, p)) return true;
  }
  return false;
}

/// Provider service-key governing [location], or null if unmapped / never
/// gated (→ always allowed).
String? serviceKeyForLocation(String location) {
  if (isNeverGated(location)) return null;
  for (final entry in _pathServiceKeys) {
    if (_matches(location, entry.$1)) return entry.$2;
  }
  return null;
}
