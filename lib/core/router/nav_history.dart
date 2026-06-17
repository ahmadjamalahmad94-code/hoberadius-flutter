import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Lightweight in-app location history for the shell.
///
/// The app navigates with go_router's `go`/`goNamed` (declarative), which
/// REPLACES the location instead of pushing — so the Android system back
/// button has nothing to pop and would exit the app mid-flow. The shell
/// records each visited location here and, on back, walks to the previous
/// one (see `ShellScaffold`'s `PopScope`).
class NavHistory extends ChangeNotifier {
  final List<String> _stack = <String>[];

  static const int _cap = 50;

  List<String> get stack => List.unmodifiable(_stack);

  /// True when there is a previous location to return to.
  bool get canGoBack => _stack.length > 1;

  String? get current => _stack.isEmpty ? null : _stack.last;

  /// Record a freshly-visited location.
  ///
  /// - Same as current → no-op (avoids duplicates on rebuilds).
  /// - Already earlier in the stack → trim everything after it (the user
  ///   navigated back to it, or re-tapped a parent tab), so we don't grow
  ///   an endless forward trail.
  /// - Otherwise → append (capped).
  void record(String location) {
    if (_stack.isNotEmpty && _stack.last == location) return;
    final existing = _stack.lastIndexOf(location);
    if (existing != -1) {
      _stack.removeRange(existing + 1, _stack.length);
    } else {
      _stack.add(location);
      if (_stack.length > _cap) _stack.removeAt(0);
    }
  }

  /// Pop the current location and return the previous one, or null when
  /// there is nothing left to go back to.
  String? back() {
    if (_stack.length < 2) return null;
    _stack.removeLast();
    return _stack.last;
  }
}

final navHistoryProvider =
    ChangeNotifierProvider<NavHistory>((ref) => NavHistory());
