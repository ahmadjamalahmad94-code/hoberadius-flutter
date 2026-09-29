import 'package:flutter_riverpod/flutter_riverpod.dart';

/// `system.create_without_expiry` values (fix2-final): what creating a
/// subscriber WITHOUT an expiry means on this server.
const kCreateWithoutExpiryExpired = 'expired';
const kCreateWithoutExpiryUnlimited = 'unlimited';

/// `system.create_without_expiry` of an /api/admin/me or /api/v1/settings
/// payload («expired» — the default — or «unlimited»); also the raw
/// `settings['subscribers.create_without_expiry']` of the settings API.
/// Null when absent (an older server: an omitted expiry meant «no expiry»).
String? createWithoutExpiryOf(Map<String, dynamic> data) {
  String? norm(Object? v) {
    final s = '${v ?? ''}'.trim().toLowerCase();
    return s == kCreateWithoutExpiryExpired ||
            s == kCreateWithoutExpiryUnlimited
        ? s
        : null;
  }

  final system = data['system'];
  if (system is Map) {
    final v = norm(system['create_without_expiry']);
    if (v != null) return v;
  }
  final settings = data['settings'];
  if (settings is Map) {
    return norm(settings['subscribers.create_without_expiry']);
  }
  return null;
}

/// The server's `create_without_expiry` for this session (null = unknown /
/// older server). Published at sign-in and session restore, refreshed with
/// the grants, cleared at sign-out.
final createWithoutExpiryProvider = StateProvider<String?>((ref) => null);

/// Publishes the mode of [data] when it carries one (never clears a known
/// value on a payload that lacks it).
void publishCreateWithoutExpiry(Ref ref, Map<String, dynamic> data) {
  final mode = createWithoutExpiryOf(data);
  if (mode == null) return;
  try {
    ref.read(createWithoutExpiryProvider.notifier).state = mode;
  } catch (_) {/* container disposed */}
}
