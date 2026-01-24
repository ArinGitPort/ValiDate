import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'database_helper.dart';
import 'sync_service.dart';
import '../models/warranty_item.dart';

class OfflineSyncService {
  final SupabaseClient _client = Supabase.instance.client;
  final DatabaseHelper _db = DatabaseHelper.instance;
  final SyncService _syncService = SyncService();

  ValueNotifier<bool> isSyncing = ValueNotifier(false);

  // Check connectivity
  Future<bool> get isOnline async {
    final result = await Connectivity().checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }

  // Trigger sync process
  Future<void> syncPendingChanges() async {
    if (isSyncing.value || !await isOnline) return;

    try {
      isSyncing.value = true;
      final queue = await _db.getSyncQueue();

      for (var item in queue) {
        final int id = item['id'];
        final String action = item['action'];
        final String tableName = item['table_name'];
        final Map<String, dynamic> payload = jsonDecode(item['payload']);

        bool success = false;

        switch (action) {
          case 'INSERT':
            if (tableName == 'warranties') {
              success = await _syncInsertWarranty(payload);
            }
            break;
          case 'UPDATE':
            if (tableName == 'warranties') {
               success = await _syncUpdateWarranty(payload);
            }
            break;
          case 'DELETE':
            if (tableName == 'warranties') {
              success = await _syncDeleteWarranty(payload['id']);
            }
            break;
        }

        if (success) {
          await _db.removeFromSyncQueue(id);
        }
      }
    } catch (e) {
      debugPrint('OfflineSyncService: Error during sync: $e');
    } finally {
      isSyncing.value = false;
    }
  }

  // --- Manual Download ---
  
  Future<bool> downloadAssets(WarrantyItem item) async {
    // Only proceed if there is a remote URL and no local path
    if (item.imageUrl == null || !item.imageUrl!.startsWith('http')) return true;
    if (item.localImagePath != null && File(item.localImagePath!).existsSync()) return true;

    try {
      final response = await http.get(Uri.parse(item.imageUrl!));
      if (response.statusCode == 200) {
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = '${item.id}_offline_cache.jpg'; 
        final file = File('${appDir.path}/$fileName');
        await file.writeAsBytes(response.bodyBytes);

        // Update Local DB
        // We preserve the existing isDirty state
        final newItem = item.copyWith(localImagePath: file.path);
        await _db.insertWarranty(newItem, isDirty: item.isDirty);
        
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('OfflineSyncService: Download failed for ${item.name}: $e');
      return false;
    }
  }

  // --- Specific Sync Handlers ---

  Future<bool> _syncInsertWarranty(Map<String, dynamic> payload) async {
    try {
      debugPrint('Sync: Inserting ${payload['id']} - ${payload['name']}');
      
      // 1. Handle Image Upload if local path
      String? imageUrl = payload['image_url'];
      String? localPath;

      if (imageUrl != null && !imageUrl.startsWith('http')) {
        localPath = imageUrl; // Capture local path
        if (File(localPath).existsSync()) {
            final uploadedUrl = await _syncService.uploadImage(localPath);
            if (uploadedUrl != null) {
              imageUrl = uploadedUrl;
              payload['image_url'] = imageUrl; 
            } else {
              debugPrint('Sync Error: Image upload failed for $localPath');
              return false; // Retry later
            }
        } else {
            debugPrint('Sync Warning: Local file missing at $localPath, skipping upload');
            payload['image_url'] = null; // Can't upload, so prevent sending local path to server
        }
      }
      
      // Remove local-only fields
      payload.remove('is_dirty');
      // local_image_path isn't in payload usually, but good to be safe
      payload.remove('local_image_path'); 
      
      // 2. Insert to Supabase
      await _client.from('warranties').insert(payload);
      
      // 3. Update local record
      // We explicitly set isDirty: false. 
      // AND we ensure the local_image_path is preserved so Manual Download isn't needed immediately.
      var item = WarrantyItem.fromJson(payload);
      if (localPath != null) {
        item = item.copyWith(localImagePath: localPath);
      }
      
      await _db.insertWarranty(item, isDirty: false);
      debugPrint('Sync: Insert Success');
      return true;
    } catch (e) {
      debugPrint('Sync Insert Failed: $e');
      return false;
    }
  }

  Future<bool> _syncUpdateWarranty(Map<String, dynamic> payload) async {
     try {
       debugPrint('Sync: Updating ${payload['id']}');

       // 1. Handle Image Upload
      String? imageUrl = payload['image_url'];
      String? localPath;

      if (imageUrl != null && !imageUrl.startsWith('http')) {
        localPath = imageUrl;
         if (File(localPath).existsSync()) {
            final uploadedUrl = await _syncService.uploadImage(localPath);
            if (uploadedUrl != null) {
              imageUrl = uploadedUrl;
              payload['image_url'] = imageUrl; 
            } else {
               debugPrint('Sync Error: Image upload failed');
               return false;
            }
         } else {
             payload['image_url'] = null; 
         }
      }

      payload.remove('is_dirty');
      payload.remove('local_image_path');

      // 2. Update Supabase
      await _client.from('warranties').update(payload).eq('id', payload['id']);

      // 3. Update local
      var item = WarrantyItem.fromJson(payload);
      if (localPath != null) {
         item = item.copyWith(localImagePath: localPath);
      }
      
      await _db.insertWarranty(item, isDirty: false);
      debugPrint('Sync: Update Success');
      return true;
     } catch (e) {
       debugPrint('Sync Update Failed: $e');
       return false;
     }
  }

  Future<bool> _syncDeleteWarranty(String id) async {
    try {
      await _client.from('warranties').delete().eq('id', id);
      return true;
    } catch (e) {
      debugPrint('Sync Delete Failed: $e');
      return false;
    }
  }
}
