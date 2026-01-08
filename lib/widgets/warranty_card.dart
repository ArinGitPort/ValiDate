import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Badges Row
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item.category.toUpperCase(), // Assuming category exists, fallback to "OTHER" if needed
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        days < 0 
                          ? "EXPIRED" 
                          : "$days DAYS LEFT",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
               const Divider(height: 1, color: Color(0xFFEEEEEE)),
              // Main Content
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Hero(
                      tag: 'img_${item.id}',
                      child: ReceiptThumbnail(imagePath: item.imagePath, size: 70), // Slightly larger image
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                             crossAxisAlignment: CrossAxisAlignment.start,
                             children: [
                               Expanded(
                                 child: Text(
                                  item.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold, 
                                    fontSize: 16,
                                    height: 1.2
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                 ),
                               ),
                                // Menu Dots
                                SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: PopupMenuButton<String>(
                                    padding: EdgeInsets.zero,
                                    icon: const Icon(LucideIcons.ellipsis_vertical, size: 20, color: Colors.grey),
                                    onSelected: (value) {
                                      if (value == 'archive' && onArchive != null) {
                                        onArchive!(context);
                                      } else if (value == 'delete' && onDelete != null) {
                                        onDelete!(context);
                                      }
                                    },
                                    itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                                      if (onArchive != null)
                                        const PopupMenuItem<String>(
                                          value: 'archive',
                                          child: Row(
                                            children: [
                                              Icon(LucideIcons.archive, size: 18),
                                              SizedBox(width: 8),
                                              Text('Archive'),
                                            ],
                                          ),
                                        ),
                                      if (onDelete != null)
                                        const PopupMenuItem<String>(
                                          value: 'delete',
                                          child: Row(
                                            children: [
                                              Icon(LucideIcons.trash_2, size: 18, color: Colors.red),
                                              SizedBox(width: 8),
                                              Text('Delete', style: TextStyle(color: Colors.red)),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                             ]
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.storeName,
                            style: TextStyle(color: Colors.grey[600], fontSize: 13),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Expired On ${item.expiryDate.day} ${_getMonthName(item.expiryDate.month)} ${item.expiryDate.year}",
                            style: TextStyle(color: Colors.grey[400], fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      "Jan", "Feb", "Mar", "Apr", "May", "Jun", 
      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
    ];
    return months[month - 1];
  }
}

