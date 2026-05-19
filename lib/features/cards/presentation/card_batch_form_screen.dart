import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/collapsible_section.dart';
import '../../../shared/widgets/form_field_row.dart';
import '../data/cards_repository.dart';
import '../domain/card_model.dart';

class CardBatchFormScreen extends ConsumerStatefulWidget {
  const CardBatchFormScreen({super.key});

  @override
  ConsumerState<CardBatchFormScreen> createState() => _CardBatchFormScreenState();
}

class _CardBatchFormScreenState extends ConsumerState<CardBatchFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _plan = TextEditingController();
  final _count = TextEditingController(text: '10');
  final _prefix = TextEditingController();
  final _ulen = TextEditingController(text: '8');
  final _plen = TextEditingController(text: '6');
  final _timeVal = TextEditingController(text: '1');
  final _notes = TextEditingController();

  String _passwordType = 'medium';
  String _timeUnit = 'days';
  String _affixMode = 'none';
  int _devices = 1;

  bool _loading = false;
  String? _error;
  GenerateResult? _result;

  @override
  void dispose() {
    for (final c in [_plan, _count, _prefix, _ulen, _plen, _timeVal, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final req = GenerateBatchRequest(
      planId: int.parse(_plan.text.trim()),
      count: int.parse(_count.text.trim()),
      usernamePrefix: _prefix.text.trim(),
      startsWithOrEndsWith: _affixMode == 'none' ? '' : _affixMode,
      prefixOrSuffixValue: _affixMode == 'none' ? '' : _prefix.text.trim(),
      usernameLength: int.tryParse(_ulen.text) ?? 8,
      passwordLength: int.tryParse(_plen.text) ?? 6,
      passwordGenerationType: _passwordType,
      timeValue: int.tryParse(_timeVal.text) ?? 0,
      timeUnit: _timeUnit,
      deviceCount: _devices,
      notes: _notes.text.trim(),
    );
    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });
    try {
      final r = await ref.read(cardsRepositoryProvider).generate(req);
      setState(() => _result = r);
    } catch (e) {
      setState(() => _error = '$e');
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
    final bytes = Uint8List.fromList(csv.codeUnits);
    await FileSaver.instance.saveFile(
      name: 'cards_${r.batch.batchCode}',
      bytes: bytes,
      ext: 'csv',
      mimeType: MimeType.csv,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => context.goNamed('cards'),
                icon: const Icon(Icons.arrow_back),
              ),
              Text(
                'توليد دفعة كروت',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppTokens.navy900,
                    ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _loading ? null : _submit,
                icon: _loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.play_arrow_outlined),
                label: const Text('توليد'),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: AppTokens.s12),
            Container(
              padding: const EdgeInsets.all(AppTokens.s12),
              decoration: BoxDecoration(
                color: const Color(0xFFFDE9E9),
                borderRadius: BorderRadius.circular(AppTokens.r10),
              ),
              child: Text(_error!, style: const TextStyle(color: AppTokens.red)),
            ),
          ],
          const SizedBox(height: AppTokens.s16),
          CollapsibleSection(
            storageKey: 'batch.core',
            icon: Icons.credit_card_outlined,
            title: 'الإعدادات الأساسية',
            child: Column(
              children: [
                FormFieldRow(
                  label: 'معرّف الباقة',
                  required: true,
                  child: TextFormField(
                    controller: _plan,
                    keyboardType: TextInputType.number,
                    validator: (v) =>
                        (v == null || int.tryParse(v.trim()) == null) ? 'مطلوب' : null,
                  ),
                ),
                FormFieldRow(
                  label: 'العدد',
                  required: true,
                  hint: 'بين 1 و 2000',
                  child: TextFormField(
                    controller: _count,
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      final n = int.tryParse(v?.trim() ?? '');
                      if (n == null || n < 1 || n > 2000) return 'بين 1 و 2000';
                      return null;
                    },
                  ),
                ),
                FormFieldRow(label: 'ملاحظات', child: TextFormField(controller: _notes)),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.s16),
          CollapsibleSection(
            storageKey: 'batch.username',
            icon: Icons.text_fields,
            title: 'إعدادات اسم المستخدم',
            child: Column(
              children: [
                FormFieldRow(
                  label: 'موضع البادئة/اللاحقة',
                  child: DropdownButtonFormField<String>(
                    value: _affixMode,
                    items: const [
                      DropdownMenuItem(value: 'none', child: Text('بدون')),
                      DropdownMenuItem(value: 'prefix', child: Text('بادئة')),
                      DropdownMenuItem(value: 'suffix', child: Text('لاحقة')),
                    ],
                    onChanged: (v) => setState(() => _affixMode = v ?? 'none'),
                  ),
                ),
                FormFieldRow(
                  label: 'القيمة',
                  hint: 'مثال: qa-',
                  child: TextFormField(controller: _prefix),
                ),
                FormFieldRow(
                  label: 'طول الاسم',
                  child: TextFormField(controller: _ulen, keyboardType: TextInputType.number),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.s16),
          CollapsibleSection(
            storageKey: 'batch.password',
            icon: Icons.password,
            title: 'إعدادات كلمة المرور',
            child: Column(
              children: [
                FormFieldRow(
                  label: 'الطول',
                  child: TextFormField(controller: _plen, keyboardType: TextInputType.number),
                ),
                FormFieldRow(
                  label: 'مستوى التعقيد',
                  child: DropdownButtonFormField<String>(
                    value: _passwordType,
                    items: const [
                      DropdownMenuItem(value: 'digits', child: Text('أرقام فقط')),
                      DropdownMenuItem(value: 'weak', child: Text('ضعيف')),
                      DropdownMenuItem(value: 'medium', child: Text('متوسط')),
                      DropdownMenuItem(value: 'strong', child: Text('قوي')),
                    ],
                    onChanged: (v) => setState(() => _passwordType = v ?? 'medium'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.s16),
          CollapsibleSection(
            storageKey: 'batch.expiry',
            icon: Icons.timer_outlined,
            title: 'الصلاحية',
            child: Column(
              children: [
                FormFieldRow(
                  label: 'القيمة',
                  child: TextFormField(controller: _timeVal, keyboardType: TextInputType.number),
                ),
                FormFieldRow(
                  label: 'الوحدة',
                  child: DropdownButtonFormField<String>(
                    value: _timeUnit,
                    items: const [
                      DropdownMenuItem(value: 'minutes', child: Text('دقائق')),
                      DropdownMenuItem(value: 'hours', child: Text('ساعات')),
                      DropdownMenuItem(value: 'days', child: Text('أيام')),
                    ],
                    onChanged: (v) => setState(() => _timeUnit = v ?? 'days'),
                  ),
                ),
                FormFieldRow(
                  label: 'عدد الأجهزة المسموحة',
                  child: DropdownButtonFormField<int>(
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
            const SizedBox(height: AppTokens.s20),
            _BatchResult(result: _result!, onExportCsv: _exportCsv),
          ],
          const SizedBox(height: AppTokens.s40),
        ],
      ),
    );
  }
}

class _BatchResult extends StatelessWidget {
  const _BatchResult({required this.result, required this.onExportCsv});
  final GenerateResult result;
  final VoidCallback onExportCsv;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppTokens.s16),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: AppTokens.green),
                const SizedBox(width: AppTokens.s8),
                Expanded(
                  child: Text(
                    'تم توليد ${result.cards.length} كرت — الدفعة ${result.batch.batchCode}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppTokens.navy900,
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: onExportCsv,
                  icon: const Icon(Icons.file_download_outlined),
                  label: const Text('تصدير CSV'),
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
