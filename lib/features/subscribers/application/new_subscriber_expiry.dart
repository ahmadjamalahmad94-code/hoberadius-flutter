import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/auth/permissions.dart';
import '../../../core/auth/system_settings.dart';

/// Hint under the «مشترك جديد» expiry when NO date is chosen and the server
/// creates such a subscriber born expired (`create_without_expiry=expired`,
/// the default).
const kNoExpiryHintExpired = 'سيُنشأ المشترك منتهيًا حتى تجدّده';

/// Same when the server creates it without an expiry (`unlimited`).
const kNoExpiryHintUnlimited = 'بلا تاريخ انتهاء';

/// Label of the explicit choice (sends `expire_at: null`).
const kExplicitNoExpiryLabel = 'بدون انتهاء';

/// Hint once «بدون انتهاء» is chosen explicitly.
const kExplicitNoExpiryHint =
    'لن ينتهي هذا المشترك — يُرسَل «بدون انتهاء» صراحةً.';

/// Field text while no date is chosen (the server rule applies).
const kExpiryNotChosen = 'لم يُحدَّد';

/// The hint for a create form with no date: the server's rule [mode]
/// («expired» / «unlimited»), the explicit choice, or null when the server
/// did not say (older server: the field keeps its old «بدون انتهاء»).
String? newSubscriberExpiryHint({
  required String? mode,
  required bool explicitNoExpiry,
}) {
  if (mode == null) return null;
  if (explicitNoExpiry) return kExplicitNoExpiryHint;
  return switch (mode) {
    kCreateWithoutExpiryExpired => kNoExpiryHintExpired,
    kCreateWithoutExpiryUnlimited => kNoExpiryHintUnlimited,
    _ => null,
  };
}

/// The server's `create_without_expiry` for the «مشترك جديد» form: the
/// session value (from /me or /settings); when unknown on a server that
/// speaks the permission contract, one background read of /api/admin/me.
/// Null = an older server (an omitted expiry means «no expiry» there).
final newSubscriberExpiryModeProvider =
    FutureProvider.autoDispose<String?>((ref) async {
  final known = ref.watch(createWithoutExpiryProvider);
  if (known != null) return known;
  final legacy = ref.watch(permissionsProvider.select((p) => p.legacy));
  if (legacy) return null;
  try {
    final res = await ref
        .read(apiClientProvider)
        .get('/api/admin/me', background: true);
    final d = res['data'];
    return d is Map<String, dynamic> ? createWithoutExpiryOf(d) : null;
  } catch (_) {
    return null;
  }
});
