import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/page_header.dart';
import '../../plans/data/plans_repository.dart';
import '../../plans/domain/plan_model.dart';
import '../data/cards_repository.dart';
import '../domain/card_model.dart';
import 'cards_list_screen.dart';

final _importPlansProvider = FutureProvider.autoDispose<List<Plan>>((ref) {
  return ref.watch(plansRepositoryProvider).list();
});

class CardBatchImportScreen extends ConsumerStatefulWidget {
  const CardBatchImportScreen({super.key});

  @override
  ConsumerState<CardBatchImportScreen> createState() =>
      _CardBatchImportScreenState();
}

class _CardBatchImportScreenState extends ConsumerState<CardBatchImportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _packageName = TextEditingController();
  final _serviceName = TextEditingController();
  final _pricePerCard = TextEditingController(text: '0');
  final _totalPrice = TextEditingController(text: '0');
  final _notes = TextEditingController();
  final _csvText = TextEditingController(
    text: 'username,password\ncard001,pass001\ncard002,pass002\n',
  );

  int? _planId;
  String _sourceType = 'external';
  bool _syncToRadius = false;
  bool _loading = false;
  String? _error;
  CardBatchImportResult? _result;

  @override
  void dispose() {
    _packageName.dispose();
    _serviceName.dispose();
    _pricePerCard.dispose();
    _totalPrice.dispose();
    _notes.dispose();
    _csvText.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });
    try {
      final result = await ref.read(cardsRepositoryProvider).importBatch(
            CardBatchImportRequest(
              planId: _planId!,
              csvText: _csvText.text,
              sourceType: _sourceType,
              packageName: _packageName.text.trim(),
              serviceName: _serviceName.text.trim(),
              pricePerCard: num.tryParse(_pricePerCard.text.trim()) ?? 0,
              totalPrice: num.tryParse(_totalPrice.text.trim()) ?? 0,
              notes: _notes.text.trim(),
              syncToRadius: _syncToRadius,
            ),
          );
      ref.invalidate(batchesOperationsProvider);
      ref.invalidate(batchesListProvider);
      if (mounted) setState(() => _result = result);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final plans = ref.watch(_importPlansProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          title: 'استيراد ملف كروت',
          subtitle:
              'أضف ملفًا جاهزًا للحساب التشغيلي أو كروت مستوردة عبر API حقيقي. الملف الخارجي لا يلمس RADIUS.',
          actions: [
            OutlinedButton.icon(
              onPressed: () => context.goNamed('cards'),
              icon: const Icon(Icons.arrow_back),
              label: const Text('العودة للحزم'),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.s16),
        plans.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(AppTokens.s32),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (e, _) => EmptyState(
            icon: Icons.error_outline,
            title: 'تعذر تحميل الباقات',
            subtitle: '$e',
            action: OutlinedButton.icon(
              onPressed: () => ref.invalidate(_importPlansProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
            ),
          ),
          data: (items) => _ImportForm(
            plans: items,
            formKey: _formKey,
            packageName: _packageName,
            serviceName: _serviceName,
            pricePerCard: _pricePerCard,
            totalPrice: _totalPrice,
            notes: _notes,
            csvText: _csvText,
            planId: _planId,
            sourceType: _sourceType,
            syncToRadius: _syncToRadius,
            loading: _loading,
            error: _error,
            result: _result,
            onPlanChanged: (value) => setState(() => _planId = value),
            onSourceChanged: (value) {
              setState(() {
                _sourceType = value;
                if (value == 'external') _syncToRadius = false;
              });
            },
            onSyncChanged: (value) => setState(() => _syncToRadius = value),
            onSubmit: _submit,
          ),
        ),
      ],
    );
  }
}

class _ImportForm extends StatelessWidget {
  const _ImportForm({
    required this.plans,
    required this.formKey,
    required this.packageName,
    required this.serviceName,
    required this.pricePerCard,
    required this.totalPrice,
    required this.notes,
    required this.csvText,
    required this.planId,
    required this.sourceType,
    required this.syncToRadius,
    required this.loading,
    required this.error,
    required this.result,
    required this.onPlanChanged,
    required this.onSourceChanged,
    required this.onSyncChanged,
    required this.onSubmit,
  });

