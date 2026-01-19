import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:path_provider/path_provider.dart';
import '../providers/warranty_provider.dart';
import '../widgets/page_header.dart';
import '../services/pdf_service.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pdfService = PDFService();

    return Scaffold(
      body: SafeArea(
        child: Consumer<WarrantyProvider>(
          builder: (context, provider, child) {
            return Column(
              children: [
                const PageHeader(
                  title: "Settings",
                  notificationCount: 0,
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    children: [
                      const SizedBox(height: 24),
                      _buildSectionHeader("Data & Compliance"),
                      _buildSettingsTile(
                        context,
                        icon: LucideIcons.file_output,
                        title: "Export Claim Report (PDF)",
                        subtitle: "Generate compliance document",
                        onTap: () async {
                           await pdfService.previewReport(provider.activeItems);
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildSettingsTile(
                        context,
                        icon: LucideIcons.database_backup,
                        title: "Backup / Restore",
                        subtitle: "Save your data safely",
                        onTap: () => _showBackupDialog(context, provider),
                      ),

                      const SizedBox(height: 32),
                      _buildSectionHeader("Storage Management"),
                      FutureBuilder<String>(
                        future: provider.storageUsage,
                        builder: (context, snapshot) {
                          return _buildInfoTile(
                            icon: LucideIcons.hard_drive,
                            title: "Storage Usage",
                            value: snapshot.data ?? "Calculating...",
                          );
                        }
                      ),
                      const SizedBox(height: 12),
                      _buildSettingsTile(
                        context,
                        icon: LucideIcons.trash_2,
                        title: "Clean Up Expired",
                        subtitle: "Delete items with 0 days left",
                        color: Colors.red,
                        onTap: () => _confirmCleanup(context, provider),
                      ),

                      const SizedBox(height: 32),
                      _buildSectionHeader("Preferences"),
                      _buildSwitchTile(
                        context,
                        title: "Notifications",
                        subtitle: "Expiry alerts (7 days prior)",
                        value: true, // Need to implement persistence for this later
                        onChanged: (val) {
                          // Todo: save preference
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Notifications updated")));
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildSettingsTile(
                        context,
                        icon: LucideIcons.arrow_up_down,
                        title: "Sort Order",
                        subtitle: provider.sortOrder == 'expiring_soon' ? "Expiring Soonest" : "Purchase Date",
                        onTap: () => _showSortDialog(context, provider),
                      ),

                      const SizedBox(height: 32),
                      _buildSectionHeader("Legal & About"),
                      _buildSettingsTile(
                        context,
                        icon: LucideIcons.scale,
                        title: "Know Your Rights (RA 7394)",
                        subtitle: "Consumer Act of the Philippines",
                        onTap: () => _showLegalDialog(context),
                      ),
                      
                      const SizedBox(height: 32),
                      _buildSectionHeader("Account"),
                      _buildInfoTile(
                         icon: LucideIcons.user,
                         title: "Email",
                         value: Supabase.instance.client.auth.currentUser?.email ?? "Not logged in",
                      ),

                      const SizedBox(height: 32),
                      _buildSectionHeader("Danger Zone"),
                      _buildSettingsTile(
                        context,
                        icon: LucideIcons.skull,
                        title: "Reset Account Data",
                        subtitle: "Permanently delete all local data",
                        color: Colors.red,
                        onTap: () => _confirmResetAccount(context, provider),
                      ),
                      
                      const SizedBox(height: 12),
                      _buildSettingsTile(
                        context,
                        icon: LucideIcons.log_out,
                        title: "Sign Out",
                        subtitle: "Log out of your account",
                        color: Colors.red,
                        onTap: () async {
                           await _handleSignOut(context);
                        },
                      ),

                      const SizedBox(height: 50),
                      Center(
                        child: Text(
                          "ValiDate v1.0.0",
                          style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                        ),
                      ),
                      const SizedBox(height: 50),
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

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: Colors.grey,
          fontWeight: FontWeight.bold,
          fontSize: 12,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingsTile(BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color color = Colors.black,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
        trailing: const Icon(LucideIcons.chevron_right, size: 16, color: Colors.grey),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.blue, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        trailing: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
      ),
    );
  }

  Widget _buildSwitchTile(BuildContext context, {
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
   return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: SwitchListTile(
        activeTrackColor: Colors.blue,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
        value: value,
        onChanged: onChanged,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  void _showSortDialog(BuildContext context, WarrantyProvider provider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Sort By", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ListTile(
              title: const Text("Expiring Soonest"),
              trailing: provider.sortOrder == 'expiring_soon' ? const Icon(LucideIcons.check, color: Colors.blue) : null,
              onTap: () {
                provider.setSortOrder('expiring_soon');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text("Purchase Date (Newest)"),
              trailing: provider.sortOrder == 'purchase_date' ? const Icon(LucideIcons.check, color: Colors.blue) : null,
              onTap: () {
                provider.setSortOrder('purchase_date');
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmCleanup(BuildContext context, WarrantyProvider provider) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Clean Up Expired"),
        content: const Text("Are you sure you want to permanently delete all items that have expired?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
               await provider.cleanUpExpired();
               if (context.mounted) {
                 Navigator.pop(context);
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cleanup complete")));
               }
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
  
  void _showLegalDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        expand: false,
        builder: (_, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.all(24),
          children: [
             Center(child: Container(width: 40, height: 4, color: Colors.grey)),
             SizedBox(height: 24),
             Text("Consumer Act of the Philippines (RA 7394)", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
             SizedBox(height: 16),
             Text(
               "Article 68. Additional Provisions on Warranties.\n\nIn addition to the Civil Code provisions on sale with warranties, the following provisions shall govern the sale of consumer products with warranties:\n\na) Terms of express warranty. — Any seller or manufacturer who gives an express warranty shall:\n1) Set forth the terms of warranty in clear and readily understandable language and clearly identify himself as the warrantor;\n2) Identify the party to whom the warranty is extended;\n3) State the products or parts covered;\n4) State what the warrantor will do in the event of a defect, malfunction or failure to conform to such written warranty and at whose expense;\n5) State what the consumer must do to avail of the rights which accrue to the warranty;\n6) Stipulate the period within which, after notice of defect, malfunction or failure to conform to the warranty, the warrantor will perform any obligation under the warranty.\n\nb) Express warranty — operative from moment of sale. — All written warranties or guarantees issued by a manufacturer, producer, or importer shall be operative from the moment of sale.",
               style: TextStyle(height: 1.6, color: Colors.black87),
             ),
          ],
        ),
      ),
    );
  }

  void _showBackupDialog(BuildContext context, WarrantyProvider provider) {
      // Mock Backup Functionality using JSON export (Write to File)
      showDialog(
         context: context, 
         builder: (_) => AlertDialog(
           title: const Text("Backup"),
           content: const Text("Backup functionality saves your data to a local JSON file."),
           actions: [
             TextButton(
               onPressed: () async {
                  await _performBackup(context, provider);
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
               }, 
               child: const Text("Export JSON")
             ),
             TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close")),
           ],
         )
      );
  }

  Future<void> _performBackup(BuildContext context, WarrantyProvider provider) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/validate_backup.json');
      
      // Serialize all items
      final List<Map<String, dynamic>> data = provider.allItems.map((e) => {
        'id': e.id,
        'name': e.name,
        'store': e.storeName,
        'purchaseDate': e.purchaseDate.toIso8601String(),
        'warrantyMonths': e.warrantyPeriodInMonths,
        'serial': e.serialNumber,
        'category': e.category,
      }).toList();

      await file.writeAsString(jsonEncode(data));
      
      if (context.mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Backup saved to ${file.path}")));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Backup failed: $e")));
      }
    }
  }
  Future<void> _handleSignOut(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Sign Out"),
        content: const Text("Are you sure you want to sign out?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Sign Out", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (shouldLogout == true && context.mounted) {
      try {
        await AuthService().signOut();
        if (context.mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error signing out: $e")),
          );
        }
      }
    }
  }

  void _confirmResetAccount(BuildContext context, WarrantyProvider provider) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Reset Account Data?", style: TextStyle(color: Colors.red)),
        content: const Text(
          "This will PERMANENTLY DELETE all your warranties, images, and logs from this device.\n\nThis action cannot be undone.",
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close first dialog
              _finalConfirmReset(context, provider);
            },
            child: const Text("Delete Everything", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _finalConfirmReset(BuildContext context, WarrantyProvider provider) {
     showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Are you absolutely sure?"),
        content: const Text("There is no going back."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
               Navigator.pop(context);
               await _performReset(context, provider);
            },
            child: const Text("I Understand, Delete.", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _performReset(BuildContext context, WarrantyProvider provider) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
      
      await provider.resetAccount();
      
      if (context.mounted) {
        Navigator.pop(context); // Pop loading
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Account data reset successfully")));
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Pop loading
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Reset failed: $e")));
      }
    }
  }
}

