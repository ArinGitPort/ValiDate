import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

class SyncService {
  final SupabaseClient _client = Supabase.instance.client;
  static const String _bucketName = 'warranty-images';

  /// Upload an image to Supabase Storage
  Future<String?> uploadImage(String localPath) async {
    try {
      final file = File(localPath);
      if (!await file.exists()) {
        return null;
      }

      final userId = _client.auth.currentUser?.id;
      if (userId == null) return null;

      final extension = path.extension(localPath);
      final fileName = '${const Uuid().v4()}$extension';
      final storagePath = '$userId/$fileName';

      await _client.storage.from(_bucketName).upload(
        storagePath,
        file,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
      );

      // Get public URL
      final publicUrl = _client.storage.from(_bucketName).getPublicUrl(storagePath);
      return publicUrl;
    } catch (e) {
      debugPrint('SyncService: Image upload failed: $e');
      return null;
    }
  }

  /// Delete an image from Supabase Storage
  Future<void> deleteImage(String? imageUrl) async {
    if (imageUrl == null || imageUrl.isEmpty) return;

    try {
      // Extract path from URL
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;
      
      // Find index after 'warranty-images' in path
      final bucketIndex = pathSegments.indexOf(_bucketName);
      if (bucketIndex == -1 || bucketIndex >= pathSegments.length - 1) return;
      
      final storagePath = pathSegments.sublist(bucketIndex + 1).join('/');
      
      await _client.storage.from(_bucketName).remove([storagePath]);
    } catch (e) {
      debugPrint('SyncService: Image delete failed: $e');
    }
  }
}