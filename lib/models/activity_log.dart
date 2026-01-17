import 'package:hive/hive.dart';

part 'activity_log.g.dart';

@HiveType(typeId: 1)
class ActivityLog extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String actionType; // "added", "updated", "deleted", "archived"

  @HiveField(2)
  final String description;

  @HiveField(3)
  final DateTime timestamp;

  @HiveField(4)
  final String? relatedItemId;

  ActivityLog({
    required this.id,
    required this.actionType,
    required this.description,
    required this.timestamp,
    this.relatedItemId,
  });
}
