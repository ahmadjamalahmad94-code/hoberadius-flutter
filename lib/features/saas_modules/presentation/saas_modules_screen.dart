import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../data/saas_modules_repository.dart';
import '../domain/saas_module_model.dart';

const _modules = <String, _ModuleDef>{
  'bandwidth': _ModuleDef(
    title: 'بروفايلات السرعة',
    subtitle: 'قوالب سرعة محفوظة للاستخدام مع الباقات والمشتركين.',
    path: '/api/v1/bandwidth-profiles',
    fields: [
      _Field('name', 'الاسم'),
      _Field('rate_down', 'تنزيل Kbps', number: true),
      _Field('rate_up', 'رفع Kbps', number: true),
      _Field('priority', 'الأولوية', number: true),
    ],
    columns: ['name', 'rate_down', 'rate_up', 'priority'],
    canDelete: true,
  ),
  'pools': _ModuleDef(
    title: 'مجموعات العناوين',
    subtitle: 'IP pools كما تظهر في الويب.',
    path: '/api/v1/pools',
    fields: [
      _Field('pool_name', 'اسم المجموعة'),
      _Field('range_ip', 'نطاق العناوين'),
      _Field('local_ip', 'العنوان المحلي'),
    ],
    columns: ['pool_name', 'range_ip', 'local_ip'],
    canDelete: true,
  ),
  'vouchers': _ModuleDef(
    title: 'قسائم الشحن',
    subtitle: 'إنشاء قسائم وشحنها أو إلغاؤها من الخادم.',
    path: '/api/v1/vouchers',
    createLabel: 'توليد قسائم',
    fields: [
      _Field('amount', 'القيمة', number: true),
      _Field('count', 'العدد', number: true, defaultValue: '1'),
      _Field('plan_id', 'رقم الباقة', number: true),
    ],
    columns: ['code', 'amount', 'status', 'created_at'],
    canRevokeVoucher: true,
  ),
  'invoices': _ModuleDef(
    title: 'الفواتير',
    subtitle: 'فواتير تشغيلية بدون حذف نهائي.',
    path: '/api/v1/invoices',
    fields: [
      _Field('subscriber_id', 'رقم المستفيد', number: true),
      _Field('username', 'اسم الدخول'),
      _Field('amount', 'المبلغ', number: true),
      _Field('note', 'ملاحظة'),
    ],
    columns: ['invoice_number', 'username', 'amount', 'status'],
    canMarkPaid: true,
  ),
  'tickets': _ModuleDef(
    title: 'التذاكر',
    subtitle: 'شكاوى ومتابعة المستفيدين.',
    path: '/api/v1/tickets',
    fields: [
      _Field('subscriber_id', 'رقم المستفيد', number: true),
      _Field('subject', 'العنوان'),
      _Field('body', 'الوصف'),
    ],
    columns: ['subject', 'status', 'priority', 'created_at'],
    canReply: true,
  ),
  'services': _ModuleDef(
    title: 'الخدمات والمعدات',
    subtitle: 'أجهزة أو خدمات مرتبطة بالمستفيد.',
    path: '/api/v1/services',
    fields: [
      _Field('subscriber_id', 'رقم المستفيد', number: true),
      _Field('name', 'الاسم'),
      _Field('serial', 'السيريال'),
      _Field('mac', 'MAC'),
      _Field('rent_per_month', 'الإيجار الشهري', number: true),
    ],
    columns: ['name', 'subscriber_id', 'status', 'rent_per_month'],
    canDelete: true,
  ),
  'share-groups': _ModuleDef(
    title: 'مجموعات المشاركة',
    subtitle: 'مشاركة حصة أو سرعة بين أكثر من مستفيد.',
    path: '/api/v1/share-groups',
    fields: [
      _Field('name', 'الاسم'),
      _Field('shared_quota_mb', 'الحصة MB', number: true),
      _Field('shared_speed_down_kbps', 'سرعة التنزيل', number: true),
      _Field('shared_speed_up_kbps', 'سرعة الرفع', number: true),
      _Field('max_members', 'أقصى عدد أعضاء', number: true),
    ],
    columns: ['name', 'members', 'shared_quota_mb', 'enabled'],
    canDelete: true,
  ),
};

final _moduleProvider =
    FutureProvider.autoDispose.family<SaasModuleSnapshot, String>((ref, key) {
  final def = _modules[key]!;
  return ref.watch(saasModulesRepositoryProvider).list(def.path);
});

