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
}
