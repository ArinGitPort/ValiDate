import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:uuid/uuid.dart';
import '../models/warranty_item.dart';
import '../models/activity_log.dart';
import '../services/notification_service.dart';
import '../services/sync_service.dart';
import '../services/database_helper.dart';
import '../services/offline_sync_service.dart';

class WarrantyProvider with ChangeNotifier {
  final SupabaseClient _client = Supabase.instance.client;
  final SyncService _syncService = SyncService();
  final DatabaseHelper _db = DatabaseHelper.instance;
  final OfflineSyncService _offlineSyncService = OfflineSyncService();

  List<WarrantyItem> _items = [];
  List<ActivityLog> _logs = [];
  
  String _sortOrder = 'expiring_soon';
  String get sortOrder => _sortOrder;

  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  // Expose sync status
  bool get isSyncing => _offlineSyncService.isSyncing.value;

  // Track downloading items
  final Set<String> _downloadingItems = {};
  bool isDownloading(String id) => _downloadingItems.contains(id);

  String? get _userId => _client.auth.currentUser?.id;

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();
    
    debugPrint('🚀 WarrantyProvider: Initializing...');
    debugPrint('👤 Current user ID: $_userId');
    
    // Bind sync service listener to notify UI when syncing state changes
    _offlineSyncService.isSyncing.addListener(() {
      // Notify to show/hide syncing indicator
      notifyListeners();
      // If sync just finished, reload data from local DB to reflect changes (e.g. clean dirty flags, updated URLs)
      if (!_offlineSyncService.isSyncing.value) {
        debugPrint('✅ Sync completed, reloading data...');
        _fetchData().then((_) {
          // Ensure UI updates after data is loaded
          notifyListeners();
          debugPrint('📱 UI updated with synced data');
        });
      }
    });

    // Listen to auth changes
    _client.auth.onAuthStateChange.listen((data) {
      debugPrint('🔐 Auth state changed');
      if (data.session != null) {
        debugPrint('✅ User authenticated: ${data.session?.user.id}');
        _fetchData();
      } else {
        debugPrint('⚠️ User logged out');
        _items = [];
        _logs = [];
        notifyListeners();
      }
    });
    
    // Connectivity listener to trigger sync when online
    Connectivity().onConnectivityChanged.listen((result) {
      if (!result.contains(ConnectivityResult.none)) {
        debugPrint('🌐 Connectivity restored - triggering sync');
        _syncData();
      }
    });

    if (_userId != null) {
      await _fetchData();
      
      // Try to sync on init if possible - await to ensure data loads before UI renders
      await _syncData();
    } else {
      debugPrint('⚠️ No authenticated user - skipping initial data fetch');
    }

