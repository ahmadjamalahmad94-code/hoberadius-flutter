import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';

/// Prompts the operator for an extension duration in minutes. Resolves
/// with the parsed value, or `null` on cancel / invalid input.
Future<int?> askExtendMinutes(BuildContext context) async {
  final ctrl = TextEditingController(text: '60');
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('تمديد الاشتراك'),
      content: TextField(
        controller: ctrl,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          labelText: 'الدقائق',
          hintText: 'مثال: 1440 (يوم)',
        ),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('تمديد'),
        ),
      ],
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
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('إعادة تعيين كلمة المرور'),
      content: TextField(
        controller: ctrl,
        obscureText: true,
        decoration: const InputDecoration(labelText: 'كلمة المرور الجديدة'),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('تعيين'),
        ),
      ],
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
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('حذف المشترك'),
      content: Text('سيُحذف "$username" نهائيًا. متأكّد؟'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppTokens.red),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('حذف'),
        ),
      ],
    ),
  );
  return ok == true;
}
