import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:mime/mime.dart';

class FileUtils {
  static const maxFileSize = 200 * 1024; // 200 KB

  static Future<File> processFile(File file) async {
    if (!await isScannedDocument(file)) {
      throw Exception(
        'Unsupported file type. Only PDF, JPEG, PNG, TIFF are allowed.',
      );
    }

    final length = await file.length();
    final mimeType = lookupMimeType(file.path);

    // For PDFs, only check size
    if (mimeType == 'application/pdf') {
      if (length > maxFileSize) {
        throw Exception('PDF file exceeds 200KB limit');
      }
      return file;
    }

    // For images, compress if needed
    if (length > maxFileSize) {
      return await _compressImage(file, 85);
    }

    return file;
  }

  static Future<File> compressAndValidateFile(
    File file, {
    required bool isImage,
    required int quality,
  }) async {
    // Check file size
    final length = await file.length();
    if (length > maxFileSize) {
      if (isImage) {
        return await _compressImage(file, quality);
      } else {
        throw Exception('File exceeds 350 KB limit');
      }
    }
    return file;
  }

  static Future<File> _compressImage(File file, int quality) async {
    final tempDir = await getTemporaryDirectory();
    final ext = file.path.split('.').last.toLowerCase();
    final targetPath =
        '${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.${ext == 'png' ? 'png' : 'jpg'}';

    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: quality,
      minWidth: 1024,
      minHeight: 1024,
    );

    return result != null ? File(result.path) : file;
  }

  static Future<bool> isScannedDocument(File file) async {
    final mimeType = lookupMimeType(file.path);
    return [
      'application/pdf',
      'image/jpeg',
      'image/png',
      'image/tiff',
    ].contains(mimeType);
  }
}

class documentsFileUtils {
  static const maxFileSize = 350 * 1024; // 350KB

  static Future<File> compressAndValidateFile(
    File file, {
    required bool isImage,
    required int quality,
  }) async {
    // Check file size
    final length = await file.length();
    if (length > maxFileSize) {
      if (isImage) {
        return await _compressImage(file, quality);
      } else {
        throw Exception('File exceeds 350 KB limit');
      }
    }
    return file;
  }

  static Future<File> _compressImage(File file, int quality) async {
    final tempDir = await getTemporaryDirectory();
    final targetPath =
        '${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';

    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: quality,
      minWidth: 1024,
      minHeight: 1024,
    );

    if (result == null) throw Exception('Image compression failed');
    return File(result.path);
  }

  static Future<bool> isScannedDocument(File file) async {
    final mimeType = lookupMimeType(file.path);
    return [
      'application/pdf',
      'image/jpeg',
      'image/png',
      'image/tiff',
    ].contains(mimeType);
  }
}
