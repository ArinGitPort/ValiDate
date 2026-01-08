import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:intl/intl.dart';
import '../providers/warranty_provider.dart';
import '../widgets/receipt_thumbnail.dart';
import '../widgets/status_badge.dart';

class DetailsScreen extends StatelessWidget {
  final String itemId;

  const DetailsScreen({super.key, required this.itemId});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<WarrantyProvider>(context);
    // Find item safely
    final item = provider.allItems.cast<dynamic>().firstWhere((e) => e.id == itemId, orElse: () => null);

    if (item == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text("Item not found")),
      );
    }

    final days = item.daysRemaining;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(item.name),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.trash_2),
            onPressed: () {
               // Archive confirmation
               showDialog(
                 context: context, 
                 builder: (ctx) => AlertDialog(
                   title: const Text("Archive Warranty?"),
                   content: const Text("This will move the item to the archive folder."),
                   actions: [
                     TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
                     TextButton(
                       onPressed: () {
                         provider.toggleArchive(item.id, true);
                         Navigator.pop(ctx); // Close dialog
                         Navigator.pop(context); // Go back to dashboard
                       }, 
                       child: const Text("Archive", style: TextStyle(color: Colors.red)),
                     ),
                   ],
                 )
               );
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Stats
            Container(
              color: Colors.grey[900],
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    days < 0 ? "${days.abs()}" : "$days",
                    style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    days < 0 ? "Days Ago" : "Days Left",
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  StatusBadge(
                    label: days < 0 ? "EXPIRED" : (days <= 30 ? "EXPIRING SOON" : "ACTIVE"),
                    color: days < 0 ? Colors.red : (days <= 30 ? Colors.orange : Colors.green),
                  ),
                ],
              ),
            ),
            
            // Receipt
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Evidence", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) => Dialog(
                          child: InteractiveViewer(
                            child: ReceiptThumbnail(imagePath: item.imagePath, size: 400),
                          ),
                        ),
                      );
                    },
                    child: Hero(
                      tag: 'receipt_${item.id}',
                      child: Container(
                        height: 250,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[900],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ReceiptThumbnail(imagePath: item.imagePath, size: 250),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Details
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildDetailRow("Store", item.storeName),
                  _buildDetailRow("Purchase Date", DateFormat('yyyy-MM-dd').format(item.purchaseDate)),
                  _buildDetailRow("Serial Number", item.serialNumber),
                  _buildDetailRow("Warranty Period", "${item.warrantyPeriodInMonths} Months"),
                  _buildDetailRow("Expiry Date", DateFormat('yyyy-MM-dd').format(item.expiryDate)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
