import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoberadius_app/core/api/visible_error_message.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../data/operational_reports_repository.dart';
import '../domain/operational_report_model.dart';

const _reports = <String, _ReportDef>{
  'sessions': _ReportDef(
    'جلسات الاتصال',
    'كل جلسات الريدياس المسجلة في جدول المحاسبة.',
  ),
  'failed-logins': _ReportDef(
    'محاولات فاشلة',
    'رفض الدخول من radpostauth بدون كشف كلمة المرور.',
  ),
  'login-status': _ReportDef(
    'حالة دخول المستفيدين',
    'آخر دخول وظهور وحالة الحساب.',
  ),
  'mac-history': _ReportDef(
    'تاريخ MAC',
    'الأجهزة المختلفة التي ظهرت لكل اسم دخول.',
  ),
  'profile-changes': _ReportDef(
    'تغييرات الباقة',
    'أحداث تعديل أو تمديد حسابات المستفيدين.',
  ),
  'api-messages': _ReportDef(
    'رسائل واجهة الربط',
    'أحداث نفذتها مفاتيح الربط.',
  ),
  'coa-failures': _ReportDef(
    'فشل أوامر الشبكة',
    'عمليات فصل أو مزامنة فشلت أو تنتظر إعادة محاولة.',
  ),
  'manager-events': _ReportDef(
    'أحداث المدراء',
    'الأفعال الإدارية من غير مفاتيح الربط.',
  ),
  'manager-login-status': _ReportDef(
    'دخول المدراء',
    'آخر دخول وحالة حسابات الإدارة.',
  ),
  'user-events': _ReportDef(
    'أحداث المستفيدين',
    'سجل الأحداث المرتبطة بحسابات المستفيدين.',
  ),
};

final _reportProvider = FutureProvider.autoDispose
    .family<OperationalReportSnapshot, _ReportRequest>((ref, request) {
  return ref.watch(operationalReportsRepositoryProvider).fetch(
        slug: request.slug,
        query: request.query,
      );
});

class OperationalReportsScreen extends ConsumerStatefulWidget {
  const OperationalReportsScreen({super.key});

  @override
  ConsumerState<OperationalReportsScreen> createState() =>
      _OperationalReportsScreenState();
}

class _OperationalReportsScreenState
    extends ConsumerState<OperationalReportsScreen> {
  final _queryController = TextEditingController();
  String _slug = 'sessions';
  String _query = '';

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final request = _ReportRequest(_slug, _query);
    final async = ref.watch(_reportProvider(request));
    final selected = _reports[_slug]!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'تقارير التشغيل',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppTokens.sidebarBg,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
            IconButton(
              tooltip: 'تحديث',
              onPressed: () => ref.invalidate(_reportProvider(request)),
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
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
        const SizedBox(height: AppTokens.s12),
        AppCard(
          padding: const EdgeInsets.all(AppTokens.s12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _slug,
                decoration: const InputDecoration(labelText: 'نوع التقرير'),
                items: _reports.entries
                    .map(
                      (entry) => DropdownMenuItem(
                        value: entry.key,
                        child: Text(entry.value.title),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _slug = value);
                },
              ),
              const SizedBox(height: AppTokens.s8),
              Text(
                selected.subtitle,
                style: const TextStyle(color: AppTokens.textMuted),
              ),
              const SizedBox(height: AppTokens.s12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _queryController,
                      decoration: const InputDecoration(
                        labelText: 'بحث',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onSubmitted: (_) => _search(),
                    ),
                  ),
                  const SizedBox(width: AppTokens.s8),
                  FilledButton.icon(
                    onPressed: _search,
                    icon: const Icon(Icons.search),
                    label: const Text('بحث'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTokens.s12),
        async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => EmptyState(
            icon: Icons.error_outline,
            title: 'تعذر جلب التقرير',
            subtitle: visibleErrorMessage(e),
          ),
          data: _ReportTable.new,
        ),
      ],
    );
  }

  void _search() {
    setState(() => _query = _queryController.text.trim());
  }
}

class _ReportTable extends StatelessWidget {
  const _ReportTable(this.snapshot);

