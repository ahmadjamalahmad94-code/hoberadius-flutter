import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../../core/theme/tokens.dart';
import '../../../../shared/widgets/form_field_row.dart';
import '../../../../shared/widgets/hub_layout.dart';
import '../../../../shared/widgets/hub_switch_row.dart';
import '../../../../shared/widgets/status_pill.dart';
import '../../../plans/domain/plan_model.dart';
import '../../data/subscriber_actions_repository.dart';
import '../../domain/subscriber_actions_model.dart';
import 'action_dialog_kit.dart';
import 'plan_picker.dart';

/// What a finished action reports back to the caller: the toast text, and
/// whether it is a plain success or an informational outcome (e.g. a loan
/// waiting for the owner's approval).
class ActionOutcome {
  const ActionOutcome(this.message, {this.info = false, this.renamedTo});
  final String message;
  final bool info;

  /// Set by the rename dialog — pages keyed by username must follow it.
  final String? renamedTo;
}

/// Opens [dialog] on the ROOT navigator (the shell pages live in one scroll
/// view; an inner-navigator dialog renders off-screen).
Future<ActionOutcome?> showActionDialog(BuildContext context, Widget dialog) {
  return showDialog<ActionOutcome>(
    context: context,
    useRootNavigator: true,
    builder: (_) => dialog,
  );
}

final _dateTime = DateFormat('yyyy-MM-dd  HH:mm', 'en');
final _date = DateFormat('yyyy-MM-dd', 'en');

String _fmtExpire(DateTime? t) => t == null ? 'بدون انتهاء' : _date.format(t);

String _fmtMb(double? mb) {
  if (mb == null) return '—';
  if (mb >= 1024) {
    final gb = mb / 1024;
    final v = gb == gb.roundToDouble()
        ? gb.toStringAsFixed(0)
        : gb.toStringAsFixed(1);
    return '\u2066$v GB\u2069';
  }
  return '\u2066${mb.toStringAsFixed(0)} MB\u2069';
}

/// Busy/error bookkeeping shared by every action dialog: [run] shows the
/// spinner, pops with the outcome on success, or keeps the dialog open with
/// the server's Arabic message.
mixin _ActionRunner<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  bool busy = false;
  String? error;

  SubscriberActionsRepository get repo =>
      ref.read(subscriberActionsRepositoryProvider);

  Future<void> run(Future<ActionOutcome> Function() task) async {
    FocusScope.of(context).unfocus();
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final outcome = await task();
      if (!mounted) return;
      Navigator.of(context).pop(outcome);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        busy = false;
        error = mapActionError(e).message;
      });
    }
  }
}

/// Current plan / price / expiry strip at the top of a dialog.
class _CurrentStrip extends StatelessWidget {
  const _CurrentStrip({required this.c});
  final SubscriberActionsContext c;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.s12),
      child: InfoGrid(
        columns: 3,
        items: [
          InfoItem(
            icon: Icons.layers_outlined,
            label: 'العرض الحالي',
            value: c.planName.isEmpty ? '—' : c.planName,
          ),
          InfoItem(
            icon: Icons.sell_outlined,
            label: 'سعر الباقة',
            value: c.effectivePrice > 0
                ? formatMoney(c.effectivePrice, c.currency)
                : '—',
          ),
          InfoItem(
            icon: Icons.event_outlined,
            label: 'ينتهي',
            value: _fmtExpire(c.expireAt),
          ),
        ],
      ),
    );
  }
}

List<ChoiceOption<ChargeMode>> _chargeOptions({bool paidEnabled = true}) => [
      const ChoiceOption(
        ChargeMode.free,
        'مجاني',
        icon: Icons.card_giftcard_outlined,
      ),
      ChoiceOption(
        ChargeMode.paid,
        'مدفوع — نقدًا',
        icon: Icons.payments_outlined,
        enabled: paidEnabled,
      ),
      ChoiceOption(
        ChargeMode.debt,
        'مدفوع — دين',
        icon: Icons.receipt_long_outlined,
        enabled: paidEnabled,
      ),
    ];

Widget _notesField(TextEditingController ctrl, {String label = 'ملاحظات'}) =>
    FormFieldRow(
      label: label,
      child: TextField(
        controller: ctrl,
        minLines: 2,
        maxLines: 3,
        decoration: actionFieldDecoration,
      ),
    );

Widget _gap([double h = AppTokens.s12]) => SizedBox(height: h);

// ═════════════════════════════════════════════════════════════════════════
//  1. تجديد / إضافة وقت
// ═════════════════════════════════════════════════════════════════════════

class ExtendDialog extends ConsumerStatefulWidget {
  const ExtendDialog({super.key, required this.c, this.now});
  final SubscriberActionsContext c;

  /// Injected clock for tests.
  final DateTime? now;

  @override
  ConsumerState<ExtendDialog> createState() => _ExtendDialogState();
}

