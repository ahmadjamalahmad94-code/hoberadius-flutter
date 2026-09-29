import 'permissions.dart';

/// What a screen needs, in the server's own terms: RBAC keys (any one is
/// enough), a manager section (visible, or writable for a form), a server
/// action (ACTION_REGISTRY key) and/or owner-only.
class RouteRequirement {
  const RouteRequirement({
    this.anyOf = const [],
    this.section,
    this.writeSection = false,
    this.action,
    this.ownerOnly = false,
    this.ownerOr = const [],
    this.distributorAllowed = false,
  });

  /// RBAC keys — at least one is needed (empty = none).
  final List<String> anyOf;

  /// Manager section (`grants.sections`) that must not be hidden.
  final String? section;

  /// The screen is a form that saves: the section must be OPEN (a locked
  /// section is read-only, so the form must not open).
  final bool writeSection;

  /// Server action (`grants.actions`) the screen performs.
  final String? action;

  /// Owner / co-owner only (settings, backups, tokens, collection…).
  final bool ownerOnly;

  /// Owner-like OR one of these keys (managers/roles: the server delegates
  /// them to `admins.*`).
  final List<String> ownerOr;

  /// A distributor login may open this screen.
  final bool distributorAllowed;

  bool allows(AppPermissions p) => denial(p) == null;

  /// Arabic reason the screen is refused, or null when allowed.
  String? denial(AppPermissions p) {
    if (p.legacy || p.isOwner) return null;
    if (p.isDistributor && !distributorAllowed) {
      return 'هذه الصفحة غير متاحة لحساب الموزّع.';
    }
    if (ownerOnly) return p.deniedReason(ownerOnly: true);
    if (ownerOr.isNotEmpty && !p.canAny(ownerOr)) {
      return p.deniedReason(anyOf: ownerOr);
    }
    final sec = section;
    if (sec != null) {
      if (!p.canSection(sec)) return p.deniedReason(section: sec);
      if (writeSection && !p.canWriteSection(sec)) {
        return p.deniedReason(section: sec);
      }
    }
    if (anyOf.isNotEmpty && !p.canAny(anyOf)) {
      return p.deniedReason(anyOf: anyOf);
    }
    final act = action;
    if (act != null && !p.canAction(act)) {
      return p.deniedReason(action: act, anyOf: anyOf);
    }
    return null;
  }
}

