import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/permissions.dart';
import '../../core/auth/route_permissions.dart';
import '../../shared/widgets/empty_state.dart';

/// Shown instead of a screen the signed-in admin may not open (a deep link
/// from a notification, an old bookmark, a hidden menu entry): the reason
/// in Arabic — never a form that would refuse the save after it is filled.
class NoAccessScreen extends ConsumerWidget {
  const NoAccessScreen({super.key, this.from = ''});

  /// The refused location (`?from=`).
  final String from;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perms = ref.watch(permissionsProvider);
    final reason = from.isEmpty ? null : routeDenial(perms, from);
    return EmptyState(
      icon: Icons.lock_outline,
      title: 'لا تملك صلاحية فتح هذه الصفحة',
      subtitle: reason ??
          'اطلب من المالك منحك الصلاحية ثم أعد المحاولة.',
      action: FilledButton.icon(
        onPressed: () => context.go('/'),
        icon: const Icon(Icons.home_outlined),
        label: const Text('العودة للرئيسية'),
      ),
    );
  }
}
