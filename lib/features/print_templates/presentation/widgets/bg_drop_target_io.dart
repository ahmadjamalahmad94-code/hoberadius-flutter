/// Desktop drag-drop target using `desktop_drop`.
///
/// Only imported when `dart:io` is available. The mobile entry point
/// resolves the stub file instead — `desktop_drop` is never loaded
/// at runtime on Android / iOS.
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:desktop_drop/desktop_drop.dart';
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
  Widget build(BuildContext context) {
    return DropTarget(
      onDragEntered: (_) => onDragEntered(),
      onDragExited: (_) => onDragExited(),
      onDragDone: (detail) async {
        for (final file in detail.files) {
          final bytes = await File(file.path).readAsBytes();
          onDropped(bytes, file.name, file.mimeType);
          break;
        }
      },
      child: child,
    );
  }
}