/// Screen × permission matrix (p01 matrix + backend keys). Keyed by the
/// route PATTERN (`:param` segments); the most specific pattern wins.
/// Paths not listed (dashboard, notifications, account, more, licence
/// screens, portals) need no permission.
const kRouteRequirements = <String, RouteRequirement>{
  // ── subscribers ──
  '/subscribers': RouteRequirement(
    anyOf: ['users.view'],
    section: 'subscribers',
    distributorAllowed: true,
  ),
  '/subscribers/new': RouteRequirement(
    anyOf: ['users.create'],
    section: 'subscribers',
    writeSection: true,
    action: 'subscriber.create',
    distributorAllowed: true,
  ),
  '/subscribers/:username': RouteRequirement(
    anyOf: ['users.edit'],
    section: 'subscribers',
    writeSection: true,
    distributorAllowed: true,
  ),
  '/subscribers/:username/360': RouteRequirement(
    anyOf: ['users.view'],
    section: 'subscribers',
    distributorAllowed: true,
  ),
  '/subscribers/:username/finance': RouteRequirement(
    anyOf: ['users.view'],
    section: 'subscribers',
    distributorAllowed: true,
  ),
  '/sessions': RouteRequirement(
    anyOf: ['online.view'],
    section: 'sessions',
    distributorAllowed: true,
  ),
  // ── cards ──
  '/cards': RouteRequirement(
    anyOf: ['cards.view'],
    section: 'cards',
    distributorAllowed: true,
  ),
  '/cards/new': RouteRequirement(
    anyOf: ['cards.generate'],
    section: 'cards',
    writeSection: true,
    action: 'cards.generate',
  ),
  '/cards/import': RouteRequirement(
    anyOf: ['cards.import'],
    section: 'cards',
    writeSection: true,
    action: 'cards.import',
  ),
  '/cards/checker': RouteRequirement(
    anyOf: ['cards.view', 'cards.verify'],
    section: 'cards',
    distributorAllowed: true,
  ),
  '/cards/batches/:id': RouteRequirement(
    anyOf: ['cards.view'],
    section: 'cards',
    distributorAllowed: true,
  ),
  // Printing hands out the passwords: the server unmasks them only with
  // cards.print (or scope.view_passwords) — permguard.
  '/cards/batches/:id/print': RouteRequirement(
    anyOf: ['cards.print', 'scope.view_passwords'],
    section: 'cards',
    distributorAllowed: true,
  ),
  '/cards/batches/:id/edit': RouteRequirement(
    anyOf: ['cards.edit_batch'],
    section: 'cards',
    writeSection: true,
    action: 'batch.edit',
  ),
  '/cards/recharge': RouteRequirement(
    anyOf: ['cards.recharge'],
    section: 'cards',
  ),
  '/print-templates': RouteRequirement(
    anyOf: ['cards.print'],
    section: 'cards',
  ),
  '/vouchers': RouteRequirement(anyOf: ['cards.view'], section: 'cards'),
  // ── electronic store ──
  '/card-users': RouteRequirement(anyOf: ['store.view']),
  '/card-users/:id': RouteRequirement(anyOf: ['store.view']),
  '/store-admin': RouteRequirement(anyOf: ['store.review'], section: 'store'),
  // ── plans / speeds ──
  '/plans': RouteRequirement(anyOf: ['plans.view'], section: 'plans'),
  '/plans/new': RouteRequirement(
    anyOf: ['plans.create'],
    section: 'plans',
    writeSection: true,
    action: 'plan.create',
  ),
  '/plans/:id': RouteRequirement(
    anyOf: ['plans.edit'],
    section: 'plans',
    writeSection: true,
    action: 'plan.edit',
  ),
  '/bandwidth-schedules':
      RouteRequirement(anyOf: ['plans.view'], section: 'plans'),
  // ── network ──
  '/nas': RouteRequirement(anyOf: ['nas.view'], section: 'network'),
  '/nas/new': RouteRequirement(
    anyOf: ['nas.create'],
    section: 'network',
    writeSection: true,
  ),
  '/nas/:id': RouteRequirement(
    anyOf: ['nas.edit'],
    section: 'network',
    writeSection: true,
  ),
  '/mikrotik': RouteRequirement(anyOf: ['nas.view'], section: 'network'),
  '/router-operations':
      RouteRequirement(anyOf: ['nas.view'], section: 'network'),
  // MikroTik-domain pages (programming, smart alerts, network policy) are
  // guarded by `mt:mikrotik.*` / `mt:npc.*`, which no role can grant today
  // (permguard) — owner / co-owner in practice.
  '/router-programming/:id': RouteRequirement(ownerOnly: true),
  '/device-fingerprints':
      RouteRequirement(anyOf: ['nas.view'], section: 'network'),
  '/network-devices':
      RouteRequirement(anyOf: ['nas.view'], section: 'network'),
  '/router-alerts': RouteRequirement(ownerOnly: true),
  '/network-policy': RouteRequirement(ownerOnly: true),
  '/radius-resources':
      RouteRequirement(anyOf: ['nas.view'], section: 'network'),
  // web tools: speeds/test-auth are owner-only, the RADIUS log is reports.view
  '/tools': RouteRequirement(anyOf: ['reports.view']),
  // ── money ──
  '/revenue': RouteRequirement(anyOf: ['reports.finance'], section: 'finance'),
  '/reports': RouteRequirement(anyOf: ['reports.finance'], section: 'finance'),
  '/ledger': RouteRequirement(anyOf: ['reports.finance'], section: 'finance'),
  '/wallets': RouteRequirement(anyOf: ['reports.finance'], section: 'finance'),
  '/invoices': RouteRequirement(anyOf: ['reports.finance'], section: 'finance'),
  '/loans': RouteRequirement(
    anyOf: ['users.view'],
    section: 'subscribers',
    distributorAllowed: true,
  ),
  '/payment-collection': RouteRequirement(ownerOnly: true),
  '/payment-collection/:id': RouteRequirement(ownerOnly: true),
  '/distributors': RouteRequirement(
    anyOf: ['reports.finance'],
    section: 'distributors',
  ),
  '/distributors/new': RouteRequirement(
    anyOf: ['reports.finance'],
    section: 'distributors',
    writeSection: true,
    action: 'distributor.manage',
  ),
  '/distributors/:id': RouteRequirement(
    anyOf: ['reports.finance'],
    section: 'distributors',
    distributorAllowed: true,
  ),
  '/business-ops': RouteRequirement(anyOf: ['admins.view']),
  // ── reports / events ──
  '/operational-reports':
      RouteRequirement(anyOf: ['reports.view'], section: 'reports'),
  '/operational-reports/:slug':
      RouteRequirement(anyOf: ['reports.view'], section: 'reports'),
  '/events': RouteRequirement(anyOf: ['audit.view']),
  '/audit': RouteRequirement(anyOf: ['audit.view']),
  // ── support / comms ──
  '/tickets': RouteRequirement(anyOf: ['users.view']),
  '/tickets/:id': RouteRequirement(anyOf: ['users.view']),
  '/communications': RouteRequirement(
    anyOf: ['users.send_message'],
    section: 'communications',
  ),
  // ── administration ──
  // Managers / roles: owner, co-owner, or the delegated admins.* keys
  // (permmodel SUPER_DELEGABLE — the «مدير عام» role has them).
  '/admins': RouteRequirement(ownerOr: ['admins.view']),
  '/admins/new': RouteRequirement(ownerOr: ['admins.create']),
  '/admins/:id': RouteRequirement(ownerOr: ['admins.edit']),
  '/roles': RouteRequirement(ownerOr: ['admins.view']),
  '/roles/new': RouteRequirement(ownerOr: ['admins.edit']),
  '/roles/:id': RouteRequirement(ownerOr: ['admins.edit']),
  '/alerts/telegram': RouteRequirement(anyOf: ['settings.view']),
  '/saas-modules': RouteRequirement(anyOf: ['users.view']),
  '/recycle-bin': RouteRequirement(anyOf: ['settings.view']),
  '/lifecycle': RouteRequirement(anyOf: ['settings.view']),
  // owner-only (auth/owner.OWNER_ONLY): system settings, backups, data reset
  '/admin-control': RouteRequirement(ownerOnly: true),
  '/backups': RouteRequirement(ownerOnly: true),
};

