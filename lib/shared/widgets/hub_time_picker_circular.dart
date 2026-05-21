import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import '../../core/theme/tokens.dart';

/// Canonical analog-clock time picker — Flutter mirror of the web
/// `_partials/time_picker_circular.html` macro.
///
/// Renders a compact pill that, when tapped, opens a circular
/// clock-face dialog. The user picks hour → minute → AM/PM and the
/// result is reported as a 24-hour `HH:MM` string (matching the server
/// contract). Pass `null` / empty to render the placeholder.
class HubTimePickerCircular extends StatelessWidget {
  const HubTimePickerCircular({
    super.key,
    required this.value,
    required this.onChanged,
    this.placeholder = '--:--',
    this.enabled = true,
  });

  /// Current value as 24-hour `HH:MM`, or null / empty for unset.
  final String? value;

  /// Fires with the chosen 24-hour `HH:MM`. Not called on cancel.
  final ValueChanged<String> onChanged;

  final String placeholder;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final hasValue = value != null && value!.trim().isNotEmpty;
    final display = hasValue ? _formatDisplay(value!) : placeholder;

    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: Material(
        color: p.card,
        borderRadius: BorderRadius.circular(AppTokens.r10),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTokens.r10),
          onTap: enabled
              ? () async {
                  final res = await showHubCircularTimePicker(
                    context,
                    initial: value,
                  );
                  if (res != null) onChanged(res);
                }
              : null,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 8,
            ),
            constraints: const BoxConstraints(minHeight: 40),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTokens.r10),
              border: Border.all(color: p.border),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.schedule_outlined,
                  size: 16,
                  color: p.brandInk,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    display,
                    textAlign: TextAlign.start,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: hasValue
                          ? FontWeight.w700
                          : FontWeight.w600,
                      color:
                          hasValue ? p.textPrimary : p.textMuted,
                      fontFeatures: const [
                        FontFeature.tabularFigures(),
                      ],
                    ),
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

/// Opens the circular clock-face dialog. Resolves with a 24-hour
/// `HH:MM` string on confirm, or `null` on cancel / dismiss.
Future<String?> showHubCircularTimePicker(
  BuildContext context, {
  String? initial,
}) {
  return showDialog<String>(
    context: context,
    barrierColor: const Color(0x6B141232),
    builder: (_) => _HubTimePickerDialog(initial: initial),
  );
}

// ───────────────────────────────────────────────────────────────
//  Internals
// ───────────────────────────────────────────────────────────────
String _pad2(int n) => n < 10 ? '0$n' : '$n';

({int h, int m})? _parse24(String? s) {
  if (s == null) return null;
  final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(s.trim());
  if (match == null) return null;
  final h = int.parse(match.group(1)!);
  final m = int.parse(match.group(2)!);
  if (h < 0 || h > 23 || m < 0 || m > 59) return null;
  return (h: h, m: m);
}

({int h, String ap}) _to12(int h24) {
  if (h24 == 0) return (h: 12, ap: 'AM');
  if (h24 == 12) return (h: 12, ap: 'PM');
  if (h24 > 12) return (h: h24 - 12, ap: 'PM');
  return (h: h24, ap: 'AM');
}

int _to24(int h12, String ap) {
  if (ap == 'AM') return h12 == 12 ? 0 : h12;
  return h12 == 12 ? 12 : h12 + 12;
}

String _formatDisplay(String v) {
  final parsed = _parse24(v);
  if (parsed == null) return v;
  final t12 = _to12(parsed.h);
  final tag = t12.ap == 'AM' ? 'ص' : 'م';
  return '${_pad2(t12.h)}:${_pad2(parsed.m)} $tag';
}

enum _PickMode { hour, minute }

class _HubTimePickerDialog extends StatefulWidget {
  const _HubTimePickerDialog({this.initial});
  final String? initial;

  @override
  State<_HubTimePickerDialog> createState() =>
      _HubTimePickerDialogState();
}

class _HubTimePickerDialogState extends State<_HubTimePickerDialog> {
  int _h = 9;
  int _m = 0;
  String _ap = 'AM';
  _PickMode _mode = _PickMode.hour;

