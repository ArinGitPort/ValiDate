import 'package:flutter/material.dart';

import '../models/warranty_item.dart';
import '../theme/app_theme.dart';
import 'status_badge.dart';
import 'receipt_thumbnail.dart';

class WarrantyCard extends StatelessWidget {
  final WarrantyItem item;
  final VoidCallback onTap;

  const WarrantyCard({super.key, required this.item, required this.onTap});

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

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              ReceiptThumbnail(imagePath: item.imagePath, size: 60),
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
                      style: TextStyle(color: Colors.grey[400], fontSize: 13),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  StatusBadge(label: statusText, color: statusColor),
                  const SizedBox(height: 8),
                  Text(
                    days < 0 ? "${days.abs()} days ago" : "$days days left",
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
