import '../../../../core/format/bidi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/visible_error_message.dart';
import '../../../../core/auth/permissions.dart';
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
    // The plan list (/api/v1/profiles) needs «عرض الباقات»; the server has
    // no lighter list for a manager who may only create subscribers (f01).
    // Say so plainly instead of a failed load and a retry that fails again.
    final canList = ref.watch(
      permissionsProvider.select((p) => p.can('plans.view')),
    );
    if (!canList) return _NoPlanList(controller: controller);
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
              Expanded(
                child: Text(
                  'تعذّر جلب قائمة الباقات — أدخل المعرّف يدويًا. '
                  '${visibleErrorMessage(e)}',
                  style:
                      const TextStyle(color: AppTokens.textMuted, fontSize: 12),
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
          return const Text(
            'لا توجد باقات بعد. أضف باقة من لوحة الويب.',
            style: TextStyle(color: AppTokens.textMuted),
          );
        }
        final current = int.tryParse(controller.text.trim());
        // Disabled plans are not offered — except the one already set.
        plans = plans.where((p) => p.enabled || p.id == current).toList();
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
                  '${autoIsolate(p.name)}'
                  '${p.code.isNotEmpty ? "  •  ${ltrIsolate(p.code)}" : ""}'
                  '${p.enabled ? '' : ' (معطّلة)'}',
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

/// Message shown by [PlanPicker] to a manager without «عرض الباقات».
const String kNoPlanListMessage =
    'لا تملك صلاحية «عرض الباقات»، لذلك لا تظهر قائمة الباقات هنا. '
    'اكتب رقم الباقة إن كنت تعرفه، أو احفظ المشترك بدون باقة ثم اطلب من '
    'المالك منحك «عرض الباقات».';

class _NoPlanList extends StatelessWidget {
  const _NoPlanList({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'رقم الباقة (اختياري)',
          ),
        ),
        const SizedBox(height: 4),
        const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, size: 14, color: AppTokens.textMuted),
            SizedBox(width: 4),
            Expanded(
              child: Text(
                kNoPlanListMessage,
                style: TextStyle(color: AppTokens.textMuted, fontSize: 12),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
