import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/visible_error_message.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/hub_error_state.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/status_pill.dart';
import '../application/router_alerts_providers.dart';
import '../data/router_alerts_repository.dart';
import '../domain/router_alerts_model.dart';

class RouterAlertsScreen extends ConsumerStatefulWidget {
  const RouterAlertsScreen({super.key});

  @override
  ConsumerState<RouterAlertsScreen> createState() => _RouterAlertsScreenState();
}

class _RouterAlertsScreenState extends ConsumerState<RouterAlertsScreen> {
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(routerAlertsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          title: 'التنبيهات الذكية للراوترات',
          subtitle:
              'اضبط متى يعتبر الراوتر مفصولًا، وحدود الترافيك والاستهلاك التي تفتح تنبيهًا في مركز الأحداث. الراوترات تدفع المقاييس إلى الخادم، والتطبيق هنا يدير الحدود فقط.',
          actions: [
            IconButton(
              tooltip: 'تحديث',
              onPressed: () => ref.invalidate(routerAlertsProvider),
              icon: const Icon(Icons.refresh, color: AppTokens.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.s16),
        async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => HubErrorState(
            title: 'تعذر جلب إعدادات التنبيهات',
            subtitle: visibleErrorMessage(error),
            onRetry: () => ref.invalidate(routerAlertsProvider),
          ),
          data: _body,
        ),
      ],
    );
  }

  Widget _body(RouterAlertsState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SummaryGrid(counts: state.counts, settings: state.settings),
        const SizedBox(height: AppTokens.s12),
        _GlobalSettingsCard(
          settings: state.settings,
          windows: state.usageWindows,
          saving: _saving,
          onSave: (settings) => _save(settings: settings),
        ),
        const SizedBox(height: AppTokens.s12),
        if (state.routers.isEmpty)
          const EmptyState(
            icon: Icons.router_outlined,
            title: 'لا توجد راوترات لإعداد التنبيهات',
            subtitle:
                'أضف راوترًا من قسم أجهزة الشبكة، ثم فعّل دفع المقاييس حتى تظهر النبضات والحدود هنا.',
          )
        else
          for (final router in state.routers) ...[
            _RouterAlertCard(
              router: router,
              windows: state.usageWindows,
              saving: _saving,
              onSave: (updated) => _save(routers: [updated]),
            ),
            const SizedBox(height: AppTokens.s12),
          ],
      ],
    );
  }

  Future<void> _save({
    RouterAlertSettings? settings,
    List<RouterAlertTarget>? routers,
  }) async {
    setState(() => _saving = true);
    try {
      await ref.read(routerAlertsRepositoryProvider).save(
            settings: settings,
            routers: routers,
          );
      ref.invalidate(routerAlertsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ إعدادات التنبيهات')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(visibleErrorMessage(error))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.counts, required this.settings});

  final RouterAlertCounts counts;
  final RouterAlertSettings settings;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 860;
        return GridView.count(
          crossAxisCount: wide ? 4 : 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppTokens.s12,
          crossAxisSpacing: AppTokens.s12,
          childAspectRatio: wide ? 3.1 : 2.35,
          children: [
            _MetricTile(
              icon: Icons.router_outlined,
              label: 'الراوترات',
              value: counts.routers.toString(),
            ),
            _MetricTile(
              icon: Icons.sensors_outlined,
              label: 'تدفع مقاييس',
              value: counts.pushing.toString(),
            ),
            _MetricTile(
              icon: Icons.tune_outlined,
              label: 'حدود مخصصة',
              value: counts.overrides.toString(),
            ),
            _MetricTile(
              icon: settings.enabled
                  ? Icons.notifications_active_outlined
                  : Icons.notifications_off_outlined,
              label: 'الحالة العامة',
              value: settings.enabled ? 'مفعلة' : 'متوقفة',
            ),
          ],
        );
      },
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Icon(icon, color: AppTokens.brand),
          const SizedBox(width: AppTokens.s12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                Text(label, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GlobalSettingsCard extends StatefulWidget {
  const _GlobalSettingsCard({
    required this.settings,
    required this.windows,
    required this.saving,
    required this.onSave,
  });

  final RouterAlertSettings settings;
  final List<UsageWindowOption> windows;
  final bool saving;
  final ValueChanged<RouterAlertSettings> onSave;

  @override
  State<_GlobalSettingsCard> createState() => _GlobalSettingsCardState();
}

class _GlobalSettingsCardState extends State<_GlobalSettingsCard> {
  late bool _enabled;
  late bool _telegram;
  late bool _offline;
  late bool _traffic;
  late bool _usage;
  final _offlineAfter = TextEditingController();
  final _speed = TextEditingController();
  final _usageGb = TextEditingController();
  late String _window;

  @override
  void initState() {
    super.initState();
    _load(widget.settings);
  }

  @override
  void didUpdateWidget(covariant _GlobalSettingsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settings != widget.settings) _load(widget.settings);
  }

  void _load(RouterAlertSettings settings) {
    _enabled = settings.enabled;
    _telegram = settings.telegram;
    _offline = settings.offline;
    _traffic = settings.highTraffic;
    _usage = settings.highUsage;
    _offlineAfter.text = settings.offlineAfterMin.toString();
    _speed.text = settings.defaultSpeedMbps.toString();
    _usageGb.text = settings.defaultUsageGb.toString();
    _window = settings.usageWindow.isEmpty ? 'day' : settings.usageWindow;
  }

  @override
  void dispose() {
    _offlineAfter.dispose();
    _speed.dispose();
    _usageGb.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.settings_suggest_outlined),
              const SizedBox(width: AppTokens.s8),
              Expanded(
                child: Text(
                  'الإعدادات العامة',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              StatusPill(
                text: _enabled ? 'مفعلة' : 'متوقفة',
                tone: _enabled ? PillTone.green : PillTone.neutral,
              ),
            ],
          ),
          const SizedBox(height: AppTokens.s12),
          Wrap(
            spacing: AppTokens.s12,
            runSpacing: AppTokens.s8,
            children: [
              _SwitchChip(
                label: 'تشغيل التنبيهات',
                value: _enabled,
                onChanged: (value) => setState(() => _enabled = value),
              ),
              _SwitchChip(
                label: 'إشعار تيليجرام',
                value: _telegram,
                onChanged: (value) => setState(() => _telegram = value),
              ),
              _SwitchChip(
                label: 'راوتر مفصول',
                value: _offline,
                onChanged: (value) => setState(() => _offline = value),
              ),
              _SwitchChip(
                label: 'ترافيك عالٍ',
                value: _traffic,
                onChanged: (value) => setState(() => _traffic = value),
              ),
              _SwitchChip(
                label: 'استهلاك عالٍ',
                value: _usage,
                onChanged: (value) => setState(() => _usage = value),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.s12),
          _FieldsGrid(
            children: [
              _NumberField(
                controller: _offlineAfter,
                label: 'يُعد مفصولًا بعد',
                suffix: 'دقيقة',
              ),
              _NumberField(
                controller: _speed,
                label: 'حد السرعة العام',
                suffix: 'Mbps',
              ),
              _NumberField(
                controller: _usageGb,
                label: 'حد الاستهلاك العام',
                suffix: 'GB',
              ),
              _WindowPicker(
                value: _window,
                windows: widget.windows,
                onChanged: (value) => setState(() => _window = value),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.s12),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: FilledButton.icon(
              onPressed: widget.saving ? null : _submit,
              icon: const Icon(Icons.save_outlined),
              label: Text(widget.saving ? 'جارٍ الحفظ' : 'حفظ الإعدادات العامة'),
            ),
          ),
        ],
      ),
    );
  }

  void _submit() {
    final offline = int.tryParse(_offlineAfter.text.trim()) ?? 0;
    final speed = int.tryParse(_speed.text.trim()) ?? 0;
    final usage = int.tryParse(_usageGb.text.trim()) ?? 0;
    if (offline < 2 || speed < 1 || usage < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أدخل أرقامًا صحيحة وموجبة للحدود')),
      );
      return;
    }
    widget.onSave(
      widget.settings.copyWith(
        enabled: _enabled,
        telegram: _telegram,
        offline: _offline,
        highTraffic: _traffic,
        highUsage: _usage,
        offlineAfterMin: offline,
        defaultSpeedMbps: speed,
        defaultUsageGb: usage,
        usageWindow: _window,
      ),
    );
  }
}

class _RouterAlertCard extends StatefulWidget {
  const _RouterAlertCard({
    required this.router,
    required this.windows,
    required this.saving,
    required this.onSave,
  });

  final RouterAlertTarget router;
  final List<UsageWindowOption> windows;
  final bool saving;
  final ValueChanged<RouterAlertTarget> onSave;

  @override
  State<_RouterAlertCard> createState() => _RouterAlertCardState();
}

class _RouterAlertCardState extends State<_RouterAlertCard> {
  late bool _enabled;
  final _offlineAfter = TextEditingController();
  final _speed = TextEditingController();
  final _usageGb = TextEditingController();
  late String _window;

  @override
  void initState() {
    super.initState();
    _load(widget.router);
  }

  @override
  void didUpdateWidget(covariant _RouterAlertCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.router != widget.router) _load(widget.router);
  }

  void _load(RouterAlertTarget router) {
    _enabled = router.enabled;
    _offlineAfter.text = router.offlineAfterMin.toString();
    _speed.text = router.normalSpeedMbps.toString();
    _usageGb.text = router.normalUsageGb.toString();
    _window = router.usageWindow.isEmpty ? 'day' : router.usageWindow;
  }

  @override
  void dispose() {
    _offlineAfter.dispose();
    _speed.dispose();
    _usageGb.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pushed = widget.router.lastPushAt.isNotEmpty;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                pushed ? Icons.sensors_outlined : Icons.sensors_off_outlined,
                color: pushed ? AppTokens.successFg : AppTokens.textMuted,
              ),
              const SizedBox(width: AppTokens.s8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.router.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    Text(
                      [
                        if (widget.router.address.isNotEmpty)
                          widget.router.address,
                        pushed
                            ? 'آخر نبضة: ${widget.router.lastPushAt}'
                            : 'لم تصل مقاييس بعد',
                      ].join(' · '),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              StatusPill(
                text: _enabled ? 'مراقب' : 'متوقف',
                tone: _enabled ? PillTone.green : PillTone.neutral,
              ),
            ],
          ),
          const SizedBox(height: AppTokens.s12),
          _SwitchChip(
            label: 'تفعيل مراقبة هذا الراوتر',
            value: _enabled,
            onChanged: (value) => setState(() => _enabled = value),
          ),
          const SizedBox(height: AppTokens.s12),
          _FieldsGrid(
            children: [
              _NumberField(
                controller: _offlineAfter,
                label: 'مفصول بعد',
                suffix: 'دقيقة',
              ),
              _NumberField(
                controller: _speed,
                label: 'حد السرعة',
                suffix: 'Mbps',
              ),
              _NumberField(
                controller: _usageGb,
                label: 'حد الاستهلاك',
                suffix: 'GB',
              ),
              _WindowPicker(
                value: _window,
                windows: widget.windows,
                onChanged: (value) => setState(() => _window = value),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.s12),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: OutlinedButton.icon(
              onPressed: widget.saving ? null : _submit,
              icon: const Icon(Icons.save_outlined),
              label: Text(widget.saving ? 'جارٍ الحفظ' : 'حفظ حدود الراوتر'),
            ),
          ),
        ],
      ),
    );
  }

  void _submit() {
    final offline = int.tryParse(_offlineAfter.text.trim()) ?? 0;
    final speed = int.tryParse(_speed.text.trim()) ?? 0;
    final usage = int.tryParse(_usageGb.text.trim()) ?? 0;
    if (offline < 2 || speed < 1 || usage < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أدخل أرقامًا صحيحة وموجبة للراوتر')),
      );
      return;
    }
    widget.onSave(
      widget.router.copyWith(
        enabled: _enabled,
        offlineAfterMin: offline,
        normalSpeedMbps: speed,
        normalUsageGb: usage,
        usageWindow: _window,
      ),
    );
  }
}

