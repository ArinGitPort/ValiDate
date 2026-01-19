class ActivityLog {
  final String id;
  final String userId;
  final String actionType;
  final String description;
  final DateTime timestamp;
  final String? relatedItemId;

  ActivityLog({
    required this.id,
    required this.userId,
    required this.actionType,
    required this.description,
    required this.timestamp,
    this.relatedItemId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'action_type': actionType,
      'description': description,
      'related_item_id': relatedItemId,
    };
  }

  factory ActivityLog.fromJson(Map<String, dynamic> json) {
    return ActivityLog(
      id: json['id'],
      userId: json['user_id'],
      actionType: json['action_type'] ?? '',
      description: json['description'] ?? '',
      timestamp: DateTime.parse(json['created_at']),
      relatedItemId: json['related_item_id'],
    );
  }
}