class SaasModulesScreen extends ConsumerStatefulWidget {
  const SaasModulesScreen({super.key});

  @override
  ConsumerState<SaasModulesScreen> createState() => _SaasModulesScreenState();
}

class _SaasModulesScreenState extends ConsumerState<SaasModulesScreen> {
  String _key = 'bandwidth';

  @override
  Widget build(BuildContext context) {
    final def = _modules[_key]!;
    final async = ref.watch(_moduleProvider(_key));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'الوحدات التجارية',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppTokens.sidebarBg,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
            IconButton(
              tooltip: 'تحديث',
              onPressed: () => ref.invalidate(_moduleProvider(_key)),
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.s12),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _key,
                decoration: const InputDecoration(labelText: 'الوحدة'),
                items: _modules.entries
                    .map(
                      (entry) => DropdownMenuItem(
                        value: entry.key,
                        child: Text(entry.value.title),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _key = value);
                },
              ),
              const SizedBox(height: AppTokens.s8),
              Text(
                def.subtitle,
                style: const TextStyle(color: AppTokens.textMuted),
              ),
              const SizedBox(height: AppTokens.s12),
              FilledButton.icon(
                onPressed: () => _create(def),
                icon: const Icon(Icons.add),
                label: Text(def.createLabel),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTokens.s12),
        async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => EmptyState(
            icon: Icons.error_outline,
            title: 'تعذر تحميل البيانات',
            subtitle: '$e',
          ),
          data: (snapshot) => _RecordsList(
            def: def,
            snapshot: snapshot,
            onChanged: () => ref.invalidate(_moduleProvider(_key)),
          ),
        ),
      ],
    );
  }

  Future<void> _create(_ModuleDef def) async {
    final body = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _CreateDialog(def: def),
    );
    if (body == null) return;
    try {
      await ref.read(saasModulesRepositoryProvider).create(def.path, body);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم الحفظ')),
        );
      }
      ref.invalidate(_moduleProvider(_key));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    }
  }
}

class _RecordsList extends ConsumerWidget {
  const _RecordsList({
    required this.def,
    required this.snapshot,
    required this.onChanged,
  });

