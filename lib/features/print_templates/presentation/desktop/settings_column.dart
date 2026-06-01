/// Left column of the Windows export room.
/// Batch picker + override text fields + action buttons + the
/// "تنظيف قوالب المعاينة" button — mirrors the web's
/// `#export .pr-export-body` settings card byte-for-byte.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/tokens.dart';
import '../../../cards/data/cards_repository.dart';
import '../../../cards/domain/card_batch.dart';
import '../../data/print_templates_repository.dart';
import '../widgets/pdf_preview_launcher.dart';
import 'export_room_state.dart';

class SettingsColumn extends ConsumerStatefulWidget {
  const SettingsColumn({super.key});

  @override
  ConsumerState<SettingsColumn> createState() => _SettingsColumnState();
}

class _SettingsColumnState extends ConsumerState<SettingsColumn> {
  final _hotspot = TextEditingController();
  final _price = TextEditingController();
  final _validity = TextEditingController();
  final _footer = TextEditingController();
  Future<List<CardBatch>>? _batchesFuture;

  @override
  void initState() {
    super.initState();
    _batchesFuture = ref.read(cardsRepositoryProvider).listBatches(limit: 200);
  }

  @override
  void dispose() {
    _hotspot.dispose();
    _price.dispose();
    _validity.dispose();
    _footer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(exportRoomControllerProvider);
    final notifier = ref.read(exportRoomControllerProvider.notifier);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.s12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.checklist_outlined),
                const SizedBox(width: AppTokens.s8),
                const Text(
                  'إعداد التصدير',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                ),
                const Spacer(),
                if (state.busy)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: AppTokens.s12),
            FutureBuilder<List<CardBatch>>(
              future: _batchesFuture,
              builder: (context, snap) {
                final batches = snap.data ?? const <CardBatch>[];
                return DropdownButtonFormField<int?>(
                  initialValue: state.selectedBatchId,
                  isExpanded: true,
                  hint: const Text('اختر حزمة بطاقات'),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('بدون حزمة (عينة فقط)'),
                    ),
                    ...batches.map(
                      (b) => DropdownMenuItem<int?>(
                        value: b.id,
                        child: Text(
                          b.batchCode.isNotEmpty
                              ? b.batchCode
                              : 'حزمة #${b.id}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                  onChanged: (v) => notifier.selectBatch(v),
                  decoration: const InputDecoration(
                    labelText: 'الحزمة',
                    border: OutlineInputBorder(),
                  ),
                );
              },
            ),
            const SizedBox(height: AppTokens.s12),
            _overrideRow(
              left: _overrideField(
                'hotspot_address',
                _hotspot,
                label: 'عنوان Hotspot/DNS',
                hint: 'اتركه فارغًا لاستخدام القالب',
              ),
              right: _overrideField(
                'price_text',
                _price,
                label: 'السعر الظاهر',
                hint: 'مثال: 1.00 دينار',
              ),
            ),
            const SizedBox(height: AppTokens.s8),
            _overrideRow(
              left: _overrideField(
                'validity_text',
                _validity,
                label: 'الصلاحية الظاهرة',
                hint: 'مثال: 4 ساعات',
              ),
              right: _overrideField(
                'footer_text',
                _footer,
                label: 'النص أسفل البطاقة',
                hint: 'اتركه فارغًا لاستخدام القالب',
              ),
            ),
            const SizedBox(height: AppTokens.s12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: state.selectedTemplateId == null || state.busy
                      ? null
                      : _exportPdf,
                  icon: const Icon(Icons.print_outlined),
                  label: const Text('تصدير PDF للحزمة'),
                ),
                OutlinedButton.icon(
                  onPressed: state.selectedTemplateId == null || state.busy
                      ? null
                      : _sampleSinglePdf,
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: const Text('ملف PDF تجريبي'),
                ),
                OutlinedButton.icon(
                  onPressed: state.busy ? null : _confirmCleanup,
                  icon: const Icon(Icons.cleaning_services_outlined),
                  label: const Text('تنظيف قوالب المعاينة'),
                ),
              ],
            ),
            if (state.error != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  border: Border.all(color: const Color(0xFFFECACA)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  state.error!,
                  style: const TextStyle(
                    color: Color(0xFFB91C1C),
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _overrideField(
    String key,
    TextEditingController controller, {
    required String label,
    required String hint,
  }) {
    return TextField(
      controller: controller,
      onChanged: (v) =>
          ref.read(exportRoomControllerProvider.notifier).setOverride(key, v),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
    );
  }

  Widget _overrideRow({required Widget left, required Widget right}) {
    return Row(
      children: [
        Expanded(child: left),
        const SizedBox(width: 8),
        Expanded(child: right),
      ],
    );
  }

  Future<void> _exportPdf() async {
    final state = ref.read(exportRoomControllerProvider);
    if (state.selectedTemplateId == null) return;
    final repo = ref.read(printTemplatesRepositoryProvider);
    final bytes = await repo.exportPdf(
      state.selectedTemplateId!,
      batchId: state.selectedBatchId,
      overrides: state.overrides,
    );
    if (!mounted) return;
    await PdfPreviewLauncher.show(
      context,
      pdfBytes: bytes,
      fileName: state.selectedBatchId != null
          ? 'cards-batch-${state.selectedBatchId}-template-${state.selectedTemplateId}.pdf'
          : 'cards-template-${state.selectedTemplateId}.pdf',
    );
  }

  Future<void> _sampleSinglePdf() async {
    final state = ref.read(exportRoomControllerProvider);
    if (state.selectedTemplateId == null) return;
    final repo = ref.read(printTemplatesRepositoryProvider);
    final bytes = await repo.exportPdf(
      state.selectedTemplateId!,
      overrides: state.overrides,
    );
    if (!mounted) return;
    await PdfPreviewLauncher.show(
      context,
      pdfBytes: bytes,
      fileName: 'sample-template-${state.selectedTemplateId}.pdf',
    );
  }

  Future<void> _confirmCleanup() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تنظيف قوالب المعاينة'),
        content: const Text(
          'سيتم حذف القوالب التي أنشأتها الاختبارات تلقائيًا '
          '(Print UI / ops_room_ / template_…). متابعة؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    final purged =
        await ref.read(exportRoomControllerProvider.notifier).cleanupFixtures();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          purged != null && purged > 0
              ? 'تم تنظيف $purged قالب اختبار من القائمة.'
              : 'لا توجد قوالب اختبار للتنظيف.',
        ),
      ),
    );
  }
}
