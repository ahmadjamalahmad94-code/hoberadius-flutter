import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/network_devices_repository.dart';
import '../domain/network_device_model.dart';

final networkDevicesProvider =
    FutureProvider.autoDispose<NetworkDevicesState>((ref) {
  return ref.watch(networkDevicesRepositoryProvider).list();
});
