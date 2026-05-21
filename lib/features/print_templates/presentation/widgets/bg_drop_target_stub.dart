/// Web stub for the bg-image drop zone — drag-drop on the web is
/// already handled by the browser's standard `<input type=file>`,
/// so this stub is a transparent pass-through.
library;

import 'dart:typed_data';

import 'package:flutter/widgets.dart';

class DropZone extends StatelessWidget {
  const DropZone({
    super.key,
    required this.child,
    required this.onDragEntered,
    required this.onDragExited,
    required this.onDropped,
  });

  final Widget child;
  final VoidCallback onDragEntered;
  final VoidCallback onDragExited;
  final void Function(Uint8List bytes, String fileName, String? mime)
      onDropped;

  @override
  Widget build(BuildContext context) => child;
}
