import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

class CategoryItem {
  final String id;
  final String label;
  final IconData icon;
  final Color color;

  const CategoryItem({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
  });
}

class CategoryData {
  static const List<CategoryItem> categories = [
    CategoryItem(
      id: 'computers',
      label: 'Computers & Laptops',
      icon: LucideIcons.laptop,
      color: Colors.indigo,
    ),
    CategoryItem(
      id: 'smartphones',
      label: 'Smartphones & Tablets',
      icon: LucideIcons.smartphone,
      color: Colors.blue,
    ),
    CategoryItem(
      id: 'appliances',
      label: 'Home Appliances',
      icon: LucideIcons.zap, // Refrigerator/WashingMachine might not be in basic set, using Zap as fallback/utility
      color: Colors.cyan,
    ),
    CategoryItem(
      id: 'audio',
      label: 'Audio & Peripherals',
      icon: LucideIcons.headphones,
      color: Colors.purple, // Violet
    ),
    CategoryItem(
      id: 'furniture',
      label: 'Furniture & Fixtures',
      icon: LucideIcons.armchair,
      color: Colors.amber,
    ),
    CategoryItem(
      id: 'tools',
      label: 'Tools & Hardware',
      icon: LucideIcons.hammer,
      color: Colors.blueGrey, // Slate
    ),
    CategoryItem(
      id: 'vehicle',
      label: 'Vehicle & Auto',
      icon: LucideIcons.car,
      color: Colors.red,
    ),
    CategoryItem(
      id: 'others',
      label: 'Others',
      icon: LucideIcons.package,
      color: Colors.grey,
    ),
  ];

  static CategoryItem getCategory(String id) {
    return categories.firstWhere(
      (c) => c.id == id,
      orElse: () => categories.last, // Default to Others
    );
  }
}
