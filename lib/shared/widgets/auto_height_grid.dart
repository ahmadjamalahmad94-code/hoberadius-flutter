import 'package:flutter/material.dart';

/// A grid whose rows are as tall as their tallest tile (no fixed aspect
/// ratio). `GridView.count(childAspectRatio: …)` gave KPI tiles a height from
/// their WIDTH, so on a 360 px phone the label + value overflowed the tile at
/// the bottom (33/51 px on «الكروت» and «المتصلون»). Tiles here size to their
/// content and each row stretches its tiles to the same height.
///
/// Children must support intrinsic sizing (no LayoutBuilder inside a tile).
class AutoHeightGrid extends StatelessWidget {
  const AutoHeightGrid({
    super.key,
    required this.columns,
    required this.children,
    this.spacing = 12,
    this.runSpacing,
  });

  final int columns;
  final double spacing;
  final double? runSpacing;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final cols = columns < 1 ? 1 : columns;
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += cols) {
      final cells = <Widget>[];
      for (var j = 0; j < cols; j++) {
        if (j > 0) cells.add(SizedBox(width: spacing));
        final index = i + j;
        cells.add(
          Expanded(
            child: index < children.length
                ? children[index]
                : const SizedBox.shrink(),
          ),
        );
      }
      if (rows.isNotEmpty) rows.add(SizedBox(height: runSpacing ?? spacing));
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: cells,
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: rows,
    );
  }
}
