import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../providers/warranty_provider.dart';
import '../widgets/page_header.dart';
import '../services/pdf_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pdfService = PDFService();

    return Scaffold(
      body: SafeArea(
        child: Consumer<WarrantyProvider>(
          builder: (context, provider, child) {
            final expiringCount = provider.expiringCount;
            
            return Column(
              children: [
                PageHeader(
                  title: "Settings",
                  notificationCount: expiringCount,
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    children: [
                      const Text("Data Management", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 16),
                      ListTile(
                        tileColor: Colors.white,
                        leading: const Icon(LucideIcons.file_output, color: Colors.black),
                        title: const Text("Generate Claim Report"),
                        subtitle: const Text("Export PDF of all active warranties"),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                        onTap: () async {
                           await pdfService.previewReport(provider.activeItems);
                        },
                      ),
                      
                      const SizedBox(height: 32),
                      const Text("Legal & Policy", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Consumer Act of the Philippines (RA 7394)", style: TextStyle(fontWeight: FontWeight.bold)),
                            SizedBox(height: 16),
                            Text(
                              "This Act protects the interests of the consumer, promotes his general welfare and establishes standards of conduct for business and industry. \n\nWarranties are part of your rights. Validating your claims with receipts and serial numbers is crucial.",
                              style: TextStyle(height: 1.6, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
