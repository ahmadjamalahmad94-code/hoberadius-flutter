import 'package:flutter/material.dart';

import '../../../../core/format/money_limits.dart';
import '../../../../core/format/number_input.dart';
import '../../../../core/format/server_time.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/hub_switch_row.dart';
import '../../domain/tools_models.dart';
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
  String? _error;

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
      padding: const EdgeInsets.all(AppTokens.s12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ToolsPanelTitle(
            icon: Icons.rule_folder_outlined,
            title: 'تعديلات عامة على حسابات',
            subtitle: 'إجراءات جماعية؛ المعاينة تعرض المستهدفين أولًا.',
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
              hint: 'حتى سنة واحدة (525,600 دقيقة) في المرة',
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
          HubSwitchRow(
            dense: true,
            value: _dryRun,
            onChanged: (value) => setState(() => _dryRun = value),
            label: 'معاينة بدون تنفيذ',
          ),
          const SizedBox(height: AppTokens.s4),
          if (_error != null) ...[
            Text(
              _error!,
              style: const TextStyle(
                color: AppTokens.red,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppTokens.s4),
          ],
          FilledButton.icon(
            onPressed: widget.busy ? null : _submit,
            icon: const Icon(Icons.play_arrow),
            label: const Text('تنفيذ'),
          ),
          if (_result != null) ...[
            const SizedBox(height: AppTokens.s12),
            _AdjustmentsResult(
              report: AdjustmentsReport.fromJson(_result!),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final minutes = parseIntInput(_minutes.text) ?? 0;
    final problem =
        _action == 'extend' ? validateAdjustmentMinutes(_minutes.text) : null;
    setState(() => _error = problem);
    if (problem != null) return;
    final result = await widget.run({
      'action': _action,
      'usernames': _users.text,
      'minutes': minutes,
      'new_password': _password.text,
      'dry_run': _dryRun,
    });
    if (result != null && mounted) setState(() => _result = result);
  }
}

/// The bulk «تمديد وقت» minutes: a whole number above zero and at most a
/// year per operation (owner rule; the server answers the same 422).
String? validateAdjustmentMinutes(String raw) {
  final minutes = parseIntInput(raw);
  if (minutes == null || minutes <= 0) {
    return 'أدخل عدد دقائق صحيحًا أكبر من صفر.';
  }
  return validateExtendSpan(minutes);
}

/// Preview / result of a general adjustment: counters + one line per
/// account (was a raw key/value dump of the whole answer).
class _AdjustmentsResult extends StatelessWidget {
  const _AdjustmentsResult({required this.report});

  final AdjustmentsReport report;

  @override
  Widget build(BuildContext context) {
    if (!report.hasDetails) {
      // older servers: flat counters only
      return ToolsKeyValueBox(
        values: {
          for (final e in report.raw.entries)
            if (e.value is! List && e.value is! Map) e.key: e.value,
        },
      );
    }
    final text = Theme.of(context).textTheme;
    return ToolsTintBox(
      color: AppTokens.surfaceMuted,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            report.dryRun ? 'معاينة فقط — لم يُنفَّذ شيء' : 'تم التنفيذ',
            style: text.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppTokens.s4),
          Text(
            [
              if (report.targets != null) 'الحسابات: ${report.targets}',
              if (report.wouldSucceed != null)
                '${report.dryRun ? 'سينجح' : 'نجح'}: ${report.wouldSucceed}',
              if (report.wouldFail != null)
                '${report.dryRun ? 'سيفشل' : 'فشل'}: ${report.wouldFail}',
              if (report.notFound.isNotEmpty)
                'غير موجود: ${report.notFound.join('، ')}',
            ].join(' · '),
          ),
          const SizedBox(height: AppTokens.s8),
          for (final item in report.items)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                [
                  item.username,
                  item.statusLabel,
                  if (item.message.isNotEmpty) item.message,
                  if (item.newExpireAt.isNotEmpty)
                    'الانتهاء الجديد: ${_localExpire(item.newExpireAt)}',
                ].join(' — '),
                style: TextStyle(
                  color: item.ok ? AppTokens.textPrimary : AppTokens.red,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

String _localExpire(String raw) {
  final t = parseServerDateTime(raw);
  if (t == null) return raw;
  String two(int v) => v.toString().padLeft(2, '0');
  return '${t.year}-${two(t.month)}-${two(t.day)} ${two(t.hour)}:${two(t.minute)}';
}
