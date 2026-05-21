import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/status_pill.dart';
import '../../domain/tools_models.dart';
import 'tools_common.dart';

class ToolsTestAuthPanel extends StatefulWidget {
  const ToolsTestAuthPanel({
    super.key,
    required this.busy,
    required this.run,
  });

  final bool busy;
  final Future<AuthTestDecision?> Function(Map<String, dynamic> body) run;

  @override
  State<ToolsTestAuthPanel> createState() => _ToolsTestAuthPanelState();
}

class _ToolsTestAuthPanelState extends State<ToolsTestAuthPanel> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _mac = TextEditingController();
  final _nas = TextEditingController();
  AuthTestDecision? _decision;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    _mac.dispose();
    _nas.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ToolsPanelTitle(
            icon: Icons.verified_user_outlined,
            title: 'اختبار مصادقة',
            subtitle:
                'يفحص قرار السماح من محرك السياسات في الخادم بدون اتصال مباشر من التطبيق إلى RADIUS.',
          ),
          const SizedBox(height: AppTokens.s12),
          ToolsTwoFields(
            first: ToolsTextField(controller: _username, label: 'اسم الدخول'),
            second:
                ToolsTextField(controller: _password, label: 'كلمة المرور'),
          ),
          const SizedBox(height: AppTokens.s8),
          ToolsTwoFields(
            first: ToolsTextField(controller: _mac, label: 'MAC الجهاز'),
            second: ToolsTextField(controller: _nas, label: 'عنوان NAS'),
          ),
          FilledButton.icon(
            onPressed: widget.busy ? null : _submit,
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('اختبار'),
          ),
          if (_decision != null) ...[
            const SizedBox(height: AppTokens.s12),
            ToolsTintBox(
              color: _decision!.ok ? AppTokens.successBg : AppTokens.dangerBg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StatusPill(
                    text: _decision!.ok ? 'مسموح' : 'مرفوض',
                    tone: _decision!.ok ? PillTone.green : PillTone.red,
                  ),
                  const SizedBox(height: AppTokens.s8),
                  Text('السبب: ${_decision!.reason}'),
                  if (_decision!.message.isNotEmpty)
                    Text('الرسالة: ${_decision!.message}'),
                  if (_decision!.replyAttrs.isNotEmpty)
                    Text('خصائص الرد: ${_decision!.replyAttrs}'),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final decision = await widget.run({
      'username': _username.text.trim(),
      'password': _password.text,
      'calling_station_id': _mac.text.trim(),
      'nas_ip': _nas.text.trim(),
      'nas_port_type': 'Ethernet',
    });
    if (decision != null && mounted) setState(() => _decision = decision);
  }
}
