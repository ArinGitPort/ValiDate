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
  bool isArchived;

  WarrantyItem({
    required this.id,
    required this.name,
    required this.storeName,
    required this.purchaseDate,
    required this.warrantyPeriodInMonths,
    required this.serialNumber,
    required this.category,
    required this.imagePath,
    this.isArchived = false,
  });

  DateTime get expiryDate {
    // Basic calculation: add months. 
    // Note: This logic adds 30 days * months or uses calendar months?
    // Dart's standard DateTime add/subtract logic:
    // Adding months directly isn't built-in perfectly, but mostly:
    // date.copyWith(month: date.month + months) handles year rollover automatically.
    // However, clean way:
    return DateTime(
      purchaseDate.year,
      purchaseDate.month + warrantyPeriodInMonths,
      purchaseDate.day,
    );
  }

  int get daysRemaining {
    final now = DateTime.now();
    // Reset time components for accurate day diff
    final today = DateTime(now.year, now.month, now.day);
    final expiry = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);
    return expiry.difference(today).inDays;
  }
}
