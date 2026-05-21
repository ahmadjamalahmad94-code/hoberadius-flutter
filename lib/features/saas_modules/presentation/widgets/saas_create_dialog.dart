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

  Map<String, dynamic> _body() {
    return {
      for (final field in widget.def.fields)
        field.key: field.number
            ? num.tryParse(_controllers[field.key]!.text.trim()) ?? 0
            : _controllers[field.key]!.text.trim(),
    };
  }
}
