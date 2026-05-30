import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/card_users_repository.dart';
import '../domain/card_users_model.dart';

final cardUsersPageProvider = FutureProvider.autoDispose<CardUsersPage>((ref) {
  return ref.watch(cardUsersRepositoryProvider).listUsers();
});

final cardMarketplacePackagesProvider =
    FutureProvider.autoDispose<List<MarketplacePackage>>((ref) {
  return ref.watch(cardUsersRepositoryProvider).listPackages();
});

final cardUser360Provider =
    FutureProvider.autoDispose.family<CardUser360, int>((ref, cardUserId) {
  return ref.watch(cardUsersRepositoryProvider).get360(cardUserId);
});
