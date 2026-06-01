import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/status_pill.dart';
import '../../domain/print_template_model.dart';
import 'template_metric.dart';

/// Card listing the saved [CardPrintTemplate]s. Empty / non-empty
/// states wrap an [AppCard]. Action buttons are wired to the parent
/// via [onPreview] / [onExportPdf].
class TemplateList extends StatelessWidget {
  const TemplateList({
    super.key,
    required this.items,
    required this.previewing,
    required this.exportingPdf,
    required this.onPreview,
    required this.onExportPdf,
  });

  final List<CardPrintTemplate> items;
  final bool previewing;
  final bool exportingPdf;
  final ValueChanged<CardPrintTemplate> onPreview;
  final ValueChanged<CardPrintTemplate> onExportPdf;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const AppCard(
        child: EmptyState(
          icon: Icons.print_outlined,
          title: 'لا توجد قوالب طباعة بعد',
          subtitle: 'احفظ أول قالب لاستخدامه في الطباعة.',
        ),
      );
    }
    return AppCard(
      title: 'القوالب المحفوظة',
      icon: Icons.print_outlined,
      child: Column(
        children: [
          for (final item in items) ...[
            _TemplateTile(
              item: item,
              previewing: previewing,
              exportingPdf: exportingPdf,
              onPreview: () => onPreview(item),
              onExportPdf: () => onExportPdf(item),
            ),
            if (item != items.last) const Divider(height: AppTokens.s24),
          ],
        ],
      ),
    );
  }
}

class _TemplateTile extends StatelessWidget {
  const _TemplateTile({
    required this.item,
    required this.previewing,
    required this.exportingPdf,
    required this.onPreview,
    required this.onExportPdf,
  });

  final CardPrintTemplate item;
  final bool previewing;
  final bool exportingPdf;
  final VoidCallback onPreview;
  final VoidCallback onExportPdf;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: AppTokens.s8,
          runSpacing: AppTokens.s8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              item.name,
              style: const TextStyle(
                color: AppTokens.sidebarBg,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
            StatusPill(
              text: item.orientation == 'landscape' ? 'أفقي' : 'عمودي',
              tone: PillTone.cyan,
            ),
            StatusPill(
              text: item.showQr ? 'QR ظاهر' : 'بدون QR',
              tone: item.showQr ? PillTone.green : PillTone.neutral,
            ),
          ],
        ),
        const SizedBox(height: AppTokens.s8),
        Wrap(
          spacing: AppTokens.s8,
          runSpacing: AppTokens.s8,
          children: [
            TemplateMetric(label: 'لكل صفحة', value: '${item.cardsPerPage}'),
            TemplateMetric(label: 'الصف', value: '${item.cardsPerRow}'),
            TemplateMetric(label: 'العمود', value: '${item.cardsPerColumn}'),
            TemplateMetric(label: 'الخط', value: '${item.fontSize}'),
          ],
        ),
        const SizedBox(height: AppTokens.s8),
        Text(
          'اسم الدخول (${item.usernameX}, ${item.usernameY}) • كلمة المرور (${item.passwordX}, ${item.passwordY}) • QR (${item.qrX}, ${item.qrY})',
          style: const TextStyle(color: AppTokens.textMuted),
        ),
        const SizedBox(height: AppTokens.s12),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: Wrap(
            spacing: AppTokens.s8,
            runSpacing: AppTokens.s8,
            children: [
              OutlinedButton.icon(
                onPressed: previewing ? null : onPreview,
                icon: const Icon(Icons.visibility_outlined),
                label: const Text('معاينة بصرية'),
              ),
              ElevatedButton.icon(
                onPressed: exportingPdf ? null : onExportPdf,
                icon: exportingPdf
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.picture_as_pdf_outlined),
                label: Text(exportingPdf ? 'جاري التصدير...' : 'PDF'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
