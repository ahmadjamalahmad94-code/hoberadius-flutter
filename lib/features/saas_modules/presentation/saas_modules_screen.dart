import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoberadius_app/core/api/visible_error_message.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../application/saas_modules_catalog.dart';
import '../data/saas_modules_repository.dart';
import '../domain/saas_module_model.dart';
import 'widgets/saas_create_dialog.dart';
import 'widgets/saas_record_card.dart';

class SaasModulesScreen extends ConsumerStatefulWidget {
  const SaasModulesScreen({super.key});

  @override
  ConsumerState<SaasModulesScreen> createState() => _SaasModulesScreenState();
}

class _SaasModulesScreenState extends ConsumerState<SaasModulesScreen> {
  String _key = 'bandwidth';

  @override
  Widget build(BuildContext context) {
    final def = kSaasModules[_key]!;
    final async = ref.watch(saasModuleProvider(_key));

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
              onPressed: () => ref.invalidate(saasModuleProvider(_key)),
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
                isExpanded: true,
                initialValue: _key,
                decoration: const InputDecoration(labelText: 'الوحدة'),
                items: kSaasModules.entries
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
            subtitle: visibleErrorMessage(e),
          ),
          data: (snapshot) => _RecordsList(
            def: def,
            snapshot: snapshot,
            onChanged: () => ref.invalidate(saasModuleProvider(_key)),
          ),
        ),
      ],
    );
  }

  Future<void> _create(SaasModuleDef def) async {
    final body = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => SaasCreateDialog(def: def),
    );
    if (body == null) return;
    try {
      await ref.read(saasModulesRepositoryProvider).create(def.path, body);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم الحفظ')),
        );
      }
      ref.invalidate(saasModuleProvider(_key));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(visibleErrorMessage(e))),
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

  final SaasModuleDef def;
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
          SaasRecordCard(def: def, record: item, onChanged: onChanged),
          const SizedBox(height: AppTokens.s8),
        ],
      ],
    );
  }
}
