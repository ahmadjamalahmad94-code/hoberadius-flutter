import 'package:hoberadius_app/core/format/panel_time.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../../core/auth/permissions.dart';
import '../../../../core/auth/system_settings.dart';
import '../../../../core/theme/tokens.dart';
import '../../application/new_subscriber_expiry.dart';

/// Expiry = date AND time, like the web («تاريخ وساعة الانتهاء بالضبط»).
/// Picking a date then a time; a new date defaults to 23:59 (the old
/// «end of that day»). Shown and picked on the PANEL's clock (the tenant's
/// `billing.timezone`, labelled under the field); the model sends it as UTC.
class ExpirePicker extends StatelessWidget {
  const ExpirePicker({
    super.key,
    required this.value,
    required this.onChange,
    this.error,
    this.allowClear = true,
    this.emptyText = kExplicitNoExpiryLabel,
  });

  final DateTime? value;

  /// Offer the ✕ (clear the date) button — on the edit form only to admins
  /// allowed to set the expiry ([AppPermissions.canSetExpiry]).
  final bool allowClear;

  /// The field text while [value] is null.
  final String emptyText;

  /// The server's (or the form's) message about the expiry.
  final String? error;
  final ValueChanged<DateTime?> onChange;

  Future<void> _pick(BuildContext context) async {
    final base = value ?? panelNow().add(const Duration(days: 30));
    final day = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'تاريخ الانتهاء',
    );
    if (day == null || !context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: value == null
          ? const TimeOfDay(hour: 23, minute: 59)
          : TimeOfDay.fromDateTime(value!),
      helpText: 'ساعة الانتهاء',
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    final t = time ??
        (value == null
            ? const TimeOfDay(hour: 23, minute: 59)
            : TimeOfDay.fromDateTime(value!));
    onChange(
      DateTime(
        day.year,
        day.month,
        day.day,
        t.hour,
        t.minute,
        t.hour == 23 && t.minute == 59 ? 59 : 0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('yyyy-MM-dd  HH:mm', 'en');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _row(context, df),
        if (error != null && error!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              error!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTokens.red,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            PanelTimeZone.label(value),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTokens.textMuted,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ],
    );
  }

  Widget _row(BuildContext context, DateFormat df) {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(AppTokens.r10),
            onTap: () => _pick(context),
            child: InputDecorator(
              decoration: InputDecoration(
                errorText: error == null || error!.isEmpty ? null : '',
                errorStyle: const TextStyle(height: 0, fontSize: 0),
              ),
              child: Text(
                value == null ? emptyText : df.format(value!),
                textDirection: value == null ? null : TextDirection.ltr,
                textAlign: TextAlign.right,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppTokens.s8),
        IconButton(
          tooltip: 'اختيار التاريخ والساعة',
          onPressed: () => _pick(context),
          icon: const Icon(Icons.event_outlined),
        ),
        if (value != null && allowClear)
          IconButton(
            tooltip: emptyText,
            onPressed: () => onChange(null),
            icon: const Icon(Icons.clear),
          ),
      ],
    );
  }
}

/// The expiry of the subscriber form.
///
/// **Edit:** the [ExpirePicker] (its ✕ clears the date = «بدون انتهاء»,
/// offered only to admins allowed to set the expiry).
///
/// **Create (fix2-final):** no date chosen means the server's
/// `create_without_expiry` rule — the field says «لم يُحدَّد» with the
/// matching hint («سيُنشأ المشترك منتهيًا حتى تجدّده» / «بلا تاريخ انتهاء»).
/// An explicit «بدون انتهاء» choice (sends `expire_at: null`) is offered only
/// to admins allowed to set the expiry. An older server that does not send
/// the rule keeps the old field exactly («بدون انتهاء» when empty).
class SubscriberExpiryField extends ConsumerWidget {
  const SubscriberExpiryField({
    super.key,
    required this.isEdit,
    required this.value,
    required this.onChange,
    this.explicitNoExpiry = false,
    this.onExplicitNoExpiryChanged,
    this.error,
  });

  final bool isEdit;
  final DateTime? value;
  final ValueChanged<DateTime?> onChange;
  final bool explicitNoExpiry;
  final ValueChanged<bool>? onExplicitNoExpiryChanged;
  final String? error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canSet =
        ref.watch(permissionsProvider.select((p) => p.canSetExpiry));
    if (isEdit) {
      return ExpirePicker(
        value: value,
        onChange: onChange,
        error: error,
        allowClear: canSet,
      );
    }
    final mode = ref.watch(newSubscriberExpiryModeProvider).valueOrNull;
    if (mode == null) {
      // Older server: an omitted expiry already means «no expiry».
      return ExpirePicker(value: value, onChange: onChange, error: error);
    }
    final explicit = explicitNoExpiry && canSet && value == null;
    final hint = value == null
        ? newSubscriberExpiryHint(mode: mode, explicitNoExpiry: explicit)
        : null;
    final small = Theme.of(context).textTheme.bodySmall;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        ExpirePicker(
          value: value,
          onChange: (d) {
            if (d != null && explicitNoExpiry) {
              onExplicitNoExpiryChanged?.call(false);
            }
            onChange(d);
          },
          error: error,
          // ✕ on a chosen date = back to «not chosen» (the server rule).
          emptyText: explicit ? kExplicitNoExpiryLabel : kExpiryNotChosen,
        ),
        if (hint != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              hint,
              key: const ValueKey('new-subscriber-expiry-hint'),
              style: small?.copyWith(
                color: mode == kCreateWithoutExpiryExpired && !explicit
                    ? AppTokens.amberInk
                    : AppTokens.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        if (canSet && value == null)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: explicit
                ? TextButton.icon(
                    key: const ValueKey('new-subscriber-expiry-undo'),
                    onPressed: () => onExplicitNoExpiryChanged?.call(false),
                    icon: const Icon(Icons.undo, size: 18),
                    label: const Text('إلغاء «بدون انتهاء»'),
                  )
                : TextButton.icon(
                    key: const ValueKey('new-subscriber-no-expiry'),
                    onPressed: () => onExplicitNoExpiryChanged?.call(true),
                    icon: const Icon(Icons.all_inclusive, size: 18),
                    label: const Text(kExplicitNoExpiryLabel),
                  ),
          ),
      ],
    );
  }
}
