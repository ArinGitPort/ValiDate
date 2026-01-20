import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../providers/warranty_provider.dart';
import '../widgets/warranty_card.dart';
import '../widgets/page_header.dart';
import '../theme/app_theme.dart';
import '../utils/category_data.dart';
import 'details_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = "";
  String _selectedCategory = 'all';

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
            // First search
            var items = provider.searchActive(_searchQuery);
            
            // Then filter by category
            if (_selectedCategory != 'all') {
              items = items.where((i) => i.category == _selectedCategory).toList();
            }
        
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
                        color: AppTheme.white,
                        child: const Divider(height: 1, thickness: 1, color: AppTheme.dividerColor),
                      ),
                      if (provider.isSyncing)
                        Container(
                          width: double.infinity,
                          color: AppTheme.primaryBrand.withValues(alpha: 0.1),
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 12, 
                                  height: 12, 
                                  child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryBrand)
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "Syncing changes...",
                                  style: GoogleFonts.manrope(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.primaryBrand,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      Container(
                        color: AppTheme.white,
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            TextField(
                              controller: _searchCtrl,
                              onChanged: (val) => setState(() => _searchQuery = val),
                              decoration: InputDecoration(
                                hintText: "Search warranties...",
                                hintStyle: const TextStyle(color: AppTheme.secondaryText),
                                prefixIcon: const Icon(LucideIcons.search, size: 20, color: AppTheme.secondaryText),
                                suffixIcon: IconButton(
                                  icon: const Icon(LucideIcons.arrow_up_down, size: 20, color: AppTheme.secondaryText),
                                  onPressed: () => _showSortOptions(context),
                                ),
                                filled: true,
                                fillColor: AppTheme.inputFill,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: AppTheme.dividerColor),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: AppTheme.dividerColor),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: AppTheme.primaryBrand, width: 1.5),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildCategoryFilter(),
                          ],
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
                          Icon(LucideIcons.box, size: 64, color: AppTheme.dividerColor),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isEmpty && _selectedCategory == 'all' 
                                ? "Your vault is empty" 
                                : "No results found",
                            style: const TextStyle(color: AppTheme.secondaryText),
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
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: Text(item.isArchived ? "Unarchive Warranty?" : "Archive Warranty?"),
                                  content: Text(item.isArchived 
                                    ? "This will move the warranty back to your active vault." 
                                    : "This will move the warranty to the archive. You can restore it later."),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      child: const Text("Cancel"),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        provider.toggleArchive(item.id, true);
                                        Navigator.pop(ctx);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text("Archived"),
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                      },
                                      child: const Text("Archive"),
                                    ),
                                  ],
                                ),
                              );
                            },
                            onDelete: (ctx) {
                               showDialog(
                                 context: context,
                                 builder: (ctx) => AlertDialog(
                                   title: const Text("Delete Permanently?"),
                                   content: const Text("This cannot be undone. All documents and data will be removed."),
                                   actions: [
                                     TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
                                     TextButton(
                                       onPressed: () {
                                         provider.deleteWarranty(item.id);
                                         Navigator.pop(ctx);
                                       },
                                       child: const Text("Delete", style: TextStyle(color: AppTheme.statusExpiredText)),
                                     ),
                                   ],
                                 ),
                               );
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

  Widget _buildCategoryFilter() {
    // Add "All" option to categories
    final allCategory = CategoryItem(id: 'all', label: 'All', icon: LucideIcons.layout_grid, color: AppTheme.primaryBrand);
    final categories = [allCategory, ...CategoryData.categories];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (c, i) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = _selectedCategory == cat.id;
          
          return GestureDetector(
            onTap: () {
              setState(() => _selectedCategory = cat.id);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryBrand : AppTheme.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppTheme.primaryBrand : AppTheme.dividerColor,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    cat.icon, 
                    size: 16, 
                    color: isSelected ? AppTheme.white : AppTheme.secondaryText
                  ),
                  const SizedBox(width: 8),
                  Text(
                    cat.label,
                    style: TextStyle(
                      color: isSelected ? AppTheme.white : AppTheme.secondaryText,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
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
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppTheme.primaryDark),
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
          color: isSelected ? AppTheme.inputFill : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? AppTheme.primaryDark : AppTheme.secondaryText,
                ),
              ),
            ),
            if (isSelected)
              const Icon(LucideIcons.check, size: 20, color: AppTheme.primaryBrand),
          ],
        ),
      ),
    );
  }
}
