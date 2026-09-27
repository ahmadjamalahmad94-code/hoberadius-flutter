import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/hub_layout.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/status_pill.dart';
import '../domain/operational_report_catalog.dart';

/// Reports-center hub — a KPI strip over the catalogue plus the 15 operational
/// reports grouped by category as tappable cards. Replaces the old single
/// dropdown with the web `reports_center` landing + `rep_*` drill-downs.
class ReportsCenterScreen extends StatelessWidget {
  const ReportsCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final categories = operationalReportCategories();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // The read-only/privacy note used to be a card of its own; it is the
        // subtitle now.
        const PageHeader(
          title: 'مركز التقارير',
          subtitle: 'تقارير قراءة فقط — لا تعرض كلمات مرور أو أسرار',
        ),
        const SizedBox(height: AppTokens.s12),
        _CatalogHero(categories: categories),
        for (final category in categories) ...[
          const SizedBox(height: AppTokens.s12),
          _CategorySection(category: category),
        ],
      ],
    );
  }
}

class _CatalogHero extends StatelessWidget {
  const _CatalogHero({required this.categories});

  final List<String> categories;

  @override
  Widget build(BuildContext context) {
    final financeCount = operationalReportCatalog
        .where((def) => def.category == 'المالية')
        .length;
    final auditCount = operationalReportCatalog
        .where((def) => def.category == 'الأحداث والتدقيق')
        .length;
    // Four tight counters in one row instead of four full-width KPI cards.
    return CountGrid(
      columns: 4,
      items: [
        CountItem(
          'التقارير',
          operationalReportCatalog.length,
          tone: PillTone.brand,
        ),
        CountItem('التصنيفات', categories.length, tone: PillTone.blue),
        CountItem('الأحداث', auditCount, tone: PillTone.amber),
        CountItem('المالية', financeCount, tone: PillTone.green),
      ],
    );
  }
}

class _CategorySection extends StatelessWidget {
  const _CategorySection({required this.category});

  final String category;

  @override
  Widget build(BuildContext context) {
    final reports = operationalReportCatalog
        .where((def) => def.category == category)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            right: AppTokens.s4,
            bottom: AppTokens.s4 + 2,
          ),
          child: Text(
            category,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: AppTokens.sidebarBg,
            ),
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 880
                ? 3
                : constraints.maxWidth >= 560
                    ? 2
                    : 1;
            const gap = AppTokens.s8;
            final itemWidth =
                (constraints.maxWidth - gap * (columns - 1)) / columns;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final def in reports)
                  SizedBox(
                    width: itemWidth,
                    child: _ReportCard(def: def),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.def});

  final OperationalReportDef def;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTokens.r14),
        onTap: () => context.go('/operational-reports/${def.slug}'),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.s12,
            vertical: AppTokens.s8 + 2,
          ),
          decoration: BoxDecoration(
            color: AppTokens.card,
            borderRadius: BorderRadius.circular(AppTokens.r14),
            border: Border.all(color: AppTokens.border),
            boxShadow: AppTokens.shCard,
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTokens.brandSoft,
                  borderRadius: BorderRadius.circular(AppTokens.r10),
                ),
                child: Icon(def.icon, size: 18, color: AppTokens.brandInk),
              ),
              const SizedBox(width: AppTokens.s8 + 2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      def.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppTokens.sidebarBg,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      def.subtitle,
                      style: const TextStyle(
                        color: AppTokens.textMuted,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_left, color: AppTokens.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
