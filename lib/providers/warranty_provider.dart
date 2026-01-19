import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/warranty_item.dart';
import '../models/activity_log.dart';
import '../services/notification_service.dart';
import '../services/sync_service.dart';

class WarrantyProvider with ChangeNotifier {
  final SupabaseClient _client = Supabase.instance.client;
  final SyncService _syncService = SyncService();

  List<WarrantyItem> _items = [];
  List<ActivityLog> _logs = [];
  
  String _sortOrder = 'expiring_soon';
  String get sortOrder => _sortOrder;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? get _userId => _client.auth.currentUser?.id;

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    // Listen to auth changes
    _client.auth.onAuthStateChange.listen((data) {
      if (data.session != null) {
        _fetchData();
      } else {
        _items = [];
        _logs = [];
        notifyListeners();
      }
    });

    if (_userId != null) {
      await _fetchData();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _fetchData() async {
    if (_userId == null) return;

    try {
      // Fetch warranties with documents
      final warrantyResponse = await _client
          .from('warranties')
          .select('*, warranty_documents(document_url)')
          .eq('user_id', _userId!)
          .order('created_at', ascending: false);

      _items = (warrantyResponse as List)
          .map((json) => WarrantyItem.fromJson(json))
          .toList();

      // Fetch logs
      final logResponse = await _client
          .from('activity_logs')
          .select()
          .eq('user_id', _userId!)
          .order('created_at', ascending: false)
          .limit(50);

      _logs = (logResponse as List)
          .map((json) => ActivityLog.fromJson(json))
          .toList();

      notifyListeners();
    } catch (e) {
      debugPrint('WarrantyProvider: Error fetching data: $e');
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
      // Upload image if exists (local path)
      String? imageUrl = item.imageUrl;
      
      if (item.imageUrl != null && item.imageUrl!.isNotEmpty && !item.imageUrl!.startsWith('http')) {
        debugPrint('WarrantyProvider: Uploading image from ${item.imageUrl}');
        final uploadedUrl = await _syncService.uploadImage(item.imageUrl!);
        
        if (uploadedUrl != null) {
          imageUrl = uploadedUrl;
          debugPrint('WarrantyProvider: Image uploaded to $uploadedUrl');
        } else {
          debugPrint('WarrantyProvider: Image upload failed, saving without image');
          imageUrl = null; // Don't save local path to database
        }
      }

      final newItem = item.copyWith(
        id: const Uuid().v4(),
        userId: _userId!,
        imageUrl: imageUrl,
      );

      // Insert warranty
      await _client.from('warranties').insert(newItem.toJson());
      
      // Handle Additional Documents
      // Merge docs from item.additionalDocuments (if populated) and extraDocs (argument)
      List<String> docsToUpload = [];
      if (item.additionalDocuments.isNotEmpty) docsToUpload.addAll(item.additionalDocuments);
      if (extraDocs != null) docsToUpload.addAll(extraDocs);
      
      // Deduplicate
      docsToUpload = docsToUpload.toSet().toList();

      if (docsToUpload.isNotEmpty) {
        debugPrint('WarrantyProvider: Uploading ${docsToUpload.length} additional documents');
        await _syncService.uploadAdditionalDocuments(newItem.id, docsToUpload);
      }
      
      // Notifications
      await NotificationService().scheduleWarrantyNotification(
        itemId: newItem.id,
        itemName: newItem.name,
        expiryDate: newItem.expiryDate,
        enabled: newItem.notificationsEnabled,
      );

      await _addLog("added", "Added ${newItem.name} to vault", itemId: newItem.id);
      await _fetchData();
    } catch (e) {
      debugPrint('WarrantyProvider: Error adding warranty: $e');
      rethrow;
    }
  }

  Future<void> updateWarranty(WarrantyItem item) async {
    try {
      // 1. Handle Primary Image Update
      String? imageUrl = item.imageUrl;
      
      // Fetch currently saved item to compare primary image
      final oldItem = _items.firstWhere((e) => e.id == item.id, orElse: () => item);

      // Check if image changed
      if (item.imageUrl != oldItem.imageUrl) {
        // If new image is a local file (not http), Upload it
        if (item.imageUrl != null && !item.imageUrl!.startsWith('http')) {
           debugPrint('WarrantyProvider: Uploading new primary image');
           final uploadedUrl = await _syncService.uploadImage(item.imageUrl!);
           if (uploadedUrl != null) {
             imageUrl = uploadedUrl; // Update to remote URL
           }
        }
        
        // If we successfully have a new image (or it was null/removed), 
        // and there was an old remote image, delete the old one
        if (oldItem.imageUrl != null && oldItem.imageUrl!.startsWith('http')) {
          await _syncService.deleteImage(oldItem.imageUrl);
        }
      }

      final itemToUpdate = item.copyWith(imageUrl: imageUrl);

      // 2. Update basic fields with correct URL
      await _client.from('warranties').update(itemToUpdate.toJson()).eq('id', item.id);
      
      // 2. Handle Additional Documents Update
      // Fetch currently saved documents for this warranty to compare
      // We can rely on _items if it's up to date, but fetching fresh is safer for concurrency 
      // or we can use the ones currently in memory for this item id. 
      // Let's assume _items is ground truth.
      // Let's assume _items is ground truth.
      // Reuse oldItem fetched above
      final oldDocs = oldItem.additionalDocuments; // List<String> URLs
      final newDocs = item.additionalDocuments;    // List<String> Mixed URLs and Local Paths

      // Helper to check if string is a remote URL
      bool isRemote(String s) => s.startsWith('http');

      // Identify docs to delete: In old but NOT in new (by exact string match for URLs)
      // Note: If a URL is in newDocs, it should match oldDocs exactly. Local paths are new additions.
      final docsToDelete = oldDocs.where((url) => !newDocs.contains(url)).toList();

      // Identify new docs to upload: In newDocs but NOT remote (i.e., local paths)
      final docsToUpload = newDocs.where((path) => !isRemote(path)).toList();

      // Execute Deletions
      for (final url in docsToDelete) {
        await _syncService.deleteImage(url); // Delete storage
        await _client.from('warranty_documents').delete().match({
          'warranty_id': item.id,
          'document_url': url
        }); // Delete DB record
      }

      // Execute Uploads
      if (docsToUpload.isNotEmpty) {
         await _syncService.uploadAdditionalDocuments(item.id, docsToUpload);
      }

      await NotificationService().scheduleWarrantyNotification(
        itemId: item.id,
        itemName: item.name,
        expiryDate: item.expiryDate,
        enabled: item.notificationsEnabled,
      );

      await _addLog("updated", "Updated ${item.name}", itemId: item.id);
      await _fetchData();
    } catch (e) {
      debugPrint('WarrantyProvider: Error updating warranty: $e');
      rethrow;
    }
  }

  Future<void> deleteWarranty(String id) async {
    try {
      final item = _items.firstWhere((e) => e.id == id);
      
      // Delete image from storage
      if (item.imageUrl != null) {
        await _syncService.deleteImage(item.imageUrl);
      }
      
      // Delete additional documents
      await _syncService.deleteAdditionalDocuments(id);
      
      await _client.from('warranties').delete().eq('id', id);
      await _addLog("deleted", "Deleted ${item.name}", itemId: id);
      await _fetchData();
    } catch (e) {
      debugPrint('WarrantyProvider: Error deleting warranty: $e');
      rethrow;
    }
  }

  Future<void> toggleArchive(String id, bool archive) async {
    try {
      final item = _items.firstWhere((e) => e.id == id);
      
      await _client.from('warranties').update({'is_archived': archive}).eq('id', id);
      
      final action = archive ? "archived" : "unarchived";
      final desc = archive ? "Moved ${item.name} to archive" : "Restored ${item.name} from archive";
      await _addLog(action, desc, itemId: id);
      await _fetchData();
    } catch (e) {
      debugPrint('WarrantyProvider: Error toggling archive: $e');
    }
  }

  // --- Utils ---

  void setSortOrder(String order) {
    _sortOrder = order;
    notifyListeners();
  }

  Future<String> get storageUsage async {
    return "Supabase Cloud";
  }

  Future<void> cleanUpExpired() async {
    final expired = _items.where((e) => e.isExpired && !e.isLifetime).toList();
    for (var item in expired) {
      await deleteWarranty(item.id);
    }
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
      
      await _client.from('activity_logs').insert(log.toJson());
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

      // Delete all warranties and their images
      for (var item in _items) {
        if (item.imageUrl != null) {
          await _syncService.deleteImage(item.imageUrl);
        }
      }

      await _client.from('warranties').delete().eq('user_id', _userId!);
      await _client.from('activity_logs').delete().eq('user_id', _userId!);

      await _fetchData();
    } catch (e) {
      debugPrint('WarrantyProvider: Error resetting account: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
