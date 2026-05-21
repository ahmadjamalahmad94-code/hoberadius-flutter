import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../data/tools_repository.dart';
import '../../domain/tools_models.dart';
import 'tools_common.dart';

class ToolsMaintenancePanel extends ConsumerStatefulWidget {
  const ToolsMaintenancePanel({
    super.key,
    required this.busy,
    required this.runPreview,
  });

  final bool busy;
  final Future<MaintenancePreview?> Function(String action, int days)
      runPreview;

  @override
  ConsumerState<ToolsMaintenancePanel> createState() =>
      _ToolsMaintenancePanelState();
}

class _ToolsMaintenancePanelState
    extends ConsumerState<ToolsMaintenancePanel> {
  String _action = 'vacuum';
  final _days = TextEditingController(text: '90');
  MaintenancePreview? _preview;
  bool _running = false;

  @override
  void dispose() {
    _days.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ToolsPanelTitle(
            icon: Icons.cleaning_services_outlined,
            title: 'الصيانة الآمنة',
            subtitle:
                'أي تنظيف يحتاج معاينة أولًا ثم تنفيذ بتأكيد قوي من الخادم.',
          ),
          const SizedBox(height: AppTokens.s12),
          DropdownButtonFormField<String>(
            initialValue: _action,
            decoration: const InputDecoration(labelText: 'نوع الصيانة'),
            items: const [
              DropdownMenuItem(
                value: 'vacuum',
                child: Text('ضغط قاعدة البيانات'),
              ),
              DropdownMenuItem(
                value: 'purge_sync_done',
                child: Text('تنظيف مهام المزامنة المكتملة'),
              ),
              DropdownMenuItem(
                value: 'purge_failed_webhooks',
                child: Text('تنظيف Webhooks الفاشلة'),
              ),
              DropdownMenuItem(
                value: 'purge_radacct',
                child: Text('تنظيف جلسات RADIUS القديمة'),
              ),
              DropdownMenuItem(
                value: 'purge_audit',
                child: Text('تنظيف سجل التدقيق القديم'),
              ),
            ],
            onChanged: (value) => setState(() {
              _action = value ?? _action;
              _preview = null;
            }),
          ),
          const SizedBox(height: AppTokens.s8),
          ToolsTextField(
            controller: _days,
            label: 'أقدم من عدد أيام',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: AppTokens.s8),
          OutlinedButton.icon(
            onPressed: widget.busy ? null : _previewNow,
            icon: const Icon(Icons.search),
            label: const Text('معاينة'),
          ),
          if (_preview != null) ...[
            const SizedBox(height: AppTokens.s12),
            ToolsTintBox(
              color: _preview!.destructive
                  ? AppTokens.warningBg
                  : AppTokens.successBg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('الجدول: ${_preview!.table}'),
                  Text('الصفوف المتوقعة: ${_preview!.estimatedRows}'),
                  Text('يتطلب التأكيد: ${_preview!.confirmPhrase}'),
                  const SizedBox(height: AppTokens.s8),
                  FilledButton.icon(
                    onPressed: _running ? null : _run,
                    icon: _running
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.warning_amber),
                    label: const Text('تنفيذ الصيانة'),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _previewNow() async {
    final preview = await widget.runPreview(
      _action,
      int.tryParse(_days.text.trim()) ?? 90,
    );
    if (preview != null && mounted) setState(() => _preview = preview);
  }

  Future<void> _run() async {
    final preview = _preview;
    if (preview == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تنفيذ الصيانة'),
        content: Text(
          'سيتم تنفيذ ${preview.action} على ${preview.estimatedRows} صف تقريبًا. لا تتابع إلا إذا كنت متأكدًا.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('تنفيذ'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _running = true);
    try {
      final result =
          await ref.read(toolsRepositoryProvider).maintenanceRun(preview);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم التنفيذ: ${result['affected_rows'] ?? 0} صف'),
        ),
      );
      setState(() => _preview = null);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }
}
