import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Saves an exported file where the operator can actually find it.
///
/// `FileSaver.saveFile` on Android writes into the app's private folder —
/// the owner pressed CSV/Excel/PDF, read «تم التحميل», and found nothing
/// (2026-10-02). On a phone/desktop we open the system «save as» picker
/// (the same path the print flow already uses); on the web it is a normal
/// browser download.
///
/// Returns `false` when the operator closed the picker without saving, so
/// callers never show «تم» for a file that was not written.
Future<bool> saveUserFile({
  required String name,
  required Uint8List bytes,
  required String ext,
  required MimeType mimeType,
}) async {
  if (kIsWeb) {
    await FileSaver.instance.saveFile(
      name: name,
      bytes: bytes,
      ext: ext,
      mimeType: mimeType,
    );
    return true;
  }
  final path = await FileSaver.instance.saveAs(
    name: name,
    bytes: bytes,
    ext: ext,
    mimeType: mimeType,
  );
  return path != null && path.isNotEmpty;
}
