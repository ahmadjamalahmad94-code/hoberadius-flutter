import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/admins/domain/permission_labels.dart';
import '../api/api_client.dart';

/// Section states of the server's per-manager grants (`grants.sections`).
const kSectionOpen = 'open';
const kSectionLocked = 'locked';
const kSectionHidden = 'hidden';

/// Arabic names of the server's manager sections (MANAGER_SECTION_REGISTRY).
const kSectionLabels = <String, String>{
  'subscribers': 'المشتركون',
  'sessions': 'الجلسات / المتصلون',
  'cards': 'البطاقات',
  'plans': 'الباقات والسرعات',
  'distributors': 'الموزّعون',
  'network': 'الشبكة والراوترات',
  'reports': 'التقارير',
  'finance': 'المال والمحاسبة',
  'communications': 'الاتصالات والحملات',
  'store': 'المتجر الإلكتروني',
};

/// Fallback for an action the server's `grants.actions` does not list (an
/// older permmodel build): the RBAC key the server derives it from
/// (`manager_grants._ACTION_RBAC`). A tuple = any one is enough.
const kActionRbac = <String, List<String>>{
  'subscriber.create': ['users.create'],
  'subscriber.delete': ['users.delete'],
  'subscriber.status': ['users.change_status'],
  'subscriber.extend': ['users.extend'],
  'subscriber.renew': ['users.change_plan'],
  'subscriber.quota': ['users.quota'],
  'subscriber.balance_add': ['users.balance_add'],
  'subscriber.payment': ['users.payments'],
  'subscriber.loan': ['users.loans'],
  'subscriber.send_credentials': ['users.send_message'],
  'cards.generate': ['cards.generate'],
  'cards.import': ['cards.import'],
  'cards.revoke': ['cards.revoke'],
  'cards.batch_ops': ['cards.batch_ops'],
  'cards.recharge': ['cards.recharge'],
  'cards.print': ['cards.print'],
  'batch.edit': ['cards.edit_batch'],
  'plan.create': ['plans.create'],
  'plan.edit': ['plans.edit'],
  'plan.delete': ['plans.delete'],
  'data.export': ['users.export'],
  'session.disconnect': ['online.disconnect'],
  'session.force_close': ['online.disconnect'],
  'session.reconcile': ['online.disconnect'],
  'session.lock_mac': ['online.lock_mac'],
  'session.lock_ip': ['online.lock_ip'],
  'session.edit': ['online.lock_ip', 'users.temp_speed'],
  'session.temp_speed': ['users.temp_speed'],
  'comms.sms': ['users.send_message'],
  'comms.templates': ['users.send_message'],
  'comms.whatsapp': ['settings.edit'],
  'store.deposit_approve': ['store.review'],
  'store.withdraw_approve': ['store.review'],
  'storeuser.create': ['store.user_add'],
  'storeuser.edit': ['store.user_recharge', 'store.user_purchase'],
  'storeuser.password': ['store.user_edit'],
  'storeuser.delete': ['store.user_delete'],
  'distributor.manage': ['reports.finance'],
};

/// The section a server action belongs to (ACTION_REGISTRY `section`).
const kActionSection = <String, String>{
  'subscriber.create': 'subscribers',
  'subscriber.delete': 'subscribers',
  'subscriber.status': 'subscribers',
  'subscriber.extend': 'subscribers',
  'subscriber.renew': 'subscribers',
  'subscriber.quota': 'subscribers',
  'subscriber.balance_add': 'subscribers',
  'subscriber.payment': 'subscribers',
  'subscriber.loan': 'subscribers',
  'subscriber.send_credentials': 'subscribers',
  'bulk.ops': 'subscribers',
  'cards.generate': 'cards',
  'cards.import': 'cards',
  'cards.revoke': 'cards',
  'cards.batch_ops': 'cards',
  'cards.recharge': 'cards',
  'cards.print': 'cards',
  'batch.edit': 'cards',
  'plan.create': 'plans',
  'plan.edit': 'plans',
  'plan.delete': 'plans',
  'distributor.manage': 'distributors',
  'session.disconnect': 'sessions',
  'session.force_close': 'sessions',
  'session.reconcile': 'sessions',
  'session.lock_mac': 'sessions',
  'session.lock_ip': 'sessions',
  'session.edit': 'sessions',
  'session.temp_speed': 'sessions',
  'comms.sms': 'communications',
  'comms.templates': 'communications',
  'store.deposit_approve': 'store',
  'store.withdraw_approve': 'store',
  'storeuser.create': 'store',
  'storeuser.edit': 'store',
  'storeuser.password': 'store',
  'storeuser.delete': 'store',
};

