import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/tokens.dart';

/// Custom go_router page builder that wraps every transition in a
/// soft fade + small forward slide (subtle SharedAxisTransition-like
/// effect) without pulling in the `animations` package.
///
/// Use as the `pageBuilder:` for any GoRoute that wants a polished
/// route transition.
CustomTransitionPage<T> hubFadeThroughPage<T>({
  required Widget child,
  Object? arguments,
  String? name,
}) {
  return CustomTransitionPage<T>(
    child: child,
    arguments: arguments,
    name: name,
    transitionDuration: AppTokens.motionMedium,
    reverseTransitionDuration: AppTokens.motionFast,
    transitionsBuilder: (context, animation, secondary, child) {
      final fade = CurvedAnimation(
        parent: animation,
        curve: AppTokens.motionEaseInOut,
      );
      final slide = Tween<Offset>(
        begin: const Offset(0, 0.04),
        end: Offset.zero,
      ).animate(fade);
      return FadeTransition(
        opacity: fade,
        child: SlideTransition(position: slide, child: child),
      );
    },
  );
}
