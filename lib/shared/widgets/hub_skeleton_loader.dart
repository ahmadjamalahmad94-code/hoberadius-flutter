import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import '../../core/theme/tokens.dart';

/// Animated shimmer skeleton for "list / detail awaits data" states.
///
/// Adopts in place of `CircularProgressIndicator` when the operator
/// is waiting for content with a knowable shape — e.g. list of cards,
/// list of rows, KPI grid. The shimmer travels start→end every
/// [period] using only token colours so it themes correctly in
/// light + dark.
class HubSkeletonLoader extends StatefulWidget {
  const HubSkeletonLoader({
    super.key,
    this.height = 16,
    this.width,
    this.radius = 8,
  });

  /// Convenience builder: a small stack of skeleton rows shaped like
  /// a list of `count` rows with a leading avatar + two text lines.
  static Widget list({int count = 6, double rowHeight = 64}) {
    return _SkeletonList(count: count, rowHeight: rowHeight);
  }

  /// Grid of skeleton tiles — useful for KPI / summary panels.
  static Widget tiles({int count = 4, double aspectRatio = 2.2}) {
    return _SkeletonTiles(count: count, aspectRatio: aspectRatio);
  }

  final double height;
  final double? width;
  final double radius;

  @override
  State<HubSkeletonLoader> createState() => _HubSkeletonLoaderState();
}

class _HubSkeletonLoaderState extends State<HubSkeletonLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final t = _ctrl.value; // 0..1
        return Container(
          height: widget.height,
          width: widget.width ?? double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(-1 + 2 * t, 0),
              end: Alignment(0 + 2 * t, 0),
              colors: [
                p.surfaceMuted,
                p.surfaceTinted,
                p.surfaceMuted,
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SkeletonList extends StatelessWidget {
  const _SkeletonList({required this.count, required this.rowHeight});
  final int count;
  final double rowHeight;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: List.generate(count, (i) {
        return Padding(
          padding: EdgeInsets.only(bottom: i == count - 1 ? 0 : AppTokens.s8),
          child: const Row(
            children: [
              HubSkeletonLoader(width: 40, height: 40, radius: 20),
              SizedBox(width: AppTokens.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    HubSkeletonLoader(height: 12, radius: 6),
                    SizedBox(height: 6),
                    HubSkeletonLoader(width: 200, height: 10, radius: 5),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _SkeletonTiles extends StatelessWidget {
  const _SkeletonTiles({required this.count, required this.aspectRatio});
  final int count;
  final double aspectRatio;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final cols = c.maxWidth >= 960 ? 4 : (c.maxWidth >= 600 ? 3 : 2);
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: cols,
          mainAxisSpacing: AppTokens.s12,
          crossAxisSpacing: AppTokens.s12,
          childAspectRatio: aspectRatio,
          children: List.generate(
            count,
            (_) => const HubSkeletonLoader(
              radius: AppTokens.r14,
              height: 0,
            ),
          ),
        );
      },
    );
  }
}
