import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/warranty_item.dart';
import '../services/notification_service.dart';

class WarrantyProvider with ChangeNotifier {
  static const String boxName = 'warranties';
  Box<WarrantyItem>? _box;

  bool get isInitialized => _box != null && _box!.isOpen;

  Future<void> init() async {
    // await Hive.initFlutter(); // Should be called in main.dart
    // Hive.registerAdapter(WarrantyItemAdapter());
    _box = await Hive.openBox<WarrantyItem>(boxName);
    notifyListeners();
  }

  List<WarrantyItem> get allItems {
    if (_box == null) return [];
    return _box!.values.toList();
  }

  List<WarrantyItem> get activeItems {
    return allItems.where((item) => !item.isArchived).toList()
      ..sort((a, b) => a.daysRemaining.compareTo(b.daysRemaining));
  }

  List<WarrantyItem> get archivedItems {
    return allItems.where((item) => item.isArchived).toList()
      ..sort((a, b) => b.purchaseDate.compareTo(a.purchaseDate)); // Newest archived first
  }

  List<WarrantyItem> get expiringSoonItems {
    return activeItems.where((item) => item.daysRemaining <= 30 && item.daysRemaining > 0).toList();
  }

  int get totalActiveCount => activeItems.length;
  int get expiringCount => expiringSoonItems.length;
  int get safeCount => activeItems.where((item) => item.daysRemaining > 30).length;

  Future<void> addWarranty(WarrantyItem item) async {
    if (_box == null) return;
    await _box!.put(item.id, item);
    
    // Schedule notifications for this warranty
    await NotificationService().scheduleWarrantyNotification(
      itemId: item.id,
      itemName: item.name,
      expiryDate: item.expiryDate,
      enabled: item.notificationsEnabled ?? true,
    );

    notifyListeners();
  }

  Future<void> deleteWarranty(String id) async {
    // Permanent delete
    if (_box == null) return;
    final item = _box!.values.firstWhere((e) => e.id == id);
     await item.delete(); // HiveObject delete
    // or _box!.delete(id);
    notifyListeners();
  }

  Future<void> toggleArchive(String id, bool archive) async {
    if (_box == null) return;
    final item = _box!.values.firstWhere((e) => e.id == id);
    item.isArchived = archive;
    await item.save();
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

  // Expose notifyListeners for external updates (e.g. from Hive objects)
  void notify() {
    notifyListeners();
  }
}

