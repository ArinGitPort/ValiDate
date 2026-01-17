import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/warranty_item.dart';
import '../models/activity_log.dart';
import '../services/notification_service.dart';
import 'package:uuid/uuid.dart';

class WarrantyProvider with ChangeNotifier {
  late Box<WarrantyItem> _warrantyBox;
  late Box<ActivityLog> _logBox;

  // Cache
  List<WarrantyItem> _items = [];
  List<ActivityLog> _logs = [];

  // Preferences
  String _sortOrder = 'expiring_soon';
  String get sortOrder => _sortOrder;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    try {
      _warrantyBox = await Hive.openBox<WarrantyItem>('warranties');
      _logBox = await Hive.openBox<ActivityLog>('activity_logs');
      _refreshData();
    } catch (e) {
      debugPrint("WarrantyProvider Init Error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  void _refreshData() {
    if (_warrantyBox.isOpen) {
      _items = _warrantyBox.values.toList();
    }
    if (_logBox.isOpen) {
      // Sort logs by newest first
      _logs = _logBox.values.toList()..sort((a, b) => b.timestamp.compareTo(a.timestamp));
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

  Future<void> addWarranty(WarrantyItem item) async {
    await _warrantyBox.add(item);
    
    // Notifications
    await NotificationService().scheduleWarrantyNotification(
      itemId: item.id,
      itemName: item.name,
      expiryDate: item.expiryDate,
      enabled: item.notificationsEnabled ?? true,
    );

    await _addLog("added", "Added ${item.name} to vault", itemId: item.id);
    _refreshData();
    notifyListeners();
  }

  Future<void> updateWarranty(WarrantyItem item) async {
    // Hive objects can save themselves if they are in a box
    await item.save(); 

    // Update Notifications
    await NotificationService().scheduleWarrantyNotification(
      itemId: item.id,
      itemName: item.name,
      expiryDate: item.expiryDate,
      enabled: item.notificationsEnabled ?? true,
    );

    await _addLog("updated", "Updated details for ${item.name}", itemId: item.id);
    _refreshData();
    notifyListeners();
  }

  Future<void> deleteWarranty(String id) async {
    final item = _items.firstWhere((e) => e.id == id, orElse: () => WarrantyItem(id: '0', name: 'Unknown', storeName: '', purchaseDate: DateTime.now(), warrantyPeriodInMonths: 0, category: ''));
    
    // Standard ID compare, or check if it's the Hive key?
    // Usually item.delete() works if referenced from box.
    // If we only have ID, we need to find it in the box.
    
    final itemInBox = _items.firstWhere((e) => e.id == id);
    await itemInBox.delete();

    await _addLog("deleted", "Deleted ${item.name} permanently", itemId: id);
    _refreshData();
    notifyListeners();
  }
  
  Future<void> toggleArchive(String id, bool archive) async {
    final item = _items.firstWhere((e) => e.id == id);
    // We can't assign to final field? 
    // Ah, WarrantyItem fields were made final in previous steps?
    // Checking previous VIEW: yes, fields are final. 
    // Wait, Hive objects usually need mutable fields to be updated via setters or we replace the object.
    // Since I can't mutate `isArchived` if it's final... I have to create a copy or "put" at the key.
    
    // But `WarrantyItem` structure I just wrote: fields ARE final.
    // Hive requires re-putting the object if fields are final.
    
    // Let's create a copy
    final newItem = WarrantyItem(
      id: item.id,
      name: item.name,
      storeName: item.storeName,
      purchaseDate: item.purchaseDate,
      warrantyPeriodInMonths: item.warrantyPeriodInMonths,
      serialNumber: item.serialNumber,
      category: item.category,
      imagePath: item.imagePath,
      isArchived: archive, // Changed
      notificationsEnabled: item.notificationsEnabled,
      additionalDocuments: item.additionalDocuments,
      firebaseId: item.firebaseId,
      remoteImageUrl: item.remoteImageUrl,
    );
    
    // To replace in Hive using extension: we need the key.
    // item.key might give us the key.
    if (item.isInBox) {
       await _warrantyBox.put(item.key, newItem);
    }
    
    final action = archive ? "archived" : "unarchived";
    final desc = archive ? "Moved ${item.name} to archive" : "Restored ${item.name} from archive";
    await _addLog(action, desc, itemId: id);
    _refreshData();
    notifyListeners();
  }

  // --- Utils ---

  void setSortOrder(String order) {
    _sortOrder = order;
    notifyListeners();
  }

  Future<String> get storageUsage async {
    // Basic stub
    return "Local Storage";
  }

  Future<void> cleanUpExpired() async {
    final expired = _items.where((e) => e.isExpired && !e.isLifetime).toList();
    for (var item in expired) {
      await item.delete();
    }
    _refreshData();
    notifyListeners();
  }

  // --- Logs ---

  List<ActivityLog> get logs => _logs;

  Future<void> _addLog(String action, String description, {String? itemId}) async {
    final log = ActivityLog(
      id: const Uuid().v4(),
      actionType: action,
      description: description,
      timestamp: DateTime.now(),
      relatedItemId: itemId,
    );
    await _logBox.add(log);
    _refreshData(); // update local list
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
    // Clear all local data
    await _warrantyBox.clear();
    await _logBox.clear();
    
    await _addLog("reset", "Factory reset performed on device"); // Will be the only log
    _refreshData();
    notifyListeners();
  }
}
