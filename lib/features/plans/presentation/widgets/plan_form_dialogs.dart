import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';

Future<bool> confirmDeletePlan(BuildContext context, String name) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('حذف الباقة'),
      content: Text('سيُحذف "$name" نهائيًا. متأكّد؟'),
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