  @override
  void initState() {
    super.initState();
    final parsed = _parse24(widget.initial);
    if (parsed != null) {
      final t12 = _to12(parsed.h);
      _h = t12.h;
      _m = parsed.m;
      _ap = t12.ap;
    }
  }

  void _commit() {
    final h24 = _to24(_h, _ap);
    Navigator.of(context).pop('${_pad2(h24)}:${_pad2(_m)}');
  }

  void _now() {
    final now = TimeOfDay.now();
    final t12 = _to12(now.hour);
    setState(() {
      _h = t12.h;
      _m = now.minute;
      _ap = t12.ap;
      _mode = _PickMode.hour;
    });
  }

  void _pickNumber(int value) {
    setState(() {
      if (_mode == _PickMode.hour) {
        _h = value;
        _mode = _PickMode.minute;
      } else {
        _m = value;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Dialog(
      backgroundColor: p.card,
      insetPadding: const EdgeInsets.all(AppTokens.s16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DigitalReadout(
                hour: _h,
                minute: _m,
                ampm: _ap,
                mode: _mode,
                palette: p,
                onPickMode: (m) => setState(() => _mode = m),
                onPickAmPm: (v) => setState(() => _ap = v),
              ),
              const SizedBox(height: 4),
              _ClockFace(
                mode: _mode,
                hour: _h,
                minute: _m,
                palette: p,
                onPick: _pickNumber,
              ),
              const SizedBox(height: 8),
              _ActionRow(
                palette: p,
                onNow: _now,
                onCancel: () => Navigator.of(context).pop(),
                onOk: _commit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DigitalReadout extends StatelessWidget {
  const _DigitalReadout({
    required this.hour,
    required this.minute,
    required this.ampm,
    required this.mode,
    required this.palette,
    required this.onPickMode,
    required this.onPickAmPm,
  });

  final int hour;
  final int minute;
  final String ampm;
  final _PickMode mode;
  final AppPalette palette;
  final ValueChanged<_PickMode> onPickMode;
  final ValueChanged<String> onPickAmPm;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _DisplayNum(
            text: _pad2(hour),
            active: mode == _PickMode.hour,
            palette: palette,
            onTap: () => onPickMode(_PickMode.hour),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Text(
              ':',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w800,
                color: palette.textSecondary,
              ),
            ),
          ),
          _DisplayNum(
            text: _pad2(minute),
            active: mode == _PickMode.minute,
            palette: palette,
            onTap: () => onPickMode(_PickMode.minute),
          ),
          const SizedBox(width: 10),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _AmPmBtn(
                label: 'ص',
                active: ampm == 'AM',
                palette: palette,
                onTap: () => onPickAmPm('AM'),
              ),
              const SizedBox(height: 4),
              _AmPmBtn(
                label: 'م',
                active: ampm == 'PM',
                palette: palette,
                onTap: () => onPickAmPm('PM'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DisplayNum extends StatelessWidget {
  const _DisplayNum({
    required this.text,
    required this.active,
    required this.palette,
    required this.onTap,
  });

  final String text;
  final bool active;
  final AppPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppTokens.motionFast,
        curve: AppTokens.motionEase,
        constraints: const BoxConstraints(minWidth: 56),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          gradient: active ? palette.brandGradient : null,
          borderRadius: BorderRadius.circular(10),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: palette.brand.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w800,
            color: active ? Colors.white : palette.textMuted,
            fontFeatures: const [FontFeature.tabularFigures()],
            height: 1,
          ),
        ),
      ),
    );
  }
}

class _AmPmBtn extends StatelessWidget {
  const _AmPmBtn({
    required this.label,
    required this.active,
    required this.palette,
    required this.onTap,
  });

  final String label;
  final bool active;
  final AppPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppTokens.motionFast,
        curve: AppTokens.motionEase,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          gradient: active ? palette.brandGradient : null,
          color: active ? null : palette.brandSoft,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: active ? Colors.white : palette.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _ClockFace extends StatelessWidget {
  const _ClockFace({
    required this.mode,
    required this.hour,
    required this.minute,
    required this.palette,
    required this.onPick,
  });

  final _PickMode mode;
  final int hour;
  final int minute;
  final AppPalette palette;
  final ValueChanged<int> onPick;

  static const double _size = 248;
  static const double _radius = 96;
  static const double _numCell = 36;

  @override
  Widget build(BuildContext context) {
    final nums = mode == _PickMode.hour
        ? const [12, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]
        : const [0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55];
    final selected = mode == _PickMode.hour
        ? hour
        : minute - (minute % 5);
    final selIdx = nums.indexOf(selected);
    final handIdx = selIdx >= 0 ? selIdx : 0;

    return SizedBox(
      width: _size,
      height: _size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  palette.card,
                  palette.brandSoft,
                ],
              ),
              border: Border.all(color: palette.brandLine, width: 1.5),
            ),
          ),
          CustomPaint(
            size: const Size(_size, _size),
            painter: _HandPainter(
              angle: (handIdx / 12) * math.pi * 2 - math.pi / 2,
              palette: palette,
            ),
          ),
          for (int i = 0; i < nums.length; i++)
            _NumberChip(
              value: nums[i],
              angleIndex: i,
              selected: nums[i] == selected,
              isMinute: mode == _PickMode.minute,
              palette: palette,
              onTap: () => onPick(nums[i]),
            ),
        ],
      ),
    );
  }
}

