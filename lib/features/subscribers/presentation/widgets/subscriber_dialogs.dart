import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';

/// Shared chrome for the subscriber prompts: a tinted icon chip beside the
/// title, tight padding, and an outlined «إلغاء» + filled confirm button that
/// split the width evenly. Opened on the ROOT navigator — the shell pages
/// live inside one scroll view, so an inner-navigator dialog could render
/// off-screen.
Future<bool?> _showSubscriberDialog(
  BuildContext context, {
  required IconData icon,
  required Color color,
  required String title,
  required Widget content,
  required String confirmLabel,
}) {
  return showDialog<bool>(
    context: context,
    useRootNavigator: true,
    builder: (ctx) {
      final text = Theme.of(ctx).textTheme;
      final btnText = text.labelLarge?.copyWith(fontWeight: FontWeight.w800);
      final shape = RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.s12),
      );
      return AlertDialog(
        titlePadding: const EdgeInsets.fromLTRB(
          AppTokens.s20,
          AppTokens.s20,
          AppTokens.s20,
          AppTokens.s8,
        ),
        contentPadding: const EdgeInsets.fromLTRB(
          AppTokens.s20,
          AppTokens.s8,
          AppTokens.s20,
          AppTokens.s8,
        ),
        actionsPadding: const EdgeInsets.fromLTRB(
          AppTokens.s20,
          AppTokens.s8,
          AppTokens.s20,
          AppTokens.s16,
        ),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppTokens.r10),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: AppTokens.s12),
            Expanded(
              child: Text(
                title,
                style: text.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppTokens.sidebarBg,
                ),
              ),
            ),
          ],
        ),
        content: content,
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                    shape: shape,
                    textStyle: btnText,
                  ),
                  child: const Text('إلغاء'),
                ),
              ),
              const SizedBox(width: AppTokens.s8),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: FilledButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(44),
                    shape: shape,
                    textStyle: btnText,
                  ),
                  child: Text(confirmLabel),
                ),
              ),
            ],
          ),
        ],
      );
    },
  );
}

/// Prompts the operator for an extension duration in minutes. Resolves
/// with the parsed value, or `null` on cancel / invalid input.
Future<int?> askExtendMinutes(BuildContext context) async {
  final ctrl = TextEditingController(text: '60');
  final ok = await _showSubscriberDialog(
    context,
    icon: Icons.more_time_outlined,
    color: AppTokens.greenInk,
    title: 'تمديد الاشتراك',
    confirmLabel: 'تمديد',
    content: TextField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(
        labelText: 'الدقائق',
        hintText: 'مثال: 1440 (يوم)',
      ),
      autofocus: true,
    ),
  );
  if (ok != true) return null;
  final mins = int.tryParse(ctrl.text.trim());
  return (mins == null || mins <= 0) ? null : mins;
}

/// Prompts for a new password. Resolves with the entered string, or
/// `null` on cancel / empty input.
Future<String?> askNewPassword(BuildContext context) async {
  final ctrl = TextEditingController();
  final ok = await _showSubscriberDialog(
    context,
    icon: Icons.password_outlined,
    color: AppTokens.blue,
    title: 'إعادة تعيين كلمة المرور',
    confirmLabel: 'تعيين',
    content: TextField(
      controller: ctrl,
      obscureText: true,
      decoration: const InputDecoration(labelText: 'كلمة المرور الجديدة'),
      autofocus: true,
    ),
  );
  if (ok != true) return null;
  final pw = ctrl.text;
  return pw.isEmpty ? null : pw;
}

/// Permanent-delete confirmation. Returns `true` only on explicit
/// confirm.
Future<bool> confirmDeleteSubscriber(
  BuildContext context,
  String username,
) async {
  final ok = await _showSubscriberDialog(
    context,
    icon: Icons.delete_outline,
    color: AppTokens.red,
    title: 'حذف المشترك',
    confirmLabel: 'حذف',
    content: Text('سيُحذف "$username" نهائيًا. متأكّد؟'),
  );
  return ok == true;
}
