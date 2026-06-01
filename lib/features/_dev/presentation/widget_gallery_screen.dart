import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/hub_access_schedule.dart';
import '../../../shared/widgets/hub_speed_rules_panel.dart';
import '../../../shared/widgets/hub_time_picker_circular.dart';
import '../../../shared/widgets/hub_toast.dart';
import '../../../shared/widgets/hub_toggle_switch.dart';
import '../../../shared/widgets/hub_unit_input.dart';

/// Dev-only gallery for the J2 canonical widgets.
///
/// Source-only gallery for local design checks. It is intentionally not
/// mounted in the production router. Engineers can still instantiate it
/// from a local debug harness when reviewing theme and directionality.
class WidgetGalleryScreen extends StatefulWidget {
  const WidgetGalleryScreen({super.key});

  @override
  State<WidgetGalleryScreen> createState() => _WidgetGalleryScreenState();
}

class _WidgetGalleryScreenState extends State<WidgetGalleryScreen> {
  Brightness _brightness = Brightness.light;
  TextDirection _direction = TextDirection.rtl;

  // Live state for each interactive widget.
  bool _toggleA = true;
  bool _toggleB = false;
  int _speedKbps = 1024;
  int _quotaMb = 5120;
  int _timeMin = 60;
  String _from = '08:00';
  String _to = '16:00';
  AccessSchedule _schedule = const AccessSchedule(
    windows: [
      AccessWindow(days: ['sat', 'sun', 'mon'], from: '09:00', to: '17:00'),
    ],
  );
  List<SpeedRule> _rules = const [
    SpeedRule(
      name: 'سرعة المساء',
      days: ['sun', 'mon', 'tue'],
      startsAtTime: '18:00',
      endsAtTime: '23:00',
      speedDownKbps: 2048,
      speedUpKbps: 1024,
      enabled: true,
    ),
    SpeedRule(
      name: 'وقت النوم',
      days: ['fri'],
      startsAtTime: '23:00',
      endsAtTime: '06:00',
      speedDownKbps: 512,
      speedUpKbps: 256,
      enabled: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme =
        _brightness == Brightness.light ? AppTheme.light() : AppTheme.dark();
    return Theme(
      data: theme,
      child: Directionality(
        textDirection: _direction,
        child: Builder(builder: _buildScaffold),
      ),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    final p = AppPalette.of(context);
    return Scaffold(
      backgroundColor: p.bg,
      appBar: AppBar(
        title: const Text('معرض مكونات الواجهة'),
        actions: [
          _ModeButton(
            icon: _brightness == Brightness.light
                ? Icons.dark_mode_outlined
                : Icons.light_mode_outlined,
            label: _brightness == Brightness.light ? 'داكن' : 'فاتح',
            onPressed: () => setState(
              () => _brightness = _brightness == Brightness.light
                  ? Brightness.dark
                  : Brightness.light,
            ),
          ),
          const SizedBox(width: 8),
          _ModeButton(
            icon: Icons.swap_horiz,
            label: _direction == TextDirection.rtl ? 'LTR' : 'RTL',
            onPressed: () => setState(
              () => _direction = _direction == TextDirection.rtl
                  ? TextDirection.ltr
                  : TextDirection.rtl,
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.s16,
          vertical: AppTokens.s24,
        ),
        children: [
          _Section(
            title: 'مفتاح التفعيل',
            child: Wrap(
              spacing: 14,
              runSpacing: 14,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                HubToggleSwitch(
                  value: _toggleA,
                  onChanged: (v) => setState(() => _toggleA = v),
                ),
                HubToggleSwitch(
                  value: _toggleB,
                  size: HubToggleSize.sm,
                  onChanged: (v) => setState(() => _toggleB = v),
                ),
                HubToggleSwitch(
                  value: _toggleA,
                  bare: true,
                  onChanged: (v) => setState(() => _toggleA = v),
                ),
                const HubToggleSwitch(
                  value: true,
                  onChanged: null,
                ),
                HubToggleSwitch(
                  value: false,
                  showLabel: false,
                  onChanged: (v) => setState(() => _toggleA = v),
                ),
              ],
            ),
          ),
          _Section(
            title: 'إدخال القيم والوحدات',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Row2(
                  left: HubUnitInput(
                    value: _speedKbps,
                    kind: HubUnitKind.speed,
                    onChanged: (v) => setState(() => _speedKbps = v),
                  ),
                  right: HubUnitInput(
                    value: _quotaMb,
                    kind: HubUnitKind.quota,
                    onChanged: (v) => setState(() => _quotaMb = v),
                  ),
                ),
                const SizedBox(height: 10),
                _Row2(
                  left: HubUnitInput(
                    value: _timeMin,
                    kind: HubUnitKind.time,
                    onChanged: (v) => setState(() => _timeMin = v),
                  ),
                  right: HubUnitInput(
                    value: _speedKbps,
                    kind: HubUnitKind.speed,
                    units: const ['kbps', 'Mbps'],
                    enabled: false,
                    onChanged: (_) {},
                  ),
                ),
              ],
            ),
          ),
          _Section(
            title: 'اختيار الوقت',
            child: _Row2(
              left: HubTimePickerCircular(
                value: _from,
                onChanged: (v) => setState(() => _from = v),
              ),
              right: HubTimePickerCircular(
                value: _to,
                onChanged: (v) => setState(() => _to = v),
                placeholder: 'اختاري الوقت',
              ),
            ),
          ),
          _Section(
            title: 'جدول السماح',
            child: HubAccessSchedule(
              value: _schedule,
              onChanged: (v) => setState(() => _schedule = v),
            ),
          ),
          _Section(
            title: 'قواعد السرعة',
            child: HubSpeedRulesPanel(
              rules: _rules,
              onChanged: (v) => setState(() => _rules = v),
              helpText: 'اختبر القواعد والإضافة والتعديل والحذف.',
            ),
          ),
          _Section(
            title: 'رسائل التنبيه',
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ElevatedButton.icon(
                  onPressed: () => HubToaster.success(
                    context,
                    'تم الحفظ بنجاح',
                  ),
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('تنبيه نجاح'),
                ),
                OutlinedButton.icon(
                  onPressed: () => HubToaster.error(
                    context,
                    'تعذّر إتمام العملية',
                  ),
                  icon: const Icon(Icons.error_outline, size: 16),
                  label: const Text('تنبيه خطأ'),
                ),
                TextButton.icon(
                  onPressed: () => HubToaster.info(
                    context,
                    'جاري المزامنة…',
                  ),
                  icon: const Icon(Icons.info_outline, size: 16),
                  label: const Text('تنبيه معلومات'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.s24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: AppTokens.s12),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
                color: p.brandInk,
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _Row2 extends StatelessWidget {
  const _Row2({required this.left, required this.right});
  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        const SizedBox(width: AppTokens.s12),
        Expanded(child: right),
      ],
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}
