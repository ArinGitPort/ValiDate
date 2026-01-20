import 'dart:convert';
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

  // --- Specific Sync Handlers ---

  Future<bool> _syncInsertWarranty(Map<String, dynamic> payload) async {
    try {
      // 1. Handle Image Upload if local path
      String? imageUrl = payload['image_url'];
      if (imageUrl != null && !imageUrl.startsWith('http')) {
        final uploadedUrl = await _syncService.uploadImage(imageUrl);
        if (uploadedUrl != null) {
          imageUrl = uploadedUrl;
          payload['image_url'] = imageUrl; // Update payload
        }
      }
      
      // Remove local-only fields if any
      payload.remove('is_dirty');
      
      // 2. Insert to Supabase
      await _client.from('warranties').insert(payload);
      
      // 3. Update local record with definitive data (especially URL)
      // Note: We should probably fetch the inserted record to be sure, 
      // but payload with updated URL is good enough for now.
      // Or we can just update the image_url locally.
      
      // Construct WarrantyItem to update local DB properly
      final item = WarrantyItem.fromJson(payload);
      await _db.insertWarranty(item, isDirty: false);
      
      return true;
    } catch (e) {
      debugPrint('Sync Insert Failed: $e');
      return false;
    }
  }

  Future<bool> _syncUpdateWarranty(Map<String, dynamic> payload) async {
     try {
       // 1. Handle Image Upload if local path
      String? imageUrl = payload['image_url'];
      if (imageUrl != null && !imageUrl.startsWith('http')) {
        final uploadedUrl = await _syncService.uploadImage(imageUrl);
        if (uploadedUrl != null) {
          imageUrl = uploadedUrl;
          payload['image_url'] = imageUrl; 
        }
      }

      payload.remove('is_dirty');

      // 2. Update Supabase
      await _client.from('warranties').update(payload).eq('id', payload['id']);

      // 3. Update local
      final item = WarrantyItem.fromJson(payload);
      await _db.insertWarranty(item, isDirty: false);

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
