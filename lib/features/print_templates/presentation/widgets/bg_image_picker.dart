/// Strict background-image picker for the print-templates designer.
///
/// Mirror of the web admin's `[data-bg-picker]` component shipped in
/// the P4 commit. Same MIME whitelist, same 1.5 MB cap, same Arabic
/// error copy, same drag-drop on desktop, same clear-button reset.
///
/// On Windows, drag-and-drop is wired via `desktop_drop`. On every
/// other platform (mobile, web) the trigger button still works
/// (regular file picker) — the drag-drop import is conditional so
/// the mobile build never touches it.
library;

import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../../core/platform/platform_capabilities.dart';
import 'bg_drop_target_stub.dart'
    if (dart.library.io) 'bg_drop_target_io.dart' as drop;

class BgImagePicker extends StatefulWidget {
  const BgImagePicker({
    super.key,
    required this.onImageBytes,
    required this.onClear,
    this.initialFileName,
  });

  /// Called with the accepted bytes + the mime + the file name.
  final void Function(Uint8List bytes, String mime, String fileName)
      onImageBytes;

  /// Called when the user clears the file.
  final VoidCallback onClear;

  /// Optional pre-existing filename (e.g. when editing a saved template
  /// that already has a background image).
  final String? initialFileName;

  @override
  State<BgImagePicker> createState() => _BgImagePickerState();
}

class _BgImagePickerState extends State<BgImagePicker> {
  static const _maxBytes = 1500000; // 1.5 MB — matches server cap
  static const _allowedExts = {'png', 'jpg', 'jpeg', 'webp'};
  static const _allowedMimes = {
    'image/png',
    'image/jpeg',
    'image/jpg',
    'image/webp',
  };

  Uint8List? _bytes;
  String? _fileName;
  String? _mime;
  String? _error;
  bool _dragging = false;

  @override
  void initState() {
    super.initState();
    _fileName = widget.initialFileName;
  }

  void _setError(String? msg) => setState(() => _error = msg);

  String _formatSize(int b) {
    if (b < 1024) return '$b B';
    if (b < 1048576) return '${(b / 1024).toStringAsFixed(1)} KB';
    return '${(b / 1048576).toStringAsFixed(2)} MB';
  }

  Future<void> _acceptBytes(Uint8List bytes, String fileName, String? mime) async {
    final ext = fileName.split('.').last.toLowerCase();
    final detectedMime = mime ?? _guessMime(ext);
    if (!_allowedMimes.contains(detectedMime) &&
        !_allowedExts.contains(ext)) {
      _setError('نوع الملف غير مدعوم. اختر صورة بصيغة PNG أو JPG أو WEBP.');
      return;
    }
    if (bytes.length > _maxBytes) {
      _setError(
        'حجم الصورة ${_formatSize(bytes.length)} تجاوز الحد المسموح 1.5MB. '
        'اختر صورة أصغر أو اضغطها.',
      );
      return;
    }
    setState(() {
      _bytes = bytes;
      _fileName = fileName;
      _mime = detectedMime;
      _error = null;
    });
    widget.onImageBytes(bytes, detectedMime, fileName);
  }

  String _guessMime(String ext) {
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'webp':
        return 'image/webp';
      default:
        return '';
    }
  }

  Future<void> _pickViaDialog() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: _allowedExts.toList(),
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null) {
      _setError('تعذّر قراءة الملف. حاول مرة أخرى.');
      return;
    }
    await _acceptBytes(bytes, file.name, null);
  }

  void _clear() {
    setState(() {
      _bytes = null;
      _fileName = null;
      _mime = null;
      _error = null;
    });
    widget.onClear();
  }

  @override
  Widget build(BuildContext context) {
    final hasFile = _bytes != null || _fileName != null;
    final trigger = OutlinedButton.icon(
      onPressed: _pickViaDialog,
      icon: const Icon(Icons.image_outlined),
      label: const Text('اختر صورة الخلفية'),
      style: OutlinedButton.styleFrom(
        side: BorderSide(
          color: _dragging
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.outlineVariant,
          width: _dragging ? 2 : 1,
          style: _dragging ? BorderStyle.solid : BorderStyle.solid,
        ),
        backgroundColor: _dragging
            ? Theme.of(context).colorScheme.surfaceContainerHighest
            : null,
      ),
    );

    final triggerWithDrop = PlatformCapabilities.supportsDragDrop
        ? drop.DropZone(
            onDragEntered: () => setState(() => _dragging = true),
            onDragExited: () => setState(() => _dragging = false),
            onDropped: (bytes, fileName, mime) async {
              setState(() => _dragging = false);
              await _acceptBytes(bytes, fileName, mime);
            },
            child: trigger,
          )
        : trigger;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Align(alignment: AlignmentDirectional.centerStart, child: triggerWithDrop),
        if (hasFile) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                if (_bytes != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      _bytes!,
                      width: 48,
                      height: 32,
                      fit: BoxFit.cover,
                    ),
                  )
                else
                  const SizedBox(
                    width: 48,
                    height: 32,
                    child: ColoredBox(color: Color(0xFF0F172A)),
                  ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _fileName ?? '',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                      if (_bytes != null)
                        Text(
                          '${_formatSize(_bytes!.length)}'
                          '${_mime != null ? ' · ${_mime!.split('/').last.toUpperCase()}' : ''}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF64748B),
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _clear,
                  icon: const Icon(Icons.close),
                  tooltip: 'إزالة الصورة',
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
        ],
        if (_error != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              border: Border.all(color: const Color(0xFFFECACA)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              _error!,
              style: const TextStyle(
                color: Color(0xFFB91C1C),
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
        ],
        const SizedBox(height: 4),
        const Text(
          'PNG / JPG / WEBP — حد أقصى 1.5MB. تُحفظ داخل القالب نفسه (data URL).',
          style: TextStyle(
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w700,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
