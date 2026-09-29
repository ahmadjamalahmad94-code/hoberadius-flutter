import 'permissions.dart';
import 'route_permissions.dart';

/// Router-side permission gate.
///
/// A screen the admin may not open redirects to `/no-access` — BEFORE its
/// form is built. It never evicts the screen already on display: when the
/// grants are re-read (after a 403, on resume) the router re-runs its
/// redirect for the current location, and throwing the admin out of a
/// half-filled form would lose the typed input. That form shows the
/// server's Arabic refusal instead and keeps its fields.
class PermissionRouteGate {
  String? _current;

  /// The location currently on display (last one this gate allowed).
  String? get current => _current;

  String? redirect(AppPermissions perms, String location) {
    if (location == _current) return null;
    final denied = routeDenial(perms, location);
    if (denied == null) {
      _current = location;
      return null;
    }
    return Uri(path: '/no-access', queryParameters: {'from': location})
        .toString();
  }

  void reset() => _current = null;
}
