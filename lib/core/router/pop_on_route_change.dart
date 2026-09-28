import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// For a screen pushed imperatively on top of the router (e.g. the PDF
/// viewer): when the router's location changes underneath it — the browser
/// back button on the web build — the screen closes itself. Before, the URL
/// became «#/» while the PDF stayed on screen.
class PopOnRouteChange extends StatefulWidget {
  const PopOnRouteChange({super.key, required this.child});

  final Widget child;

  @override
  State<PopOnRouteChange> createState() => _PopOnRouteChangeState();
}

class _PopOnRouteChangeState extends State<PopOnRouteChange> {
  GoRouter? _router;
  String? _openedAt;
  bool _popped = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final router = GoRouter.maybeOf(context);
    if (!identical(router, _router)) {
      _router?.routerDelegate.removeListener(_onRouteChanged);
      _router = router;
      _openedAt = _location();
      _router?.routerDelegate.addListener(_onRouteChanged);
    }
  }

  String? _location() =>
      _router?.routerDelegate.currentConfiguration.uri.toString();

  void _onRouteChanged() {
    if (_popped || !mounted) return;
    final now = _location();
    if (now == null || now == _openedAt) return;
    _popped = true;
    final nav = Navigator.maybeOf(context);
    if (nav != null && nav.canPop()) nav.pop();
  }

  @override
  void dispose() {
    _router?.routerDelegate.removeListener(_onRouteChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
