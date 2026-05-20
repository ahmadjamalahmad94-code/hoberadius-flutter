import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/status_pill.dart';
import '../data/tools_repository.dart';
import '../domain/tools_models.dart';

final radiusLogProvider = FutureProvider.autoDispose<RadiusLogSnapshot>((ref) {
  return ref.watch(toolsRepositoryProvider).radiusLog();
});

class ToolsScreen extends ConsumerStatefulWidget {
  const ToolsScreen({super.key});

  @override
  ConsumerState<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends ConsumerState<ToolsScreen> {
  int _tab = 0;
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          title: 'الأدوات',
          subtitle:
              'أدوات تشغيل حقيقية من الخادم: تعديل سرعات، اختبار دخول، سجل RADIUS، وصيانة بمعاينة قبل التنفيذ.',
          actions: [
            IconButton(
              tooltip: 'تحديث',
              onPressed: () => ref.invalidate(radiusLogProvider),
              icon: const Icon(Icons.refresh, color: AppTokens.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.s12),
        AppCard(
          padding: const EdgeInsets.all(AppTokens.s8),
          child: SegmentedButton<int>(
            segments: const [
              ButtonSegment(
                value: 0,
                icon: Icon(Icons.speed_outlined),
                label: Text('السرعات'),
              ),
              ButtonSegment(
                value: 1,
                icon: Icon(Icons.rule_folder_outlined),
                label: Text('تعديلات'),
              ),
              ButtonSegment(
                value: 2,
                icon: Icon(Icons.verified_user_outlined),
                label: Text('اختبار'),
              ),
              ButtonSegment(
                value: 3,
                icon: Icon(Icons.rss_feed),
                label: Text('السجل'),
              ),
              ButtonSegment(
                value: 4,
                icon: Icon(Icons.cleaning_services_outlined),
                label: Text('الصيانة'),
              ),
            ],
            selected: {_tab},
            onSelectionChanged: (value) => setState(() => _tab = value.first),
            showSelectedIcon: false,
          ),
        ),
        const SizedBox(height: AppTokens.s12),
        IndexedStack(
          index: _tab,
          children: [
            _SetSpeedsPanel(busy: _busy, run: _setSpeeds),
            _GeneralAdjustmentsPanel(busy: _busy, run: _generalAdjustment),
            _TestAuthPanel(busy: _busy, run: _testAuth),
            _RadiusLogPanel(onRefresh: () => ref.invalidate(radiusLogProvider)),
            _MaintenancePanel(busy: _busy, runPreview: _previewMaintenance),
          ],
        ),
      ],
    );
  }

  Future<SetSpeedsResult?> _setSpeeds(Map<String, dynamic> body) async {
    return _guard(() => ref.read(toolsRepositoryProvider).setSpeeds(body));
  }

  Future<Map<String, dynamic>?> _generalAdjustment(
    Map<String, dynamic> body,
  ) async {
    return _guard(
      () => ref.read(toolsRepositoryProvider).generalAdjustments(body),
    );
  }

  Future<AuthTestDecision?> _testAuth(Map<String, dynamic> body) async {
    return _guard(() => ref.read(toolsRepositoryProvider).testAuth(body));
  }

  Future<MaintenancePreview?> _previewMaintenance(
    String action,
    int days,
  ) async {
    return _guard(
      () => ref.read(toolsRepositoryProvider).maintenancePreview(
            action: action,
            days: days,
          ),
    );
  }

