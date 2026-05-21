/// Windows / desktop implementation of the PDF preview window.
///
/// Only imported when `dart:io` is available AND the calling site has
/// already gated the call on `PlatformCapabilities.supportsEmbeddedPdfPreview`.
library;

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

Future<void> openPdfPreview({
  required BuildContext context,
  required Uint8List pdfBytes,
  required String fileName,
}) async {
  final scheme = Theme.of(context).colorScheme;
  await showDialog<void>(
    context: context,
    builder: (ctx) => Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: SizedBox(
        width: 920,
        height: 720,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
              child: Row(
                children: [
                  Icon(Icons.picture_as_pdf_outlined, color: scheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      fileName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    icon: const Icon(Icons.close),
                    tooltip: 'إغلاق',
                  ),
                ],
              ),
            ),
            Expanded(
              child: PdfPreview(
                build: (_) async => pdfBytes,
                allowPrinting: true,
                allowSharing: true,
                canChangePageFormat: false,
                canChangeOrientation: false,
                canDebug: false,
                pdfFileName: fileName,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
