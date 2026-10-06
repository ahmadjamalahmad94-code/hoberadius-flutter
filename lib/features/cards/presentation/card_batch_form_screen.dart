// ignore_for_file: require_trailing_commas, deprecated_member_use

import 'package:hoberadius_app/core/format/arabic_plural.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoberadius_app/core/api/idempotency.dart';
import 'package:hoberadius_app/core/api/api_exception.dart';
import 'package:hoberadius_app/core/api/visible_error_message.dart';

import '../../../core/format/number_input.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/collapsible_section.dart';
import '../../../shared/widgets/form_field_row.dart';
import '../../admin_control/application/admin_control_providers.dart';
import '../../plans/domain/plan_option.dart';
import '../data/cards_repository.dart';
import '../domain/card_model.dart';
import '../domain/username_preview.dart';
import '../application/cards_list_providers.dart';
import 'widgets/card_device_limit_fields.dart';
import 'widgets/card_generate_dialog.dart';
import 'widgets/card_number_field.dart';
import 'widgets/card_plan_picker.dart';
import 'widgets/cards_form_header.dart';

class CardBatchFormScreen extends ConsumerStatefulWidget {
  const CardBatchFormScreen({super.key});

  @override
  ConsumerState<CardBatchFormScreen> createState() =>
      _CardBatchFormScreenState();
}

