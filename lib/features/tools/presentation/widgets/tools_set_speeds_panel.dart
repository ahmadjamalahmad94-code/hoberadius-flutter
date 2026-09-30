import 'package:flutter/material.dart';

import '../../../../core/format/number_input.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/hub_switch_row.dart';
import '../../domain/tools_models.dart';
import 'tools_common.dart';

/// The server's ceiling for a fixed plan speed (1 Gbit — bulk_speeds).
const int kMaxPlanKbps = 1000000;

/// The «السرعات» tool's request, read strictly (f06 L6: «٢٠٤٨», «0.5» or
/// «abc» used to be sent as `set_down: 0` — no error, the download kept):
/// Arabic digits are accepted, anything else is an Arabic field error and
/// nothing is sent. An EMPTY speed means «unchanged» (the server's 0).
class SetSpeedsRequest {
  const SetSpeedsRequest({
    this.body,
    this.plansError,
    this.downError,
    this.upError,
  });

  /// Null while any field is invalid.
  final Map<String, dynamic>? body;
  final String? plansError;
  final String? downError;
  final String? upError;

  bool get isValid => body != null;
}

SetSpeedsRequest buildSetSpeedsRequest({
  required String plans,
  required String down,
  required String up,
  required bool dryRun,
}) {
  final ids = <int>[];
  String? plansError;
  final parts = latinizeNumberText(plans)
      .replaceAll('\n', ',')
      .replaceAll('،', ',')
      .split(',')
      .map((p) => p.trim())
      .where((p) => p.isNotEmpty);
  for (final part in parts) {
    final id = int.tryParse(part);
    if (id == null || id <= 0 || !RegExp(r'^\d+$').hasMatch(part)) {
      plansError = 'رقم باقة غير صالح: «$part» — أرقام صحيحة مفصولة بفواصل.';
      break;
    }
    if (!ids.contains(id)) ids.add(id);
  }
  if (plansError == null && ids.isEmpty) {
    plansError = 'اكتب رقم باقة واحدة على الأقل.';
  }
  String? speedError(String raw) => validateNumberInput(
        raw,
        required: false,
        decimal: false,
        min: 1,
        max: kMaxPlanKbps,
        maxMessage: 'أعلى سرعة 1,000,000 كيلوبت/ث (1 جيجابت).',
      );
  final downError = speedError(down);
  final upError = speedError(up);
  final setDown = parseIntInput(down) ?? 0;
  final setUp = parseIntInput(up) ?? 0;
  final bothEmpty = down.trim().isEmpty && up.trim().isEmpty;
  final downMsg = downError ??
      (bothEmpty ? 'اكتب سرعة التنزيل أو الرفع (أو كليهما).' : null);
  if (plansError != null || downMsg != null || upError != null) {
    return SetSpeedsRequest(
      plansError: plansError,
      downError: downMsg,
      upError: upError,
    );
  }
  return SetSpeedsRequest(
    body: {
      'plan_ids': ids,
      'set_down': setDown,
      'set_up': setUp,
      'dry_run': dryRun,
    },
  );
}

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
  SetSpeedsRequest? _errors;

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
      padding: const EdgeInsets.all(AppTokens.s12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ToolsPanelTitle(
            icon: Icons.speed_outlined,
            title: 'تعديل سرعات باقات محددة',
            subtitle: 'أرقام الباقات بفواصل، وعاين قبل الاعتماد.',
          ),
          const SizedBox(height: AppTokens.s12),
          ToolsTextField(
            controller: _plans,
            label: 'أرقام الباقات',
            hint: '1, 2, 3',
            errorText: _errors?.plansError,
            onChanged: (_) => _clearErrors(),
          ),
          const SizedBox(height: AppTokens.s8),
          ToolsTwoFields(
            alwaysRow: true,
            first: ToolsTextField(
              controller: _down,
              label: 'تنزيل Kbps',
              keyboardType: TextInputType.number,
              helperText: 'فارغ = بدون تغيير',
              errorText: _errors?.downError,
              onChanged: (_) => _clearErrors(),
            ),
            second: ToolsTextField(
              controller: _up,
              label: 'رفع Kbps',
              keyboardType: TextInputType.number,
              helperText: 'فارغ = بدون تغيير',
              errorText: _errors?.upError,
              onChanged: (_) => _clearErrors(),
            ),
          ),
          HubSwitchRow(
            dense: true,
            value: _dryRun,
            onChanged: (value) => setState(() => _dryRun = value),
            label: 'معاينة بدون تنفيذ',
            subtitle: 'لا يغيّر الخادم إلا عند إيقاف هذا الخيار.',
          ),
          const SizedBox(height: AppTokens.s4),
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

  void _clearErrors() {
    if (_errors != null) setState(() => _errors = null);
  }

  Future<void> _submit() async {
    final req = buildSetSpeedsRequest(
      plans: _plans.text,
      down: _down.text,
      up: _up.text,
      dryRun: _dryRun,
    );
    if (!req.isValid) {
      setState(() => _errors = req);
      return;
    }
    final result = await widget.run(req.body!);
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
