import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../providers/warranty_provider.dart';
import '../widgets/warranty_card.dart';
import '../widgets/page_header.dart';
import '../theme/app_theme.dart';
import 'details_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = "";

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer<WarrantyProvider>(
          builder: (context, provider, child) {
            final expiringCount = provider.expiringCount;
            final items = provider.searchActive(_searchQuery);
        
            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      PageHeader(
                        title: "My Vault",
                        notificationCount: expiringCount,
                      ),
                      
                      Container(
                        color: Colors.white,
                        child: const Divider(height: 1, thickness: 1, color: AppTheme.zinc100),
                      ),
                      Container(
                        padding: const EdgeInsets.all(24.0),
                        child: TextField(
                          controller: _searchCtrl,
                          onChanged: (val) => setState(() => _searchQuery = val),
                          decoration: InputDecoration(
                            hintText: "Search warranties...",
                            hintStyle: const TextStyle(color: AppTheme.zinc500),
                            prefixIcon: const Icon(LucideIcons.search, size: 20, color: AppTheme.zinc500),
                            suffixIcon: IconButton(
                              icon: const Icon(LucideIcons.arrow_up_down, size: 20, color: AppTheme.zinc500),
                              onPressed: () => _showSortOptions(context),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppTheme.zinc200),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppTheme.zinc200),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppTheme.zinc300, width: 1),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        
                if (items.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.box, size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isEmpty ? "Your vault is empty" : "No results found",
                            style: TextStyle(color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final item = items[index];
                          return WarrantyCard(
                            item: item,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => DetailsScreen(itemId: item.id)),
                              );
                            },
                            onArchive: (ctx) {
                              provider.toggleArchive(item.id, true);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Archived"),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            onDelete: (ctx) {
                               provider.deleteWarranty(item.id);
                            },
                          );
                        },
                        childCount: items.length,
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

  void _showSortOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Consumer<WarrantyProvider>(
          builder: (context, provider, _) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Sort By",
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  _buildSortOption(context, provider, "Expiring Soonest", "expiring_soon"),
                  _buildSortOption(context, provider, "Purchase Date (Newest)", "purchase_newest"),
                  _buildSortOption(context, provider, "Purchase Date (Oldest)", "purchase_oldest"),
                  _buildSortOption(context, provider, "Name (A-Z)", "name_az"),
                  _buildSortOption(context, provider, "Name (Z-A)", "name_za"),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSortOption(BuildContext context, WarrantyProvider provider, String label, String value) {
    final isSelected = provider.sortOrder == value;
    return InkWell(
      onTap: () {
        provider.setSortOrder(value);
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.zinc100 : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? AppTheme.zinc900 : AppTheme.zinc500,
                ),
              ),
            ),
            if (isSelected)
              const Icon(LucideIcons.check, size: 20, color: AppTheme.accentOrange),
          ],
        ),
      ),
    );
  }
}
