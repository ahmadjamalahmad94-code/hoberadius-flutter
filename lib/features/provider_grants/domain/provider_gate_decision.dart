import 'provider_grants_model.dart';
import 'provider_grants_nav_map.dart';

/// Pure provider-grant redirect decision (mirror of the web admin guard).
/// Returns the path to redirect to, or null to allow [location].
///
/// Fail-open: a null [grants] (no decision yet / fetch failed with no
/// last-known-good) always allows. Only a *successful* definitive lockout or an
/// explicit service disable/upgrade redirects.
String? providerGateRedirect(ProviderGrants? grants, String location) {
  if (grants == null) return null; // fail-open

  // (1) License lifecycle lockout — block everything except the renew/activate
  //     surfaces + license/bridge/account (so the owner can still fix it).
  if (grants.license.blocksPanel) {
    final allowed = location == '/license-file' ||
        location.startsWith('/license-file/') ||
        location == '/system-operations' ||
        location == '/account' ||
        location == '/license-expired' ||
        location == '/license-activate';
    if (allowed) return null;
    return grants.license.state == LicenseState.neverActivated
        ? '/license-activate'
        : '/license-expired';
  }

  // (2) Per-service gate. Never-gated routes always pass; unmapped/unknown
  //     keys default to allowed.
  if (isNeverGated(location)) return null;
  final key = serviceKeyForLocation(location);
  if (key == null) return null;
  final svc = grants.service(key);
  if (svc == null) return null;
  if (svc.disabled || svc.fullyHidden) {
    return '/service-blocked?service=$key';
  }
  if (svc.requiresUpgrade) {
    return '/service-upgrade?service=$key';
  }
  return null;
}