class _CardBatchFormScreenState extends ConsumerState<CardBatchFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _packageName = TextEditingController();
  final _count = TextEditingController(text: '10');
  final _pricePerCard = TextEditingController(text: '0');
  final _totalPrice = TextEditingController(text: '0');
  final _totalQuota = TextEditingController(text: '0');
  final _serviceName = TextEditingController();
  final _prefix = TextEditingController();
  final _suffix = TextEditingController();
  final _ulen = TextEditingController(text: '8');
  final _plen = TextEditingController(text: '6');
  // 0 = the plan's own validity (web «0 = استخدم صلاحية الباقة»). A default
  // of «1 day» gave 1-hour-plan cards 24 h (stress re-test R05).
  final _timeVal = TextEditingController(text: '0');
  final _notes = TextEditingController();

  // «أرقام فقط» by default, like the web generator (شبكة المحترف request):
  // numeric cards are easier to print and type.
  String _passwordType = 'digits';
  String _timeUnit = 'days';
  bool _includeBatchNumber = false;

  /// Estimated id of the batch about to be created (latest id + 1), for the
  /// «تضمين رقم الحزمة» preview; null until known.
  int? _nextBatchId;
  // 0 = follow the global card setting, like the web generator.
  int _devices = 0;

  /// «عند بلوغ حدّ الأجهزة»: '' = the global card setting.
  String _deviceLimitMode = '';

  bool _loading = false;

  /// A server error that names no field (the general error box).
  String? _error;

  /// Server errors next to the field they concern ('plan', 'count',
  /// 'username_length').
  Map<String, String> _fieldErrors = const {};

  /// The picked plan (required; was a raw «معرّف الباقة» number).
  PlanOption? _planPick;

  /// «السعر الإجمالي» follows price × count until the operator types it.
  bool _totalEdited = false;

  /// One Idempotency-Key per «توليد» submission; the same request sent again
  /// (retry after «الخادم مشغول» / a lost answer) returns the same batch.
  final _idem = IdempotencyKeeper();

  bool get _noPassword => _passwordType == 'none';

  @override
  void initState() {
    super.initState();
    for (final c in [_prefix, _suffix, _ulen, _count]) {
      c.addListener(_refreshPreview);
    }
    _pricePerCard.addListener(_recomputeTotal);
    _count.addListener(_recomputeTotal);
    _loadCardDefaults();
  }

  /// The network's default card lengths (web «طول اسم/كلمة البطاقة
  /// الافتراضي», owner 2026-10-06 «وصّله»): fill the two boxes unless the
  /// operator already typed there. Older servers send none → 8 / 6 stay.
  Future<void> _loadCardDefaults() async {
    try {
      final page = await ref
          .read(cardsRepositoryProvider)
          .listBatchOperations(perPage: 1);
      if (!mounted) return;
      final next = applyCardDefaultLengths(
        currentUsername: _ulen.text,
        currentPassword: _plen.text,
        defaultUsername: page.defaultUsernameLength,
        defaultPassword: page.defaultPasswordLength,
      );
      if (next.$1 != _ulen.text) _ulen.text = next.$1;
      if (next.$2 != _plen.text) _plen.text = next.$2;
      if (_nextBatchId == null && page.nextBatchId != null) {
        setState(() => _nextBatchId = page.nextBatchId);
      }
    } catch (_) {
      // Defaults only — the server applies the network's lengths anyway.
    }
  }

  /// price × count into «السعر الإجمالي» (Arabic digits read too) until
  /// the operator edits the total by hand.
  void _recomputeTotal() {
    if (_totalEdited) return;
    final total = batchTotalPrice(_pricePerCard.text, _count.text);
    if (total != null && _totalPrice.text != total) _totalPrice.text = total;
  }

  void _pickPlan(PlanOption p) {
    setState(() {
      _planPick = p;
      _fieldErrors = {..._fieldErrors}..remove('plan');
    });
    _pricePerCard.text = formatBatchNumber(planCardPrice(p));
  }

  void _refreshPreview() {
    if (mounted) setState(() {});
  }

  Future<void> _loadNextBatchId() async {
    if (_nextBatchId != null) return;
    try {
      final page = await ref
          .read(cardsRepositoryProvider)
          .listBatchOperations(perPage: 5);
      // The server's own number (as the web shows it); older servers →
      // estimate from the newest batches.
      final next = page.nextBatchId ??
          page.items.fold<int>(0, (m, b) => (b.id ?? 0) > m ? b.id! : m) + 1;
      if (mounted) setState(() => _nextBatchId = next);
    } catch (_) {
      // Preview only — the server applies the real batch number.
    }
  }

  @override
  void dispose() {
    for (final c in [
      _packageName,
      _count,
      _pricePerCard,
      _totalPrice,
      _totalQuota,
      _serviceName,
      _prefix,
      _suffix,
      _ulen,
      _plen,
      _timeVal,
      _notes,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<bool> _confirmLargeBatch(int count) async {
    final ok = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => AlertDialog(
        title: const Text('توليد عدد كبير من الكروت؟'),
        content: Text(
          'سيتم توليد ${arCount(count, arCard, showOne: true)} في دفعة واحدة. قد يستغرق ذلك وقتًا '
          'ويضغط الخادم. هل أنت متأكد؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('نعم، ولّد'),
          ),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _submit() async {
    if (_loading) return;
    if (!_formKey.currentState!.validate()) return;
    // The server's length rule, checked BEFORE sending (the preview shows
    // the same text): never generate a name the server refuses.
    final lengthRefusal = cardUsernameLengthRefusal(
      prefix: _prefix.text,
      suffix: _suffix.text,
      totalLength: parseIntInput(_ulen.text),
      batchNumber: _includeBatchNumber ? '${_nextBatchId ?? ''}' : '',
    );
    if (lengthRefusal != null) {
      setState(() => _fieldErrors = {'username_length': lengthRefusal});
      return;
    }
    final count = parseIntInput(_count.text)!;
    if (count > kConfirmCardsAbove && !await _confirmLargeBatch(count)) return;
    if (!mounted) return;
    final req = GenerateBatchRequest(
      planId: _planPick!.id,
      count: count,
      packageName: _packageName.text.trim(),
      usernamePrefix: normalizeCardAffix(_prefix.text),
      usernameSuffix: normalizeCardAffix(_suffix.text),
      includeBatchNumber: _includeBatchNumber,
      usernameLength: parseIntInput(_ulen.text) ?? 8,
      passwordLength: parseIntInput(_plen.text) ?? 6,
      passwordGenerationType: _noPassword ? 'digits' : _passwordType,
      loginWithoutPassword: _noPassword,
      timeValue: parseIntInput(_timeVal.text) ?? 0,
      timeUnit: _timeUnit,
      deviceCount: _devices,
      deviceLimitMode: _deviceLimitMode,
      pricePerCard: parseNumberInput(_pricePerCard.text) ?? 0,
      totalPrice: parseNumberInput(_totalPrice.text) ?? 0,
      totalQuotaMb: parseIntInput(_totalQuota.text) ?? 0,
      serviceName: _serviceName.text.trim(),
      notes: _notes.text.trim(),
    );
    final repo = ref.read(cardsRepositoryProvider);
    final router = GoRouter.maybeOf(context);
    // The same body keeps the same key: «إعادة المحاولة» (and a second
    // «توليد» after closing an error) replays, never a second batch.
    final key = _idem.keyFor('cards/generate', req.toBody());
    setState(() {
      _loading = true;
      _error = null;
      _fieldErrors = const {};
    });
    try {
      final outcome = await showDialog<GenerateDialogOutcome>(
        context: context,
        useRootNavigator: true,
        barrierDismissible: false,
        builder: (_) => CardGenerateDialog(
          count: count,
          run: () async {
            final r = await repo.generate(req, idempotencyKey: key);
            // Still on this screen (the dialog is open): refresh the lists.
            _idem.reset();
            ref.invalidate(batchesListProvider);
            return r;
          },
          routes: GenerateDialogRoutes(
            print: (id) => router?.goNamed(
              'card-batch-print',
              pathParameters: {'id': '$id'},
            ),
            detail: (id) => router?.goNamed(
              'card-batch-detail',
              pathParameters: {'id': '$id'},
            ),
            batches: () => router?.goNamed('cards'),
          ),
        ),
      );
      if (outcome?.result != null) {
        // The next batch number moved on — refresh the preview's estimate.
        _nextBatchId = null;
        if (mounted && _includeBatchNumber) _loadNextBatchId();
      } else if (outcome?.error != null && mounted) {
        // Closed after an error: the form is intact; the message goes next
        // to the field it concerns (else the general box).
        final e = outcome!.error!;
        final field = generateErrorField(e);
        final msg = formSaveErrorMessage(e);
        setState(() {
          if (field == null) {
            _error = msg;
          } else {
            _fieldErrors = {field: msg};
          }
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _clearFieldError(String field) {
    if (_fieldErrors.containsKey(field)) {
      setState(() => _fieldErrors = {..._fieldErrors}..remove(field));
    }
  }

  Widget _num(
    TextEditingController c,
    String label, {
    bool money = false,
  }) =>
      FormFieldRow(
        label: label,
        child: money
            ? CardNumberField.money(controller: c)
            : CardNumberField(controller: c),
      );

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CardsFormHeader(
            title: 'توليد دفعة كروت',
            onBack: () => context.goNamed('cards'),
            actionLabel: 'توليد',
            actionIcon: Icons.play_arrow_outlined,
            busy: _loading,
            onAction: _submit,
          ),
          if (_error != null) ...[
            const SizedBox(height: AppTokens.s12),
            Container(
              padding: const EdgeInsets.all(AppTokens.s12),
              decoration: BoxDecoration(
                color: AppTokens.dangerBg,
                borderRadius: BorderRadius.circular(AppTokens.r10),
              ),
              child: Text(
                _error!,
                style: const TextStyle(color: AppTokens.red),
              ),
            ),
          ],
          const SizedBox(height: AppTokens.s12),
          CollapsibleSection(
            storageKey: 'batch.core',
            icon: Icons.credit_card_outlined,
            title: 'الإعدادات الأساسية',
            child: Column(
              children: [
                FormFieldRow(
                  label: 'اسم باقة الكروت',
                  child: TextFormField(controller: _packageName),
                ),
                FormFieldRow(
                  label: 'الباقة',
                  required: true,
                  child: CardPlanPicker(
                    selectedId: _planPick?.id,
                    onChanged: _pickPlan,
                    serverError: _fieldErrors['plan'],
                    currency: ref.watch(tenantCurrencyProvider),
                  ),
                ),
                FormFieldRow(
                  label: 'العدد',
                  required: true,
                  hint: '1 – $kMaxCardsPerBatch',
                  child: CardNumberField(
                    controller: _count,
                    required: true,
                    emptyMessage: validateCardCount(null),
                    check: (v) => validateCardCount(v?.toInt()),
                    serverError: _fieldErrors['count'],
                    onChanged: (_) => _clearFieldError('count'),
                  ),
                ),
                FormFieldPair(
                  first: _num(_pricePerCard, 'سعر البطاقة', money: true),
                  second: FormFieldRow(
                    label: 'السعر الإجمالي',
                    hint: 'سعر البطاقة × العدد — يمكنك تعديله',
                    child: CardNumberField.money(
                      controller: _totalPrice,
                      // Typed by hand: stop following price × count.
                      onChanged: (_) => _totalEdited = true,
                    ),
                  ),
                ),
                FormFieldPair(
                  first: _num(_totalQuota, 'الحصة الكلية MB'),
                  second: FormFieldRow(
                    label: 'اسم الخدمة',
                    child: TextFormField(controller: _serviceName),
                  ),
                ),
                FormFieldRow(
                  label: 'ملاحظات',
                  child: TextFormField(controller: _notes),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.s12),
          CollapsibleSection(
            storageKey: 'batch.username',
            icon: Icons.text_fields,
            title: 'إعدادات اسم المستخدم',
            child: Column(
              children: [
                FormFieldPair(
                  first: FormFieldRow(
                    label: 'بادئة اسم المستخدم — اختياري',
                    child: TextFormField(
                      controller: _prefix,
                      maxLength: 12,
                      textDirection: TextDirection.ltr,
                      decoration: const InputDecoration(
                        hintText: 'مثال: 25',
                        counterText: '',
                      ),
                      validator: (v) => validateCardAffix(v ?? ''),
                    ),
                  ),
                  second: FormFieldRow(
                    label: 'لاحقة اسم المستخدم — اختياري',
                    child: TextFormField(
                      controller: _suffix,
                      maxLength: 12,
                      textDirection: TextDirection.ltr,
                      decoration: const InputDecoration(
                        hintText: 'مثال: 99',
                        counterText: '',
                      ),
                      validator: (v) => validateCardAffix(v ?? ''),
                    ),
                  ),
                ),
                FormFieldRow(
                  label: 'طول الاسم (كامل مع البادئة واللاحقة)',
                  child: CardNumberField(
                    controller: _ulen,
                    required: true,
                    min: kCardUsernameLengthMin,
                    max: kCardUsernameLengthMax,
                    serverError: _fieldErrors['username_length'],
                    onChanged: (_) => _clearFieldError('username_length'),
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('تضمين رقم الحزمة'),
                  subtitle: const Text(
                    'يضيف رقم الحزمة بعد البادئة وقبل الأرقام العشوائيّة، '
                    'ضمن الطول الكلّيّ.',
                  ),
                  value: _includeBatchNumber,
                  onChanged: (v) {
                    setState(() => _includeBatchNumber = v);
                    if (v) _loadNextBatchId();
                  },
                ),
                _UsernamePreviewCard(
                  preview: UsernamePreview.of(
                    prefix: _prefix.text,
                    suffix: _suffix.text,
                    totalLength: parseIntInput(_ulen.text),
                    batchNumber:
                        _includeBatchNumber ? '${_nextBatchId ?? ''}' : '',
                    count: parseIntInput(_count.text) ?? 0,
                  ),
                  batchEstimated: _includeBatchNumber,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.s12),
          CollapsibleSection(
            storageKey: 'batch.password',
            icon: Icons.password,
            title: 'إعدادات كلمة المرور',
            child: FormFieldPair(
              first: _noPassword
                  ? const FormFieldRow(
                      label: 'الطول',
                      child: Text('—'),
                    )
                  : FormFieldRow(
                      label: 'الطول',
                      child: CardNumberField(
                        controller: _plen,
                        required: true,
                        min: 1,
                        max: kCardPasswordLengthMax,
                      ),
                    ),
              second: FormFieldRow(
                label: 'مستوى التعقيد',
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: _passwordType,
                  items: const [
                    DropdownMenuItem(value: 'digits', child: Text('أرقام فقط')),
                    DropdownMenuItem(
                      value: 'medium',
                      child: Text('متوسط (حروف وأرقام)'),
                    ),
                    DropdownMenuItem(
                      value: 'strong',
                      child: Text('قوي (حروف كبيرة وصغيرة وأرقام)'),
                    ),
                    DropdownMenuItem(value: 'weak', child: Text('حروف فقط')),
                    DropdownMenuItem(
                      value: 'none',
                      child: Text('بدون كلمة مرور (رقم فقط)'),
                    ),
                  ],
                  onChanged: (v) =>
                      setState(() => _passwordType = v ?? 'digits'),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppTokens.s12),
          CollapsibleSection(
            storageKey: 'batch.expiry',
            icon: Icons.timer_outlined,
            title: 'الصلاحية',
            child: Column(
              children: [
                FormFieldPair(
                  first: _num(_timeVal, 'مدة البطاقة (0 = صلاحية الباقة)'),
                  second: FormFieldRow(
                    label: 'الوحدة',
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: _timeUnit,
                      items: const [
                        DropdownMenuItem(
                          value: 'minutes',
                          child: Text('دقائق'),
                        ),
                        DropdownMenuItem(value: 'hours', child: Text('ساعات')),
                        DropdownMenuItem(value: 'days', child: Text('أيام')),
                      ],
                      onChanged: (v) => setState(() => _timeUnit = v ?? 'days'),
                    ),
                  ),
                ),
                CardDeviceCountField(
                  value: _devices,
                  onChanged: (v) => setState(() => _devices = v),
                ),
                CardDeviceLimitModeField(
                  value: _deviceLimitMode,
                  onChanged: (v) => setState(() => _deviceLimitMode = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.s40),
        ],
      ),
    );
  }
}

/// «معاينة اسم المستخدم»: prefix | batch no. | generated | suffix in
/// distinct colours, like the web generator.
class _UsernamePreviewCard extends StatelessWidget {
  const _UsernamePreviewCard({
    required this.preview,
    required this.batchEstimated,
  });
  final UsernamePreview preview;
  final bool batchEstimated;

  static const _pre = Color(0xFF7C3AED);
  static const _bn = Color(0xFFD97706);
  static const _gen = Color(0xFF0F766E);
  static const _suf = Color(0xFFDB2777);

  @override
  Widget build(BuildContext context) {
    final p = preview;
    Widget legend(Color c, String t) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: c, shape: BoxShape.circle),
            ),
            const SizedBox(width: 4),
            Text(t, style: const TextStyle(fontSize: 12)),
          ],
        );
    return Container(
      margin: const EdgeInsets.only(top: AppTokens.s8),
      padding: const EdgeInsets.all(AppTokens.s12),
      decoration: BoxDecoration(
        color: AppTokens.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'معاينة اسم المستخدم',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Directionality(
            textDirection: TextDirection.ltr,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text.rich(
                TextSpan(
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                  children: [
                    TextSpan(
                      text: p.prefix,
                      style: const TextStyle(color: _pre),
                    ),
                    TextSpan(
                      text: p.batchNumber,
                      style: const TextStyle(color: _bn),
                    ),
                    TextSpan(
                      text: p.generated,
                      style: const TextStyle(color: _gen),
                    ),
                    TextSpan(
                      text: p.suffix,
                      style: const TextStyle(color: _suf),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              legend(_pre, 'البادئة'),
              if (p.batchNumber.isNotEmpty)
                legend(
                  _bn,
                  batchEstimated ? 'رقم الحزمة (المتوقَّع)' : 'رقم الحزمة',
                ),
              legend(_gen, 'الجزء المولَّد (${p.generatedLength} أرقام)'),
              legend(_suf, 'اللاحقة'),
            ],
          ),
          if (p.refusal != null) ...[
            const SizedBox(height: 6),
            Text(
              p.refusal!,
              key: const ValueKey('username-length-refusal'),
              style: const TextStyle(
                color: AppTokens.redInk,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (p.warning != null) ...[
            const SizedBox(height: 6),
            Text(
              p.warning!,
              style: const TextStyle(
                color: AppTokens.amberInk,
                fontSize: 12.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// «السعر الإجمالي» = card price × count (Arabic digits too); null when
/// either is not a valid number.
String? batchTotalPrice(String price, String count) {
  final p = parseNumberInput(price);
  final c = parseIntInput(count);
  if (p == null || c == null) return null;
  return formatBatchNumber(p * c);
}

/// 5 → «5», 2.5 → «2.5», 1.005 → «1.01» (what the price fields show).
String formatBatchNumber(num v) {
  if (v == v.roundToDouble()) return v.toInt().toString();
  var t = v.toStringAsFixed(2);
  if (t.endsWith('0')) t = t.substring(0, t.length - 1);
  return t;
}

/// Which generate-form field a server 4xx concerns: `details.field` when
/// sent, else a keyword match; null = the general error box.
String? generateErrorField(Object e) {
  if (e is! ApiException) return null;
  final d = e.details;
  final f = d is Map ? '${d['field'] ?? ''}' : '';
  const byField = {
    'plan_id': 'plan',
    'plan': 'plan',
    'count': 'count',
    'username_length': 'username_length',
  };
  if (byField.containsKey(f)) return byField[f];
  final m = e.message;
  if (m.contains('طول اسم') || m.contains('username_length')) {
    return 'username_length';
  }
  if (m.contains('الباقة') || m.contains('العرض')) return 'plan';
  if (m.contains('العدد') ||
      m.contains('عدد البطاقات') ||
      m.contains('عدد الكروت') ||
      m.contains('الدفعة الواحدة')) {
    return 'count';
  }
  return null;
}

/// The generator form's length boxes start at 8 / 6; when the server tells
/// the network's defaults, untouched boxes take them (an edited box wins).
(String, String) applyCardDefaultLengths({
  required String currentUsername,
  required String currentPassword,
  int? defaultUsername,
  int? defaultPassword,
}) {
  final u = (defaultUsername != null && currentUsername.trim() == '8')
      ? '$defaultUsername'
      : currentUsername;
  final p = (defaultPassword != null && currentPassword.trim() == '6')
      ? '$defaultPassword'
      : currentPassword;
  return (u, p);
}
