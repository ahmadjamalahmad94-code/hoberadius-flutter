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

/// Marks the shell's content area: every page there is laid out inside ONE
/// vertical scroll view (the shell's), so pages are Columns sized by their
/// content.
class ShellContentScope extends InheritedWidget {
  const ShellContentScope({super.key, required super.child});

  static bool isInside(BuildContext context) =>
      context.getInheritedWidgetOfExactType<ShellContentScope>() != null;

  @override
  bool updateShouldNotify(ShellContentScope oldWidget) => false;
}

/// Lets a shell page keep its natural height while the inner navigator's
/// overlay forces a bounded one. During a route transition the overlay is
/// sized by the NEW page, so the old (taller) page was laid out with the new
/// page's height and every navigation logged «A RenderFlex overflowed by
/// 900–13,000 pixels on the bottom» (from the Column ← _ZoomExitTransition).
class ShellPageBox extends StatelessWidget {
  const ShellPageBox({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!ShellContentScope.isInside(context)) return child;
    return LayoutBuilder(
      builder: (context, constraints) {
        if (!constraints.hasBoundedHeight) return child;
        return OverflowBox(
          alignment: Alignment.topCenter,
          minHeight: 0,
          maxHeight: double.infinity,
          child: child,
        );
      },
    );
  }
}

/// Wraps a platform's page transition so shell pages go through
/// [ShellPageBox] (no-op for full-screen routes such as the login).
class ShellSafePageTransitionsBuilder extends PageTransitionsBuilder {
  const ShellSafePageTransitionsBuilder(this.inner);

  final PageTransitionsBuilder inner;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) =>
      inner.buildTransitions<T>(
        route,
        context,
        animation,
        secondaryAnimation,
        ShellPageBox(child: child),
      );
}

/// The app's page transitions: the platform defaults, made shell-safe.
PageTransitionsTheme shellSafePageTransitionsTheme(PageTransitionsTheme base) {
  const fallback = ZoomPageTransitionsBuilder();
  return PageTransitionsTheme(
    builders: {
      for (final platform in TargetPlatform.values)
        platform: ShellSafePageTransitionsBuilder(
          base.builders[platform] ?? fallback,
        ),
    },
  );
}
