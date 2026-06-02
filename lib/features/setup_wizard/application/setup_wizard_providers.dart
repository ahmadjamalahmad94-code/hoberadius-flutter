import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/setup_wizard_repository.dart';
import '../domain/setup_wizard_model.dart';

final setupWizardOverviewProvider =
    FutureProvider.autoDispose<SetupWizardOverview>((ref) {
  return ref.watch(setupWizardRepositoryProvider).overview();
});
