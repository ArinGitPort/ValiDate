class WarrantyItem {
  final String id;
  final String userId;
  final String name;
  final String storeName;
  final DateTime purchaseDate;
  final int warrantyPeriodInMonths;
  final String serialNumber;
  final String category;
  final List<String> additionalDocuments;
  final String? imageUrl;
  final bool isArchived;
  final bool notificationsEnabled;
  final DateTime createdAt;

  WarrantyItem({
    required this.id,
    required this.userId,
    required this.name,
    required this.storeName,
    required this.purchaseDate,
    required this.warrantyPeriodInMonths,
    this.serialNumber = '',
    required this.category,
    this.imageUrl,
    this.additionalDocuments = const [],
    this.isArchived = false,
    this.notificationsEnabled = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // Calculate expiry date
  DateTime get expiryDate {
    if (warrantyPeriodInMonths == -1) {
      return DateTime(9999, 12, 31); // Lifetime
    }
    return purchaseDate.add(Duration(days: warrantyPeriodInMonths * 30));
  }

  // Calculate days remaining
  int get daysRemaining {
    if (isLifetime) return 9999;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiry = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);
    return expiry.difference(today).inDays;
  }

  bool get isExpired {
    if (isLifetime) return false;
    return DateTime.now().isAfter(expiryDate);
  }

  bool get isLifetime => warrantyPeriodInMonths == -1;

  // Backward compatibility getter for UI components
  String get imagePath => imageUrl ?? '';
  
  // Supabase JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'store_name': storeName,
      'purchase_date': purchaseDate.toIso8601String(),
      'warranty_period_months': warrantyPeriodInMonths,
      'serial_number': serialNumber,
      'category': category,
      'image_url': imageUrl,
      'is_archived': isArchived,
      'notifications_enabled': notificationsEnabled,
    };
  }

  factory WarrantyItem.fromJson(Map<String, dynamic> json) {
    // Extract documents if available
    List<String> docs = [];
    if (json['warranty_documents'] != null) {
      final docList = json['warranty_documents'] as List;
      docs = docList.map((d) => d['document_url'] as String).toList();
    }

    return WarrantyItem(
      id: json['id'],
      userId: json['user_id'],
      name: json['name'] ?? '',
      storeName: json['store_name'] ?? '',
      purchaseDate: DateTime.parse(json['purchase_date']),
      warrantyPeriodInMonths: json['warranty_period_months'] ?? 0,
      serialNumber: json['serial_number'] ?? '',
      category: json['category'] ?? '',
      imageUrl: json['image_url'],
      additionalDocuments: docs,
      isArchived: json['is_archived'] ?? false,
      notificationsEnabled: json['notifications_enabled'] ?? true,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    );
  }

  WarrantyItem copyWith({
    String? id,
    String? userId,
    String? name,
    String? storeName,
    DateTime? purchaseDate,
    int? warrantyPeriodInMonths,
    String? serialNumber,
    String? category,
    String? imageUrl,
    List<String>? additionalDocuments,
    bool? isArchived,
    bool? notificationsEnabled,
  }) {
    return WarrantyItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      storeName: storeName ?? this.storeName,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      warrantyPeriodInMonths: warrantyPeriodInMonths ?? this.warrantyPeriodInMonths,
      serialNumber: serialNumber ?? this.serialNumber,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      additionalDocuments: additionalDocuments ?? this.additionalDocuments,
      isArchived: isArchived ?? this.isArchived,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      createdAt: createdAt,
    );
  }
}

