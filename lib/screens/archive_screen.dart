import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../providers/warranty_provider.dart';
import '../widgets/warranty_card.dart';

class ArchiveScreen extends StatelessWidget {
  const ArchiveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("The Archive")),
      body: Consumer<WarrantyProvider>(
        builder: (context, provider, child) {
          final archivedItems = provider.archivedItems;

          if (archivedItems.isEmpty) {
            return const Center(child: Text("Archive is empty", style: TextStyle(color: Colors.grey)));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: archivedItems.length,
            itemBuilder: (context, index) {
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
                  opacity: 0.6,
                  child: WarrantyCard(
                    item: item,
                    onTap: () {
                      // Option to restore
                       showDialog(
                         context: context,
                         builder: (ctx) => AlertDialog(
                           title: const Text("Restore Item?"),
                           actions: [
                             TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
                             TextButton(
                               onPressed: () {
                                 provider.toggleArchive(item.id, false);
                                 Navigator.pop(ctx);
                               },
                               child: const Text("Restore"),
                             ),
                           ],
                         ),
                       );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
