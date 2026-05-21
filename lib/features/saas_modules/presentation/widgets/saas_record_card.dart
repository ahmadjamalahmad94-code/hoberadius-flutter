import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../application/saas_modules_catalog.dart';
import '../../data/saas_modules_repository.dart';
import '../../domain/saas_module_model.dart';

class SaasRecordCard extends ConsumerWidget {
  const SaasRecordCard({
    super.key,
    required this.def,
    required this.record,
    required this.onChanged,
  });

  final SaasModuleDef def;
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
                _MiniField(label: saasFieldLabel(key), value: record.text(key)),
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
      if (value != null && value.toString().isNotEmpty) {
        return value.toString();
      }
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
      () => ref
          .read(saasModulesRepositoryProvider)
          .delete(def.path, record.id),
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