class _ExtendDialogState extends ConsumerState<ExtendDialog>
    with _ActionRunner {
  ExtendMode _mode = ExtendMode.duration;
  ChargeMode _charge = ChargeMode.free;
  int _unit = 1440;
  final _amount = TextEditingController(text: '1');
  final _notes = TextEditingController();
  late DateTime _exact;

  SubscriberActionsContext get c => widget.c;
  DateTime get _now => widget.now ?? DateTime.now();

  @override
  void initState() {
    super.initState();
    _exact = defaultExactExpiry(c.expireAt, _now);
  }

  @override
  void dispose() {
    _amount.dispose();
    _notes.dispose();
    super.dispose();
  }

  int get _minutes {
    if (_mode == ExtendMode.exact) {
      return exactExtendMinutes(_exact, c.expireAt, _now);
    }
    final v = parseLocalizedNumber(_amount.text) ?? 0;
    return v <= 0 ? 0 : (v * _unit).round();
  }

  double get _price => priceForMinutes(
        effectivePrice: c.effectivePrice,
        planMinutes: c.planMinutes,
        minutes: _minutes,
        mode: _charge,
      );

  String? get _invalid {
    if (_mode == ExtendMode.duration && _minutes <= 0) {
      return 'أدخل مدّة أكبر من صفر.';
    }
    return null;
  }

  Future<void> _pickExact() async {
    final day = await showDatePicker(
      context: context,
      initialDate: _exact,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'تاريخ الانتهاء',
    );
    if (day == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_exact),
      helpText: 'ساعة الانتهاء',
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    final t = time ?? TimeOfDay.fromDateTime(_exact);
    setState(() {
      _exact = DateTime(day.year, day.month, day.day, t.hour, t.minute);
    });
  }

  String get _chargeHint {
    if (_charge == ChargeMode.free) {
      return 'إضافة وقت مجانية بدون أي قيمة مالية.';
    }
    if (_price > 0) {
      return 'سعر الوقت المُضاف ${formatMoney(_price, c.currency)} '
          '(حسب سعر العرض ${formatMoney(c.effectivePrice, c.currency)}).'
          '${_charge == ChargeMode.paid ? ' تُخصم من رصيد المشترك.' : ' تُسجَّل كدين على المشترك.'}';
    }
    return 'حدّد المدة لاحتساب السعر تلقائيًا حسب سعر العرض/المخصّص.';
  }

  Future<void> _submit() => run(() async {
        if (c.legacy) {
          final res = await repo.extendTimeLegacy(c.username, _minutes);
          return ActionOutcome(_doneMessage(res['new_expire_at']));
        }
        final res = await repo.extend(
          c.username,
          extendPayload(
            mode: _mode,
            minutes: _minutes,
            expireAt: _exact,
            charge: _charge,
            amount: _price,
            notes: _notes.text,
          ),
        );
        return ActionOutcome(_doneMessage(res['new_expire_at']));
      });

  String _doneMessage(Object? rawExpire) {
    final t = parseServerUtc(rawExpire);
    return t == null
        ? 'تمت إضافة الوقت لـ ${c.username}'
        : 'تمت إضافة الوقت — ينتهي ${_dateTime.format(t)}';
  }

  @override
  Widget build(BuildContext context) {
    final legacy = c.legacy;
    return ActionDialogFrame(
      icon: Icons.more_time_outlined,
      tone: PillTone.green,
      title: 'إضافة وقت',
      subtitle: c.username,
      busy: busy,
      error: error,
      confirmLabel: 'إضافة',
      confirmIcon: Icons.add,
      onConfirm: _invalid == null ? _submit : null,
      children: [
        _CurrentStrip(c: c),
        const ActionFieldLabel('طريقة التحديد'),
        ChoiceTiles<ExtendMode>(
          value: _mode,
          onChanged: (v) => setState(() => _mode = v),
          options: [
            const ChoiceOption(
              ExtendMode.duration,
              'إضافة مدّة',
              icon: Icons.hourglass_bottom_outlined,
              caption: 'تُضاف فوق نهايته الحاليّة.',
            ),
            ChoiceOption(
              ExtendMode.exact,
              'تاريخ وساعة الانتهاء',
              icon: Icons.event_available_outlined,
              caption: 'تُعيَّن اللحظة بالضبط.',
              enabled: !legacy,
            ),
          ],
        ),
        _gap(),
        if (_mode == ExtendMode.duration)
          FormFieldPair(
            first: FormFieldRow(
              label: 'المدّة',
              child: TextField(
                controller: _amount,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: numberInputFormatters,
                decoration: actionFieldDecoration,
                onChanged: (_) => setState(() {}),
              ),
            ),
            second: FormFieldRow(
              label: 'الوحدة',
              child: DropdownButtonFormField<int>(
                initialValue: _unit,
                isExpanded: true,
                decoration: actionFieldDecoration,
                items: [
                  for (final (m, label) in kDurationUnits)
                    DropdownMenuItem(value: m, child: Text(label)),
                ],
                onChanged: (v) => setState(() => _unit = v ?? 1440),
              ),
            ),
          )
        else
          FormFieldRow(
            label: 'ينتهي في',
            hint: 'بتوقيتك المحلّي',
            child: _DateTimeTile(value: _exact, onTap: _pickExact),
          ),
        if (_invalid != null) ...[
          ActionNote(text: _invalid!, tone: PillTone.amber),
          _gap(),
        ],
        const ActionFieldLabel('طريقة الإضافة'),
        ChoiceTiles<ChargeMode>(
          value: _charge,
          onChanged: (v) => setState(() => _charge = v),
          options: _chargeOptions(paidEnabled: !legacy),
        ),
        const SizedBox(height: 6),
        ActionNote(
          text: legacy
              ? 'هذا الخادم لم يُحدَّث بعد: الإضافة المجانية بالمدّة فقط.'
              : _chargeHint,
          tone: legacy ? PillTone.amber : PillTone.blue,
        ),
        _gap(),
        if (_charge != ChargeMode.free)
          FormFieldPair(
            first: FormFieldRow(
              label: 'السعر (يُحتسب تلقائيًا)',
              child: ReadOnlyValue(
                value: _price.toStringAsFixed(2),
                emphasis: true,
              ),
            ),
            second: FormFieldRow(
              label: 'العملة',
              child: ReadOnlyValue(value: c.currency),
            ),
          ),
        if (!legacy) _notesField(_notes),
      ],
    );
  }
}

