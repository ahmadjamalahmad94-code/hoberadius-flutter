import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../shared/widgets/app_card.dart';
import 'tools_common.dart';

class ToolsAdjustmentsPanel extends StatefulWidget {
  const ToolsAdjustmentsPanel({
    super.key,
    required this.busy,
    required this.run,
  });

  final bool busy;
  final Future<Map<String, dynamic>?> Function(Map<String, dynamic> body) run;

  @override
  State<ToolsAdjustmentsPanel> createState() => _ToolsAdjustmentsPanelState();
}

class _ToolsAdjustmentsPanelState extends State<ToolsAdjustmentsPanel> {
  final _users = TextEditingController();
  final _minutes = TextEditingController();
  final _password = TextEditingController();
  String _action = 'disable';
  bool _dryRun = true;
  Map<String, dynamic>? _result;

  @override
  void dispose() {
    _users.dispose();
    _minutes.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ToolsPanelTitle(
            icon: Icons.rule_folder_outlined,
            title: 'تعديلات عامة على حسابات',
            subtitle:
                'إجراءات جماعية تمر عبر الخادم. المعاينة بدون تنفيذ تعرض المستهدفين قبل أي تعديل.',
          ),
          const SizedBox(height: AppTokens.s12),
          DropdownButtonFormField<String>(
            isExpanded: true,
            initialValue: _action,
            decoration: const InputDecoration(labelText: 'الإجراء'),
            items: const [
              DropdownMenuItem(value: 'disable', child: Text('تعطيل')),
              DropdownMenuItem(value: 'enable', child: Text('تفعيل')),
              DropdownMenuItem(value: 'extend', child: Text('تمديد وقت')),
              DropdownMenuItem(
                value: 'reset_password',
                child: Text('تغيير كلمة المرور'),
              ),
            ],
            onChanged: (value) => setState(() => _action = value ?? _action),
          ),
          const SizedBox(height: AppTokens.s8),
          ToolsTextField(
            controller: _users,
            label: 'أسماء الدخول',
            hint: 'كل اسم في سطر أو افصل بفاصلة',
            maxLines: 4,
          ),
          if (_action == 'extend') ...[
            const SizedBox(height: AppTokens.s8),
            ToolsTextField(
              controller: _minutes,
              label: 'عدد الدقائق',
              keyboardType: TextInputType.number,
            ),
          ],
          if (_action == 'reset_password') ...[
            const SizedBox(height: AppTokens.s8),
            ToolsTextField(
              controller: _password,
              label: 'كلمة المرور الجديدة',
            ),
          ],
          SwitchListTile(
            value: _dryRun,
            onChanged: (value) => setState(() => _dryRun = value),
            title: const Text('معاينة بدون تنفيذ'),
          ),
          FilledButton.icon(
            onPressed: widget.busy ? null : _submit,
            icon: const Icon(Icons.play_arrow),
            label: const Text('تنفيذ'),
          ),
          if (_result != null) ...[
            const SizedBox(height: AppTokens.s12),
            ToolsKeyValueBox(values: _result!),
          ],
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final result = await widget.run({
      'action': _action,
      'usernames': _users.text,
      'minutes': int.tryParse(_minutes.text.trim()) ?? 0,
      'new_password': _password.text,
      'dry_run': _dryRun,
    });
    if (result != null && mounted) setState(() => _result = result);
  }
}