  final List<Plan> plans;
  final GlobalKey<FormState> formKey;
  final TextEditingController packageName;
  final TextEditingController serviceName;
  final TextEditingController pricePerCard;
  final TextEditingController totalPrice;
  final TextEditingController notes;
  final TextEditingController csvText;
  final int? planId;
  final String sourceType;
  final bool syncToRadius;
  final bool loading;
  final String? error;
  final CardBatchImportResult? result;
  final ValueChanged<int?> onPlanChanged;
  final ValueChanged<String> onSourceChanged;
  final ValueChanged<bool> onSyncChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final external = sourceType == 'external';
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (error != null) ...[
            _MessageBox(text: error!, error: true),
            const SizedBox(height: AppTokens.s12),
          ],
          if (result != null) ...[
            _ImportResultCard(result: result!),
            const SizedBox(height: AppTokens.s12),
          ],
          AppCard(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 720;
                return Wrap(
                  spacing: AppTokens.s12,
                  runSpacing: AppTokens.s12,
                  children: [
                    _FieldBox(
                      compact: compact,
                      child: DropdownButtonFormField<int>(
                        initialValue: planId,
                        decoration: const InputDecoration(
                          labelText: 'الباقة المرتبطة',
                        ),
                        items: [
                          for (final p in plans)
                            DropdownMenuItem(
                              value: p.id,
                              child: Text(p.name),
                            ),
                        ],
                        onChanged: onPlanChanged,
                        validator: (value) =>
                            value == null ? 'اختر الباقة' : null,
                      ),
                    ),
                    _FieldBox(
                      compact: compact,
                      child: DropdownButtonFormField<String>(
                        initialValue: sourceType,
                        decoration: const InputDecoration(
                          labelText: 'نوع المصدر',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'external',
                            child: Text('ملف خارجي للحساب فقط'),
                          ),
                          DropdownMenuItem(
                            value: 'imported',
                            child: Text('ملف مستورد داخل RADIUS'),
                          ),
                        ],
                        onChanged: (value) =>
                            onSourceChanged(value ?? 'external'),
                      ),
                    ),
                    _FieldBox(
                      compact: compact,
                      child: TextFormField(
                        controller: packageName,
                        decoration: const InputDecoration(
                          labelText: 'اسم الحزمة',
                          hintText: 'مثال: ملف شهر 6',
                        ),
                      ),
                    ),
                    _FieldBox(
                      compact: compact,
                      child: TextFormField(
                        controller: pricePerCard,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: 'سعر البطاقة'),
                      ),
                    ),
                    _FieldBox(
                      compact: compact,
                      child: TextFormField(
                        controller: totalPrice,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: 'السعر الإجمالي'),
                      ),
                    ),
                    _FieldBox(
                      compact: compact,
                      child: TextFormField(
                        controller: serviceName,
                        decoration:
                            const InputDecoration(labelText: 'اسم الخدمة'),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: AppTokens.s12),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: csvText,
                  minLines: 10,
                  maxLines: 18,
                  textDirection: TextDirection.ltr,
                  decoration: const InputDecoration(
                    labelText: 'الكروت',
                    alignLabelWithHint: true,
                    hintText: 'username,password\ncard001,pass001',
                  ),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'أدخل كروت للاستيراد'
                      : null,
                ),
                const SizedBox(height: AppTokens.s12),
                const _MessageBox(
                  text:
                      'الصيغ المقبولة: username,password أو عمود username فقط. كلمات المرور تُرسل للخادم فقط ولا تُعرض في نتيجة الاستيراد.',
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.s12),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SwitchListTile.adaptive(
                  value: !external && syncToRadius,
                  onChanged: external ? null : onSyncChanged,
                  title: const Text('مزامنة حسابات RADIUS'),
                  subtitle: Text(
                    external
                        ? 'معطل للملف الخارجي حتى لا يلمس NAS أو FreeRADIUS.'
                        : 'يفعّل الكروت المستوردة كحسابات RADIUS فعلية.',
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
                TextFormField(
                  controller: notes,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'ملاحظات',
                    hintText: 'سبب الاستيراد أو مرجع الملف',
                  ),
                ),
                const SizedBox(height: AppTokens.s16),
                ElevatedButton.icon(
                  onPressed: loading ? null : onSubmit,
                  icon: loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.file_upload_outlined),
                  label: const Text('استيراد الملف'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldBox extends StatelessWidget {
  const _FieldBox({required this.child, required this.compact});
  final Widget child;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: compact ? double.infinity : 320, child: child);
  }
}

class _MessageBox extends StatelessWidget {
  const _MessageBox({required this.text, this.error = false});
  final String text;
  final bool error;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTokens.s12),
      decoration: BoxDecoration(
        color: error ? AppTokens.dangerBg : AppTokens.surfaceMuted,
        borderRadius: BorderRadius.circular(AppTokens.r10),
        border: Border.all(
          color:
              error ? AppTokens.red.withValues(alpha: 0.25) : AppTokens.border,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: error ? AppTokens.red : AppTokens.textSecondary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ImportResultCard extends StatelessWidget {
  const _ImportResultCard({required this.result});
  final CardBatchImportResult result;

  @override
  Widget build(BuildContext context) {
    final batch = result.batch;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle_outline, color: AppTokens.green),
              const SizedBox(width: AppTokens.s8),
              Expanded(
                child: Text(
                  'تم استيراد ${result.insertedCount} بطاقة',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppTokens.sidebarBg,
                      ),
                ),
              ),
              if (batch.id != null)
                OutlinedButton.icon(
                  onPressed: () => context.goNamed(
                    'card-batch-detail',
                    pathParameters: {'id': '${batch.id}'},
                  ),
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('فتح الحزمة'),
                ),
            ],
          ),
          const SizedBox(height: AppTokens.s8),
          Text(
            '${batch.batchCode} · ${batch.sourceType} · متخطى ${result.skippedCount} · مزامنة RADIUS ${result.radiusSyncedCount}',
            style: const TextStyle(
              color: AppTokens.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