class _FieldsGrid extends StatelessWidget {
  const _FieldsGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 820;
        return GridView.count(
          crossAxisCount: wide ? 4 : 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppTokens.s8,
          crossAxisSpacing: AppTokens.s8,
          childAspectRatio: wide ? 3.2 : 2.45,
          children: children,
        );
      },
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.controller,
    required this.label,
    required this.suffix,
  });

  final TextEditingController controller;
  final String label;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label, suffixText: suffix),
    );
  }
}

class _WindowPicker extends StatelessWidget {
  const _WindowPicker({
    required this.value,
    required this.windows,
    required this.onChanged,
  });

  final String value;
  final List<UsageWindowOption> windows;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final options = windows.isEmpty
        ? const [
            UsageWindowOption(key: 'day', label: 'يومي'),
            UsageWindowOption(key: 'month', label: 'شهري'),
          ]
        : windows;
    final safeValue = options.any((item) => item.key == value)
        ? value
        : options.first.key;
    return DropdownButtonFormField<String>(
      value: safeValue,
      decoration: const InputDecoration(labelText: 'نافذة الاستهلاك'),
      items: [
        for (final item in options)
          DropdownMenuItem(value: item.key, child: Text(item.label)),
      ],
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );
  }
}

class _SwitchChip extends StatelessWidget {
  const _SwitchChip({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      selected: value,
      onSelected: onChanged,
      avatar: Icon(value ? Icons.check_circle : Icons.circle_outlined),
      label: Text(label),
    );
  }
}
