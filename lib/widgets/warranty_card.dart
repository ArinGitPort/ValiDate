import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:flutter_lucide/flutter_lucide.dart';
import '../models/warranty_item.dart';
import '../theme/app_theme.dart';
import '../utils/category_data.dart';

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
    final isExpired = item.isExpired;
    final daysRemaining = item.daysRemaining;
    final categoryItem = CategoryData.getCategory(item.category);
    
    // Determine Status Colors & Icon
    Color statusBg;
    Color statusText;
    IconData statusIcon;
    String statusLabel;

    if (isExpired) {
      statusBg = const Color(0xFFFEF2F2); // Red-50
      statusText = const Color(0xFFB91C1C); // Red-700
      statusIcon = LucideIcons.circle_x; // Or LucideIcons.trash_2
      statusLabel = "EXPIRED";
    } else if (daysRemaining <= 30) {
      statusBg = const Color(0xFFFFF7ED); // Orange-50
      statusText = const Color(0xFFC2410C); // Orange-700
      statusIcon = LucideIcons.clock_alert;
      statusLabel = "$daysRemaining DAYS LEFT";
    } else {
      statusBg = const Color(0xFFEEF2FF); // Indigo-50
      statusText = const Color(0xFF4F46E5); // Indigo-600
      statusIcon = LucideIcons.shield_check;
      statusLabel = "$daysRemaining DAYS LEFT";
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppTheme.zinc200, width: 1),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            // Row 1: Status Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                color: statusBg,
                border: Border(bottom: BorderSide(color: statusText.withValues(alpha: 0.1))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   // Left: Category
                  Row(
                    children: [
                       Icon(categoryItem.icon, size: 14, color: statusText.withValues(alpha: 0.8)),
                       const SizedBox(width: 6),
                       Text(
                        categoryItem.label.toUpperCase(),
                        style: GoogleFonts.manrope(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: statusText.withValues(alpha: 0.8),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),

                  // Right: Status
                  Row(
                    children: [
                      if (isExpired) ...[
                        Icon(statusIcon, size: 14, color: statusText),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        statusLabel,
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: statusText,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Row 2: Content Body
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Receipt Thumbnail
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.zinc200),
                      color: AppTheme.zinc50,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: item.imagePath.isNotEmpty
                        ? Image.file(
                            File(item.imagePath),
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => const Icon(LucideIcons.image, color: AppTheme.zinc400),
                          )
                        : const Icon(LucideIcons.receipt, color: AppTheme.zinc400),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: GoogleFonts.manrope(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.zinc900,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.storeName,
                          style: GoogleFonts.manrope(
                            fontSize: 13,
                            color: AppTheme.zinc500,
                          ),
                        ),
                        if (item.serialNumber.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            "SN: ${item.serialNumber}",
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              color: AppTheme.zinc400,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  // Chevron & Popup
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                       PopupMenuButton<String>(
                        icon: const Icon(LucideIcons.ellipsis_vertical, size: 20, color: AppTheme.zinc400),
                        onSelected: (value) {
                          if (value == 'archive') {
                            onArchive?.call(context);
                          } else if (value == 'delete') {
                            onDelete?.call(context);
                          }
                        },
                        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                          PopupMenuItem<String>(
                            value: 'archive',
                            child: Row(
                              children: [
                                const Icon(LucideIcons.archive, size: 18, color: AppTheme.zinc700),
                                const SizedBox(width: 8),
                                Text(item.isArchived ? "Unarchive" : "Archive"),
                              ],
                            ),
                          ),
                          const PopupMenuItem<String>(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(LucideIcons.trash_2, size: 18, color: Colors.red),
                                SizedBox(width: 8),
                                Text("Delete", style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


}

