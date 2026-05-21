import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_palette.dart';
import '../../core/theme/tokens.dart';

/// Canonical "number + unit" input — Flutter mirror of the web
/// `_partials/unit_input.html` macro.
///
/// The widget exposes a single canonical base value via [onChanged]
/// (kbps for speed, MB for quota, min for time, KB for size) regardless
/// of the display unit the user is currently typing in. The catalog of
/// kinds, codes, labels, and ratios must stay in lock-step with
/// `app/radius/core/units.py` on the backend.
///
/// Pass an optional [units] whitelist to restrict the dropdown
/// (e.g. `['kbps', 'Mbps']` to hide Gbps from a speed input).
enum HubUnitKind { speed, quota, time, size }

class HubUnit {
  const HubUnit(this.code, this.label, this.ratio);
  final String code;
  final String label;
  final int ratio;
}

/// Catalog of kinds → ordered units (smallest → largest). Mirrors the
/// `UI_LABELS` / `UI_RATIOS` maps in `unit_input.html`.
const Map<HubUnitKind, List<HubUnit>> kHubUnitCatalog = {
  HubUnitKind.speed: [
    HubUnit('kbps', 'Kbps', 1),
    HubUnit('Mbps', 'Mbps', 1024),
    HubUnit('Gbps', 'Gbps', 1048576),
  ],
  HubUnitKind.quota: [
    HubUnit('MB', 'MB', 1),
    HubUnit('GB', 'GB', 1024),
    HubUnit('TB', 'TB', 1048576),
  ],
  HubUnitKind.time: [
    HubUnit('min', 'دقائق', 1),
    HubUnit('hr', 'ساعات', 60),
    HubUnit('day', 'أيام', 1440),
    HubUnit('month', 'شهور', 43200),
  ],
  HubUnitKind.size: [
    HubUnit('KB', 'KB', 1),
    HubUnit('MB', 'MB', 1024),
    HubUnit('GB', 'GB', 1048576),
  ],
};

class HubUnitInput extends StatefulWidget {
  const HubUnitInput({
    super.key,
    required this.value,
    required this.onChanged,
    this.kind = HubUnitKind.speed,
    this.units,
    this.placeholder = '0',
    this.minValue = 0,
    this.enabled = true,
  });

  /// Current canonical base value (kbps / MB / min / KB).
  final int value;

  /// Fired with the new canonical base value on every edit.
  final ValueChanged<int>? onChanged;

  final HubUnitKind kind;

  /// Optional whitelist of unit codes to expose in the dropdown.
  final List<String>? units;

  final String placeholder;
  final int minValue;
  final bool enabled;

  @override
  State<HubUnitInput> createState() => _HubUnitInputState();
}

