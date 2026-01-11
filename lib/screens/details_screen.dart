import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:intl/intl.dart';
import '../providers/warranty_provider.dart';
import '../widgets/receipt_thumbnail.dart';
import '../theme/app_theme.dart';
import '../utils/category_data.dart';
import 'capture_screen.dart';


class DetailsScreen extends StatelessWidget {
  final String itemId;

  const DetailsScreen({super.key, required this.itemId});

  @override
  Widget build(BuildContext context) {
    // Listen to provider to handle deletions (pop if missing)
    final provider = Provider.of<WarrantyProvider>(context);
    final item = provider.allItems.cast<dynamic>().firstWhere((e) => e.id == itemId, orElse: () => null);

    if (item == null) {
      // Handle item deletion gracefully
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Navigator.canPop(context)) Navigator.pop(context);
      });
      return const Scaffold(body: SizedBox()); // Empty while popping
    }

    final days = item.daysRemaining;
    
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrow_left, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Warranty Details'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               // Header Image (Matching CaptureScreen style)
              SizedBox(
                height: 250,
                width: double.infinity,
                child: GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => Dialog(
                        backgroundColor: Colors.black,
                        child: Stack(
                          children: [
                            InteractiveViewer(
                              minScale: 0.5,
                              maxScale: 4.0,
                              child: Center(
                                child: Image.file(
                                  File(item.imagePath),
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 16,
                              right: 16,
                              child: IconButton(
                                icon: const Icon(LucideIcons.x, color: AppTheme.white),
                                onPressed: () => Navigator.pop(context),
                                style: IconButton.styleFrom(
                                  backgroundColor: AppTheme.primaryDark.withValues(alpha: 0.5),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Hero(
                        tag: 'img_${item.id}',
                        child: Image.file(
                          File(item.imagePath), 
                          fit: BoxFit.cover,
                          errorBuilder: (c,e,s) => Container(
                            color: AppTheme.zinc100, 
                            child: const Icon(LucideIcons.image, size: 48, color: AppTheme.zinc400)
                          ),
                        ),
                      ),
                      
                      // Gradient Overlay
                      Positioned(
                        bottom: 0, left: 0, right: 0,
                        child: Container(
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, AppTheme.primaryDark.withValues(alpha: 0.7)],
                            ),
                          ),
                        ),
                      ),
                      
                      // Item Name on Overlay
                      Positioned(
                        bottom: 16,
                        left: 16,
                        right: 16,
                        child: Text(
                          item.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Count Down
                    Text(
                      days < 0 ? "${days.abs()} DAYS AGO" : "$days DAYS LEFT",
                      style: Theme.of(context).textTheme.displayLarge,
                    ),
                    const SizedBox(height: 8),
                     Text(
                      days < 0 ? "Expired on ${DateFormat('MMMM dd, yyyy').format(item.expiryDate)}" 
                              : "Expires on ${DateFormat('MMMM dd, yyyy').format(item.expiryDate)}",
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 14),
                    ),
                    

                    const SizedBox(height: 32),
                    
                    _buildDetailRow(context, CategoryData.getCategory(item.category).icon, "Category", CategoryData.getCategory(item.category).label),
                    _buildDetailRow(context, LucideIcons.store, "Store", item.storeName),
                    _buildDetailRow(context, LucideIcons.calendar, "Purchased", DateFormat('yyyy-MM-dd').format(item.purchaseDate)),
                    _buildDetailRow(context, LucideIcons.hash, "Serial", item.serialNumber),
                    _buildDetailRow(context, LucideIcons.clock, "Term", "${item.warrantyPeriodInMonths} Months"),
                    
                    const SizedBox(height: 32),
                    
                    // Additional Documents Viewer
                    if (item.additionalDocuments?.isNotEmpty ?? false) ...[
                      Row(
                        children: [
                          const Text(
                            "Your Documents",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryDark,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(child: Divider(color: AppTheme.dividerColor)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 120,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: item.additionalDocuments?.length ?? 0,
                          separatorBuilder: (c, i) => const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final path = item.additionalDocuments![index];
                            return GestureDetector(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => Dialog(
                                    backgroundColor: Colors.black,
                                    child: Stack(
                                      children: [
                                        InteractiveViewer(
                                          minScale: 0.5,
                                          maxScale: 4.0,
                                          child: Center(
                                            child: Image.file(
                                              File(path),
                                              fit: BoxFit.contain,
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          top: 16,
                                          right: 16,
                                          child: IconButton(
                                            icon: const Icon(LucideIcons.x, color: AppTheme.white),
                                            onPressed: () => Navigator.pop(context),
                                            style: IconButton.styleFrom(
                                              backgroundColor: AppTheme.primaryDark.withValues(alpha: 0.5),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                width: 120,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppTheme.dividerColor),
                                  image: DecorationImage(
                                    image: FileImage(File(path)),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                    
                    // Notification Toggle
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.inputFill,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Notification',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.primaryDark,
                            ),
                          ),
                          Switch(
                            value: item.notificationsEnabled ?? true,
                            onChanged: (value) {
                              item.notificationsEnabled = value;
                              item.save();
                              provider.notify();
                            },
                            activeTrackColor: AppTheme.primaryBrand,
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 48),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(LucideIcons.pencil),
                            label: const Text("Edit"),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => CaptureScreen(item: item)),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              foregroundColor: AppTheme.primaryDark,
                              side: const BorderSide(color: AppTheme.dividerColor),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextButton.icon(
                            icon: const Icon(LucideIcons.trash_2, color: AppTheme.statusExpiredText),
                            label: const Text("Delete", style: TextStyle(color: AppTheme.statusExpiredText)),
                             onPressed: () {
                               showDialog(
                                 context: context, 
                                 builder: (ctx) => AlertDialog(
                                   title: const Text("Delete Permanently?"),
                                   actions: [
                                     TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel", style: TextStyle(color: AppTheme.secondaryText))),
                                     TextButton(
                                       onPressed: () {
                                         provider.deleteWarranty(item.id);
                                         Navigator.pop(ctx);
                                       // Navigation handled by build method check or pop here
                                       }, 
                                       child: const Text("Delete", style: TextStyle(color: AppTheme.statusExpiredText)),
                                     ),
                                   ],
                                 )
                               );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.secondaryText),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.secondaryText, letterSpacing: 1.2)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
