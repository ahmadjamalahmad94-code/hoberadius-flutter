import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import '../../core/theme/tokens.dart';
import 'hub_access_schedule.dart' show kAccessDays, kAccessDayNames;
import 'hub_time_picker_circular.dart';
import 'hub_toggle_switch.dart';
import 'hub_unit_input.dart';

/// Canonical speed-rules panel — Flutter mirror of the web
/// `templates/radius/_speed_rules_panel.html` partial.
///
/// Hosts a list of [SpeedRule]s with a summary-then-expand interaction
/// model: each rule renders as a compact pill that, when "تعديل" is
/// tapped, expands to a full editor (name + days + من/إلى times +
/// download/upload speeds + restore mode + priority + enabled).
///
/// The bottom "إضافة قاعدة جديدة" card stages a new rule which is
/// appended to the list only when the operator taps "اعتماد القاعدة".
/// Bulk actions (تفعيل الكل / تعطيل الكل) flip every rule's `enabled`.
enum SpeedRestoreMode { profileDefault, keepCurrent, disconnect }

const Map<SpeedRestoreMode, String> kSpeedRestoreLabels = {
  SpeedRestoreMode.profileDefault: 'الرجوع للسرعة الأساسية',
  SpeedRestoreMode.keepCurrent: 'إبقاء آخر سرعة',
  SpeedRestoreMode.disconnect: 'فصل الجلسة',
};

const Map<SpeedRestoreMode, String> kSpeedRestoreCodes = {
  SpeedRestoreMode.profileDefault: 'profile_default',
  SpeedRestoreMode.keepCurrent: 'keep_current',
  SpeedRestoreMode.disconnect: 'disconnect',
};

class SpeedRule {
  const SpeedRule({
    this.id,
    this.name = 'قاعدة سرعة',
    this.days = const [],
    this.startsAtTime = '',
    this.endsAtTime = '',
    this.speedDownKbps = 0,
    this.speedUpKbps = 0,
    this.restoreMode = SpeedRestoreMode.profileDefault,
    this.priority = 5,
    this.enabled = true,
    this.notes = '',
  });

  final int? id;
  final String name;
  final List<String> days;
  final String startsAtTime;
  final String endsAtTime;
  final int speedDownKbps;
  final int speedUpKbps;
  final SpeedRestoreMode restoreMode;
  final int priority;
  final bool enabled;
  final String notes;

  SpeedRule copyWith({
    int? id,
    String? name,
    List<String>? days,
    String? startsAtTime,
    String? endsAtTime,
    int? speedDownKbps,
    int? speedUpKbps,
    SpeedRestoreMode? restoreMode,
    int? priority,
    bool? enabled,
    String? notes,
  }) =>
      SpeedRule(
        id: id ?? this.id,
        name: name ?? this.name,
        days: days ?? this.days,
        startsAtTime: startsAtTime ?? this.startsAtTime,
        endsAtTime: endsAtTime ?? this.endsAtTime,
        speedDownKbps: speedDownKbps ?? this.speedDownKbps,
        speedUpKbps: speedUpKbps ?? this.speedUpKbps,
        restoreMode: restoreMode ?? this.restoreMode,
        priority: priority ?? this.priority,
        enabled: enabled ?? this.enabled,
        notes: notes ?? this.notes,
      );
}

class HubSpeedRulesPanel extends StatefulWidget {
  const HubSpeedRulesPanel({
    super.key,
    required this.rules,
    required this.onChanged,
    this.title = 'قواعد السرعة المجدولة',
    this.helpText,
  });

  final List<SpeedRule> rules;
  final ValueChanged<List<SpeedRule>> onChanged;
  final String title;
  final String? helpText;

  @override
  State<HubSpeedRulesPanel> createState() => _HubSpeedRulesPanelState();
}

class _HubSpeedRulesPanelState extends State<HubSpeedRulesPanel> {
  final Set<int> _expandedIndexes = {};

  void _updateRule(int i, SpeedRule next) {
    final list = List<SpeedRule>.from(widget.rules);
    list[i] = next;
    widget.onChanged(list);
  }

  void _removeRule(int i) {
    final list = List<SpeedRule>.from(widget.rules)..removeAt(i);
    _expandedIndexes.remove(i);
    widget.onChanged(list);
  }

  void _addRule(SpeedRule rule) {
    widget.onChanged([...widget.rules, rule]);
  }

  void _bulkSetEnabled(bool enabled) {
    widget.onChanged(
      widget.rules.map((r) => r.copyWith(enabled: enabled)).toList(),
    );
  }

