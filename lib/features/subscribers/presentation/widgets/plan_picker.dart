import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/tokens.dart';
import '../../../plans/data/plans_repository.dart';
import '../../../plans/domain/plan_model.dart';

final plansForPickerProvider = FutureProvider.autoDispose<List<Plan>>((ref) {
  return ref.watch(plansRepositoryProvider).list();
});

/// Plan dropdown backed by /api/v1/profiles. Falls back to a plain
/// numeric text field if the list cannot load — admins keep working
/// offline-friendly instead of being blocked by a transient network
/// error.
class PlanPicker extends ConsumerWidget {
  const PlanPicker({super.key, required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(plansForPickerProvider);
    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: LinearProgressIndicator(minHeight: 4),
      ),
      error: (e, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'معرّف الباقة (يدوي)',
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                size: 14,
                color: AppTokens.amber,
              ),
              const SizedBox(width: 4),
              const Expanded(
                child: Text(
                  'تعذّر جلب قائمة الباقات — أدخل المعرّف يدويًا',
                  style: TextStyle(color: AppTokens.textMuted, fontSize: 12),
                ),
              ),
              TextButton(
                onPressed: () => ref.invalidate(plansForPickerProvider),
                child: const Text('إعادة'),
              ),
            ],
          ),
        ],
      ),
      data: (plans) {
        if (plans.isEmpty) {
          return Row(
            children: [
              const Expanded(
                child: Text(
                  'لا توجد باقات بعد. أنشئ باقة من قسم الباقات.',
                  style: TextStyle(color: AppTokens.textMuted),
                ),
              ),
              TextButton.icon(
                onPressed: () => GoRouter.of(context).goNamed('plan-new'),
                icon: const Icon(Icons.add),
                label: const Text('إضافة'),
              ),
            ],
          );
        }
        final current = int.tryParse(controller.text.trim());
        final exists = plans.any((p) => p.id == current);
        return DropdownButtonFormField<int?>(
          initialValue: exists ? current : null,
          isExpanded: true,
          items: [
            const DropdownMenuItem<int?>(
              value: null,
              child: Text('— بدون باقة —'),
            ),
            ...plans.map(
              (p) => DropdownMenuItem<int?>(
                value: p.id,
                child: Text(
                  '${p.name}${p.code.isNotEmpty ? "  •  ${p.code}" : ""}',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
          onChanged: (v) {
            controller.text = v?.toString() ?? '';
          },
        );
      },
    );
  }
}
