import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/setup_wizard_repository.dart';
import '../domain/setup_wizard_model.dart';

final setupWizardOverviewProvider =
    FutureProvider.autoDispose<SetupWizardOverview>((ref) {
  return ref.watch(setupWizardRepositoryProvider).overview();
});

final setupWizardPhasePlannersProvider =
    FutureProvider.autoDispose<List<SetupWizardPhasePlanner>>((ref) {
  return ref.watch(setupWizardRepositoryProvider).phasePlanners();
});

final setupWizardRouterServiceCatalogueProvider =
    FutureProvider.autoDispose<List<SetupWizardRouterServiceCard>>((ref) {
  return ref.watch(setupWizardRepositoryProvider).routerServiceCatalogue();
});

final setupWizardRouterServicesStatusProvider = FutureProvider.autoDispose
    .family<SetupWizardRouterServicesStatus, int>((ref, routerId) {
  return ref
      .watch(setupWizardRepositoryProvider)
      .routerServicesStatus(routerId);
});
