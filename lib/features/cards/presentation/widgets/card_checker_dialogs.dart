import 'package:flutter/material.dart';

/// Generic confirm dialog used for "destructive" card operations.
Future<bool> cardCheckerConfirm(
  BuildContext context, {
  required String title,
  required String body,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('تأكيد'),
        ),
      ],
    ),
  );
  return ok == true;
}

/// Single-line text-edit dialog. Resolves with the trimmed value on
/// "اعتماد", or `null` on cancel.
Future<String?> cardCheckerAskText(
  BuildContext context, {
  required String title,
  required String label,
  String initial = '',
}) async {
  final ctrl = TextEditingController(text: initial);
  final value = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: ctrl,
        decoration: InputDecoration(labelText: label),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
          child: const Text('اعتماد'),
        ),
      ],
    ),
  );
  ctrl.dispose();
  return value?.trim();
}
