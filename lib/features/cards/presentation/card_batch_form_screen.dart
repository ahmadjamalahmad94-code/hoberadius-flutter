// ignore_for_file: require_trailing_commas, deprecated_member_use

import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoberadius_app/core/api/idempotency.dart';
import 'package:hoberadius_app/core/api/visible_error_message.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/collapsible_section.dart';
import '../../../shared/widgets/form_field_row.dart';
import '../../../shared/widgets/hub_layout.dart';
import '../data/cards_repository.dart';
import '../domain/card_model.dart';
import '../domain/username_preview.dart';
import '../application/cards_list_providers.dart';
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
  final _plan = TextEditingController();
  final _count = TextEditingController(text: '10');
  final _pricePerCard = TextEditingController(text: '0');
  final _totalPrice = TextEditingController(text: '0');
  final _totalQuota = TextEditingController(text: '0');
  final _serviceName = TextEditingController();
  final _prefix = TextEditingController();
  final _suffix = TextEditingController();
  final _ulen = TextEditingController(text: '8');
  final _plen = TextEditingController(text: '6');
  final _timeVal = TextEditingController(text: '1');
  final _notes = TextEditingController();

  // «أرقام فقط» by default, like the web generator (شبكة المحترف request):
  // numeric cards are easier to print and type.
  String _passwordType = 'digits';
  String _timeUnit = 'days';
  bool _includeBatchNumber = false;

  /// Estimated id of the batch about to be created (latest id + 1), for the
  /// «تضمين رقم الحزمة» preview; null until known.
  int? _nextBatchId;
  int _devices = 1;

  bool _loading = false;
  String? _error;
  GenerateResult? _result;

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
  }

  void _refreshPreview() {
    if (mounted) setState(() {});
  }

  Future<void> _loadNextBatchId() async {
    if (_nextBatchId != null) return;
    try {
      final rows =
          await ref.read(cardsRepositoryProvider).listBatches(limit: 5);
      final maxId = rows.fold<int>(0, (m, b) => (b.id ?? 0) > m ? b.id! : m);
      if (mounted) setState(() => _nextBatchId = maxId + 1);
    } catch (_) {
      // Preview only — the server applies the real batch number.
    }
  }

  @override
  void dispose() {
    for (final c in [
      _packageName,
      _plan,
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
          'سيتم توليد $count بطاقة في دفعة واحدة. قد يستغرق ذلك وقتًا '
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
    final count = int.parse(_count.text.trim());
    if (count > kConfirmCardsAbove && !await _confirmLargeBatch(count)) return;
    if (!mounted) return;
    final req = GenerateBatchRequest(
      planId: int.parse(_plan.text.trim()),
      count: count,
      packageName: _packageName.text.trim(),
      usernamePrefix: normalizeCardAffix(_prefix.text),
      usernameSuffix: normalizeCardAffix(_suffix.text),
      includeBatchNumber: _includeBatchNumber,
      usernameLength: int.tryParse(_ulen.text) ?? 8,
      passwordLength: int.tryParse(_plen.text) ?? 6,
      passwordGenerationType: _noPassword ? 'digits' : _passwordType,
      loginWithoutPassword: _noPassword,
      timeValue: int.tryParse(_timeVal.text) ?? 0,
      timeUnit: _timeUnit,
      deviceCount: _devices,
      pricePerCard: num.tryParse(_pricePerCard.text.trim()) ?? 0,
      totalPrice: num.tryParse(_totalPrice.text.trim()) ?? 0,
      totalQuotaMb: int.tryParse(_totalQuota.text.trim()) ?? 0,
      serviceName: _serviceName.text.trim(),
      notes: _notes.text.trim(),
    );
    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });
    try {
      final r = await ref.read(cardsRepositoryProvider).generate(
            req,
            idempotencyKey: _idem.keyFor('cards/generate', req.toBody()),
          );
      _idem.reset();
      if (!mounted) return;
      setState(() => _result = r);
      ref.invalidate(batchesListProvider);
    } catch (e) {
      // 422 (cap / too few digit combinations: the server names the max),
      // 503 busy (retry keeps the same key) — the server's Arabic text.
      if (mounted) setState(() => _error = visibleErrorWithRetryHint(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _exportCsv() async {
    final r = _result;
    if (r == null) return;
    final rows = <List<dynamic>>[
      ['username', 'password', 'expire_at'],
      for (final c in r.cards)
        [c.username, c.password, c.expireAt?.toIso8601String() ?? ''],
    ];
    final csv = const ListToCsvConverter().convert(rows);
    // UTF-8 with BOM (codeUnits truncated every non-Latin character).
    final bytes = Uint8List.fromList([0xEF, 0xBB, 0xBF, ...utf8.encode(csv)]);
    await FileSaver.instance.saveFile(
      name: 'cards_${r.batch.batchCode}',
      bytes: bytes,
      ext: 'csv',
      mimeType: MimeType.csv,
    );
  }

  Widget _num(TextEditingController c, String label) => FormFieldRow(
        label: label,
        child: TextFormField(controller: c, keyboardType: TextInputType.number),
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
                FormFieldPair(
                  first: FormFieldRow(
                    label: 'معرّف الباقة',
                    required: true,
                    child: TextFormField(
                      controller: _plan,
                      keyboardType: TextInputType.number,
                      validator: (v) =>
                          (v == null || int.tryParse(v.trim()) == null)
                              ? 'مطلوب'
                              : null,
                    ),
                  ),
                  second: FormFieldRow(
                    label: 'العدد',
                    required: true,
                    hint: '1 – $kMaxCardsPerBatch',
                    child: TextFormField(
                      controller: _count,
                      keyboardType: TextInputType.number,
                      validator: (v) =>
                          validateCardCount(int.tryParse(v?.trim() ?? '')),
                    ),
                  ),
                ),
                FormFieldPair(
                  first: _num(_pricePerCard, 'سعر البطاقة'),
                  second: _num(_totalPrice, 'السعر الإجمالي'),
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
                _num(_ulen, 'طول الاسم (كامل مع البادئة واللاحقة)'),
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
                    totalLength: int.tryParse(_ulen.text.trim()),
                    batchNumber:
                        _includeBatchNumber ? '${_nextBatchId ?? ''}' : '',
                    count: int.tryParse(_count.text.trim()) ?? 0,
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
                  : _num(_plen, 'الطول'),
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
                  first: _num(_timeVal, 'القيمة'),
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
                FormFieldRow(
                  label: 'عدد الأجهزة المسموحة',
                  child: DropdownButtonFormField<int>(
                    isExpanded: true,
                    value: _devices,
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('1')),
                      DropdownMenuItem(value: 2, child: Text('2')),
                      DropdownMenuItem(value: 3, child: Text('3')),
                      DropdownMenuItem(value: 5, child: Text('5')),
                      DropdownMenuItem(value: 10, child: Text('10')),
                    ],
                    onChanged: (v) => setState(() => _devices = v ?? 1),
                  ),
                ),
              ],
            ),
          ),
          if (_result != null) ...[
            const SizedBox(height: AppTokens.s16),
            _BatchResult(result: _result!, onExportCsv: _exportCsv),
          ],
          const SizedBox(height: AppTokens.s40),
        ],
      ),
    );
  }
}

class _BatchResult extends ConsumerWidget {
  const _BatchResult({required this.result, required this.onExportCsv});
  final GenerateResult result;
  final VoidCallback onExportCsv;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = AppPalette.of(context);
    return Container(
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(AppTokens.r14),
        border: Border.all(color: p.successStrong.withValues(alpha: 0.4)),
        boxShadow: p.shCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(AppTokens.s12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [p.successBg, p.card],
                begin: Alignment.centerRight,
                end: Alignment.centerLeft,
              ),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(AppTokens.r14),
                topLeft: Radius.circular(AppTokens.r14),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(Icons.check_circle, color: p.successStrong),
                    const SizedBox(width: AppTokens.s8),
                    Expanded(
                      child: Text(
                        'تم توليد ${result.cards.length} كرت — الدفعة ${result.batch.batchCode}',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: p.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTokens.s12),
                ActionBar(
                  items: [
                    ActionItem(
                      icon: Icons.file_download_outlined,
                      label: 'تصدير ملف',
                      onPressed: onExportCsv,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: result.cards.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (ctx, i) {
              final c = result.cards[i];
              return ListTile(
                dense: true,
                title: Text(
                  c.username,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text('كلمة المرور: ${c.password}'),
              );
            },
          ),
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
