/// Dart mirror of the `GET /api/v1/provider/grants` contract
/// (radius-module: app/api/v1/provider_grants.py, schema_version 2).
///
/// The provider (license panel) issues each tenant a capacity contract. This
/// endpoint exposes the same decision the web admin's gate makes, so the
/// Flutter client can apply it identically:
///   • license lifecycle screens (activate / expired / active),
///   • hide disabled sections from the nav,
///   • keep locked-upgrade services visible with a «طلب تفعيل» badge,
///   • block "create" when a granted quantity cap is reached,
///   • distinguish a transient sync outage (fail-open) from a definitive
///     expiry/never-activated (fail-closed).
library;

/// License lifecycle state — mirror of `LifecycleState` in
/// license_lifecycle.py. [blocksPanel] mirrors the server property.
enum LicenseState {
  active,
  neverActivated,
  expired,
  syncOutageInGrace,
  syncOutageBeyondGrace,
  unknown;

  static LicenseState parse(Object? raw) {
    switch ((raw ?? '').toString().trim().toLowerCase()) {
      case 'active':
        return LicenseState.active;
      case 'never_activated':
        return LicenseState.neverActivated;
      case 'expired':
        return LicenseState.expired;
      case 'sync_outage_in_grace':
        return LicenseState.syncOutageInGrace;
      case 'sync_outage_beyond_grace':
        return LicenseState.syncOutageBeyondGrace;
      default:
        return LicenseState.unknown;
    }
  }

  /// True when the panel must be blocked (definitive lockout). Matches the
  /// server's `LifecycleState.blocks_panel`: never_activated / expired /
  /// sync_outage_beyond_grace. A sync outage *within* grace stays open
  /// (fail-open / last-known-good).
  bool get blocksPanel =>
      this == LicenseState.neverActivated ||
      this == LicenseState.expired ||
      this == LicenseState.syncOutageBeyondGrace;
}

/// The `license` block of the grants payload.
class LicenseStatus {
  const LicenseStatus({
    required this.state,
    required this.blocksPanel,
    this.status = '',
    this.reason = '',
    this.expiresAt,
    this.graceUntil,
    this.fetchedAt,
    this.staleDays = 0,
    this.graceRemainingDays = 0,
  });

  final LicenseState state;

  /// The server's own `blocks_panel` flag. We trust it over deriving from
  /// [state] so future server states stay correct, but [state.blocksPanel]
  /// agrees for all current states.
  final bool blocksPanel;
  final String status; // raw provider status
  final String reason; // diagnostic code
  final String? expiresAt; // ISO
  final String? graceUntil; // ISO
  final String? fetchedAt; // ISO last successful sync
  final double staleDays;
  final double graceRemainingDays;

  static const active = LicenseStatus(
    state: LicenseState.active,
    blocksPanel: false,
  );

  factory LicenseStatus.fromJson(Map<String, dynamic> json) {
    return LicenseStatus(
      state: LicenseState.parse(json['state']),
      blocksPanel: json['blocks_panel'] == true,
      status: (json['status'] ?? '').toString(),
      reason: (json['reason'] ?? '').toString(),
      expiresAt: _str(json['expires_at']),
      graceUntil: _str(json['grace_until']),
      fetchedAt: _str(json['fetched_at']),
      staleDays: _double(json['stale_days']),
      graceRemainingDays: _double(json['grace_remaining_days']),
    );
  }
}

/// One service grant — mirror of `provider_grant.list_all_grants` rows.
class ServiceGrant {
  const ServiceGrant({
    required this.key,
    this.present = false,
    this.enabled = true,
    this.status = 'active',
    this.featureState = 'enabled',
    this.disabled = false,
    this.requiresUpgrade = false,
    this.readonly = false,
    this.hiddenPortal = false,
    this.hiddenFromPortalEffective = false,
  });

  final String key;
  final bool present;
  final bool enabled;
  final String status;
  final String featureState;

  /// Hard suspend (super-admin can't bypass). Hidden from nav + deep-link
  /// shows «الخدمة موقوفة من المزوّد». Includes feature_state locked/hidden.
  final bool disabled;

  /// Paid-not-active. Stays visible in nav with a «طلب تفعيل» badge; deep-link
  /// routes to the activation request screen.
  final bool requiresUpgrade;
  final bool readonly;
  final bool hiddenPortal;
  final bool hiddenFromPortalEffective;

  /// «مخفية كليًّا» — feature explicitly hidden. The owner wants these simply
  /// not shown (الجهات). In the contract a hidden feature_state already implies
  /// [disabled]; this exposes the distinction for labelling/tests.
  bool get fullyHidden => featureState.trim().toLowerCase() == 'hidden';

  factory ServiceGrant.fromJson(Map<String, dynamic> json) {
    return ServiceGrant(
      key: (json['key'] ?? '').toString().trim().toLowerCase(),
      present: json['present'] == true,
      enabled: json['enabled'] != false,
      status: (json['status'] ?? 'active').toString(),
      featureState: (json['feature_state'] ?? 'enabled').toString(),
      disabled: json['disabled'] == true,
      requiresUpgrade: json['requires_upgrade'] == true,
      readonly: json['readonly'] == true,
      hiddenPortal: json['hidden_portal'] == true,
      hiddenFromPortalEffective:
          json['hidden_from_portal_effective'] == true,
    );
  }
}