  void _toggleExpanded(int i) {
    setState(() {
      if (_expandedIndexes.contains(i)) {
        _expandedIndexes.remove(i);
      } else {
        _expandedIndexes.add(i);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(AppTokens.r18),
        border: Border.all(color: p.border),
        boxShadow: p.shCard,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [p.brandSoft.withValues(alpha: 0.35), p.card],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PanelHeader(
            title: widget.title,
            helpText: widget.helpText,
            hasRules: widget.rules.isNotEmpty,
            onEnableAll: () => _bulkSetEnabled(true),
            onDisableAll: () => _bulkSetEnabled(false),
          ),
          const SizedBox(height: 16),
          if (widget.rules.isEmpty)
            const _EmptyState()
          else
            for (int i = 0; i < widget.rules.length; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              _RuleCard(
                rule: widget.rules[i],
                expanded: _expandedIndexes.contains(i),
                onToggle: () => _toggleExpanded(i),
                onChanged: (r) => _updateRule(i, r),
                onRemove: () => _removeRule(i),
              ),
            ],
          const SizedBox(height: 14),
          _AddRuleCard(onAdd: _addRule),
        ],
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────
//  Header
// ───────────────────────────────────────────────────────────────
class _PanelHeader extends StatelessWidget {
  const _PanelHeader({
    required this.title,
    required this.helpText,
    required this.hasRules,
    required this.onEnableAll,
    required this.onDisableAll,
  });

  final String title;
  final String? helpText;
  final bool hasRules;
  final VoidCallback onEnableAll;
  final VoidCallback onDisableAll;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: p.border)),
        ),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.spaceBetween,
            runSpacing: 8,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: p.brandSoft,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.speed,
                      size: 18,
                      color: p.brandInk,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: p.textPrimary,
                          ),
                        ),
                        if (helpText != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            helpText!,
                            style: TextStyle(
                              fontSize: 12,
                              color: p.textMuted,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              if (hasRules)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _BulkButton(
                      icon: Icons.toggle_on_outlined,
                      label: 'تفعيل الكل',
                      onPressed: onEnableAll,
                    ),
                    const SizedBox(width: 6),
                    _BulkButton(
                      icon: Icons.toggle_off_outlined,
                      label: 'تعطيل الكل',
                      onPressed: onDisableAll,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BulkButton extends StatelessWidget {
  const _BulkButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: p.brandSoft,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: p.brandLine),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: p.brandInk),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: p.brandInk,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
      decoration: BoxDecoration(
        color: p.surfaceMuted,
        borderRadius: BorderRadius.circular(AppTokens.r10),
        border: Border.all(
          color: p.border,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(Icons.schedule, size: 22, color: p.brandInk),
          const SizedBox(height: 6),
          Text(
            'لا توجد قواعد سرعة بعد. أضف قاعدة جديدة من البطاقة أدناه.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: p.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────
//  Rule card (summary + expandable detail)
// ───────────────────────────────────────────────────────────────
class _RuleCard extends StatelessWidget {
  const _RuleCard({
    required this.rule,
    required this.expanded,
    required this.onToggle,
    required this.onChanged,
    required this.onRemove,
  });

  final SpeedRule rule;
  final bool expanded;
  final VoidCallback onToggle;
  final ValueChanged<SpeedRule> onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final accent = expanded
        ? p.brand
        : (rule.enabled ? p.successStrong : p.dangerStrong);
    return AnimatedContainer(
      duration: AppTokens.motionFast,
      curve: AppTokens.motionEase,
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(14),
        border: Border(
          top: BorderSide(color: p.border, width: 1.5),
          right: BorderSide(color: p.border, width: 1.5),
          bottom: BorderSide(color: p.border, width: 1.5),
          left: BorderSide(color: accent, width: 4),
        ),
        boxShadow: expanded
            ? [
                BoxShadow(
                  color: p.brand.withValues(alpha: 0.12),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!expanded)
            _RuleSummary(
              rule: rule,
              onEdit: onToggle,
              onDelete: onRemove,
            )
          else
            _RuleDetail(
              rule: rule,
              onChanged: onChanged,
              onCollapse: onToggle,
              onDelete: onRemove,
            ),
        ],
      ),
    );
  }
}

class _RuleSummary extends StatelessWidget {
  const _RuleSummary({
    required this.rule,
    required this.onEdit,
    required this.onDelete,
  });

  final SpeedRule rule;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final enabled = rule.enabled;
    final timeText = _formatTimeRange(rule.startsAtTime, rule.endsAtTime);
    final speedText = _formatSpeedPair(rule.speedDownKbps, rule.speedUpKbps);
    final daysText = _formatDays(rule.days);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 10,
        runSpacing: 8,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: enabled ? p.successStrong : p.borderStrong,
              boxShadow: enabled
                  ? [
                      BoxShadow(
                        color: p.successStrong.withValues(alpha: 0.3),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: Text(
              rule.name,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: enabled ? p.textPrimary : p.textMuted,
                decoration: enabled ? null : TextDecoration.lineThrough,
              ),
            ),
          ),
          _SummaryChip(icon: Icons.schedule_outlined, label: timeText),
          _SummaryChip(icon: Icons.swap_vert, label: speedText),
          _SummaryChip(icon: Icons.calendar_today_outlined, label: daysText),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: enabled ? p.successBg : p.dangerBg,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  enabled
                      ? Icons.check_circle_outline
                      : Icons.pause_circle_outline,
                  size: 12,
                  color: enabled ? p.successFg : p.dangerFg,
                ),
                const SizedBox(width: 4),
                Text(
                  enabled ? 'مفعَّلة' : 'معطَّلة',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: enabled ? p.successFg : p.dangerFg,
                  ),
                ),
              ],
            ),
          ),
          _PillButton(
            icon: Icons.edit_outlined,
            label: 'تعديل',
            onPressed: onEdit,
          ),
          _PillButton(
            icon: Icons.delete_outline,
            label: '',
            tone: _PillTone.danger,
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: p.brand.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: p.brand.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: p.brandInk),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: p.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