class _NumberChip extends StatelessWidget {
  const _NumberChip({
    required this.value,
    required this.angleIndex,
    required this.selected,
    required this.isMinute,
    required this.palette,
    required this.onTap,
  });

  final int value;
  final int angleIndex;
  final bool selected;
  final bool isMinute;
  final AppPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final angle = (angleIndex / 12) * math.pi * 2 - math.pi / 2;
    final dx = _ClockFace._radius * math.cos(angle);
    final dy = _ClockFace._radius * math.sin(angle);
    return Transform.translate(
      offset: Offset(dx, dy),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: AnimatedContainer(
            duration: AppTokens.motionFast,
            curve: AppTokens.motionEase,
            width: _ClockFace._numCell,
            height: _ClockFace._numCell,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: selected ? palette.brandGradient : null,
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: palette.brand.withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Text(
              isMinute ? _pad2(value) : '$value',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: selected ? Colors.white : palette.textPrimary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HandPainter extends CustomPainter {
  _HandPainter({required this.angle, required this.palette});
  final double angle;
  final AppPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    // Hand stops just before the number ring so the chip can sit on top.
    const handLen = _ClockFace._radius - _ClockFace._numCell / 2;
    final tip = center +
        Offset(math.cos(angle) * handLen, math.sin(angle) * handLen);
    final line = Paint()
      ..color = palette.brand
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center, tip, line);
    canvas.drawCircle(
      center,
      3,
      Paint()..color = palette.brandInk,
    );
    canvas.drawCircle(tip, 5, Paint()..color = palette.brand);
  }

  @override
  bool shouldRepaint(covariant _HandPainter old) =>
      old.angle != angle || old.palette != palette;
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.palette,
    required this.onNow,
    required this.onCancel,
    required this.onOk,
  });

  final AppPalette palette;
  final VoidCallback onNow;
  final VoidCallback onCancel;
  final VoidCallback onOk;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: palette.border,
              style: BorderStyle.solid,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Row(
            children: [
              TextButton.icon(
                onPressed: onNow,
                icon: Icon(
                  Icons.schedule_outlined,
                  size: 16,
                  color: palette.brandInk,
                ),
                label: Text(
                  'الآن',
                  style: TextStyle(
                    color: palette.brandInk,
                    fontWeight: FontWeight.w800,
                    fontSize: 12.5,
                  ),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: onCancel,
                style: TextButton.styleFrom(
                  backgroundColor: palette.surfaceMuted,
                  foregroundColor: palette.textSecondary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'إلغاء',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              ElevatedButton(
                onPressed: onOk,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'تم',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