    _isLoading = false;
    notifyListeners();
    debugPrint('✅ WarrantyProvider initialization complete');
  }

  Future<void> _fetchData() async {
    if (_userId == null) {
      debugPrint('⚠️ WarrantyProvider._fetchData: No user ID, skipping fetch');
      return;
    }

    try {
      debugPrint('📂 WarrantyProvider: Loading local data for user: $_userId');
      
      // 1. Load Local Data First
      _items = await _db.getAllWarranties(_userId!);
      debugPrint('✅ Loaded ${_items.length} warranties from local DB');
      
      // Debug: Show item details
      if (_items.isNotEmpty) {
        debugPrint('📋 First item: ${_items.first.name} (archived: ${_items.first.isArchived})');
      }
      
      _logs = await _db.getLogs(_userId!);
      debugPrint('✅ Loaded ${_logs.length} activity logs from local DB');
      
      // Calculate active items for debugging
      final activeCount = _items.where((item) => !item.isArchived).length;
      debugPrint('✅ Active items: $activeCount / ${_items.length}');
      
      notifyListeners();
    } catch (e, stackTrace) {
      debugPrint('❌ WarrantyProvider: Error fetching local data: $e');
      debugPrint('Stack trace: $stackTrace');
      // Still notify listeners to update UI even on error
      notifyListeners();
    }
  }

  Future<void> _syncData() async {
    debugPrint('🔄 WarrantyProvider: Starting sync process...');
    
    // Process queue first
    debugPrint('📤 Processing pending changes queue...');
    await _offlineSyncService.syncPendingChanges();
    
    // Then fetch fresh data from cloud and update local
    if (_userId != null && await _offlineSyncService.isOnline) {
      debugPrint('🌐 Online - fetching remote data...');
      await _fetchRemoteDataAndUpdateLocal();
      await _fetchData(); // Reload from local to show fresh data
      debugPrint('✅ Sync process completed');
    } else {
      if (_userId == null) {
        debugPrint('⚠️ Cannot sync - no user authenticated');
      } else {
        debugPrint('📴 Offline - skipping remote fetch');
      }
    }
  }

  Future<void> _fetchRemoteDataAndUpdateLocal() async {
    try {
      if (_userId == null) {
        debugPrint('❌ WarrantyProvider: Cannot fetch remote data - user not authenticated');
        return;
      }

      debugPrint('📡 WarrantyProvider: Fetching remote data for user: $_userId');

      // Fetch warranties (including remote docs)
      debugPrint('🔄 Fetching warranties from Supabase...');
      final warrantyResponse = await _client
          .from('warranties')
          .select('*, warranty_documents(document_url)')
          .eq('user_id', _userId!)
          .order('created_at', ascending: false);
      
      debugPrint('✅ Warranty response received: ${warrantyResponse.runtimeType}');
      debugPrint('📊 Number of warranties fetched: ${(warrantyResponse as List).length}');

      final remoteItems = (warrantyResponse as List)
          .map((json) => WarrantyItem.fromJson(json))
          .toList();

      debugPrint('✅ Parsed ${remoteItems.length} warranty items');
      
      // Debug: Show first item details if available
      if (remoteItems.isNotEmpty) {
        final firstItem = remoteItems.first;
        debugPrint('📋 First warranty: ${firstItem.name} (id: ${firstItem.id}, archived: ${firstItem.isArchived})');
      }

      // Update Local DB with Remote Data
      // For simplicity in this iteration: Overwrite entries found in remote
      // NOTE: This might overwrite local pending changes if not careful.
      // Ideally we shouldn't overwrite items that are 'is_dirty'.
      // But since we process queue BEFORE fetching remote, 'is_dirty' items should be synced 
      // and cleared of dirty flag (or conflict handled).
      // So assuming queue process succeeded, it's safe to update.
      
      for (var item in remoteItems) {
        await _db.insertWarranty(item, isDirty: false);
        // Also insert docs (managed inside insertWarranty logic in DB helper ideally, 
        // but currently separate. Let's fix DB helper usage or loop here)
        for (var doc in item.additionalDocuments) {
           await _db.insertDocument(item.id, doc);
        }
      }

      debugPrint('💾 Updated local database with remote warranties');

      // Fetch logs
      debugPrint('🔄 Fetching activity logs from Supabase...');
      final logResponse = await _client
          .from('activity_logs')
          .select()
          .eq('user_id', _userId!)
          .order('created_at', ascending: false)
          .limit(50);

      debugPrint('✅ Log response received: ${(logResponse as List).length} logs');

      final remoteLogs = (logResponse as List)
          .map((json) => ActivityLog.fromJson(json))
          .toList();
          
      for (var log in remoteLogs) {
        await _db.insertLog(log);
      }
       
      debugPrint('✅ WarrantyProvider: Remote data fetch and local update completed successfully');
    } catch (e, stackTrace) {
      debugPrint('❌ WarrantyProvider: Error fetching remote data');
      debugPrint('Error type: ${e.runtimeType}');
      debugPrint('Error message: $e');
      debugPrint('Stack trace: $stackTrace');
      
      // Check for specific Supabase errors
      if (e is PostgrestException) {
        debugPrint('🔴 Supabase PostgrestException:');
        debugPrint('  - Code: ${e.code}');
        debugPrint('  - Message: ${e.message}');
        debugPrint('  - Details: ${e.details}');
        debugPrint('  - Hint: ${e.hint}');
      } else if (e is AuthException) {
        debugPrint('🔴 Supabase AuthException: ${e.message}');
      }
    }
  }

  // --- Warranties ---

  List<WarrantyItem> get allItems => _items;

  List<WarrantyItem> get activeItems {
    final items = _items.where((item) => !item.isArchived).toList();
    
    switch (_sortOrder) {
      case 'purchase_newest':
        items.sort((a, b) => b.purchaseDate.compareTo(a.purchaseDate));
        break;
      case 'purchase_oldest':
        items.sort((a, b) => a.purchaseDate.compareTo(b.purchaseDate));
        break;
      case 'name_az':
        items.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case 'name_za':
        items.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
        break;
      case 'expiring_soon':
      default:
        items.sort((a, b) => a.daysRemaining.compareTo(b.daysRemaining));
        break;
    }
    
    return items;
  }

  List<WarrantyItem> get archivedItems {
    return _items.where((item) => item.isArchived).toList()
      ..sort((a, b) => b.purchaseDate.compareTo(a.purchaseDate)); 
  }

  List<WarrantyItem> get expiringSoonItems {
    return activeItems.where((item) => item.daysRemaining <= 30 && item.daysRemaining > 0).toList();
  }

  int get totalActiveCount => activeItems.length;
  int get expiringCount => expiringSoonItems.length;

  Future<void> addWarranty(WarrantyItem item, {List<String>? extraDocs}) async {
    if (_userId == null) return;

    try {
      final newItem = item.copyWith(
        id: const Uuid().v4(),
        userId: _userId!,
        isDirty: true, // Mark as dirty initially
      );
      
      // Handle Docs (Merge for local storage)
      List<String> docsToSave = [];
      if (item.additionalDocuments.isNotEmpty) docsToSave.addAll(item.additionalDocuments);
      if (extraDocs != null) docsToSave.addAll(extraDocs);
      docsToSave = docsToSave.toSet().toList(); // Deduplicate

      final itemWithDocs = newItem.copyWith(additionalDocuments: docsToSave);

      // 1. Save Local Immediately
      await _db.insertWarranty(itemWithDocs, isDirty: true);
      for(var doc in docsToSave) {
        await _db.insertDocument(newItem.id, doc);
      }
      
      // 2. Queue for Sync
      // We need to construct the payload as if we are inserting to Supabase.
      // This means using the local paths for now, valid for the queue processor to handle upload.
      await _db.addToSyncQueue('INSERT', 'warranties', itemWithDocs.toJson());
      
      // 3. Update UI
      // Notifications (Schedule locally regardless of sync)
      // Use unawaited to prevent blocking - let notifications schedule in background
      unawaited(NotificationService().scheduleWarrantyNotification(
        itemId: newItem.id,
        itemName: newItem.name,
        expiryDate: newItem.expiryDate,
        enabled: newItem.notificationsEnabled,
      ));

      await _addLog("added", "Added ${newItem.name} to vault", itemId: newItem.id);
      
      await _fetchData(); // Refresh UI from local DB
      
      // 4. Trigger Sync (if online) - Non-blocking
      unawaited(_offlineSyncService.syncPendingChanges());

    } catch (e) {
      debugPrint('WarrantyProvider: Error adding warranty: $e');
      rethrow;
    }
  }

  Future<void> updateWarranty(WarrantyItem item) async {
    try {
      // 1. Save Local
      final updatedItem = item.copyWith(isDirty: true);
      await _db.insertWarranty(updatedItem, isDirty: true);
      
      // Handle docs removal/addition in local DB? 
      // For simplicity, we trust the item's doc list and overwrite.
      // But we should clean up old docs in local DB? 
      // Logic for perfect detailed local doc sync is complex, 
      // assuming insertDocument with Replace handles it "mostly" 
      // but doesn't delete removed ones.
      // For now, focus on the Queue payload being correct.
      
      // 2. Queue
      await _db.addToSyncQueue('UPDATE', 'warranties', updatedItem.toJson());

      // 3. UI - Non-blocking notifications
      unawaited(NotificationService().scheduleWarrantyNotification(
        itemId: item.id,
        itemName: item.name,
        expiryDate: item.expiryDate,
        enabled: item.notificationsEnabled,
      ));

      await _addLog("updated", "Updated ${item.name}", itemId: item.id);
      await _fetchData();
      
      // 4. Sync - Non-blocking
      unawaited(_offlineSyncService.syncPendingChanges());
    } catch (e) {
      debugPrint('WarrantyProvider: Error updating warranty: $e');
      rethrow;
    }
  }

  Future<void> deleteWarranty(String id) async {
    try {
      final item = _items.firstWhere((e) => e.id == id);
      
      // 1. Local Delete
      await _db.deleteWarranty(id);
      
      // 2. Queue
      await _db.addToSyncQueue('DELETE', 'warranties', {'id': id});
      
      // 3. Log
      await _addLog("deleted", "Deleted ${item.name}", itemId: id);
      await _fetchData();
      
      // 4. Sync
      _offlineSyncService.syncPendingChanges();
      
    } catch (e) {
      debugPrint('WarrantyProvider: Error deleting warranty: $e');
      rethrow;
    }
  }

  Future<void> toggleArchive(String id, bool archive) async {
    try {
      final item = _items.firstWhere((e) => e.id == id);
      final updated = item.copyWith(isArchived: archive);
      
      await updateWarranty(updated);
      
      final action = archive ? "archived" : "unarchived";
      final desc = archive ? "Moved ${item.name} to archive" : "Restored ${item.name} from archive";
      await _addLog(action, desc, itemId: id);
      
    } catch (e) {
      debugPrint('WarrantyProvider: Error toggling archive: $e');
    }
  }

  // --- Utils ---

  void setSortOrder(String order) {
    _sortOrder = order;
    notifyListeners();
  }

  bool _globalNotificationsEnabled = true;
  bool get globalNotificationsEnabled => _globalNotificationsEnabled;

  void setGlobalNotificationsEnabled(bool enabled) {
    _globalNotificationsEnabled = enabled;
    notifyListeners();
  }

  Future<String> get storageUsage async {
    // Helper to calculate local storage? 
    // Or just static string for now
    return "Local + Cloud Sync";
  }

  Future<void> cleanUpExpired() async {
    final expired = _items.where((e) => e.isExpired && !e.isLifetime).toList();
    for (var item in expired) {
      await deleteWarranty(item.id);
    }
  }

  Future<int> restoreData(List<dynamic> jsonList) async {
    if (_userId == null) return 0;
    int importedCount = 0;

    for (var json in jsonList) {
      if (json is Map<String, dynamic>) {
        try {
          // Generate new ID or use existing
          final String id = json['id'] ?? const Uuid().v4();
          
          // Check if item already exists in local DB
          final existingItems = await _db.getAllWarranties(_userId!);
          final exists = existingItems.any((item) => item.id == id);
          
          if (!exists) {
            final item = WarrantyItem(
              id: id,
              userId: _userId!,
              name: json['name'] ?? 'Unnamed Item',
              storeName: json['store_name'] ?? json['store'] ?? "",
              purchaseDate: DateTime.parse(json['purchase_date'] ?? json['purchaseDate']),
              warrantyPeriodInMonths: json['warranty_period_months'] ?? json['warrantyMonths'] ?? 12,
              serialNumber: json['serial_number'] ?? json['serial'] ?? "",
              category: json['category'] ?? "others",
              imageUrl: json['image_url'],
              notificationsEnabled: json['notifications_enabled'] ?? true,
              isArchived: json['is_archived'] ?? false,
            );
            
            await _db.insertWarranty(item, isDirty: true);
            await _db.addToSyncQueue('INSERT', 'warranties', item.toJson());
            importedCount++;
          }
        } catch (e) {
          debugPrint("Failed to import item: $e");
        }
      }
    }
    
    if (importedCount > 0) {
      await _fetchData();
      await _addLog("restored", "Restored $importedCount items from backup");
      unawaited(_offlineSyncService.syncPendingChanges());
    }
    return importedCount;
  }

  // --- Logs ---

  List<ActivityLog> get logs => _logs;

  Future<void> _addLog(String action, String description, {String? itemId}) async {
    if (_userId == null) return;
    
    try {
      final log = ActivityLog(
        id: const Uuid().v4(),
        userId: _userId!,
        actionType: action,
        description: description,
        timestamp: DateTime.now(),
        relatedItemId: itemId,
      );
      
      // Save local
      await _db.insertLog(log);
      notifyListeners(); // Update logs UI
      
      // Ideally queue logs too, but for now we trust they sync on next fresh fetch 
      // OR we can simple insert them to Supabase directly if online, else ignore?
      // Better: Add to queue if important. 
      // NOTE: Logs are usually server-side or less critical. 
      // Let's trying firing and forgetting to Supabase if online, 
      // or adding to queue if strict.
      // For simplicity/robustness: Queue it.
      // But we didn't add logic to sync_process for logs table yet. 
      // Let's stick to fire-and-forget for logs or just local for now if offline.
      if (await _offlineSyncService.isOnline) {
          await _client.from('activity_logs').insert(log.toJson());
      }
      
    } catch (e) {
      debugPrint('WarrantyProvider: Error adding log: $e');
    }
  }

  // Search
  List<WarrantyItem> searchActive(String query) {
    if (query.isEmpty) return activeItems;
    return activeItems.where((item) {
      return item.name.toLowerCase().contains(query.toLowerCase()) || 
             item.storeName.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  Future<void> resetAccount() async {
    if (_userId == null) return;

    try {
      _isLoading = true;
      notifyListeners();

      // Clear Local
      await _db.clearAll(_userId!);

      // Clear Remote (if online)
      if (await _offlineSyncService.isOnline) {
         // ... existing delete logic ...
         final items = await _client.from('warranties').select().eq('user_id', _userId!);
         for(var item in items) {
            String? url = item['image_url'];
             if (url != null) await _syncService.deleteImage(url);
         }
         await _client.from('warranties').delete().eq('user_id', _userId!);
         await _client.from('activity_logs').delete().eq('user_id', _userId!);
      }

      await _fetchData();
    } catch (e) {
      debugPrint('WarrantyProvider: Error resetting account: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> downloadOfflineAssets(String id) async {
    try {
       final index = _items.indexWhere((e) => e.id == id);
       if (index == -1) return;
       final item = _items[index];

       _downloadingItems.add(id);
       notifyListeners();

       final success = await _offlineSyncService.downloadAssets(item);
       
       if (success) {
         await _fetchData(); // Reload to get local path
       }
    } catch (e) {
      debugPrint("Provider: Download failed $e");
    } finally {
      _downloadingItems.remove(id);
      notifyListeners();
    }
  }
}
