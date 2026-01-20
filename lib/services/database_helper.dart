import 'dart:async';
import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/warranty_item.dart';
import '../models/activity_log.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('warranty.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE warranties ADD COLUMN local_image_path TEXT');
    }
  }

  Future<void> _createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const textNullable = 'TEXT';
    const boolType = 'INTEGER NOT NULL'; // 0 or 1
    const integerType = 'INTEGER NOT NULL';
    const timestampType = 'TEXT NOT NULL'; // ISO8601 string

    // Warranties Table
    await db.execute('''
CREATE TABLE warranties (
  id $idType,
  user_id $textType,
  name $textType,
  store_name $textNullable,
  purchase_date $timestampType,
  warranty_period_months $integerType,
  serial_number $textNullable,
  category $textType,
  image_url $textNullable,
  local_image_path $textNullable,
  is_archived $boolType,
  notifications_enabled $boolType,
  created_at $textNullable,
  is_dirty $boolType DEFAULT 0
)
    ''');
// ... (rest of createDB)

// ...

  Map<String, dynamic> _warrantyToMap(WarrantyItem item) {
    return {
      'id': item.id,
      'user_id': item.userId,
      'name': item.name,
      'store_name': item.storeName,
      'purchase_date': item.purchaseDate.toIso8601String(),
      'warranty_period_months': item.warrantyPeriodInMonths,
      'serial_number': item.serialNumber,
      'category': item.category,
      'image_url': item.imageUrl,
      'local_image_path': item.localImagePath,
      'is_archived': item.isArchived ? 1 : 0,
      'notifications_enabled': item.notificationsEnabled ? 1 : 0,
      'created_at': item.createdAt?.toIso8601String(),
    };
  }

  WarrantyItem _mapToWarranty(Map<String, dynamic> map, List<String> docs) {
    return WarrantyItem(
      id: map['id'],
      userId: map['user_id'],
      name: map['name'],
      storeName: map['store_name'],
      purchaseDate: DateTime.parse(map['purchase_date']),
      warrantyPeriodInMonths: map['warranty_period_months'],
      serialNumber: map['serial_number'] ?? '',
      category: map['category'],
      imageUrl: map['image_url'],
      localImagePath: map['local_image_path'],
      additionalDocuments: docs,
      isArchived: (map['is_archived'] as int) == 1,
      notificationsEnabled: (map['notifications_enabled'] as int) == 1,
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
      isDirty: (map['is_dirty'] as int) == 1,
    );
  }

    // Activity Logs Table
    await db.execute('''
CREATE TABLE activity_logs (
  id $idType,
  user_id $textType,
  action_type $textType,
  description $textType,
  related_item_id $textNullable,
  timestamp $timestampType
)
    ''');

    // Warranty Documents Table
    await db.execute('''
CREATE TABLE warranty_documents (
  id TEXT PRIMARY KEY, 
  warranty_id $textType,
  document_url $textType
)
    ''');

    // Sync Queue Table
    await db.execute('''
CREATE TABLE sync_queue (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  action $textType,
  table_name $textType,
  payload $textType,
  created_at $timestampType
)
    ''');
  }

  // --- Sync Queue Operations ---
  
  Future<int> addToSyncQueue(String action, String tableName, Map<String, dynamic> payload) async {
    final db = await database;
    return await db.insert('sync_queue', {
      'action': action,
      'table_name': tableName,
      'payload': jsonEncode(payload),
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getSyncQueue() async {
    final db = await database;
    return await db.query('sync_queue', orderBy: 'created_at ASC');
  }

  Future<void> removeFromSyncQueue(int id) async {
    final db = await database;
    await db.delete('sync_queue', where: 'id = ?', whereArgs: [id]);
  }

  // --- Generic CRUD Wrappers (simplified) ---

  Future<void> insertWarranty(WarrantyItem item, {bool isDirty = false}) async {
    final db = await database;
    final json = item.toJson();
    // Convert DateTime to String and bool to int for SQLite
    // Note: WarrantyItem.toJson already returns suitable primitives for JSON, 
    // but SQLite needs 0/1 for bools if we defined them as INTEGER.
    // However, toJson often keeps bools as bools.
    
    final map = _warrantyToMap(item);
    map['is_dirty'] = isDirty ? 1 : 0;
    
    await db.insert('warranties', map, conflictAlgorithm: ConflictAlgorithm.replace);
  }
  
  Future<void> insertLog(ActivityLog log) async {
    final db = await database;
    await db.insert('activity_logs', _logToMap(log), conflictAlgorithm: ConflictAlgorithm.replace);
  }
  
  Future<void> insertDocument(String warrantyId, String url) async {
    final db = await database;
    await db.insert('warranty_documents', {
      'id': '${warrantyId}_${url.hashCode}', // Simple composite ID or just random
      'warranty_id': warrantyId,
      'document_url': url
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<WarrantyItem>> getAllWarranties(String userId) async {
    final db = await database;
    final result = await db.query('warranties', where: 'user_id = ?', whereArgs: [userId]);
    
    List<WarrantyItem> items = [];
    for (var map in result) {
      // Get documents for this warranty
      final docsResult = await db.query('warranty_documents', where: 'warranty_id = ?', whereArgs: [map['id']]);
      final docs = docsResult.map((e) => e['document_url'] as String).toList();
      
      items.add(_mapToWarranty(map, docs));
    }
    return items;
  }
  
  Future<List<ActivityLog>> getLogs(String userId) async {
    final db = await database;
    final result = await db.query('activity_logs', 
      where: 'user_id = ?', 
      whereArgs: [userId],
      orderBy: 'timestamp DESC'
    );
    return result.map((map) => _mapToLog(map)).toList();
  }
  
  Future<void> deleteWarranty(String id) async {
    final db = await database;
    await db.delete('warranties', where: 'id = ?', whereArgs: [id]);
    await db.delete('warranty_documents', where: 'warranty_id = ?', whereArgs: [id]);
  }
  
  Future<void> clearAll(String userId) async {
    final db = await database;
    await db.delete('warranties', where: 'user_id = ?', whereArgs: [userId]);
    await db.delete('activity_logs', where: 'user_id = ?', whereArgs: [userId]);
    // Note: documents deletion handled by cascade usually, or manual:
    // Ideally we select IDs first or just clear everything if single user local app.
    // For now assuming we might clear exclusively by user.
    // Since document table doesn't have user_id, detailed implementation would fetch IDs first.
    // Simplified:
    // await db.delete('warranty_documents'); 
  }

  // --- Helpers for Map <-> Object conversions for SQLite ---
  
  Map<String, dynamic> _warrantyToMap(WarrantyItem item) {
    return {
      'id': item.id,
      'user_id': item.userId,
      'name': item.name,
      'store_name': item.storeName,
      'purchase_date': item.purchaseDate.toIso8601String(),
      'warranty_period_months': item.warrantyPeriodInMonths,
      'serial_number': item.serialNumber,
      'category': item.category,
      'image_url': item.imageUrl,
      'local_image_path': item.localImagePath,
      'is_archived': item.isArchived ? 1 : 0,
      'notifications_enabled': item.notificationsEnabled ? 1 : 0,
      'created_at': item.createdAt?.toIso8601String(),
    };
  }

  WarrantyItem _mapToWarranty(Map<String, dynamic> map, List<String> docs) {
    return WarrantyItem(
      id: map['id'],
      userId: map['user_id'],
      name: map['name'],
      storeName: map['store_name'],
      purchaseDate: DateTime.parse(map['purchase_date']),
      warrantyPeriodInMonths: map['warranty_period_months'],
      serialNumber: map['serial_number'] ?? '',
      category: map['category'],
      imageUrl: map['image_url'],
      localImagePath: map['local_image_path'],
      additionalDocuments: docs,
      isArchived: (map['is_archived'] as int) == 1,
      notificationsEnabled: (map['notifications_enabled'] as int) == 1,
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
      isDirty: (map['is_dirty'] as int) == 1,
    );
  }
  
  Map<String, dynamic> _logToMap(ActivityLog log) {
    return {
      'id': log.id,
      'user_id': log.userId,
      'action_type': log.actionType,
      'description': log.description,
      'related_item_id': log.relatedItemId,
      'timestamp': log.timestamp.toIso8601String(),
    };
  }
  
  ActivityLog _mapToLog(Map<String, dynamic> map) {
    return ActivityLog(
      id: map['id'],
      userId: map['user_id'],
      actionType: map['action_type'],
      description: map['description'],
      timestamp: DateTime.parse(map['timestamp']),
      relatedItemId: map['related_item_id'],
    );
  }
}
