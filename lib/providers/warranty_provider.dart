import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/warranty_item.dart';
import '../models/activity_log.dart';
import '../services/notification_service.dart';

import 'dart:io';

class WarrantyProvider with ChangeNotifier {
  static const String boxName = 'warranties';
  static const String logBoxName = 'activity_logs';
  
  Box<WarrantyItem>? _box;
  Box<ActivityLog>? _logBox;

  // Preferences
  String _sortOrder = 'expiring_soon'; // 'expiring_soon' or 'purchase_date'
  String get sortOrder => _sortOrder;

  bool get isInitialized => _box != null && _box!.isOpen && _logBox != null && _logBox!.isOpen;

  Future<void> init() async {
    // Adapters must be registered before opening boxes (done in main.dart)
    _box = await Hive.openBox<WarrantyItem>(boxName);
    _logBox = await Hive.openBox<ActivityLog>(logBoxName);
    notifyListeners();
  }

  // --- Warranties ---

  List<WarrantyItem> get allItems {
    if (_box == null) return [];
    return _box!.values.toList();
  }

  List<WarrantyItem> get activeItems {
    final items = allItems.where((item) => !item.isArchived).toList();
    
    if (_sortOrder == 'purchase_date') {
      items.sort((a, b) => b.purchaseDate.compareTo(a.purchaseDate)); // Newest bought first
    } else {
      items.sort((a, b) => a.daysRemaining.compareTo(b.daysRemaining)); // Expiring soonest first
    }
    
    return items;
  }

  List<WarrantyItem> get archivedItems {
    return allItems.where((item) => item.isArchived).toList()
      ..sort((a, b) => b.purchaseDate.compareTo(a.purchaseDate)); 
  }

  List<WarrantyItem> get expiringSoonItems {
    return activeItems.where((item) => item.daysRemaining <= 30 && item.daysRemaining > 0).toList();
  }

  int get totalActiveCount => activeItems.length;
  int get expiringCount => expiringSoonItems.length;
  int get safeCount => activeItems.where((item) => item.daysRemaining > 30).length;

  // --- Settings / Utils ---

  void setSortOrder(String order) {
    _sortOrder = order;
    notifyListeners();
  }

  Future<String> get storageUsage async {
    if (_box == null) return "0.0 MB";
    int totalBytes = 0;
    
    try {
      for (var item in allItems) {
        if (item.imagePath.isNotEmpty) {
          final file = File(item.imagePath);
          if (await file.exists()) {
            totalBytes += await file.length();
          }
        }
      }
    } catch (e) {
      // Ignore errors on web or invalid paths
    }

    // Add some base size for DB
    totalBytes += 1024 * 50; // +50KB database overhead

    return "${(totalBytes / 1024 / 1024).toStringAsFixed(2)} MB"; 
  }

  Future<void> cleanUpExpired() async {
     if (_box == null) return;
     
     final expired = allItems.where((item) => item.daysRemaining <= 0).toList();
     for (var item in expired) {
       await deleteWarranty(item.id); 
     }
  }

  // --- Logs ---

  List<ActivityLog> get logs {
    if (_logBox == null) return [];
    final list = _logBox!.values.toList();
    list.sort((a, b) => b.timestamp.compareTo(a.timestamp)); // Newest first
    return list;
  }

  Future<void> _addLog(String action, String description, {String? itemId}) async {
    if (_logBox == null) return;
    final log = ActivityLog(
      id: const Uuid().v4(),
      actionType: action,
      description: description,
      timestamp: DateTime.now(),
      relatedItemId: itemId,
    );
    await _logBox!.add(log);
    // No need to notify here if we only access logs on a separate screen that listens to provider
    // But safely, we should:
    // notifyListeners(); 
    // Optimization: We are likely calling this from methods that already notify.
  }

  Future<void> addWarranty(WarrantyItem item) async {
    if (_box == null) return;
    await _box!.put(item.id, item);
    
    await NotificationService().scheduleWarrantyNotification(
      itemId: item.id,
      itemName: item.name,
      expiryDate: item.expiryDate,
      enabled: item.notificationsEnabled ?? true,
    );

    await _addLog("added", "Added ${item.name} to vault", itemId: item.id);
    notifyListeners();
  }

  Future<void> deleteWarranty(String id) async {
    if (_box == null) return;
    final item = _box!.values.firstWhere((e) => e.id == id);
    final name = item.name;
    
    await item.delete(); // HiveObject delete
    
    await _addLog("deleted", "Deleted $name permanently", itemId: id);
    notifyListeners();
  }

  Future<void> toggleArchive(String id, bool archive) async {
    if (_box == null) return;
    final item = _box!.values.firstWhere((e) => e.id == id);
    item.isArchived = archive;
    await item.save();

    final action = archive ? "archived" : "unarchived";
    final desc = archive ? "Moved ${item.name} to archive" : "Restored ${item.name} from archive";
    await _addLog(action, desc, itemId: id);

    notifyListeners();
  }

  // Search logic for dashboard
  List<WarrantyItem> searchActive(String query) {
    if (query.isEmpty) return activeItems;
    return activeItems.where((item) {
      return item.name.toLowerCase().contains(query.toLowerCase()) || 
             item.storeName.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  void notify() {
    notifyListeners();
  }
}

