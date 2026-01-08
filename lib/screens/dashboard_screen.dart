import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../providers/warranty_provider.dart';
import '../widgets/warranty_card.dart';
import 'capture_screen.dart';
import 'details_screen.dart';
import 'archive_screen.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("ValiDate"),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.archive),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ArchiveScreen())),
          ),
          IconButton(
            icon: const Icon(LucideIcons.settings),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
      body: Consumer<WarrantyProvider>(
        builder: (context, provider, child) {
          if (!provider.isInitialized) {
            return const Center(child: CircularProgressIndicator());
          }

          final activeItems = provider.searchActive(_searchQuery);
          final safeCount = provider.safeCount;
          final expiringCount = provider.expiringCount;
          final totalCount = provider.totalActiveCount;

          return Column(
            children: [
              // Status Summary
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    _buildStatusCard("Active", totalCount.toString(), Colors.blue),
                    const SizedBox(width: 8),
                    _buildStatusCard("Expiring", expiringCount.toString(), Colors.orange),
                    const SizedBox(width: 8),
                    _buildStatusCard("Safe", safeCount.toString(), Colors.green),
                  ],
                ),
              ),
              
              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TextField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(LucideIcons.search),
                    hintText: "Search items...",
                  ),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                ),
              ),
              
              const SizedBox(height: 16),

              // List
              Expanded(
                child: activeItems.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(LucideIcons.box, size: 64, color: Colors.grey),
                            const SizedBox(height: 16),
                            Text("No active warranties found", style: TextStyle(color: Colors.grey[600])),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: activeItems.length,
                        itemBuilder: (context, index) {
                          final item = activeItems[index];
                          return WarrantyCard(
                            item: item,
                            onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => DetailsScreen(itemId: item.id),
                                  ),
                                );
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const CaptureScreen()));
        },
        label: const Text("Add Item"),
        icon: const Icon(LucideIcons.plus),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
    );
  }

  Widget _buildStatusCard(String label, String count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(8),
          border: Border(left: BorderSide(color: color, width: 4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(count, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
