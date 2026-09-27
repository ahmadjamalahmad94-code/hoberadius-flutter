import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shell/navigation_schema.dart';
import '../domain/provider_grants_model.dart';
import '../domain/provider_grants_nav_map.dart';
import 'provider_grants_provider.dart';

/// A nav item annotated with its provider-grant decision, so the sidebar can
/// drop disabled/hidden items and badge locked-upgrade ones.
class GatedNavItem {
  const GatedNavItem({required this.item, required this.requiresUpgrade});
  final AppNavItem item;

  /// Paid-not-active: keep visible with a «طلب تفعيل» badge (web parity).
  final bool requiresUpgrade;
}

/// A section whose items have been filtered/annotated by grants.
class GatedNavSection {
  const GatedNavSection({required this.section, required this.items});
  final AppNavSection section;
  final List<GatedNavItem> items;
}

/// Filters [appNavSections] through the current grants:
///   • drop items whose service is `disabled` or fully `hidden`,
///   • keep `locked_upgrade` items (flagged for a badge),
///   • drop a section once all its items are gone.
/// Never-gated routes (dashboard/account/license/bridge/tools/…) always stay.
List<GatedNavSection> gatedNavSections(ProviderGrants grants) {
  final out = <GatedNavSection>[];
  for (final section in appNavSections) {
    final items = <GatedNavItem>[];
    for (final item in section.items) {
      final key = serviceKeyForLocation(item.path);
      if (key == null) {
        items.add(GatedNavItem(item: item, requiresUpgrade: false));
        continue;
      }
      final svc = grants.service(key);
      if (svc == null) {
        items.add(GatedNavItem(item: item, requiresUpgrade: false));
        continue;
      }
      if (svc.disabled || svc.fullyHidden) continue; // hidden from nav
      items.add(GatedNavItem(item: item, requiresUpgrade: svc.requiresUpgrade));
    }
    if (items.isNotEmpty) {
      out.add(GatedNavSection(section: section, items: items));
    }
  }
  return out;
}

/// Reactive view of the gated sidebar sections.
final gatedNavSectionsProvider = Provider<List<GatedNavSection>>((ref) {
  return gatedNavSections(ref.watch(effectiveGrantsProvider));
});
