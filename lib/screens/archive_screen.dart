import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../providers/warranty_provider.dart';
import '../widgets/warranty_card.dart';
import '../widgets/page_header.dart';

class ArchiveScreen extends StatelessWidget {
  const ArchiveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer<WarrantyProvider>(
          builder: (context, provider, child) {
            final archivedItems = provider.archivedItems;
            final expiringCount = provider.expiringCount;

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: PageHeader(
                    title: "The Archive",
                    notificationCount: expiringCount,
                  ),
                ),

                if (archivedItems.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.archive, size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          const Text("Archive is empty", style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final item = archivedItems[index];
                          return Dismissible(
                            key: Key(item.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              color: Colors.red,
                              child: const Icon(LucideIcons.trash_2, color: Colors.white),
                            ),
                            confirmDismiss: (direction) async {
                               return await showDialog(
                                 context: context,
                                 builder: (ctx) => AlertDialog(
                                   title: const Text("Delete Permanently?"),
                                   content: const Text("This cannot be undone."),
                                   actions: [
                                     TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
                                     TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Delete", style: TextStyle(color: Colors.red))),
                                   ],
                                 ),
                               );
                            },
                            onDismissed: (direction) {
                              provider.deleteWarranty(item.id);
                            },
                            child: Opacity(
                              opacity: 0.8,
                              child: WarrantyCard(
                                item: item,
                                onTap: () {
                                   _showArchiveOptions(context, provider, item);
                                },
                              ),
                            ),
                          );
                        },
                        childCount: archivedItems.length,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showArchiveOptions(BuildContext context, WarrantyProvider provider, dynamic item) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(LucideIcons.archive_restore, color: Colors.blue),
              title: const Text("Restore to Vault"),
              onTap: () {
                provider.toggleArchive(item.id, false);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("${item.name} restored")),
                );
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.trash_2, color: Colors.red),
              title: const Text("Delete Permanently", style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                _confirmDelete(context, provider, item);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WarrantyProvider provider, dynamic item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Permanently?"),
        content: const Text("This cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              provider.deleteWarranty(item.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("${item.name} deleted")),
              );
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
