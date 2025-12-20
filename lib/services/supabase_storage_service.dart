import 'dart:io';

import 'package:mime/mime.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseStorageService {
  static final _supabase = Supabase.instance.client;

  static Future<String?> uploadFile({
    required String bucket,
    required String userId,
    required File file,
  }) async {
    try {
      final fileExtension = file.path.split('.').last;
      final fileName =
          '${userId}_${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
      final mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';

      await _supabase.storage
          .from(bucket)
          .upload(
            fileName,
            file,
            fileOptions: FileOptions(contentType: mimeType),
          );

      return _supabase.storage.from(bucket).getPublicUrl(fileName);
    } catch (e) {
      print('Upload error: $e');
      return null;
    }
  }
}