  Future<T?> _guard<T>(Future<T> Function() work) async {
    setState(() => _busy = true);
    try {
      return await work();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
      return null;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _SetSpeedsPanel extends StatefulWidget {
  const _SetSpeedsPanel({required this.busy, required this.run});

  final bool busy;
  final Future<SetSpeedsResult?> Function(Map<String, dynamic> body) run;

  @override
  State<_SetSpeedsPanel> createState() => _SetSpeedsPanelState();
}

class _SetSpeedsPanelState extends State<_SetSpeedsPanel> {
  final _plans = TextEditingController();
  final _down = TextEditingController();
  final _up = TextEditingController();
  bool _dryRun = true;
  SetSpeedsResult? _result;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _PanelTitle(
            icon: Icons.speed_outlined,
            title: 'تعديل سرعات باقات محددة',
            subtitle:
                'اكتب أرقام الباقات مفصولة بفاصلة. استخدم تجربة فقط أولًا قبل اعتماد التغيير الحقيقي.',
          ),
          const SizedBox(height: AppTokens.s12),
          _Text(controller: _plans, label: 'أرقام الباقات', hint: '1, 2, 3'),
          const SizedBox(height: AppTokens.s8),
          _TwoFields(
            first: _Text(
              controller: _down,
              label: 'تنزيل Kbps',
              keyboardType: TextInputType.number,
            ),
            second: _Text(
              controller: _up,
              label: 'رفع Kbps',
              keyboardType: TextInputType.number,
            ),
          ),
          SwitchListTile(
            value: _dryRun,
            onChanged: (value) => setState(() => _dryRun = value),
            title: const Text('تجربة فقط'),
            subtitle: const Text('لا يغيّر الخادم إلا عند إيقاف هذا الخيار.'),
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

class _GeneralAdjustmentsPanel extends StatefulWidget {
  const _GeneralAdjustmentsPanel({required this.busy, required this.run});

  final bool busy;
  final Future<Map<String, dynamic>?> Function(Map<String, dynamic> body) run;

  @override
  State<_GeneralAdjustmentsPanel> createState() =>
      _GeneralAdjustmentsPanelState();
}

class _GeneralAdjustmentsPanelState extends State<_GeneralAdjustmentsPanel> {
  final _users = TextEditingController();
  final _minutes = TextEditingController();
  final _password = TextEditingController();
  String _action = 'disable';
  bool _dryRun = true;
  Map<String, dynamic>? _result;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _PanelTitle(
            icon: Icons.rule_folder_outlined,
            title: 'تعديلات عامة على حسابات',
            subtitle:
                'إجراءات جماعية تمر عبر الخادم. تجربة فقط تعرض المستهدفين بدون تعديل.',
          ),
          const SizedBox(height: AppTokens.s12),
          DropdownButtonFormField<String>(
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
          _Text(
            controller: _users,
            label: 'أسماء الدخول',
            hint: 'كل اسم في سطر أو افصل بفاصلة',
            maxLines: 4,
          ),
          if (_action == 'extend') ...[
            const SizedBox(height: AppTokens.s8),
            _Text(
              controller: _minutes,
              label: 'عدد الدقائق',
              keyboardType: TextInputType.number,
            ),
          ],
          if (_action == 'reset_password') ...[
            const SizedBox(height: AppTokens.s8),
            _Text(controller: _password, label: 'كلمة المرور الجديدة'),
          ],
          SwitchListTile(
            value: _dryRun,
            onChanged: (value) => setState(() => _dryRun = value),
            title: const Text('تجربة فقط'),
          ),
          FilledButton.icon(
            onPressed: widget.busy ? null : _submit,
            icon: const Icon(Icons.play_arrow),
            label: const Text('تنفيذ'),
          ),
          if (_result != null) ...[
            const SizedBox(height: AppTokens.s12),
            _KeyValueBox(values: _result!),
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

class _TestAuthPanel extends StatefulWidget {
  const _TestAuthPanel({required this.busy, required this.run});

  final bool busy;
  final Future<AuthTestDecision?> Function(Map<String, dynamic> body) run;

  @override
  State<_TestAuthPanel> createState() => _TestAuthPanelState();
}

class _TestAuthPanelState extends State<_TestAuthPanel> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _mac = TextEditingController();
  final _nas = TextEditingController();
  AuthTestDecision? _decision;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _PanelTitle(
            icon: Icons.verified_user_outlined,
            title: 'اختبار مصادقة',
            subtitle:
                'يفحص قرار السماح من محرك السياسات في الخادم بدون اتصال مباشر من التطبيق إلى RADIUS.',
          ),
          const SizedBox(height: AppTokens.s12),
          _TwoFields(
            first: _Text(controller: _username, label: 'اسم الدخول'),
            second: _Text(controller: _password, label: 'كلمة المرور'),
          ),
          const SizedBox(height: AppTokens.s8),
          _TwoFields(
            first: _Text(controller: _mac, label: 'MAC الجهاز'),
            second: _Text(controller: _nas, label: 'عنوان NAS'),
          ),
          FilledButton.icon(
            onPressed: widget.busy ? null : _submit,
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('اختبار'),
          ),
          if (_decision != null) ...[
            const SizedBox(height: AppTokens.s12),
            _TintBox(
              color: _decision!.ok
                  ? const Color(0xFFE8F8EF)
                  : const Color(0xFFFDE9E9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StatusPill(
                    text: _decision!.ok ? 'مسموح' : 'مرفوض',
                    tone:
                        _decision!.ok ? PillTone.green : PillTone.red,
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

class _RadiusLogPanel extends ConsumerWidget {
  const _RadiusLogPanel({required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(radiusLogProvider);
    return AppCard(
      padding: EdgeInsets.zero,
      child: async.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(AppTokens.s20),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => Padding(
          padding: const EdgeInsets.all(AppTokens.s20),
          child: EmptyState(
            icon: Icons.error_outline,
            title: 'تعذر جلب سجل RADIUS',
            subtitle: '$e',
          ),
        ),
        data: (snapshot) {
          if (snapshot.items.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(AppTokens.s20),
              child: EmptyState(
                icon: Icons.rss_feed,
                title: 'لا توجد قرارات دخول بعد',
              ),
            );
          }
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('القرار')),
                DataColumn(label: Text('اسم الدخول')),
                DataColumn(label: Text('NAS')),
                DataColumn(label: Text('السبب')),
                DataColumn(label: Text('الوقت')),
              ],
              rows: snapshot.items
                  .map(
                    (item) => DataRow(
                      cells: [
                        DataCell(
                          StatusPill(
                            text: item.ok ? 'قبول' : 'رفض',
                            tone:
                                item.ok ? PillTone.green : PillTone.red,
                          ),
                        ),
                        DataCell(Text(item.username)),
                        DataCell(Text(item.nas.isEmpty ? 'غير معروف' : item.nas)),
                        DataCell(Text(item.reason.isEmpty ? item.reply : item.reason)),
                        DataCell(Text(item.authdate)),
                      ],
                    ),
                  )
                  .toList(),
            ),
          );
        },
      ),
    );
  }
}

class _MaintenancePanel extends ConsumerStatefulWidget {
  const _MaintenancePanel({required this.busy, required this.runPreview});

  final bool busy;
  final Future<MaintenancePreview?> Function(String action, int days)
      runPreview;

  @override
  ConsumerState<_MaintenancePanel> createState() => _MaintenancePanelState();
}

class _MaintenancePanelState extends ConsumerState<_MaintenancePanel> {
  String _action = 'vacuum';
  final _days = TextEditingController(text: '90');
  MaintenancePreview? _preview;
  bool _running = false;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _PanelTitle(
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
              DropdownMenuItem(value: 'vacuum', child: Text('ضغط قاعدة البيانات')),
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
          _Text(
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
            _TintBox(
              color: _preview!.destructive
                  ? const Color(0xFFFFF4E2)
                  : const Color(0xFFE8F8EF),
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
      final result = await ref.read(toolsRepositoryProvider).maintenanceRun(preview);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم التنفيذ: ${result['affected_rows'] ?? 0} صف')),
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

class _PanelTitle extends StatelessWidget {
  const _PanelTitle({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppTokens.cyan500),
        const SizedBox(width: AppTokens.s8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppTokens.navy900,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 3),
              Text(subtitle, style: const TextStyle(color: AppTokens.textMuted)),
            ],
          ),
        ),
      ],
    );
  }
}

class _SpeedsResult extends StatelessWidget {
  const _SpeedsResult({required this.result});

  final SetSpeedsResult result;

  @override
  Widget build(BuildContext context) {
    return _TintBox(
      color: result.dryRun ? const Color(0xFFFFF4E2) : const Color(0xFFE8F8EF),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(result.dryRun ? 'نتيجة التجربة' : 'تم اعتماد التغيير'),
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

class _KeyValueBox extends StatelessWidget {
  const _KeyValueBox({required this.values});

  final Map<String, dynamic> values;

  @override
  Widget build(BuildContext context) {
    return _TintBox(
      color: const Color(0xFFF6F8FB),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: values.entries
            .map((entry) => Text('${entry.key}: ${entry.value}'))
            .toList(),
      ),
    );
  }
}

class _TwoFields extends StatelessWidget {
  const _TwoFields({required this.first, required this.second});

  final Widget first;
  final Widget second;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 640) {
          return Column(
            children: [
              first,
              const SizedBox(height: AppTokens.s8),
              second,
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: first),
            const SizedBox(width: AppTokens.s8),
            Expanded(child: second),
          ],
        );
      },
    );
  }
}

class _TintBox extends StatelessWidget {
  const _TintBox({required this.color, required this.child});

  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.s16),
        child: child,
      ),
    );
  }
}

class _Text extends StatelessWidget {
  const _Text({
    required this.controller,
    required this.label,
    this.hint,
    this.maxLines = 1,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final int maxLines;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(labelText: label, hintText: hint),
    );
  }
}
