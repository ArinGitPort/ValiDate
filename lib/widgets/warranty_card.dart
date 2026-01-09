import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:flutter_lucide/flutter_lucide.dart';
import '../models/warranty_item.dart';
import '../theme/app_theme.dart';
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
    
    // Badge Logic
    Color badgeBg = AppTheme.statusSafeBg;
    Color badgeText = AppTheme.statusSafeText;
    String statusLabel = days == 1 ? "1 DAY LEFT" : "$days DAYS LEFT";

    if (days < 0) {
      badgeBg = AppTheme.statusExpiredBg;
      badgeText = AppTheme.statusExpiredText;
      statusLabel = "EXPIRED";
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
            border: Border.all(color: AppTheme.zinc200), // Zinc-200 Border
            // No Shadow
          ),
          padding: const EdgeInsets.all(12), // Uniform padding
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.zinc200), // Thumbnail Border
                ),
                child: Hero(
                  tag: 'img_${item.id}',
                  child: ClipRRect(
                     borderRadius: BorderRadius.circular(12),
                     child: ReceiptThumbnail(imagePath: item.imagePath, size: 70)
                  ),
                ),
              ),
              const SizedBox(width: 16),
              
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title & Menu
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
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
                            icon: const Icon(LucideIcons.ellipsis_vertical, size: 16, color: AppTheme.zinc400),
                            onSelected: (value) {
                              if (value == 'archive' && onArchive != null) {
                                onArchive!(context);
                              } else if (value == 'delete' && onDelete != null) {
                                onDelete!(context);
                              }
                            },
                            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                              if (onArchive != null)
                                PopupMenuItem<String>(
                                  value: 'archive',
                                  child: Row(
                                    children: [
                                      const Icon(LucideIcons.archive, size: 18),
                                      const SizedBox(width: 8),
                                      Text('Archive', style: GoogleFonts.manrope()),
                                    ],
                                  ),
                                ),
                              if (onDelete != null)
                                PopupMenuItem<String>(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      const Icon(LucideIcons.trash_2, size: 18, color: Colors.red),
                                      const SizedBox(width: 8),
                                      Text('Delete', style: GoogleFonts.manrope(color: Colors.red)),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 4),
                    Text(
                      item.storeName,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    const SizedBox(height: 12),
                    
                    // Badges Row
                    Row(
                      children: [
                        // Category Badge (Black/White)
                        /*
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.zinc900,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            item.category.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ), 
                        const SizedBox(width: 8),
                        */
                        
                        // Status Badge (Subtle Tint)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: badgeBg,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: badgeText.withValues(alpha: 0.2)),
                          ),
                          child: Text(
                            statusLabel,
                            style: TextStyle(
                              color: badgeText,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
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


}

