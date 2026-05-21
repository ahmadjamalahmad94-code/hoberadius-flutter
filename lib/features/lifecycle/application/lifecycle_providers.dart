import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/lifecycle_repository.dart';
import '../domain/lifecycle_model.dart';

final lifecyclePoliciesProvider =
    FutureProvider.autoDispose<List<LifecyclePolicy>>((ref) {
  return ref.watch(lifecycleRepositoryProvider).listPolicies();
});

final lifecyclePreviewProvider =
    FutureProvider.autoDispose<LifecyclePreview>((ref) {
  return ref.watch(lifecycleRepositoryProvider).preview();
});

String lifecycleEntityLabel(String value) => switch (value) {
      'card' => 'الكروت المنتهية',
      'subscriber' => 'المشتركون المنتهون',
      'card_batch' => 'حزم البطاقات',
      'external_file' => 'ملف خارجي',
      _ => value,
    };

String lifecycleUnitLabel(String value) => switch (value) {
      'minutes' => 'دقائق',
      'hours' => 'ساعات',
      'days' => 'أيام',
      'months' => 'أشهر',
      _ => value,
    };