enum _PillTone { brand, danger }

class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.tone = _PillTone.brand,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final _PillTone tone;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final (bg, fg) = tone == _PillTone.brand
        ? (p.brandSoft, p.brandInk)
        : (p.dangerBg, p.dangerFg);
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onPressed,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: label.isEmpty ? 9 : 12,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: fg),
            if (label.isNotEmpty) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: fg,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────
//  Rule detail (expanded editor)
// ───────────────────────────────────────────────────────────────
class _RuleDetail extends StatefulWidget {
  const _RuleDetail({
    required this.rule,
    required this.onChanged,
    required this.onCollapse,
    required this.onDelete,
  });

  final SpeedRule rule;
  final ValueChanged<SpeedRule> onChanged;
  final VoidCallback onCollapse;
  final VoidCallback onDelete;

  @override
  State<_RuleDetail> createState() => _RuleDetailState();
}

class _RuleDetailState extends State<_RuleDetail> {
  late TextEditingController _nameCtrl;
  late TextEditingController _priorityCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.rule.name);
    _priorityCtrl =
        TextEditingController(text: widget.rule.priority.toString());
  }

  @override
  void didUpdateWidget(covariant _RuleDetail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rule.name != widget.rule.name &&
        widget.rule.name != _nameCtrl.text) {
      _nameCtrl.text = widget.rule.name;
    }
    if (oldWidget.rule.priority != widget.rule.priority &&
        widget.rule.priority.toString() != _priorityCtrl.text) {
      _priorityCtrl.text = widget.rule.priority.toString();
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priorityCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final r = widget.rule;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _LabeledField(
            label: 'اسم القاعدة',
            child: _PlainTextField(
              controller: _nameCtrl,
              onChanged: (v) =>
                  widget.onChanged(r.copyWith(name: v)),
            ),
          ),
          const SizedBox(height: 12),
          _LabeledField(
            label: 'الأيام (فاضي = كل الأيام)',
            child: _DayChips(
              selected: r.days.toSet(),
              onChanged: (days) =>
                  widget.onChanged(r.copyWith(days: days.toList())),
            ),
          ),
          const SizedBox(height: 12),
          _FieldGrid(
            children: [
              _LabeledField(
                label: 'من الساعة',
                child: HubTimePickerCircular(
                  value: r.startsAtTime,
                  onChanged: (v) =>
                      widget.onChanged(r.copyWith(startsAtTime: v)),
                ),
              ),
              _LabeledField(
                label: 'إلى الساعة',
                child: HubTimePickerCircular(
                  value: r.endsAtTime,
                  onChanged: (v) =>
                      widget.onChanged(r.copyWith(endsAtTime: v)),
                ),
              ),
              _LabeledField(
                label: 'سرعة التنزيل',
                child: HubUnitInput(
                  value: r.speedDownKbps,
                  units: const ['kbps', 'Mbps'],
                  onChanged: (v) =>
                      widget.onChanged(r.copyWith(speedDownKbps: v)),
                ),
              ),
              _LabeledField(
                label: 'سرعة الرفع',
                child: HubUnitInput(
                  value: r.speedUpKbps,
                  units: const ['kbps', 'Mbps'],
                  onChanged: (v) =>
                      widget.onChanged(r.copyWith(speedUpKbps: v)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _FieldGrid(
            children: [
              _LabeledField(
                label: 'بعد الانتهاء',
                child: _RestoreModeDropdown(
                  value: r.restoreMode,
                  onChanged: (m) =>
                      widget.onChanged(r.copyWith(restoreMode: m)),
                ),
              ),
              _LabeledField(
                label: 'الأولوية (1-10)',
                child: _PlainTextField(
                  controller: _priorityCtrl,
                  keyboardType: TextInputType.number,
                  onChanged: (v) {
                    final n = int.tryParse(v) ?? r.priority;
                    final clamped = n.clamp(1, 10);
                    widget.onChanged(r.copyWith(priority: clamped));
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: p.border)),
            ),
            child: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 10,
                runSpacing: 8,
                children: [
                  HubToggleSwitch(
                    value: r.enabled,
                    onChanged: (v) =>
                        widget.onChanged(r.copyWith(enabled: v)),
                    onLabel: 'مفعَّلة',
                    offLabel: 'معطَّلة',
                  ),
                  const Spacer(),
                  _PillButton(
                    icon: Icons.close,
                    label: 'إغلاق',
                    onPressed: widget.onCollapse,
                  ),
                  _PillButton(
                    icon: Icons.delete_outline,
                    label: 'حذف',
                    tone: _PillTone.danger,
                    onPressed: widget.onDelete,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RestoreModeDropdown extends StatelessWidget {
  const _RestoreModeDropdown({required this.value, required this.onChanged});
  final SpeedRestoreMode value;
  final ValueChanged<SpeedRestoreMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(AppTokens.r10),
        border: Border.all(color: p.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<SpeedRestoreMode>(
          isExpanded: true,
          value: value,
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
          items: SpeedRestoreMode.values
              .map(
                (m) => DropdownMenuItem(
                  value: m,
                  child: Text(
                    kSpeedRestoreLabels[m]!,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: p.textPrimary,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────
//  Add-rule card
// ───────────────────────────────────────────────────────────────
class _AddRuleCard extends StatefulWidget {
  const _AddRuleCard({required this.onAdd});
  final ValueChanged<SpeedRule> onAdd;

  @override
  State<_AddRuleCard> createState() => _AddRuleCardState();
}

class _AddRuleCardState extends State<_AddRuleCard> {
  SpeedRule _draft = const SpeedRule();
  final _nameCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _confirm() {
    final name = _nameCtrl.text.trim();
    final next =
        name.isEmpty ? _draft.copyWith(name: 'قاعدة سرعة') : _draft.copyWith(name: name);
    widget.onAdd(next);
    setState(() {
      _draft = const SpeedRule();
      _nameCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: p.brandSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.brand, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.add_circle_outline, size: 14, color: p.brandInk),
              const SizedBox(width: 8),
              Text(
                'إضافة قاعدة سرعة جديدة',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: p.brandInk,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _LabeledField(
            label: 'اسم القاعدة',
            child: _PlainTextField(
              controller: _nameCtrl,
              hint: 'مثال: سرعة المساء',
            ),
          ),
          const SizedBox(height: 12),
          _LabeledField(
            label: 'الأيام (فاضي = كل الأيام)',
            child: _DayChips(
              selected: _draft.days.toSet(),
              onChanged: (days) =>
                  setState(() => _draft = _draft.copyWith(days: days.toList())),
            ),
          ),
          const SizedBox(height: 12),
          _FieldGrid(
            children: [
              _LabeledField(
                label: 'من الساعة',
                child: HubTimePickerCircular(
                  value: _draft.startsAtTime,
                  onChanged: (v) => setState(
                    () => _draft = _draft.copyWith(startsAtTime: v),
                  ),
                ),
              ),
              _LabeledField(
                label: 'إلى الساعة',
                child: HubTimePickerCircular(
                  value: _draft.endsAtTime,
                  onChanged: (v) => setState(
                    () => _draft = _draft.copyWith(endsAtTime: v),
                  ),
                ),
              ),
              _LabeledField(
                label: 'سرعة التنزيل',
                child: HubUnitInput(
                  value: _draft.speedDownKbps,
                  units: const ['kbps', 'Mbps'],
                  onChanged: (v) => setState(
                    () => _draft = _draft.copyWith(speedDownKbps: v),
                  ),
                ),
              ),
              _LabeledField(
                label: 'سرعة الرفع',
                child: HubUnitInput(
                  value: _draft.speedUpKbps,
                  units: const ['kbps', 'Mbps'],
                  onChanged: (v) => setState(
                    () => _draft = _draft.copyWith(speedUpKbps: v),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _LabeledField(
            label: 'بعد الانتهاء',
            child: _RestoreModeDropdown(
              value: _draft.restoreMode,
              onChanged: (m) => setState(
                () => _draft = _draft.copyWith(restoreMode: m),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: ElevatedButton.icon(
              onPressed: _confirm,
              icon: const Icon(Icons.check, size: 16),
              label: const Text(
                'اعتماد القاعدة',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────
//  Shared building blocks
// ───────────────────────────────────────────────────────────────
class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: p.textSecondary,
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _FieldGrid extends StatelessWidget {
  const _FieldGrid({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final cols = c.maxWidth >= 720 ? 4 : (c.maxWidth >= 420 ? 2 : 1);
        return Wrap(
          spacing: 14,
          runSpacing: 12,
          children: [
            for (final child in children)
              SizedBox(
                width:
                    (c.maxWidth - (cols - 1) * 14) / cols,
                child: child,
              ),
          ],
        );
      },
    );
  }
}

class _PlainTextField extends StatelessWidget {
  const _PlainTextField({
    required this.controller,
    this.onChanged,
    this.hint,
    this.keyboardType,
  });

  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final String? hint;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return TextField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: keyboardType,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: p.textPrimary,
      ),
      decoration: InputDecoration(
        isDense: true,
        hintText: hint,
        hintStyle: TextStyle(color: p.textMuted),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 9,
        ),
        filled: true,
        fillColor: p.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.r10),
          borderSide: BorderSide(color: p.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.r10),
          borderSide: BorderSide(color: p.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.r10),
          borderSide: BorderSide(color: p.brand, width: 1.6),
        ),
      ),
    );
  }
}

class _DayChips extends StatelessWidget {
  const _DayChips({required this.selected, required this.onChanged});

  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Wrap(
      spacing: 5,
      runSpacing: 5,
      children: [
        for (final code in kAccessDays)
          InkWell(
            borderRadius: BorderRadius.circular(9),
            onTap: () {
              final next = Set<String>.from(selected);
              if (!next.add(code)) next.remove(code);
              onChanged(next);
            },
            child: AnimatedContainer(
              duration: AppTokens.motionFast,
              curve: AppTokens.motionEase,
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                gradient: selected.contains(code) ? p.brandGradient : null,
                color: selected.contains(code) ? null : p.card,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(
                  color: selected.contains(code)
                      ? Colors.transparent
                      : p.border,
                  width: 1.5,
                ),
              ),
              child: Text(
                kAccessDayNames[code] ?? code,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: selected.contains(code)
                      ? Colors.white
                      : p.textSecondary,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ───────────────────────────────────────────────────────────────
//  Format helpers
// ───────────────────────────────────────────────────────────────
String _formatTimeRange(String from, String to) {
  final f = _fmtTime12(from);
  final t = _fmtTime12(to);
  return '$f ← $t';
}

String _fmtTime12(String v) {
  if (v.isEmpty || !v.contains(':')) return '--:--';
  final parts = v.split(':');
  final h = int.tryParse(parts[0]) ?? -1;
  if (h < 0) return '--:--';
  final mm = parts.length > 1 ? parts[1].padLeft(2, '0') : '00';
  if (h == 0) return '12:$mm ص';
  if (h < 12) return '${h.toString().padLeft(2, '0')}:$mm ص';
  if (h == 12) return '12:$mm م';
  return '${(h - 12).toString().padLeft(2, '0')}:$mm م';
}

String _formatSpeedPair(int down, int up) {
  return '↓ ${_fmtKbps(down)} · ↑ ${_fmtKbps(up)}';
}

String _fmtKbps(int kbps) {
  if (kbps >= 1024 && kbps % 1024 == 0) return '${kbps ~/ 1024} Mbps';
  if (kbps >= 1024) return '${(kbps / 1024).toStringAsFixed(1)} Mbps';
  return '$kbps Kbps';
}

String _formatDays(List<String> days) {
  if (days.isEmpty || days.length == 7) return 'كل الأيام';
  if (days.length <= 3) {
    return days.map((d) => kAccessDayNames[d] ?? d).join(' · ');
  }
  return '${days.length} أيام';
}