  final OperationalReportSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    if (snapshot.items.isEmpty) {
      return EmptyState(
        icon: Icons.insert_chart_outlined,
        title: 'لا توجد بيانات',
        subtitle: snapshot.query.isEmpty
            ? 'هذا التقرير لا يحتوي سجلات بعد.'
            : 'لا توجد نتائج تطابق البحث الحالي.',
      );
    }

    final columns = snapshot.items.expand((row) => row.keys).toSet().toList()
      ..sort();
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppTokens.s12),
            child: Text(
              '${snapshot.count} سجل',
              style: const TextStyle(
                color: AppTokens.textMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const Divider(height: 1),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: columns
                  .map((column) => DataColumn(label: Text(_label(column))))
                  .toList(),
              rows: snapshot.items
                  .map(
                    (row) => DataRow(
                      cells: columns
                          .map(
                            (column) => DataCell(
                              ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxWidth: 220),
                                child: Text(
                                  _cell(row[column]),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportDef {
  const _ReportDef(this.title, this.subtitle);
  final String title;
  final String subtitle;
}

class _ReportRequest {
  const _ReportRequest(this.slug, this.query);
  final String slug;
  final String query;

  @override
  bool operator ==(Object other) =>
      other is _ReportRequest && other.slug == slug && other.query == query;

  @override
  int get hashCode => Object.hash(slug, query);
}

String _cell(Object? value) {
  if (value == null || value.toString().isEmpty) return '—';
  if (value is bool) return value ? 'نعم' : 'لا';
  if (value is Map) {
    if (value.isEmpty) return 'لا توجد بيانات';
    final entries = value.entries.take(4).map((entry) {
      return '${_label(entry.key.toString())}: ${_cell(entry.value)}';
    }).join('، ');
    final remaining =
        value.length > 4 ? '، و${value.length - 4} حقل إضافي' : '';
    return entries + remaining;
  }
  if (value is Iterable) {
    final values = value.take(4).map(_cell).join('، ');
    if (values.isEmpty) return 'لا توجد عناصر';
    final remaining =
        value.length > 4 ? '، و${value.length - 4} عنصر إضافي' : '';
    return values + remaining;
  }
  return value.toString();
}

String _label(String key) {
  const labels = {
    'id': 'الرقم',
    'radacctid': 'رقم الجلسة',
    'acctsessionid': 'معرف الجلسة',
    'acctuniqueid': 'المعرف الفريد',
    'username': 'اسم الدخول',
    'nasipaddress': 'عنوان جهاز الشبكة',
    'nasportid': 'منفذ جهاز الشبكة',
    'nasporttype': 'نوع المنفذ',
    'acctstarttime': 'بدأت',
    'acctupdatetime': 'آخر تحديث',
    'acctstoptime': 'انتهت',
    'acctsessiontime': 'مدة الجلسة',
    'acctinputoctets': 'تحميل',
    'acctoutputoctets': 'رفع',
    'callingstationid': 'MAC',
    'calledstationid': 'الوجهة',
    'framedipaddress': 'IP',
    'reply': 'النتيجة',
    'authdate': 'وقت المحاولة',
    'mac': 'MAC',
    'sessions': 'الجلسات',
    'last_seen': 'آخر ظهور',
    'actor': 'المنفذ',
    'action': 'الإجراء',
    'target_type': 'نوع الهدف',
    'target_id': 'الهدف',
    'payload': 'البيانات',
    'ip_address': 'IP المنفذ',
    'user_agent': 'المتصفح',
    'created_at': 'وقت التسجيل',
    'kind': 'النوع',
    'entity_key': 'العنصر',
    'status': 'الحالة',
    'attempts': 'المحاولات',
    'last_error': 'آخر خطأ',
    'next_attempt_at': 'المحاولة القادمة',
    'completed_at': 'اكتمل في',
    'full_name': 'الاسم الكامل',
    'email': 'البريد',
    'enabled': 'مفعّل',
    'role_name': 'الدور',
    'role_display_name': 'اسم الدور',
  };
  return labels[key] ?? key;
}
