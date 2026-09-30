import 'permissions.dart';
import 'route_permissions.dart';

/// Router-side permission gate.
///
/// A screen the admin may not open redirects to `/no-access` — BEFORE its
/// form is built. The router re-runs this check whenever the grants change
/// (session restore, a refresh after a 403, app resume), so a screen opened
/// on the provisional (saved) grants — or one the owner revoked meanwhile —
/// is closed as soon as the server's grants say so (f07 N-B1: forbidden
/// forms stayed open after /me arrived). A screen that is STILL allowed is
/// not touched: the router keeps the same page, so a half-filled form keeps
/// its input.
///
/// While the grants are unknown ([AppPermissions.pending], a session
/// restore without a saved copy) nothing is redirected: the location is
/// kept and the shell shows a neutral loading state instead of the screen.
class PermissionRouteGate {
  String? _current;

  /// The location currently on display (last one this gate allowed).
  String? get current => _current;

  String? redirect(AppPermissions perms, String location) {
    if (perms.pending) return null;
    final own = distributorOwnPageRedirect(perms, location);
    if (own != null) return own;
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
