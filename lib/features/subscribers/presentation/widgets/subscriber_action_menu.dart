import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/subscriber_model.dart';
import 'subscriber_actions_sheet.dart';

/// ⋮ button of the edit screen: opens the same grouped actions sheet as the
/// list («تفعيل» / «إدارية») for the subscriber being edited.
class SubscriberActionMenu extends ConsumerWidget {
  const SubscriberActionMenu({
    super.key,
    required this.subscriber,
    this.enabled = true,
    this.onChanged,
    this.onRenamed,
    this.onArchived,
  });

  /// Current state of the subscriber (read when the button is pressed).
  final Subscriber Function() subscriber;
  final bool enabled;
  final VoidCallback? onChanged;
  final ValueChanged<String>? onRenamed;
  final VoidCallback? onArchived;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      tooltip: 'إجراءات',
      icon: const Icon(Icons.more_vert),
      onPressed: !enabled
          ? null
          : () => showSubscriberActionsSheet(
                context,
                ref,
                subscriber: subscriber(),
                onChanged: onChanged,
                onRenamed: onRenamed,
                onArchived: onArchived,
              ),
    );
  }
}
