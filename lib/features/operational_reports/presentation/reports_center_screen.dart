import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/hub_kpi.dart';
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
        Text(
          'مركز التقارير',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTokens.sidebarBg,
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: AppTokens.s4),
        const Text(
          'تقارير التشغيل قراءة فقط — جلسات، دخول، أحداث، شبكة، ومالية. '
          'اختر تقريرًا لعرض أعمدته المخصصة والفلترة الزمنية.',
          style: TextStyle(color: AppTokens.textMuted),
        ),
        const SizedBox(height: AppTokens.s16),
        _CatalogHero(categories: categories),
        const SizedBox(height: AppTokens.s12),
        const AppCard(
          child: Row(
            children: [
              Icon(Icons.privacy_tip_outlined, color: AppTokens.brand),
              SizedBox(width: AppTokens.s8),
              Expanded(
                child: Text(
                  'هذه التقارير قراءة فقط من الخادم. لا تعرض كلمات مرور أو أسرار.',
                  style: TextStyle(color: AppTokens.textMuted),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTokens.s8),
        for (final category in categories) ...[
          const SizedBox(height: AppTokens.s16),
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
    final kpis = <Widget>[
      HubKpi(
        label: 'التقارير المتاحة',
        value: '${operationalReportCatalog.length}',
        icon: Icons.query_stats_outlined,
        variant: KpiVariant.brand,
      ),
      HubKpi(
        label: 'التصنيفات',
        value: '${categories.length}',
        icon: Icons.category_outlined,
        variant: KpiVariant.blue,
      ),
      HubKpi(
        label: 'تقارير الأحداث',
        value: '$auditCount',
        icon: Icons.history_edu_outlined,
        variant: KpiVariant.amber,
      ),
      HubKpi(
        label: 'تقارير مالية',
        value: '$financeCount',
        icon: Icons.payments_outlined,
        variant: KpiVariant.green,
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 880
            ? 4
            : constraints.maxWidth >= 560
                ? 2
                : 1;
        const gap = AppTokens.s12;
        final itemWidth =
            (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final kpi in kpis) SizedBox(width: itemWidth, child: kpi),
          ],
        );
      },
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
            bottom: AppTokens.s8,
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
            const gap = AppTokens.s12;
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
          padding: const EdgeInsets.all(AppTokens.s16),
          decoration: BoxDecoration(
            color: AppTokens.card,
            borderRadius: BorderRadius.circular(AppTokens.r14),
            border: Border.all(color: AppTokens.border),
            boxShadow: AppTokens.shCard,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTokens.brandSoft,
                  borderRadius: BorderRadius.circular(AppTokens.r10),
                ),
                child: Icon(def.icon, size: 20, color: AppTokens.brandInk),
              ),
              const SizedBox(width: AppTokens.s12),
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
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_left,
                color: AppTokens.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
