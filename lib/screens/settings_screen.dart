import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../providers/warranty_provider.dart';
import '../services/pdf_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<WarrantyProvider>(context, listen: false);
    final pdfService = PDFService();

    return Scaffold(
      appBar: AppBar(title: const Text("Settings & Tools")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text("Data Management", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ListTile(
            tileColor: const Color(0xFF1E1E1E),
            leading: const Icon(LucideIcons.file_output),
            title: const Text("Generate Claim Report"),
            subtitle: const Text("Export PDF of all active warranties"),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            onTap: () async {
               await pdfService.previewReport(provider.activeItems);
            },
          ),
          
          const SizedBox(height: 24),
          const Text("Legal & Policy", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Consumer Act of the Philippines (RA 7394)", style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text(
                  "This Act protects the interests of the consumer, promotes his general welfare and establishes standards of conduct for business and industry. \n\nWarranties are part of your rights. Validating your claims with receipts and serial numbers is crucial.",
                  style: TextStyle(height: 1.5, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
