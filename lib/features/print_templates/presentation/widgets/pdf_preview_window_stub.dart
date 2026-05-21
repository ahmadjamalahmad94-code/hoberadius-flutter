/// Stub used on web — `printing` isn't supported there at the time of
/// writing this file. The PdfPreviewLauncher always takes the
/// file_saver path on web, but the conditional import needs SOME
/// target for `dart.library.html`/`dart.library.js` builds.
library;

import 'dart:typed_data';

import 'package:flutter/widgets.dart';

Future<void> openPdfPreview({
  required BuildContext context,
  required Uint8List pdfBytes,
  required String fileName,
}) async {
  // Intentionally a no-op — the caller already checked
  // `PlatformCapabilities.supportsEmbeddedPdfPreview` first.
}
