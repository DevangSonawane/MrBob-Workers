import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

class ImageCompressor {
  static const int maxDimension = 1920;
  static const int jpegQuality = 85;

  static Future<File> compress(File file) async {
    final bytes = await file.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return file;

    int? newWidth;
    int? newHeight;
    if (decoded.width > maxDimension || decoded.height > maxDimension) {
      if (decoded.width > decoded.height) {
        newWidth = maxDimension;
        newHeight = (decoded.height * maxDimension / decoded.width).round();
      } else {
        newHeight = maxDimension;
        newWidth = (decoded.width * maxDimension / decoded.height).round();
      }
    }

    final resized = newWidth != null && newHeight != null
        ? img.copyResize(decoded, width: newWidth, height: newHeight)
        : decoded;

    final compressed = Uint8List.fromList(img.encodeJpg(resized, quality: jpegQuality));

    final tempDir = Directory.systemTemp;
    final name = 'compressed_${DateTime.now().millisecondsSinceEpoch}${_ext(file.path)}';
    final tempFile = File('${tempDir.path}/$name');
    await tempFile.writeAsBytes(compressed, flush: true);
    return tempFile;
  }

  static String _ext(String path) {
    final idx = path.lastIndexOf('.');
    if (idx >= 0) return path.substring(idx);
    return '.jpg';
  }
}