/// One quantity cap — mirror of the `limits[feature_key]` block.
class GrantLimit {
  const GrantLimit({
    required this.featureKey,
    this.current = 0,
    this.limit,
    this.remaining,
    this.limitPath = '',
    this.usageMetric,
  });

  final String featureKey;
  final int current;
  final int? limit; // null = no cap
  final int? remaining; // null = no cap
  final String limitPath;
  final String? usageMetric;

  bool get hasCap => limit != null;
  bool get atCap => limit != null && current >= limit!;

  factory GrantLimit.fromJson(String key, Map<String, dynamic> json) {
    return GrantLimit(
      featureKey: key,
      current: _int(json['current']),
      limit: json['limit'] == null ? null : _int(json['limit']),
      remaining: json['remaining'] == null ? null : _int(json['remaining']),
      limitPath: (json['limit_path'] ?? '').toString(),
      usageMetric: _str(json['usage_metric']),
    );
  }
}

/// Sync freshness — lets the client tell transient outages from definitive.
class SyncInfo {
  const SyncInfo({
    this.hasSnapshot = false,
    this.stale = false,
    this.staleDays = 0,
    this.graceDays = 0,
    this.graceRemainingDays = 0,
  });

  final bool hasSnapshot;
  final bool stale;
  final double staleDays;
  final double graceDays;
  final double graceRemainingDays;

  factory SyncInfo.fromJson(Map<String, dynamic> json) {
    return SyncInfo(
      hasSnapshot: json['has_snapshot'] == true,
      stale: json['stale'] == true,
      staleDays: _double(json['stale_days']),
      graceDays: _double(json['grace_days']),
      graceRemainingDays: _double(json['grace_remaining_days']),
    );
  }
}

/// The full decoded grants payload (`data` of the envelope).
class ProviderGrants {
  ProviderGrants({
    required this.license,
    required this.services,
    required this.limits,
    required this.hasSnapshot,
    required this.sync,
    this.schemaVersion = 2,
  }) : _byKey = {for (final s in services) s.key: s};

  final LicenseStatus license;
  final List<ServiceGrant> services;
  final Map<String, GrantLimit> limits;
  final bool hasSnapshot;
  final SyncInfo sync;
  final int schemaVersion;

  final Map<String, ServiceGrant> _byKey;

  /// Permissive default used when no snapshot exists / fetch failed with no
  /// last-known-good: everything allowed, license active (fail-open).
  static final ProviderGrants permissive = ProviderGrants(
    license: LicenseStatus.active,
    services: const [],
    limits: const {},
    hasSnapshot: false,
    sync: const SyncInfo(),
  );

  ServiceGrant? service(String key) => _byKey[key.trim().toLowerCase()];

  /// Disabled (hard suspend or hidden). Unknown keys default to allowed.
  bool isDisabled(String key) => service(key)?.disabled ?? false;

  /// Paid-not-active (visible with badge, routes to activation request).
  bool requiresUpgrade(String key) => service(key)?.requiresUpgrade ?? false;

  /// Fully hidden (feature_state == hidden) — simply not shown.
  bool isFullyHidden(String key) => service(key)?.fullyHidden ?? false;

  GrantLimit? limit(String key) => limits[key.trim().toLowerCase()];

  factory ProviderGrants.fromJson(Map<String, dynamic> json) {
    final servicesRaw = json['services'];
    final services = <ServiceGrant>[];
    if (servicesRaw is List) {
      for (final e in servicesRaw) {
        if (e is Map) {
          services.add(
            ServiceGrant.fromJson(
              e.map((k, v) => MapEntry(k.toString(), v)),
            ),
          );
        }
      }
    }
    final limitsRaw = json['limits'];
    final limits = <String, GrantLimit>{};
    if (limitsRaw is Map) {
      limitsRaw.forEach((k, v) {
        if (v is Map) {
          final key = k.toString().trim().toLowerCase();
          limits[key] = GrantLimit.fromJson(
            key,
            v.map((kk, vv) => MapEntry(kk.toString(), vv)),
          );
        }
      });
    }
    final licenseRaw = json['license'];
    final syncRaw = json['sync'];
    return ProviderGrants(
      license: licenseRaw is Map
          ? LicenseStatus.fromJson(
              licenseRaw.map((k, v) => MapEntry(k.toString(), v)),
            )
          : LicenseStatus.active,
      services: services,
      limits: limits,
      hasSnapshot: json['has_snapshot'] == true,
      sync: syncRaw is Map
          ? SyncInfo.fromJson(syncRaw.map((k, v) => MapEntry(k.toString(), v)))
          : const SyncInfo(),
      schemaVersion: _int(json['schema_version'], 2),
    );
  }
}

// ── tiny coercion helpers ──────────────────────────────────────────────
String? _str(Object? v) {
  if (v == null) return null;
  final s = v.toString().trim();
  return s.isEmpty ? null : s;
}

int _int(Object? v, [int fallback = 0]) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? fallback;
  return fallback;
}

double _double(Object? v, [double fallback = 0]) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? fallback;
  return fallback;
}
