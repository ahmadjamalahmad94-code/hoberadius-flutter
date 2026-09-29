import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/admin_control/application/admin_control_controller.dart';
import '../../features/cards/application/card_checker_controller.dart';
import '../../features/notifications/application/notifications_providers.dart';
import '../../features/plans/application/plan_form_controller.dart';
import '../../features/print_templates/application/print_templates_controller.dart';
import '../../features/provider_grants/application/provider_grants_provider.dart';
import '../../features/subscribers/application/subscriber_form_controller.dart';
import '../router/nav_history.dart';

/// App-wide (non-autoDispose) providers that hold data of the signed-in
/// admin. Screen lists are autoDispose and die with the shell at sign-out;
/// these outlive it, so a second account on the same phone would briefly
/// see the first one's notifications, last checked card, form errors or
/// navigation history. Invalidated at every sign-in / sign-out.
final List<ProviderOrFamily> kSessionScopedProviders = [
  notificationCenterProvider,
  notificationsPollerProvider,
  providerGrantsProvider,
  cardCheckerControllerProvider,
  subscriberFormActionProvider,
  planFormActionProvider,
  adminControlControllerProvider,
  printTemplatesActionProvider,
  navHistoryProvider,
];

/// Forget everything the previous account loaded (see
/// [kSessionScopedProviders]). Never throws.
void resetSessionScopedState(Ref ref) {
  for (final p in kSessionScopedProviders) {
    try {
      ref.invalidate(p);
    } catch (_) {/* container disposed */}
  }
}
