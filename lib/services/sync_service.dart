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

  /// Upload additional documents for a warranty
  Future<List<String>> uploadAdditionalDocuments(String warrantyId, List<String> localPaths) async {
    final uploadedUrls = <String>[];
    
    for (final localPath in localPaths) {
      final url = await uploadImage(localPath);
      if (url != null) {
        // Insert into warranty_documents table
        await _client.from('warranty_documents').insert({
          'warranty_id': warrantyId,
          'document_url': url,
        });
        uploadedUrls.add(url);
      }
    }
    
    return uploadedUrls;
  }

  /// Fetch additional documents for a warranty
  Future<List<String>> fetchAdditionalDocuments(String warrantyId) async {
    try {
      final response = await _client
          .from('warranty_documents')
          .select('document_url')
          .eq('warranty_id', warrantyId);
      
      return (response as List).map((e) => e['document_url'] as String).toList();
    } catch (e) {
      debugPrint('SyncService: Error fetching documents: $e');
      return [];
    }
  }

  /// Delete all additional documents for a warranty
  Future<void> deleteAdditionalDocuments(String warrantyId) async {
    try {
      // Get URLs first
      final docs = await fetchAdditionalDocuments(warrantyId);
      
      // Delete from storage
      for (final url in docs) {
        await deleteImage(url);
      }
      
      // Delete from database
      await _client.from('warranty_documents').delete().eq('warranty_id', warrantyId);
    } catch (e) {
      debugPrint('SyncService: Error deleting documents: $e');
    }
  }
}