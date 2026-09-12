import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'ui.dart';

class PickedDoc {
  PickedDoc(this.bytes, this.mime, this.path);
  final Uint8List bytes;
  final String mime;
  final String path;

  File get file => File(path);
}

final _picker = ImagePicker();

/// Camera or gallery, chosen from a bottom sheet. Returns null if cancelled.
Future<PickedDoc?> pickDocument(BuildContext context) async {
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    backgroundColor: canvas,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Center(
            child: Container(width: 44, height: 5, decoration: BoxDecoration(color: const Color(0xFFC7D0DA), borderRadius: BorderRadius.circular(4))),
          ),
          const SizedBox(height: 18),
          const Text('Add document', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: ink)),
          const SizedBox(height: 4),
          const Text('Use a flat, well lit photo of the full page for the best OCR result.',
              style: TextStyle(color: muted, fontSize: 12.5, height: 1.4)),
          const SizedBox(height: 18),
          SoftTap(
            onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
            child: const Row(children: [
              Icon(Icons.photo_camera_outlined, color: blue),
              SizedBox(width: 13),
              Text('Take a photo', style: TextStyle(fontWeight: FontWeight.w700, color: ink)),
            ]),
          ),
          const SizedBox(height: 12),
          SoftTap(
            onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
            child: const Row(children: [
              Icon(Icons.photo_library_outlined, color: blue),
              SizedBox(width: 13),
              Text('Choose from gallery', style: TextStyle(fontWeight: FontWeight.w700, color: ink)),
            ]),
          ),
        ]),
      ),
    ),
  );
  if (source == null) return null;

  try {
    // Cap the long edge: full-res phone photos blow past the inline-data limit.
    final file = await _picker.pickImage(source: source, maxWidth: 2200, imageQuality: 88);
    if (file == null) return null;
    final bytes = await file.readAsBytes();
    final mime = file.path.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg';
    return PickedDoc(bytes, mime, file.path);
  } catch (e) {
    if (context.mounted) toast(context, 'Could not open the camera or gallery.', color: danger);
    return null;
  }
}

/// Image preview that degrades to a placeholder when the file is gone.
class DocPreview extends StatelessWidget {
  const DocPreview({super.key, required this.path, this.height = 240});
  final String? path;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SoftWell(
      padding: const EdgeInsets.all(8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: path == null
              ? const ColoredBox(
                  color: Color(0xFFDDE4EC),
                  child: Center(child: Icon(Icons.image_outlined, color: muted, size: 34)),
                )
              : Image.file(
                  File(path!),
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const ColoredBox(
                    color: Color(0xFFDDE4EC),
                    child: Center(child: Icon(Icons.broken_image_outlined, color: muted, size: 34)),
                  ),
                ),
        ),
      ),
    );
  }
}
