import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';
import '../../application/saas_modules_catalog.dart';

class SaasCreateDialog extends StatefulWidget {
  const SaasCreateDialog({super.key, required this.def});
  final SaasModuleDef def;

  @override
  State<SaasCreateDialog> createState() => _SaasCreateDialogState();
}

class _SaasCreateDialogState extends State<SaasCreateDialog> {
  late final Map<String, TextEditingController> _controllers = {
    for (final field in widget.def.fields)
      field.key: TextEditingController(text: field.defaultValue),
  };

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.def.createLabel),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final field in widget.def.fields) ...[
              TextField(
                controller: _controllers[field.key],
                keyboardType:
                    field.number ? TextInputType.number : TextInputType.text,
                decoration: InputDecoration(labelText: field.label),
              ),
              const SizedBox(height: AppTokens.s8),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _body()),
          child: const Text('حفظ'),
        ),
      ],
    );
  }

  Map<String, dynamic> _body() => saasCreateBody(widget.def, {
        for (final field in widget.def.fields)
          field.key: _controllers[field.key]!.text,
      });
}

/// The create body for a SaaS module form. A BLANK numeric field is left out
/// (the server applies its own default / «none») — it used to be sent as 0:
/// voucher `plan_id` 0 was a FOREIGN KEY 500. Text that is not a number is
/// sent as typed so the server answers with its Arabic 422.
Map<String, dynamic> saasCreateBody(
  SaasModuleDef def,
  Map<String, String> values,
) {
  final body = <String, dynamic>{};
  for (final field in def.fields) {
    final raw = (values[field.key] ?? '').trim();
    if (!field.number) {
      body[field.key] = raw;
      continue;
    }
    if (raw.isEmpty) continue;
    body[field.key] = num.tryParse(raw) ?? raw;
  }
  return body;
}
