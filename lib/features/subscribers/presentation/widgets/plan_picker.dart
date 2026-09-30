import '../../../../core/format/bidi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_exception.dart';
import '../../../../core/api/visible_error_message.dart';
import '../../../../core/theme/tokens.dart';
import '../../../plans/data/plans_repository.dart';
import '../../../plans/domain/plan_option.dart';

/// fix3: plan choices for the NEW-SUBSCRIBER create form — the lite
/// `/api/v1/plans/options` endpoint (readable with `users.create`, not
/// just `plans.view`), with an old-server fallback to `/api/v1/profiles`.
///
/// This is deliberately a separate provider from the change-plan dialog's
/// plan list (`subscriber_action_dialogs.dart`), which needs the full
/// `Plan` (`rate_per_minute`, `enabled`, …) and stays on `plans.view`.
final createSubscriberPlanOptionsProvider =
    FutureProvider.autoDispose<List<PlanOption>>((ref) {
  return ref.watch(plansRepositoryProvider).listForPicker();
});

/// Plan dropdown backed by `/api/v1/plans/options` (fix3) — falls back to
/// `/api/v1/profiles` on an older server, and to a plain numeric text field
/// when no plan list at all is allowed for this admin, or the list
/// otherwise fails to load.
class PlanPicker extends ConsumerWidget {
  const PlanPicker({super.key, required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(createSubscriberPlanOptionsProvider);
    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: LinearProgressIndicator(minHeight: 4),
      ),
      error: (e, _) {
        // Neither the lite nor the full list is allowed for this admin:
        // say so plainly instead of a failed load and a retry that fails
        // again.
        if (e is ApiException && (e.status == 403 || e.code == 'forbidden')) {
          return _NoPlanList(controller: controller);
        }
        return _LoadFailed(
          controller: controller,
          error: e,
          onRetry: () => ref.invalidate(createSubscriberPlanOptionsProvider),
        );
      },
      data: (plans) => _PlanDropdown(controller: controller, plans: plans),
    );
  }
}

class _LoadFailed extends StatelessWidget {
  const _LoadFailed({
    required this.controller,
    required this.error,
    required this.onRetry,
  });
  final TextEditingController controller;
  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
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
                '${visibleErrorMessage(error)}',
                style:
                    const TextStyle(color: AppTokens.textMuted, fontSize: 12),
              ),
            ),
            TextButton(
              onPressed: onRetry,
              child: const Text('إعادة'),
            ),
          ],
        ),
      ],
    );
  }
}

class _PlanDropdown extends StatelessWidget {
  const _PlanDropdown({required this.controller, required this.plans});
  final TextEditingController controller;
  final List<PlanOption> plans;

  @override
  Widget build(BuildContext context) {
    if (plans.isEmpty) {
      return const Text(
        'لا توجد باقات بعد. أضف باقة من لوحة الويب.',
        style: TextStyle(color: AppTokens.textMuted),
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
              autoIsolate(p.name),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
      onChanged: (v) {
        controller.text = v?.toString() ?? '';
      },
    );
  }
}

/// Message shown by [PlanPicker] to a manager with no plan-reading
/// permission at all (neither `plans.view` nor `users.create`/
/// `cards.generate`, which the fix3 lite endpoint also accepts).
const String kNoPlanListMessage =
    'لا تملك صلاحية عرض الباقات، لذلك لا تظهر قائمة الباقات هنا. '
    'اكتب رقم الباقة إن كنت تعرفه، أو احفظ المشترك بدون باقة ثم اطلب من '
    'المالك منحك الصلاحية.';

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
