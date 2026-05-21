import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persisted theme-mode controller for HobeRadius.
///
/// Default is `ThemeMode.system` so the app respects the OS preference
/// out of the box; the operator can switch to forced light or forced
/// dark via the Settings / «More» screen — that toggle simply calls
/// `ref.read(themeModeControllerProvider.notifier).set(mode)`.
///
/// Storage key is intentionally tiny — we only persist a single 0/1/2
/// enum ordinal.
class ThemeModeController extends AsyncNotifier<ThemeMode> {
  static const _prefsKey = 'hub.themeMode';

  @override
  Future<ThemeMode> build() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getInt(_prefsKey);
    return _fromOrdinal(raw);
  }

  Future<void> set(ThemeMode mode) async {
    state = AsyncData(mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefsKey, mode.index);
  }

  ThemeMode _fromOrdinal(int? raw) {
    if (raw == null) return ThemeMode.system;
    if (raw < 0 || raw >= ThemeMode.values.length) return ThemeMode.system;
    return ThemeMode.values[raw];
  }
}

final themeModeControllerProvider =
    AsyncNotifierProvider<ThemeModeController, ThemeMode>(ThemeModeController.new);

/// Convenience read-only provider — exposes the resolved value
/// (or `ThemeMode.system` until storage is loaded).
final themeModeProvider = Provider<ThemeMode>((ref) {
  final async = ref.watch(themeModeControllerProvider);
  return async.maybeWhen(
    data: (m) => m,
    orElse: () => ThemeMode.system,
  );
});
