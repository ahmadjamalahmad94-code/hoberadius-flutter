import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/features/operational_reports/domain/operational_report_catalog.dart';
import 'package:hoberadius_app/features/operational_reports/presentation/report_formatting.dart';

void main() {
  test('catalog covers the 15 wired slugs with curated columns', () {
    expect(operationalReportCatalog.length, 15);
    for (final def in operationalReportCatalog) {
      expect(def.columns, isNotEmpty, reason: 'missing columns for ${def.slug}');
      expect(def.title.trim(), isNotEmpty);
      expect(def.category.trim(), isNotEmpty);
    }
    // Lookup + categories.
    expect(operationalReportBySlug('cash-transactions')?.title, 'الحركات النقدية');
    expect(operationalReportBySlug('does-not-exist'), isNull);
    expect(operationalReportCategories(), contains('المالية'));
  });

  test('cell formatting renders each kind for humans', () {
    const dateCol = ReportColumn('d', 'd', kind: ReportColumnKind.date);
    const bytesCol = ReportColumn('b', 'b', kind: ReportColumnKind.bytes);
    const durCol = ReportColumn('s', 's', kind: ReportColumnKind.duration);
    const boolCol = ReportColumn('x', 'x', kind: ReportColumnKind.boolean);
    const amtCol = ReportColumn('a', 'a', kind: ReportColumnKind.amount);
    const textCol = ReportColumn('t', 't');

    expect(formatReportCell(bytesCol, 1536), '1.5 KB');
    expect(formatReportCell(durCol, 3661), '1س 1د');
    expect(formatReportCell(boolCol, 1), 'نعم');
    expect(formatReportCell(boolCol, 0), 'لا');
    expect(formatReportCell(boolCol, null), 'لا');
    expect(formatReportCell(amtCol, '12.5'), '12.50');
    expect(formatReportCell(textCol, null), '—');
    expect(formatReportCell(textCol, 'hello'), 'hello');
    expect(
      formatReportCell(dateCol, '2026-06-16T09:30:00'),
      contains('2026-06-16'),
    );
  });

  test('reportRowDate extracts the configured date key', () {
    final def = operationalReportBySlug('cash-transactions')!;
    final date = reportRowDate(def, {'created_at': '2026-06-16T10:00:00'});
    expect(date, isNotNull);
    expect(date!.year, 2026);
    expect(reportRowDate(def, {'created_at': ''}), isNull);
  });
}