class _HubUnitInputState extends State<HubUnitInput> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  late HubUnit _selectedUnit;
  late List<HubUnit> _availableUnits;
  bool _suppressNextSync = false;

  @override
  void initState() {
    super.initState();
    _availableUnits = _resolveUnits();
    _selectedUnit = _bestUnit(widget.value, _availableUnits);
    _controller = TextEditingController(text: _displayString(widget.value));
    _focusNode = FocusNode()..addListener(_handleFocus);
    _controller.addListener(_handleTextChanged);
  }

  @override
  void didUpdateWidget(covariant HubUnitInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    final unitsChanged = oldWidget.kind != widget.kind ||
        !_listEq(oldWidget.units, widget.units);
    if (unitsChanged) {
      _availableUnits = _resolveUnits();
      _selectedUnit = _bestUnit(widget.value, _availableUnits);
      _setControllerText(_displayString(widget.value));
      return;
    }
    if (oldWidget.value != widget.value && widget.value != _currentBase()) {
      _selectedUnit = _bestUnit(widget.value, _availableUnits);
      _setControllerText(_displayString(widget.value));
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocus);
    _focusNode.dispose();
    _controller.removeListener(_handleTextChanged);
    _controller.dispose();
    super.dispose();
  }

  // ── Unit helpers ──────────────────────────────────────────────
  List<HubUnit> _resolveUnits() {
    final all = kHubUnitCatalog[widget.kind]!;
    if (widget.units == null || widget.units!.isEmpty) return all;
    final filtered =
        all.where((u) => widget.units!.contains(u.code)).toList();
    return filtered.isEmpty ? all : filtered;
  }

  HubUnit _bestUnit(int base, List<HubUnit> units) {
    if (base <= 0) return units.first;
    HubUnit best = units.first;
    for (final u in units.reversed) {
      if (base >= u.ratio && base % u.ratio == 0) {
        best = u;
        break;
      }
    }
    return best;
  }

  String _displayString(int base) {
    final ratio = _selectedUnit.ratio;
    final raw = base / ratio;
    if (raw == raw.truncateToDouble()) return raw.toInt().toString();
    return (((raw * 100).round()) / 100).toString();
  }

  int _currentBase() {
    final v = double.tryParse(_controller.text.replaceAll(',', '.')) ?? 0;
    return (v * _selectedUnit.ratio).round();
  }

  void _setControllerText(String text) {
    _suppressNextSync = true;
    _controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  void _handleTextChanged() {
    if (_suppressNextSync) {
      _suppressNextSync = false;
      return;
    }
    final base = _currentBase();
    widget.onChanged?.call(base.clamp(widget.minValue, 1 << 62));
  }

  void _handleFocus() => setState(() {});

  void _handleUnitChanged(HubUnit next) {
    if (next.code == _selectedUnit.code) return;
    final baseBefore = _currentBase();
    setState(() => _selectedUnit = next);
    _setControllerText(_displayString(baseBefore));
    widget.onChanged?.call(baseBefore.clamp(widget.minValue, 1 << 62));
  }

  bool _listEq(List<String>? a, List<String>? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  // ── Build ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final focused = _focusNode.hasFocus;
    final borderColor = !widget.enabled
        ? p.borderSoft
        : (focused ? p.brand : p.border);

    return Opacity(
      opacity: widget.enabled ? 1 : 0.55,
      child: AnimatedContainer(
        duration: AppTokens.motionFast,
        curve: AppTokens.motionEase,
        decoration: BoxDecoration(
          color: p.card,
          borderRadius: BorderRadius.circular(AppTokens.r10),
          border: Border.all(color: borderColor),
          boxShadow: focused && widget.enabled
              ? [
                  BoxShadow(
                    color: p.brand.withValues(alpha: 0.15),
                    blurRadius: 0,
                    spreadRadius: 3,
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppTokens.r10 - 1),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  enabled: widget.enabled,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'[0-9\.,]'),
                    ),
                  ],
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: p.textPrimary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                  textAlign: TextAlign.start,
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    hintText: widget.placeholder,
                    hintStyle: TextStyle(
                      color: p.textFaintColor(),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              _UnitDropdown(
                selected: _selectedUnit,
                units: _availableUnits,
                enabled: widget.enabled,
                palette: p,
                onChanged: _handleUnitChanged,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UnitDropdown extends StatelessWidget {
  const _UnitDropdown({
    required this.selected,
    required this.units,
    required this.enabled,
    required this.palette,
    required this.onChanged,
  });

  final HubUnit selected;
  final List<HubUnit> units;
  final bool enabled;
  final AppPalette palette;
  final ValueChanged<HubUnit> onChanged;

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            palette.brandSoft.withValues(alpha: 0.55),
            palette.brandSoft,
          ],
        ),
        border: Border(
          left: isRtl
              ? BorderSide.none
              : BorderSide(color: palette.border),
          right: isRtl
              ? BorderSide(color: palette.border)
              : BorderSide.none,
        ),
      ),
      child: PopupMenuButton<HubUnit>(
        tooltip: '',
        enabled: enabled,
        position: PopupMenuPosition.under,
        onSelected: onChanged,
        constraints: const BoxConstraints(minWidth: 96),
        itemBuilder: (ctx) => [
          for (final u in units)
            PopupMenuItem<HubUnit>(
              value: u,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (u.code == selected.code) ...[
                    Icon(Icons.check, size: 14, color: palette.brandInk),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    u.label,
                    style: TextStyle(
                      color: palette.textPrimary,
                      fontWeight: u.code == selected.code
                          ? FontWeight.w800
                          : FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 78, minHeight: 36),
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(22, 0, 12, 0),
            child: Stack(
              alignment: Alignment.center,
              children: [
                PositionedDirectional(
                  start: -14,
                  top: 0,
                  bottom: 0,
                  child: Icon(
                    Icons.expand_more,
                    size: 14,
                    color: palette.brand,
                  ),
                ),
                Text(
                  selected.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: palette.brandInk,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

extension on AppPalette {
  /// Hint text color — not part of the canonical palette API yet, so
  /// derived locally from the muted text token.
  Color textFaintColor() => textMuted.withValues(alpha: 0.7);
}
