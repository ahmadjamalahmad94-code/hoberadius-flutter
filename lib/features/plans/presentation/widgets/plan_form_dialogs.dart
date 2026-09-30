import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';

Future<bool> confirmDeletePlan(BuildContext context, String name) async {
  final ok = await showDialog<bool>(
    useRootNavigator: true,
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('أرشفة الباقة'),
      // The server ARCHIVES the plan (restorable from the recycle bin) — it
      // is not deleted «نهائيًا» (r04 N9).
      content: Text(
        'ستُؤرشف الباقة «$name» وتختفي من القوائم، ويمكن استعادتها من '
        'سلة المحذوفات. متأكّد؟',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppTokens.red),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('أرشفة'),
        ),
      ],
    ),
  );
  return ok == true;
}