class _DateTimeTile extends StatelessWidget {
  const _DateTimeTile({required this.value, required this.onTap});
  final DateTime value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppTokens.r10),
      onTap: onTap,
      child: InputDecorator(
        decoration: actionFieldDecoration.copyWith(
          suffixIcon: const Icon(Icons.event_outlined, size: 20),
        ),
        child: Text(
          _dateTime.format(value),
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.right,
          style: Theme.of(context)
              .textTheme
              .bodyLarge
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
//  2. إضافة كوتة / جيجا
// ═════════════════════════════════════════════════════════════════════════

class QuotaTopupDialog extends ConsumerStatefulWidget {
  const QuotaTopupDialog({super.key, required this.c});
  final SubscriberActionsContext c;

  @override
  ConsumerState<QuotaTopupDialog> createState() => _QuotaTopupDialogState();
}

class _QuotaTopupDialogState extends ConsumerState<QuotaTopupDialog>
    with _ActionRunner {
  final _size = TextEditingController();
  final _money = TextEditingController(text: '0');
  final _notes = TextEditingController();
  int _unitMb = 1024;
  String _target = 'combined';
  ChargeMode _charge = ChargeMode.free;

  SubscriberActionsContext get c => widget.c;

  @override
  void dispose() {
    _size.dispose();
    _money.dispose();
    _notes.dispose();
    super.dispose();
  }

  double get _quotaMb => (parseLocalizedNumber(_size.text) ?? 0) * _unitMb;
  double get _amount => parseLocalizedNumber(_money.text) ?? 0;

  String? get _invalid {
    if (_quotaMb <= 0) return 'أدخل حجم الكوتة.';
    if (_charge != ChargeMode.free && _amount <= 0) {
      return 'أدخل المبلغ للإضافة المدفوعة.';
    }
    return null;
  }

  Future<void> _submit() => run(() async {
        await repo.quotaTopup(
          c.username,
          quotaMb: _quotaMb,
          target: _target,
          charge: _charge,
          amount: _amount,
          notes: _notes.text,
        );
        return ActionOutcome('تمت إضافة ${_fmtMb(_quotaMb)} لـ ${c.username}');
      });

  @override
  Widget build(BuildContext context) {
    return ActionDialogFrame(
      icon: Icons.data_usage_outlined,
      tone: PillTone.blue,
      title: 'إضافة كوتة',
      subtitle: c.username,
      busy: busy,
      error: error,
      confirmLabel: 'إضافة',
      confirmIcon: Icons.add,
      onConfirm: _invalid == null ? _submit : null,
      children: [
        FormFieldPair(
          first: FormFieldRow(
            label: 'حجم الكوتة',
            required: true,
            child: TextField(
              controller: _size,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: numberInputFormatters,
              decoration: actionFieldDecoration.copyWith(hintText: '0'),
              onChanged: (_) => setState(() {}),
            ),
          ),
          second: FormFieldRow(
            label: 'الوحدة',
            child: DropdownButtonFormField<int>(
              initialValue: _unitMb,
              isExpanded: true,
              decoration: actionFieldDecoration,
              items: const [
                DropdownMenuItem(value: 1024, child: Text('GB')),
                DropdownMenuItem(value: 1, child: Text('MB')),
              ],
              onChanged: (v) => setState(() => _unitMb = v ?? 1024),
            ),
          ),
        ),
        FormFieldRow(
          label: 'نوع الكوتة',
          child: DropdownButtonFormField<String>(
            initialValue: _target,
            isExpanded: true,
            decoration: actionFieldDecoration,
            items: [
              for (final (v, label) in kQuotaTargets)
                DropdownMenuItem(value: v, child: Text(label)),
            ],
            onChanged: (v) => setState(() => _target = v ?? 'combined'),
          ),
        ),
        const ActionFieldLabel('طريقة الإضافة'),
        ChoiceTiles<ChargeMode>(
          value: _charge,
          onChanged: (v) => setState(() => _charge = v),
          options: _chargeOptions(),
        ),
        const SizedBox(height: 6),
        ActionNote(
          tone: PillTone.blue,
          text: switch (_charge) {
            ChargeMode.free =>
              'كوتة مجانية — تُضاف بدون أي قيمة مالية أو دين على المشترك.',
            ChargeMode.paid => 'تُخصم القيمة من رصيد المشترك.',
            ChargeMode.debt => 'تُسجَّل القيمة كدين على المشترك.',
          },
        ),
        _gap(),
        if (_charge != ChargeMode.free)
          FormFieldPair(
            first: FormFieldRow(
              label: 'المبلغ',
              required: true,
              child: TextField(
                controller: _money,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: numberInputFormatters,
                decoration: actionFieldDecoration,
                onChanged: (_) => setState(() {}),
              ),
            ),
            second: FormFieldRow(
              label: 'العملة',
              child: ReadOnlyValue(value: c.currency),
            ),
          ),
        if (_invalid != null && _size.text.isNotEmpty) ...[
          ActionNote(text: _invalid!, tone: PillTone.amber),
          _gap(),
        ],
        _notesField(_notes),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
//  3. استعادة الكوتة اليومية
// ═════════════════════════════════════════════════════════════════════════

class QuotaResetDialog extends ConsumerStatefulWidget {
  const QuotaResetDialog({super.key, required this.c});
  final SubscriberActionsContext c;

  @override
  ConsumerState<QuotaResetDialog> createState() => _QuotaResetDialogState();
}

class _QuotaResetDialogState extends ConsumerState<QuotaResetDialog>
    with _ActionRunner {
  final _money = TextEditingController(text: '0');
  final _notes = TextEditingController();
  ChargeMode _charge = ChargeMode.free;

  SubscriberActionsContext get c => widget.c;

  @override
  void dispose() {
    _money.dispose();
    _notes.dispose();
    super.dispose();
  }

  double get _amount => parseLocalizedNumber(_money.text) ?? 0;

  Future<void> _submit() => run(() async {
        await repo.quotaResetDaily(
          c.username,
          charge: _charge,
          amount: _amount,
          notes: _notes.text,
        );
        return ActionOutcome('استُعيدت الكوتة اليومية لـ ${c.username}');
      });

  @override
  Widget build(BuildContext context) {
    final invalid = _charge != ChargeMode.free && _amount <= 0;
    return ActionDialogFrame(
      icon: Icons.restart_alt,
      tone: PillTone.blue,
      title: 'استعادة الكوتة اليومية',
      subtitle: c.username,
      busy: busy,
      error: error,
      confirmLabel: 'استعادة',
      confirmIcon: Icons.restart_alt,
      onConfirm: invalid ? null : _submit,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppTokens.s12),
          child: InfoGrid(
            columns: 3,
            items: [
              InfoItem(
                icon: Icons.layers_outlined,
                label: 'العرض الحالي',
                value: c.planName.isEmpty ? '—' : c.planName,
              ),
              InfoItem(
                icon: Icons.data_usage_outlined,
                label: 'الكوتة اليومية',
                value: _fmtMb(c.dailyQuotaMb),
              ),
              InfoItem(
                icon: Icons.trending_up,
                label: 'المستهلك اليوم',
                value: _fmtMb(c.usedTodayMb),
              ),
            ],
          ),
        ),
        const ActionNote(
          text: 'تُصفَّر العدّادات المستهلَكة ليعود للمشترك كامل كوتته '
              'اليومية فورًا.',
        ),
        _gap(),
        const ActionFieldLabel('طريقة الاستعادة'),
        ChoiceTiles<ChargeMode>(
          value: _charge,
          onChanged: (v) => setState(() => _charge = v),
          options: _chargeOptions(),
        ),
        const SizedBox(height: 6),
        ActionNote(
          tone: PillTone.blue,
          text: switch (_charge) {
            ChargeMode.free => 'استعادة مجانية — تُصفَّر العدّادات بدون أي '
                'قيمة مالية أو دين على المشترك.',
            ChargeMode.paid => 'تُخصم القيمة من رصيد المشترك.',
            ChargeMode.debt => 'تُسجَّل القيمة كدين على المشترك.',
          },
        ),
        _gap(),
        if (_charge != ChargeMode.free)
          FormFieldPair(
            first: FormFieldRow(
              label: 'المبلغ',
              required: true,
              child: TextField(
                controller: _money,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: numberInputFormatters,
                decoration: actionFieldDecoration,
                onChanged: (_) => setState(() {}),
              ),
            ),
            second: FormFieldRow(
              label: 'العملة',
              child: ReadOnlyValue(value: c.currency),
            ),
          ),
        _notesField(_notes),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
//  4. تسجيل دفعة نقدية
// ═════════════════════════════════════════════════════════════════════════

class PaymentDialog extends ConsumerStatefulWidget {
  const PaymentDialog({super.key, required this.c});
  final SubscriberActionsContext c;

  @override
  ConsumerState<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends ConsumerState<PaymentDialog>
    with _ActionRunner {
  final _money = TextEditingController();
  final _notes = TextEditingController();
  String _method = 'cash';
  late final Map<int, LoanChoice> _choices = {
    for (final l in widget.c.openLoans) l.id: LoanChoice.defer,
  };
  late bool _settleBalance = widget.c.debt > 0;

  SubscriberActionsContext get c => widget.c;

  @override
  void dispose() {
    _money.dispose();
    _notes.dispose();
    super.dispose();
  }

  double get _amount => parseLocalizedNumber(_money.text) ?? 0;

  String get _coverage {
    final settled = settledTotal(c.openLoans, _choices);
    final debtCut = _settleBalance ? c.debt : 0.0;
    final timeAmount = (_amount - settled - debtCut).clamp(0, double.infinity);
    if (_amount <= 0 || c.effectivePrice <= 0) {
      return 'أدخل المبلغ لعرض المدّة التي يُضيفها للحساب.';
    }
    final cover = coverageText(
      timeAmount.toDouble(),
      c.effectivePrice,
      c.planMinutes,
    );
    var msg = 'يُطبَّق على الحساب ويُمدِّد الانتهاء بـ ≈ '
        '${cover.isEmpty ? arDuration(0) : cover}.';
    final cut = settled + debtCut;
    if (cut > 0) {
      msg = 'سيُخصم ${formatMoney(cut, c.currency)} لتسوية سلف/دين؛ والباقي '
          '${formatMoney(timeAmount.toDouble(), c.currency)} ← $msg';
    }
    return msg;
  }

  Future<void> _submit() => run(() async {
        await repo.payment(
          c.username,
          paymentPayload(
            amount: _amount,
            method: _method,
            notes: _notes.text,
            choices: _choices,
            settleBalance: c.debt > 0 && _settleBalance,
          ),
        );
        return ActionOutcome(
          'تم تسجيل دفعة ${formatMoney(_amount, c.currency)} لـ ${c.username}',
        );
      });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final invalid = _amount < 0.01;
    return ActionDialogFrame(
      icon: Icons.payments_outlined,
      tone: PillTone.green,
      title: 'تسجيل دفعة نقدية',
      subtitle: c.username,
      busy: busy,
      error: error,
      confirmLabel: 'تسجيل',
      confirmIcon: Icons.add,
      onConfirm: invalid ? null : _submit,
      children: [
        FormFieldPair(
          first: FormFieldRow(
            label: 'المبلغ',
            required: true,
            child: TextField(
              controller: _money,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: numberInputFormatters,
              decoration: actionFieldDecoration.copyWith(hintText: '0.00'),
              onChanged: (_) => setState(() {}),
            ),
          ),
          second: FormFieldRow(
            label: 'العملة',
            child: ReadOnlyValue(value: c.currency),
          ),
        ),
        FormFieldRow(
          label: 'طريقة الدفع',
          child: DropdownButtonFormField<String>(
            initialValue: _method,
            isExpanded: true,
            decoration: actionFieldDecoration,
            items: [
              for (final (v, label) in kPaymentMethods)
                DropdownMenuItem(value: v, child: Text(label)),
            ],
            onChanged: (v) => setState(() => _method = v ?? 'cash'),
          ),
        ),
        _notesField(_notes),
        if (c.openLoans.isNotEmpty) ...[
          Row(
            children: [
              const Icon(
                Icons.volunteer_activism_outlined,
                size: 18,
                color: AppTokens.amberInk,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'سلف مستحقّة (${c.openLoans.length}) — اختر لكل واحدة:',
                  style: text.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppTokens.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          for (final l in c.openLoans)
            _LoanChoiceRow(
              loan: l,
              currency: c.currency,
              value: _choices[l.id] ?? LoanChoice.defer,
              onChanged: (v) => setState(() => _choices[l.id] = v),
            ),
        ],
        if (c.debt > 0) ...[
          Container(
            decoration: BoxDecoration(
              color: AppTokens.amberSoft.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(AppTokens.r10),
              border: Border.all(color: AppTokens.warningMed),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: HubSwitchRow(
              dense: true,
              label: 'سدِّد الدين ${formatMoney(c.debt, c.currency)} '
                  'من هذه الدفعة',
              subtitle: 'يُخصم من المبلغ ويُقلّل الأيام المُضافة.',
              value: _settleBalance,
              onChanged: (v) => setState(() => _settleBalance = v),
            ),
          ),
          _gap(AppTokens.s8),
        ],
        ActionNote(text: _coverage, tone: PillTone.blue),
        _gap(AppTokens.s8),
      ],
    );
  }
}

/// One open loan inside the payment dialog: days/value chips + reason and a
/// 3-way «خصم / تأجيل / مسامحة» choice (default تأجيل).
class _LoanChoiceRow extends StatelessWidget {
  const _LoanChoiceRow({
    required this.loan,
    required this.currency,
    required this.value,
    required this.onChanged,
  });

  final OpenLoan loan;
  final String currency;
  final LoanChoice value;
  final ValueChanged<LoanChoice> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTokens.s8),
      padding: const EdgeInsets.all(AppTokens.s8),
      decoration: BoxDecoration(
        color: AppTokens.surfaceMuted,
        borderRadius: BorderRadius.circular(AppTokens.r10),
        border: Border.all(color: AppTokens.borderStrong),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              StatusPill(text: loan.durationLabel, tone: PillTone.blue),
              StatusPill(
                text:
                    'القيمة ${formatMoney(loan.amount, loan.currency.isEmpty ? currency : loan.currency)}',
                tone: PillTone.amber,
              ),
              if (loan.reason.isNotEmpty)
                Text(
                  loan.reason,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTokens.textSecondary,
                      ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          ChoiceTiles<LoanChoice>(
            dense: true,
            value: value,
            onChanged: onChanged,
            tone: switch (value) {
              LoanChoice.settle => PillTone.green,
              LoanChoice.defer => PillTone.brand,
              LoanChoice.forgive => PillTone.amber,
            },
            options: [
              for (final ch in LoanChoice.values) ChoiceOption(ch, ch.label),
            ],
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
//  5. منح سلفة
// ═════════════════════════════════════════════════════════════════════════

class LoanDialog extends ConsumerStatefulWidget {
  const LoanDialog({super.key, required this.c});
  final SubscriberActionsContext c;

  @override
  ConsumerState<LoanDialog> createState() => _LoanDialogState();
}

class _LoanDialogState extends ConsumerState<LoanDialog> with _ActionRunner {
  LoanType _type = LoanType.free;
  final _days = TextEditingController(text: '1');
  final _hours = TextEditingController(text: '0');
  final _reason = TextEditingController();

  SubscriberActionsContext get c => widget.c;

  @override
  void dispose() {
    _days.dispose();
    _hours.dispose();
    _reason.dispose();
    super.dispose();
  }

  int get _d => (parseLocalizedNumber(_days.text) ?? 0).floor();
  int get _h => (parseLocalizedNumber(_hours.text) ?? 0).floor();

  String? get _invalid => validateLoan(
        type: _type,
        days: _d,
        hours: _h,
        maxFreeHours: c.maxFreeLoanHours,
        maxDebtDays: c.maxDebtLoanDays,
      );

  double get _value => priceForMinutes(
        effectivePrice: c.effectivePrice,
        planMinutes: c.planMinutes,
        minutes: _d * 1440 + _h * 60,
      );

  String get _hint {
    if (_type == LoanType.free) {
      return 'سلفة وقت مجانية بدون قيمة مالية — تُمنح مدة فقط دون تسجيل دين.';
    }
    if (_value > 0) {
      final span = [
        if (_d > 0) arDays(_d),
        if (_h > 0) '$_h ساعة',
      ].join(' و');
      return 'سيتم تسجيل دين $span بقيمة ${formatMoney(_value, c.currency)} '
          '(حسب سعر العرض ${formatMoney(c.effectivePrice, c.currency)}).';
    }
    return 'حدّد عدد الأيام لاحتساب قيمة الدين تلقائيًا حسب سعر '
        'العرض/المخصّص.';
  }

  Future<void> _submit() => run(() async {
        final res = await repo.loan(
          c.username,
          loanPayload(type: _type, days: _d, hours: _h, reason: _reason.text),
        );
        if (res['pending_approval'] == true) {
          return const ActionOutcome(
            'بانتظار موافقة المالك — أُرسلت السلفة للاعتماد.',
            info: true,
          );
        }
        return ActionOutcome('تم منح السلفة لـ ${c.username}');
      });

  Widget _intField(TextEditingController ctrl) => TextField(
        controller: ctrl,
        keyboardType: TextInputType.number,
        inputFormatters: intInputFormatters,
        decoration: actionFieldDecoration,
        onChanged: (_) => setState(() {}),
      );

  @override
  Widget build(BuildContext context) {
    final invalid = _invalid;
    return ActionDialogFrame(
      icon: Icons.volunteer_activism_outlined,
      tone: PillTone.amber,
      title: 'إضافة سلفة',
      subtitle: c.username,
      busy: busy,
      error: error,
      confirmLabel: 'إضافة',
      confirmIcon: Icons.add,
      onConfirm: invalid == null ? _submit : null,
      children: [
        const ActionFieldLabel('نوع السلفة'),
        ChoiceTiles<LoanType>(
          value: _type,
          onChanged: (v) => setState(() => _type = v),
          tone: PillTone.amber,
          options: const [
            ChoiceOption(
              LoanType.free,
              'مجانية',
              icon: Icons.card_giftcard_outlined,
              caption: 'منح وقت فقط بدون قيمة مالية.',
            ),
            ChoiceOption(
              LoanType.debt,
              'تسجيل دين (مدين)',
              icon: Icons.receipt_long_outlined,
              caption: 'تُسجَّل قيمتها كدين على المشترك.',
            ),
          ],
        ),
        const SizedBox(height: 6),
        ActionNote(text: _hint, tone: PillTone.blue),
        _gap(),
        FormFieldPair(
          first: FormFieldRow(label: 'عدد الأيام', child: _intField(_days)),
          second: FormFieldRow(label: 'عدد الساعات', child: _intField(_hours)),
        ),
        if (invalid != null) ...[
          ActionNote(text: invalid, tone: PillTone.red),
          _gap(),
        ] else ...[
          Text(
            _type == LoanType.free
                ? 'الحدّ: ${c.maxFreeLoanHours} ساعة للسلفة المجانية.'
                : 'الحدّ: ${c.maxDebtLoanDays} يومًا لسلفة الدين.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTokens.textMuted,
                  fontWeight: FontWeight.w600,
                ),
          ),
          _gap(AppTokens.s8),
        ],
        if (_type == LoanType.debt)
          FormFieldPair(
            first: FormFieldRow(
              label: 'قيمة السلفة (تُحتسب تلقائيًا)',
              child: ReadOnlyValue(
                value: _value.toStringAsFixed(2),
                emphasis: true,
              ),
            ),
            second: FormFieldRow(
              label: 'العملة',
              child: ReadOnlyValue(value: c.currency),
            ),
          ),
        _notesField(_reason, label: 'سبب السلفة'),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
//  6. تغيير العرض / السرعة
// ═════════════════════════════════════════════════════════════════════════

String _planOptionLabel(Plan p) {
  final mins =
      p.durationMinutes > 0 ? p.durationMinutes : p.validityDays * 1440;
  final price = formatMoney(p.price.toDouble(), '');
  return mins > 0
      ? '${p.name} — $price · ${arDuration(mins)}'
      : '${p.name} — $price';
}

class ChangePlanDialog extends ConsumerStatefulWidget {
  const ChangePlanDialog({super.key, required this.c});
  final SubscriberActionsContext c;

  @override
  ConsumerState<ChangePlanDialog> createState() => _ChangePlanDialogState();
}

class _ChangePlanDialogState extends ConsumerState<ChangePlanDialog>
    with _ActionRunner {
  Plan? _next;
  String _policy = 'neutral_keep_expiry';

  SubscriberActionsContext get c => widget.c;

  double get _currentPrice =>
      (c.plan?.price ?? 0) > 0 ? c.plan!.price : c.effectivePrice;

  PlanDirection get _direction => planDirection(
        currentPlanId: c.plan?.id,
        currentPrice: _currentPrice,
        nextPlanId: _next?.id,
        nextPrice: _next?.price.toDouble() ?? 0,
      );

  void _select(Plan? p) {
    setState(() {
      _next = p;
      _policy = planPolicies(_direction).first.value;
    });
  }

  Future<void> _submit() => run(() async {
        await repo.changePlan(c.username, planId: _next!.id!, policy: _policy);
        return ActionOutcome('تم تغيير العرض إلى ${_next!.name}');
      });

  @override
  Widget build(BuildContext context) {
    final plans = ref.watch(plansForPickerProvider);
    final dir = _direction;
    return ActionDialogFrame(
      icon: Icons.swap_horiz,
      tone: PillTone.brand,
      title: 'تغيير العرض للمشترك',
      subtitle: c.username,
      busy: busy,
      error: error,
      confirmLabel: 'تغيير العرض',
      confirmIcon: Icons.check,
      onConfirm: _next?.id == null ? null : _submit,
      children: [
        _CurrentStrip(c: c),
        FormFieldRow(
          label: 'عرض جديد',
          required: true,
          child: plans.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: LinearProgressIndicator(minHeight: 4),
            ),
            error: (e, _) => ActionNote(
              text: 'تعذّر جلب قائمة العروض — ${mapActionError(e).message}',
              tone: PillTone.red,
            ),
            data: (items) {
              final list = items.where((p) => p.id != null).toList();
              return DropdownButtonFormField<int>(
                initialValue: _next?.id,
                isExpanded: true,
                hint: const Text('اختر العرض'),
                decoration: actionFieldDecoration,
                items: [
                  for (final p in list)
                    DropdownMenuItem(
                      value: p.id,
                      child: Text(
                        _planOptionLabel(p),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (id) => _select(
                  list.where((p) => p.id == id).firstOrNull,
                ),
              );
            },
          ),
        ),
        ActionNote(
          tone: dir == PlanDirection.neutral ? PillTone.neutral : PillTone.blue,
          text: _next == null
              ? 'اختر عرضًا جديدًا لعرض خيارات التعويض أو الدين.'
              : planDirectionHint(dir),
        ),
        _gap(AppTokens.s8),
        for (final o in planPolicies(dir))
          _PolicyCard(
            option: o,
            selected: _policy == o.value,
            onTap: () => setState(() => _policy = o.value),
          ),
        _gap(AppTokens.s4),
      ],
    );
  }
}

class _PolicyCard extends StatelessWidget {
  const _PolicyCard({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final PlanPolicyOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: selected ? AppTokens.brandSoft : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.r10),
          side: BorderSide(
            color: selected ? AppTokens.brand : AppTokens.borderStrong,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTokens.r10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppTokens.s8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  size: 20,
                  color: selected ? AppTokens.brand : AppTokens.slate500,
                ),
                const SizedBox(width: AppTokens.s8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        option.title,
                        style: text.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppTokens.textPrimary,
                        ),
                      ),
                      Text(
                        option.description,
                        style: text.bodySmall?.copyWith(
                          color: AppTokens.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
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

// ═════════════════════════════════════════════════════════════════════════
//  7. إرسال رسالة
// ═════════════════════════════════════════════════════════════════════════

class MessageDialog extends ConsumerStatefulWidget {
  const MessageDialog({super.key, required this.c});
  final SubscriberActionsContext c;

  @override
  ConsumerState<MessageDialog> createState() => _MessageDialogState();
}

class _MessageDialogState extends ConsumerState<MessageDialog>
    with _ActionRunner {
  final _text = TextEditingController();
  late String? _channel = widget.c.smsEnabled
      ? 'sms'
      : (widget.c.whatsappEnabled ? 'whatsapp' : null);

  SubscriberActionsContext get c => widget.c;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _apply(MessageTemplate t) {
    final filled = fillMessageTemplate(
      t.text,
      username: c.username,
      plan: c.planName,
      expire: c.expireAt == null ? '' : _date.format(c.expireAt!),
    );
    setState(() {
      _text.text = filled;
      _text.selection = TextSelection.collapsed(offset: filled.length);
    });
  }

  Future<void> _submit() => run(() async {
        final res = await repo.message(
          c.username,
          channel: _channel!,
          message: _text.text.trim(),
        );
        final msg = (res['message'] ?? '').toString();
        return ActionOutcome(
          msg.isNotEmpty ? msg : 'أُرسلت الرسالة إلى ${c.username}',
        );
      });

  @override
  Widget build(BuildContext context) {
    final noChannel = _channel == null;
    final text = Theme.of(context).textTheme;
    return ActionDialogFrame(
      icon: Icons.send_outlined,
      tone: PillTone.blue,
      title: 'إرسال رسالة للمشترك',
      subtitle: c.username,
      busy: busy,
      error: error,
      confirmLabel: 'إرسال',
      confirmIcon: Icons.send,
      onConfirm: noChannel || _text.text.trim().isEmpty ? null : _submit,
      children: [
        const ActionFieldLabel('قناة الإرسال'),
        if (noChannel)
          const ActionNote(
            text: 'لا توجد قناة إرسال مفعّلة (SMS أو واتساب). فعّلها من '
                'إعدادات الإشعارات.',
            tone: PillTone.amber,
          )
        else
          ChoiceTiles<String>(
            value: _channel!,
            onChanged: (v) => setState(() => _channel = v),
            options: [
              ChoiceOption(
                'sms',
                'رسالة SMS',
                icon: Icons.sms_outlined,
                caption: 'عبر مزوّد الرسائل القصيرة.',
                enabled: c.smsEnabled,
              ),
              ChoiceOption(
                'whatsapp',
                'واتساب',
                icon: Icons.chat_outlined,
                caption: 'عبر قناة واتساب المهيّأة.',
                enabled: c.whatsappEnabled,
              ),
            ],
          ),
        _gap(),
        const ActionFieldLabel('قوالب جاهزة — اضغط لتعبئة الرسالة'),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final t in c.templates)
              ActionChip(
                label: Text(t.label),
                labelStyle: text.labelMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppTokens.brandInk,
                ),
                backgroundColor: AppTokens.brandSoft,
                side: const BorderSide(color: AppTokens.brandLine),
                visualDensity: VisualDensity.compact,
                onPressed: () => _apply(t),
              ),
          ],
        ),
        _gap(),
        FormFieldRow(
          label: 'نص الرسالة',
          required: true,
          child: TextField(
            controller: _text,
            minLines: 4,
            maxLines: 6,
            decoration: actionFieldDecoration.copyWith(
              hintText: 'اكتب نص الرسالة هنا أو اختر قالبًا',
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
//  8. تأكيدات (إرسال البيانات / فصل / تعطيل-تفعيل / أرشفة)
// ═════════════════════════════════════════════════════════════════════════

class ConfirmActionDialog extends ConsumerStatefulWidget {
  const ConfirmActionDialog({
    super.key,
    required this.icon,
    required this.tone,
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.task,
    this.subtitle,
    this.danger = false,
    this.note,
  });

  final IconData icon;
  final PillTone tone;
  final String title;
  final String? subtitle;
  final String message;
  final String confirmLabel;
  final bool danger;
  final String? note;

  /// Runs the action and returns the success toast text.
  final Future<String> Function(SubscriberActionsRepository repo) task;

  @override
  ConsumerState<ConfirmActionDialog> createState() =>
      _ConfirmActionDialogState();
}

class _ConfirmActionDialogState extends ConsumerState<ConfirmActionDialog>
    with _ActionRunner {
  @override
  Widget build(BuildContext context) {
    return ActionDialogFrame(
      icon: widget.icon,
      tone: widget.tone,
      title: widget.title,
      subtitle: widget.subtitle,
      busy: busy,
      error: error,
      danger: widget.danger,
      confirmLabel: widget.confirmLabel,
      confirmIcon: widget.icon,
      onConfirm: () => run(() async => ActionOutcome(await widget.task(repo))),
      children: [
        Text(
          widget.message,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppTokens.textPrimary,
                height: 1.6,
              ),
        ),
        if (widget.note != null) ...[
          _gap(AppTokens.s8),
          ActionNote(text: widget.note!),
        ],
        _gap(AppTokens.s8),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
//  9. تغيير اسم المستخدم
// ═════════════════════════════════════════════════════════════════════════

class RenameDialog extends ConsumerStatefulWidget {
  const RenameDialog({super.key, required this.c});
  final SubscriberActionsContext c;

  @override
  ConsumerState<RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends ConsumerState<RenameDialog>
    with _ActionRunner {
  late final _name = TextEditingController(text: widget.c.username);
  bool _touched = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  String? get _invalid =>
      validateNewUsername(_name.text, current: widget.c.username);

  Future<void> _submit() => run(() async {
        final res = await repo.rename(widget.c.username, _name.text);
        final next = (res['username'] ?? _name.text.trim()).toString();
        return ActionOutcome(
          'تم تغيير اسم المستخدم إلى $next',
          renamedTo: next,
        );
      });

  @override
  Widget build(BuildContext context) {
    final invalid = _invalid;
    return ActionDialogFrame(
      icon: Icons.drive_file_rename_outline,
      tone: PillTone.brand,
      title: 'تغيير اسم المستخدم',
      subtitle: widget.c.username,
      busy: busy,
      error: error,
      confirmLabel: 'حفظ الاسم',
      confirmIcon: Icons.check,
      onConfirm: invalid == null ? _submit : null,
      children: [
        FormFieldRow(
          label: 'اسم المستخدم الجديد',
          required: true,
          child: TextField(
            controller: _name,
            autofocus: true,
            textDirection: TextDirection.ltr,
            autocorrect: false,
            decoration: actionFieldDecoration.copyWith(
              errorText: _touched ? invalid : null,
            ),
            onChanged: (_) => setState(() => _touched = true),
          ),
        ),
        const ActionNote(
          text: 'يُنقل الاسم في كل السجلات دفعة واحدة (الجلسات، المالية، '
              'السجل)، وقد تُفصل جلسته الحالية ليعيد الدخول بالاسم الجديد.',
        ),
        _gap(AppTokens.s8),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
//  10. إعادة كلمة المرور
// ═════════════════════════════════════════════════════════════════════════

class ResetPasswordDialog extends ConsumerStatefulWidget {
  const ResetPasswordDialog({super.key, required this.c});
  final SubscriberActionsContext c;

  @override
  ConsumerState<ResetPasswordDialog> createState() =>
      _ResetPasswordDialogState();
}

class _ResetPasswordDialogState extends ConsumerState<ResetPasswordDialog>
    with _ActionRunner {
  final _pw = TextEditingController();
  bool _show = false;

  @override
  void dispose() {
    _pw.dispose();
    super.dispose();
  }

  Future<void> _submit() => run(() async {
        await repo.resetPassword(widget.c.username, _pw.text);
        return const ActionOutcome('تمّ تحديث كلمة المرور');
      });

  @override
  Widget build(BuildContext context) {
    return ActionDialogFrame(
      icon: Icons.password_outlined,
      tone: PillTone.blue,
      title: 'إعادة تعيين كلمة المرور',
      subtitle: widget.c.username,
      busy: busy,
      error: error,
      confirmLabel: 'تعيين',
      confirmIcon: Icons.check,
      onConfirm: _pw.text.isEmpty ? null : _submit,
      children: [
        FormFieldRow(
          label: 'كلمة المرور الجديدة',
          required: true,
          child: TextField(
            controller: _pw,
            autofocus: true,
            obscureText: !_show,
            textDirection: TextDirection.ltr,
            decoration: actionFieldDecoration.copyWith(
              suffixIcon: IconButton(
                tooltip: _show ? 'إخفاء' : 'إظهار',
                icon: Icon(
                  _show
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 20,
                ),
                onPressed: () => setState(() => _show = !_show),
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
      ],
    );
  }
}
