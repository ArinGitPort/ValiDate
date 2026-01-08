import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../models/warranty_item.dart';
import '../theme/app_theme.dart';
import 'status_badge.dart';
import 'receipt_thumbnail.dart';

class WarrantyCard extends StatelessWidget {
  final WarrantyItem item;
  final VoidCallback onTap;
  final Function(BuildContext)? onArchive;
  final Function(BuildContext)? onDelete;

  const WarrantyCard({
    super.key, 
    required this.item, 
    required this.onTap,
    this.onArchive,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final days = item.daysRemaining;
    Color statusColor = AppTheme.statusSafe;
    String statusText = "Safe";

    if (days < 0) {
      statusColor = AppTheme.statusExpired;
      statusText = "Expired";
    } else if (days <= 30) {
      statusColor = AppTheme.statusWarning;
      statusText = "Expiring Soon";
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Slidable(
        key: Key(item.id),
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          children: [
            if (onArchive != null)
              SlidableAction(
                onPressed: onArchive,
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                icon: LucideIcons.archive,
                label: 'Archive',
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
              ),
            if (onDelete != null)
              SlidableAction(
                onPressed: onDelete,
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                icon: LucideIcons.trash_2,
                label: 'Delete',
                borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
              ),
          ],
        ),
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade300),
            ),
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Hero(
                  tag: 'img_${item.id}',
                  child: ReceiptThumbnail(imagePath: item.imagePath, size: 60),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.storeName,
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                      Text(
                        item.serialNumber, 
                        style: TextStyle(color: Colors.grey[400], fontSize: 11, fontFamily: 'Courier'),
                      ),
                    ],
                  ),
                ),
                StatusBadge(label: statusText, color: statusColor),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