/// Paths a distributor login may always open (its own account & alerts).
const kAlwaysAllowedPaths = <String>{
  '/',
  '/more',
  '/account',
  '/notifications',
  '/license-expired',
  '/license-activate',
  '/service-blocked',
  '/service-upgrade',
  '/no-access',
};

bool _segmentsMatch(List<String> pattern, List<String> path) {
  if (pattern.length != path.length) return false;
  for (var i = 0; i < pattern.length; i++) {
    if (pattern[i].startsWith(':')) {
      if (path[i].isEmpty) return false;
      continue;
    }
    if (pattern[i] != path[i]) return false;
  }
  return true;
}

List<String> _segments(String p) =>
    p.split('?').first.split('/').where((s) => s.isNotEmpty).toList();

/// The requirement for a concrete [location] (`/subscribers/ali/360`), or
/// null when the screen needs none. Literal segments beat `:params`
/// (`/subscribers/new` is the create form, not a subscriber named «new»).
RouteRequirement? routeRequirementFor(String location) {
  final path = _segments(location);
  RouteRequirement? best;
  var bestScore = -1;
  kRouteRequirements.forEach((pattern, req) {
    final pat = _segments(pattern);
    if (!_segmentsMatch(pat, path)) return;
    final score = pat.where((s) => !s.startsWith(':')).length;
    if (score > bestScore) {
      best = req;
      bestScore = score;
    }
  });
  return best;
}

/// Refusal shown to a distributor login opening another distributor's page.
const kOtherDistributorPage = 'هذه صفحة موزّع آخر — تستطيع فتح صفحتك فقط.';

/// Refusal of the tools screen when the server allows none of its tools.
const kNoToolAllowed = 'لا تملك صلاحية أيّ أداة من الأدوات.';

/// A distributor login whose own distributor id is known (fix2-final
/// `admin.distributor_id`): its «الموزعون» entry is its own page.
bool _ownDistributorKnown(AppPermissions p) =>
    p.isDistributor && !p.legacy && !p.isOwner && p.distributorId != null;

/// Where the router sends [location] for [p] before any permission check:
/// a distributor login opening the distributors LIST lands on its own page
/// (`/distributors/<id>`). Null = no rewrite.
String? distributorOwnPageRedirect(AppPermissions p, String location) {
  if (!_ownDistributorKnown(p)) return null;
  final seg = _segments(location);
  if (seg.length == 1 && seg.first == 'distributors') {
    return '/distributors/${p.distributorId}';
  }
  return null;
}

/// Arabic reason [location] is refused for [p], or null when allowed.
String? routeDenial(AppPermissions p, String location) {
  if (p.legacy || p.isOwner) return null;
  final seg = _segments(location);
  final path = '/${seg.join('/')}';
  if (kAlwaysAllowedPaths.contains(path)) return null;
  // A distributor login: its own page (and the list, which redirects to
  // it) opens whatever its role keys say — the server scopes the data to
  // that distributor; another distributor's page never opens.
  if (_ownDistributorKnown(p) && seg.isNotEmpty && seg.first == 'distributors') {
    if (seg.length == 1) return null;
    if (seg.length == 2 && seg[1] != 'new') {
      return seg[1] == '${p.distributorId}' ? null : kOtherDistributorPage;
    }
  }
  final req = routeRequirementFor(location);
  if (req == null) {
    return p.isDistributor ? 'هذه الصفحة غير متاحة لحساب الموزّع.' : null;
  }
  final denied = req.denial(p);
  if (denied != null) return denied;
  // The tools screen with a known per-tool map that allows nothing.
  if (path == '/tools' && p.tools != null && !kToolKeys.any(p.canTool)) {
    return kNoToolAllowed;
  }
  return null;
}

bool routeAllowed(AppPermissions p, String location) =>
    routeDenial(p, location) == null;