  final _ModuleDef def;
  final SaasModuleSnapshot snapshot;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (snapshot.items.isEmpty) {
      return const EmptyState(
        icon: Icons.inventory_2_outlined,
        title: 'لا توجد بيانات بعد',
        subtitle: 'يمكنك إضافة أول عنصر من الزر بالأعلى.',
      );
    }
    return Column(
      children: [
        AppCard(
          child: Row(
            children: [
              const Icon(Icons.dataset_outlined, color: AppTokens.brand),
              const SizedBox(width: AppTokens.s8),
              Text(
                '${snapshot.count} عنصر',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              if (snapshot.stats.isNotEmpty)
                Text(
                  'إحصائيات الخادم متاحة',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ),
        ),
        const SizedBox(height: AppTokens.s8),
        for (final item in snapshot.items) ...[
          _RecordCard(def: def, record: item, onChanged: onChanged),
          const SizedBox(height: AppTokens.s8),
        ],
      ],
    );
  }
}

class _RecordCard extends ConsumerWidget {
  const _RecordCard({
    required this.def,
    required this.record,
    required this.onChanged,
  });

  final _ModuleDef def;
  final SaasRecord record;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _title(record),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppTokens.sidebarBg,
                  ),
                ),
              ),
              Text(
                '#${record.id}',
                style: const TextStyle(color: AppTokens.textMuted),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.s8),
          Wrap(
            spacing: AppTokens.s8,
            runSpacing: AppTokens.s8,
            children: [
              for (final key in def.columns)
                _MiniField(label: _label(key), value: record.text(key)),
            ],
          ),
          const SizedBox(height: AppTokens.s12),
          Wrap(
            spacing: AppTokens.s8,
            runSpacing: AppTokens.s8,
            children: [
              if (def.canRevokeVoucher && record.text('status') != 'revoked')
                OutlinedButton.icon(
                  onPressed: () => _run(
                    context,
                    ref,
                    () => ref
                        .read(saasModulesRepositoryProvider)
                        .revokeVoucher(record.id),
                  ),
                  icon: const Icon(Icons.block),
                  label: const Text('إلغاء القسيمة'),
                ),
              if (def.canMarkPaid && record.text('status') != 'paid')
                OutlinedButton.icon(
                  onPressed: () => _run(
                    context,
                    ref,
                    () => ref
                        .read(saasModulesRepositoryProvider)
                        .updateInvoiceStatus(record.id, 'paid'),
                  ),
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('تعليم كمدفوعة'),
                ),
              if (def.canReply)
                OutlinedButton.icon(
                  onPressed: () => _reply(context, ref),
                  icon: const Icon(Icons.reply),
                  label: const Text('رد'),
                ),
              if (def.canDelete)
                OutlinedButton.icon(
                  onPressed: () => _confirmDelete(context, ref),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('حذف'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _title(SaasRecord record) {
    for (final key
        in ('name,pool_name,code,invoice_number,subject').split(',')) {
      final value = record.values[key];
      if (value != null && value.toString().isNotEmpty) return value.toString();
    }
    return 'عنصر';
  }

  Future<void> _reply(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('إضافة رد'),
        content: TextField(
          controller: controller,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(labelText: 'الرد'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (text == null || text.isEmpty) return;
    if (!context.mounted) return;
    await _run(
      context,
      ref,
      () => ref
          .read(saasModulesRepositoryProvider)
          .addTicketReply(record.id, text),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text(
          'هذا الإجراء يستخدم عقد الخادم الحالي لهذه الوحدة. لا تستخدمه للسجلات المالية.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!context.mounted) return;
    await _run(
      context,
      ref,
      () => ref.read(saasModulesRepositoryProvider).delete(def.path, record.id),
    );
  }

  Future<void> _run(
    BuildContext context,
    WidgetRef ref,
    Future<void> Function() action,
  ) async {
    try {
      await action();
      onChanged();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تنفيذ الإجراء')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }
}

class _CreateDialog extends StatefulWidget {
  const _CreateDialog({required this.def});
  final _ModuleDef def;

  @override
  State<_CreateDialog> createState() => _CreateDialogState();
}

class _CreateDialogState extends State<_CreateDialog> {
  late final Map<String, TextEditingController> _controllers = {
    for (final field in widget.def.fields)
      field.key: TextEditingController(text: field.defaultValue),
  };

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.def.createLabel),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final field in widget.def.fields) ...[
              TextField(
                controller: _controllers[field.key],
                keyboardType:
                    field.number ? TextInputType.number : TextInputType.text,
                decoration: InputDecoration(labelText: field.label),
              ),
              const SizedBox(height: AppTokens.s8),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _body()),
          child: const Text('حفظ'),
        ),
      ],
    );
  }

  Map<String, dynamic> _body() {
    return {
      for (final field in widget.def.fields)
        field.key: field.number
            ? num.tryParse(_controllers[field.key]!.text.trim()) ?? 0
            : _controllers[field.key]!.text.trim(),
    };
  }
}

class _MiniField extends StatelessWidget {
  const _MiniField({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 130),
      padding: const EdgeInsets.all(AppTokens.s8),
      decoration: BoxDecoration(
        color: AppTokens.bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _ModuleDef {
  const _ModuleDef({
    required this.title,
    required this.subtitle,
    required this.path,
    required this.fields,
    required this.columns,
    this.createLabel = 'إضافة',
    this.canDelete = false,
    this.canRevokeVoucher = false,
    this.canMarkPaid = false,
    this.canReply = false,
  });

  final String title;
  final String subtitle;
  final String path;
  final List<_Field> fields;
  final List<String> columns;
  final String createLabel;
  final bool canDelete;
  final bool canRevokeVoucher;
  final bool canMarkPaid;
  final bool canReply;
}

class _Field {
  const _Field(
    this.key,
    this.label, {
    this.number = false,
    this.defaultValue = '',
  });

  final String key;
  final String label;
  final bool number;
  final String defaultValue;
}

String _label(String key) {
  const labels = {
    'name': 'الاسم',
    'pool_name': 'المجموعة',
    'range_ip': 'النطاق',
    'local_ip': 'العنوان المحلي',
    'rate_down': 'تنزيل',
    'rate_up': 'رفع',
    'priority': 'الأولوية',
    'code': 'الكود',
    'amount': 'المبلغ',
    'status': 'الحالة',
    'created_at': 'تاريخ الإنشاء',
    'invoice_number': 'الفاتورة',
    'username': 'اسم الدخول',
    'subject': 'العنوان',
    'rent_per_month': 'الإيجار',
    'subscriber_id': 'المستفيد',
    'shared_quota_mb': 'الحصة',
    'members': 'الأعضاء',
    'enabled': 'مفعلة',
  };
  return labels[key] ?? key;
}
