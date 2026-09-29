import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/visible_error_message.dart';
import '../../../../core/format/bidi.dart';
import '../../../../core/format/currency.dart';
import '../../../../core/theme/tokens.dart';
import '../../../plans/data/plans_repository.dart';
import '../../../plans/domain/plan_model.dart';

/// Plans a card batch can be generated from: enabled, not archived/deleted.
final cardPlansProvider = FutureProvider.autoDispose<List<Plan>>((ref) async {
  final plans = await ref.watch(plansRepositoryProvider).list();
  return plans.where(isPlanPickableForCards).toList();
});

/// Disabled, archived or deleted plans are not offered for new cards.
bool isPlanPickableForCards(Plan p) {
  if (p.id == null || !p.enabled) return false;
  final m = p.metadata;
  bool truthy(Object? v) =>
      v == true || v == 1 || '$v' == '1' || '$v'.toLowerCase() == 'true';
  if (truthy(m['archived']) || truthy(m['is_archived'])) return false;
  final deleted = '${m['deleted_at'] ?? ''}'.trim();
  return deleted.isEmpty || deleted == 'null';
}

/// The price of ONE card of [p]: its card price, else its price.
num planCardPrice(Plan p) => p.priceCard > 0 ? p.priceCard : p.price;

/// «صلاحية 30 يوم» / «ساعتان»… — '' when the plan has no duration.
String planDurationLabel(Plan p) {
  if (p.validityDays > 0) return 'صلاحية ${p.validityDays} يوم';
  final m = p.durationMinutes;
  if (m <= 0) return '';
  if (m % 1440 == 0) return '${m ~/ 1440} يوم';
  if (m % 60 == 0) return '${m ~/ 60} ساعة';
  return '$m دقيقة';
}

/// «5 ILS · صلاحية 30 يوم» under the plan name.
String planPickerSubtitle(Plan p, {String fallbackCurrency = ''}) {
  final cur =
      p.currency.trim().isNotEmpty ? p.currency.trim() : fallbackCurrency;
  return [
    formatWithCurrency(planCardPrice(p), cur),
    planDurationLabel(p),
  ].where((s) => s.isNotEmpty).join(' · ');
}

/// REQUIRED plan picker of the batch generator (was a raw «معرّف الباقة»
/// number field). A list that fails to load says so with «إعادة المحاولة».
class CardPlanPicker extends ConsumerWidget {
  const CardPlanPicker({
    super.key,
    required this.selectedId,
    required this.onChanged,
    this.serverError,
    this.currency = '',
  });

  final int? selectedId;
  final ValueChanged<Plan> onChanged;

  /// The server's Arabic message about the plan (e.g. «الباقة رقم … غير
  /// موجودة»), shown under the field.
  final String? serverError;
  final String currency;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(cardPlansProvider);
    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: LinearProgressIndicator(minHeight: 4),
      ),
      error: (e, _) => Container(
        padding: const EdgeInsets.all(AppTokens.s12),
        decoration: BoxDecoration(
          color: AppTokens.redSoft,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: AppTokens.redInk, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'تعذّر تحميل الباقات: '
                '${visibleErrorMessage(e, fallback: 'تحقّق من الاتصال.')}',
                style: const TextStyle(color: AppTokens.redInk),
              ),
            ),
            TextButton(
              onPressed: () => ref.invalidate(cardPlansProvider),
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
      data: (plans) {
        if (plans.isEmpty) {
          return const Text(
            'لا توجد باقات مفعّلة. أضف باقة أو فعّلها أولًا.',
            style: TextStyle(color: AppTokens.redInk),
          );
        }
        final exists = plans.any((p) => p.id == selectedId);
        return DropdownButtonFormField<int>(
          initialValue: exists ? selectedId : null,
          isExpanded: true,
          itemHeight: null,
          hint: const Text('اختر الباقة'),
          decoration: InputDecoration(errorText: serverError),
          validator: (v) => v == null ? 'اختر الباقة' : null,
          selectedItemBuilder: (_) => [
            for (final p in plans)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  autoIsolate(p.name),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          items: [
            for (final p in plans)
              DropdownMenuItem<int>(
                value: p.id,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        autoIsolate(p.name),
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        planPickerSubtitle(p, fallbackCurrency: currency),
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppTokens.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
          onChanged: (id) {
            for (final p in plans) {
              if (p.id == id) onChanged(p);
            }
          },
        );
      },
    );
  }
}