/// The signed-in admin's effective permissions, from `/api/admin/me` (or the
/// login answer): RBAC keys, per-manager grants (actions / sections /
/// view-all) and the owner flags.
///
/// **Older servers** (no `grants`, no `admin.is_owner`) → [legacy]: every
/// check answers "allowed", i.e. the app behaves exactly as before the
/// permission contract (the server still refuses what it refuses).
class AppPermissions {
  const AppPermissions({
    this.legacy = true,
    this.loaded = false,
    this.isOwner = false,
    this.isCoOwner = false,
    this.isOriginalOwner = false,
    this.isSuperAdmin = false,
    this.isDistributor = false,
    this.adminId,
    this.permissions = const <String>{},
    this.actions = const <String, bool>{},
    this.sections = const <String, String>{},
    this.viewAllSubscribers = true,
  });

  /// Nothing known yet (signed out / before the first /me): permissive.
  static const unknown = AppPermissions();

  /// Parses an `/api/admin/me` or `/api/admin/login` `data` payload.
  factory AppPermissions.fromMe(Map<String, dynamic> data) {
    final admin = data['admin'] is Map ? data['admin'] as Map : const {};
    final grants = data['grants'];
    final hasContract = grants is Map || admin.containsKey('is_owner');
    if (!hasContract) {
      return AppPermissions(
        loaded: true,
        adminId: _int(admin['id']),
        isSuperAdmin: admin['is_super_admin'] == true,
        permissions: _keys(data['permissions']),
      );
    }
    final g = grants is Map ? grants : const {};
    final rawActions = g['actions'];
    final rawSections = g['sections'];
    final isOwner = admin['is_owner'] == true;
    return AppPermissions(
      legacy: false,
      loaded: true,
      adminId: _int(admin['id']),
      isOwner: isOwner,
      isCoOwner: admin['is_co_owner'] == true,
      isOriginalOwner: admin['is_original_owner'] == true,
      isSuperAdmin: admin['is_super_admin'] == true,
      isDistributor: admin['is_distributor'] == true ||
          (_int(admin['distributor_id']) ?? 0) > 0 ||
          g['distributor'] is Map ||
          g['is_distributor'] == true,
      permissions: _keys(data['permissions']),
      actions: {
        if (rawActions is Map)
          for (final e in rawActions.entries) '${e.key}': e.value == true,
      },
      sections: {
        if (rawSections is Map)
          for (final e in rawSections.entries)
            '${e.key}': '${e.value ?? ''}'.trim().toLowerCase(),
      },
      viewAllSubscribers: isOwner || g['view_all_subscribers'] == true,
    );
  }

  static int? _int(Object? v) =>
      v is int ? v : (v is num ? v.toInt() : int.tryParse('${v ?? ''}'));

  static Set<String> _keys(Object? v) =>
      v is List ? {for (final k in v) '$k'} : const <String>{};

  /// The server does not send the permission contract (or we are signed
  /// out): allow everything, like the app did before.
  final bool legacy;

  /// A /me (or login) payload has been applied.
  final bool loaded;

  /// Owner or co-owner (`admin.is_owner`) — bypasses every check.
  final bool isOwner;
  final bool isCoOwner;

  /// The protected original owner (never editable by anyone else).
  final bool isOriginalOwner;

  /// «مدير عام / سوبر يوزر»: has the super_admin role (all non-owner keys).
  final bool isSuperAdmin;

  /// A distributor login (only when the server says so).
  final bool isDistributor;
  final int? adminId;
  final Set<String> permissions;
  final Map<String, bool> actions;
  final Map<String, String> sections;
  final bool viewAllSubscribers;

  /// Everything allowed: an older server, or the owner / a co-owner.
  bool get _all => legacy || isOwner;

  /// Owner or co-owner — the only ones who see settings, backups, tokens,
  /// ledger void, data reset and the co-owner / super-user toggles. On an
  /// older server (no contract) the app keeps its old behaviour (true).
  bool get isOwnerLike => _all;

  /// The server knows the co-owner / super-user contract (permmodel).
  bool get supportsOwnerContract => !legacy;

  /// Holds the RBAC key [key] (`users.create`, `cards.view`…).
  bool can(String key) => _all || permissions.contains(key);

  /// Holds at least one of [keys] (an empty list = no requirement).
  bool canAny(Iterable<String> keys) {
    if (_all) return true;
    var any = false;
    for (final k in keys) {
      any = true;
      if (permissions.contains(k)) return true;
    }
    return !any;
  }

