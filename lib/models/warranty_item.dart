import 'package:hive/hive.dart';

part 'warranty_item.g.dart';

@HiveType(typeId: 0)
class WarrantyItem extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String storeName;

  @HiveField(3)
  final DateTime purchaseDate;

  @HiveField(4)
  final int warrantyPeriodInMonths;

  @HiveField(5)
  final String serialNumber;

  @HiveField(6)
  final String category;

  @HiveField(7)
  final String imagePath;

  @HiveField(8)
  final bool isArchived;

  @HiveField(9)
  bool? notificationsEnabled;
  
  // Optional: We can still keep these for potential cloud usage or just ignore them in Hive
  List<String>? additionalDocuments;
  String? firebaseId;
  bool isSynced;
  String? remoteImageUrl;

  WarrantyItem({
    required this.id,
    required this.name,
    required this.storeName,
    required this.purchaseDate,
    required this.warrantyPeriodInMonths,
    this.serialNumber = '',
    required this.category,
    this.imagePath = '',
    this.isArchived = false,
    this.notificationsEnabled = true,
    this.additionalDocuments,
    this.firebaseId,
    this.isSynced = false,
    this.remoteImageUrl,
  });

  // Calculate expiry date
  DateTime get expiryDate {
    if (warrantyPeriodInMonths == -1) {
      // Lifetime warranty - effectively never expires
      return DateTime(9999, 12, 31); 
    }
    return purchaseDate.add(Duration(days: warrantyPeriodInMonths * 30));
  }

  // Calculate days remaining
  int get daysRemaining {
    if (isLifetime) return 9999;
    final now = DateTime.now();
    // Reset time components for accurate day calculation
    final today = DateTime(now.year, now.month, now.day);
    final expiry = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);
    return expiry.difference(today).inDays;
  }

  bool get isExpired {
    if (isLifetime) return false;
    return DateTime.now().isAfter(expiryDate);
  }

  bool get isLifetime => warrantyPeriodInMonths == -1;

  // -- Helpers for Firestore (keeping them won't hurt, but Hive handles serialization via adapter) --

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'storeName': storeName,
      'purchaseDate': purchaseDate.toIso8601String(),
      'warrantyPeriodInMonths': warrantyPeriodInMonths,
      'serialNumber': serialNumber,
      'category': category,
      'imagePath': imagePath,
      'isArchived': isArchived,
      'notificationsEnabled': notificationsEnabled,
      'additionalDocuments': additionalDocuments,
      // 'firebaseId': firebaseId, // Don't upload the ID as a field usually, but ok
      'remoteImageUrl': remoteImageUrl,
    };
  }

  factory WarrantyItem.fromMap(Map<String, dynamic> map, String id) {
    return WarrantyItem(
      id: map['id'] ?? id, // fallback
      name: map['name'] ?? '',
      storeName: map['storeName'] ?? '',
      purchaseDate: DateTime.tryParse(map['purchaseDate'] ?? '') ?? DateTime.now(),
      warrantyPeriodInMonths: map['warrantyPeriodInMonths'] ?? 0,
      serialNumber: map['serialNumber'] ?? '',
      category: map['category'] ?? '',
      imagePath: map['imagePath'] ?? '',
      isArchived: map['isArchived'] ?? false,
      notificationsEnabled: map['notificationsEnabled'],
      additionalDocuments: map['additionalDocuments'] != null ? List<String>.from(map['additionalDocuments']) : null,
      firebaseId: id,
      isSynced: true,
    );
  }
}

