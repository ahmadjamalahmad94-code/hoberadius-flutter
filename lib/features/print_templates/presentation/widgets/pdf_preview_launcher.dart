/// Windows-only PDF preview launcher.
///
/// On Windows: opens the `printing` package's [PdfPreview] inside a
/// modal dialog so the user can preview, save and system-print the
/// exported PDF without leaving the app.
///
/// On mobile / web: falls back to the existing `file_saver`
/// download flow — `printing` is not even imported on those
/// platforms (deferred import guarded by [PlatformCapabilities]).
///
/// Single entry-point so callers don't have to write the platform
/// check at every PDF action site.
library;

import 'dart:typed_data';

import 'package:file_saver/file_saver.dart' as fs;
import 'package:flutter/material.dart';

import '../../../../core/platform/platform_capabilities.dart';

// `printing` is heavy + has native Windows bindings. We import the
// preview widget conditionally so the mobile build doesn't pay for
// it. The conditional dance below mirrors the pattern used by
// other Flutter desktop-only packages.
import 'pdf_preview_window_stub.dart'
    if (dart.library.io) 'pdf_preview_window_io.dart' as preview;

class PdfPreviewLauncher {
  PdfPreviewLauncher._();

  /// Show the PDF — chooses the right path automatically.
  ///
  /// [pdfBytes] is the raw response of `/api/v1/print-templates/<id>/export.pdf`.
  /// [fileName] is what we save to disk when the user clicks "Save"
  /// inside the preview window OR what file_saver writes on mobile.
  static Future<void> show(
    BuildContext context, {
    required Uint8List pdfBytes,
    required String fileName,
  }) async {
    if (PlatformCapabilities.supportsEmbeddedPdfPreview) {
      await preview.openPdfPreview(
        context: context,
        pdfBytes: pdfBytes,
        fileName: fileName,
      );
      return;
    }
    // Mobile / web fallback — write to file system.
    final base = fileName.endsWith('.pdf')
        ? fileName.substring(0, fileName.length - 4)
        : fileName;
    await fs.FileSaver.instance.saveFile(
      name: base,
      bytes: pdfBytes,
      ext: 'pdf',
      mimeType: fs.MimeType.pdf,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تم حفظ $fileName')),
    );
  }
}