  /// `open` / `locked` / `hidden` for a manager section (open when unknown).
  String sectionState(String section) {
    if (_all) return kSectionOpen;
    final s = sections[section];
    return (s == kSectionLocked || s == kSectionHidden) ? s! : kSectionOpen;
  }

  /// The section is visible (open or read-only).
  bool canSection(String section) => sectionState(section) != kSectionHidden;

  /// The section accepts writes (not locked, not hidden).
  bool canWriteSection(String section) =>
      sectionState(section) == kSectionOpen;

  /// The server's decision for an ACTION_REGISTRY key (`subscriber.create`,
  /// `cards.generate`, `session.disconnect`…), including its section state.
  bool canAction(String action) {
    if (_all) return true;
    final section = kActionSection[action];
    if (section != null && !canWriteSection(section)) return false;
    final decided = actions[action];
    if (decided != null) return decided;
    final rbac = kActionRbac[action];
    if (rbac != null) return canAny(rbac);
    return true;
  }

  /// Why [can] / [canAction] / a section refuses — an Arabic tooltip.
  String deniedReason({
    String? perm,
    List<String> anyOf = const [],
    String? action,
    String? section,
    bool ownerOnly = false,
  }) {
    if (ownerOnly && !isOwnerLike) {
      return 'متاح للمالك أو الشريك فقط.';
    }
    if (section != null) {
      final st = sectionState(section);
      final name = kSectionLabels[section] ?? section;
      if (st == kSectionHidden) return 'قسم «$name» مخفيّ عنك.';
      if (st == kSectionLocked) {
        return 'قسم «$name» للعرض فقط — لا تملك صلاحية التعديل.';
      }
    }
    if (action != null) {
      final sec = kActionSection[action];
      if (sec != null && !canWriteSection(sec)) {
        return deniedReason(section: sec);
      }
    }
    final keys = [if (perm != null) perm, ...anyOf];
    if (action != null && keys.isEmpty) {
      keys.addAll(kActionRbac[action] ?? const []);
    }
    final missing = keys.where((k) => !can(k)).toList();
    if (missing.isNotEmpty) {
      return 'لا تملك صلاحية «${permissionLabel(missing.first)}».';
    }
    return 'لا تملك صلاحية تنفيذ هذا الإجراء.';
  }
}

/// Holds [AppPermissions]; refreshed at sign-in / session restore (the auth
/// controller calls [apply]), on app resume, and after any 403.
class PermissionsController extends StateNotifier<AppPermissions> {
  PermissionsController(this._ref) : super(AppPermissions.unknown);

  final Ref _ref;
  DateTime? _lastRefresh;
  Future<void>? _inFlight;

  /// Minimum spacing between two refreshes (a burst of 403s = one /me).
  static const minInterval = Duration(seconds: 5);

  void apply(Map<String, dynamic> meData) {
    state = AppPermissions.fromMe(meData);
    _lastRefresh = DateTime.now();
  }

  /// Tests: pretend the last refresh is older than [minInterval].
  @visibleForTesting
  void debugExpireThrottle() => _lastRefresh = null;

  /// Signed out / switching account: forget every grant.
  void clear() {
    state = AppPermissions.unknown;
    _lastRefresh = null;
  }

  /// Re-reads `/api/admin/me`. Throttled unless [force]; never throws and
  /// never signs out (a 401 here is left to the next foreground call).
  Future<void> refresh({bool force = false}) {
    if (!state.loaded) return Future.value();
    final last = _lastRefresh;
    if (!force &&
        last != null &&
        DateTime.now().difference(last) < minInterval) {
      return Future.value();
    }
    return _inFlight ??= _doRefresh().whenComplete(() => _inFlight = null);
  }

  Future<void> _doRefresh() async {
    _lastRefresh = DateTime.now();
    final before = state.adminId;
    try {
      final res = await _ref
          .read(apiClientProvider)
          .get('/api/admin/me', background: true);
      final d = res['data'];
      if (!mounted || !state.loaded) return; // signed out meanwhile
      if (d is Map<String, dynamic>) {
        final next = AppPermissions.fromMe(d);
        // Another account signed in while this was in flight: keep its own.
        if (before != null && next.adminId != null && next.adminId != before) {
          return;
        }
        state = next;
      }
    } catch (_) {/* keep the last known grants */}
  }
}

final permissionsProvider =
    StateNotifierProvider<PermissionsController, AppPermissions>(
  PermissionsController.new,
);
