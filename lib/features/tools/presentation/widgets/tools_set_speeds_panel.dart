import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../domain/tools_models.dart';
import 'tools_common.dart';

class ToolsSetSpeedsPanel extends StatefulWidget {
  const ToolsSetSpeedsPanel({
    super.key,
    required this.busy,
    required this.run,
  });

  final bool busy;
  final Future<SetSpeedsResult?> Function(Map<String, dynamic> body) run;

  @override
  State<ToolsSetSpeedsPanel> createState() => _ToolsSetSpeedsPanelState();
}

class _ToolsSetSpeedsPanelState extends State<ToolsSetSpeedsPanel> {
  final _plans = TextEditingController();
  final _down = TextEditingController();
  final _up = TextEditingController();
  bool _dryRun = true;
  SetSpeedsResult? _result;

  @override
  void dispose() {
    _plans.dispose();
    _down.dispose();
    _up.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ToolsPanelTitle(
            icon: Icons.speed_outlined,
            title: 'تعديل سرعات باقات محددة',
            subtitle:
                'اكتب أرقام الباقات مفصولة بفاصلة. استخدم المعاينة بدون تنفيذ أولًا قبل اعتماد التغيير الحقيقي.',
          ),
          const SizedBox(height: AppTokens.s12),
          ToolsTextField(
            controller: _plans,
            label: 'أرقام الباقات',
            hint: '1, 2, 3',
          ),
          const SizedBox(height: AppTokens.s8),
          ToolsTwoFields(
            first: ToolsTextField(
              controller: _down,
              label: 'تنزيل Kbps',
              keyboardType: TextInputType.number,
            ),
            second: ToolsTextField(
              controller: _up,
              label: 'رفع Kbps',
              keyboardType: TextInputType.number,
            ),
          ),
          SwitchListTile(
            value: _dryRun,
            onChanged: (value) => setState(() => _dryRun = value),
            title: const Text('معاينة بدون تنفيذ'),
            subtitle: const Text('يعرض التأثير المتوقع ولا يغيّر الخادم إلا عند إيقاف هذا الخيار.'),
          ),
          FilledButton.icon(
            onPressed: widget.busy ? null : _submit,
            icon: widget.busy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.play_arrow),
            label: Text(_dryRun ? 'معاينة التغيير' : 'اعتماد التغيير'),
          ),
          if (_result != null) ...[
            const SizedBox(height: AppTokens.s12),
            _SpeedsResult(result: _result!),
          ],
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final ids = _plans.text
        .replaceAll('\n', ',')
        .split(',')
        .map((part) => int.tryParse(part.trim()))
        .whereType<int>()
        .toList();
    final result = await widget.run({
      'plan_ids': ids,
      'set_down': int.tryParse(_down.text.trim()) ?? 0,
      'set_up': int.tryParse(_up.text.trim()) ?? 0,
      'dry_run': _dryRun,
    });
    if (result != null && mounted) setState(() => _result = result);
  }
}

class _SpeedsResult extends StatelessWidget {
  const _SpeedsResult({required this.result});

  final SetSpeedsResult result;

  @override
  Widget build(BuildContext context) {
    return ToolsTintBox(
      color: result.dryRun ? AppTokens.warningBg : AppTokens.successBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(result.dryRun ? 'نتيجة المعاينة' : 'تم اعتماد التغيير'),
          const SizedBox(height: AppTokens.s8),
          for (final change in result.changes)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                '#${change.planId} ${change.name}: '
                '${change.beforeDown}/${change.beforeUp} ← '
                '${change.afterDown}/${change.afterUp} Kbps',
              ),
            ),
        ],
      ),
    );
  }
}
