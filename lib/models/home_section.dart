// lib/models/home_section.dart
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class HomeSection {
  final String title;
  final IconData icon;
  final List<CategoryTab> tabs;

  HomeSection({required this.title, required this.icon, required this.tabs});

  // Factory constructor to create HomeSection from JSON
  factory HomeSection.fromJson(Map<String, dynamic> json) {
    return HomeSection(
      title: json['title'] as String,
      icon: _getIconFromName(json['icon'] as String? ?? 'category'),
      tabs: (json['tabs'] as List<dynamic>)
          .map((tab) => CategoryTab.fromJson(tab as Map<String, dynamic>))
          .toList(),
    );
  }

  // Convert HomeSection to JSON
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'icon': _getIconName(icon),
      'tabs': tabs.map((tab) => tab.toJson()).toList(),
    };
  }

  // Helper method to convert icon name string to IconData
  static IconData _getIconFromName(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'book':
      case 'book_1':
        return Iconsax.book_1;
      case 'teacher':
        return Iconsax.teacher;
      case 'monitor':
      case 'monitor_mobbile':
      case 'office':
        return Iconsax.monitor_mobbile;
      case 'game':
        return Iconsax.game;
      case 'gift':
        return Iconsax.gift;
      case 'bag':
      case 'bag_2':
        return Iconsax.bag_2;
      case 'brush':
      case 'brush_1':
        return Iconsax.brush_1;
      case 'note':
      case 'note_1':
        return Iconsax.note_1;
      case 'mobile':
        return Iconsax.mobile;
      case 'cake':
        return Iconsax.cake;
      case 'rulerpen':
        return Iconsax.rulerpen;
      case 'star':
      case 'star_1':
        return Iconsax.star_1;
      case 'ranking':
      case 'ranking_1':
        return Iconsax.ranking_1;
      default:
        return Iconsax.category;
    }
  }

  // Helper method to convert IconData to string name (for serialization)
  static String _getIconName(IconData icon) {
    if (icon == Iconsax.book_1) return 'book_1';
    if (icon == Iconsax.teacher) return 'teacher';
    if (icon == Iconsax.monitor_mobbile) return 'monitor_mobbile';
    if (icon == Iconsax.game) return 'game';
    if (icon == Iconsax.gift) return 'gift';
    if (icon == Iconsax.bag_2) return 'bag_2';
    if (icon == Iconsax.brush_1) return 'brush_1';
    if (icon == Iconsax.note_1) return 'note_1';
    if (icon == Iconsax.mobile) return 'mobile';
    if (icon == Iconsax.cake) return 'cake';
    if (icon == Iconsax.rulerpen) return 'rulerpen';
    if (icon == Iconsax.star_1) return 'star_1';
    if (icon == Iconsax.ranking_1) return 'ranking_1';
    return 'category';
  }
}

class CategoryTab {
  final String name;
  final int categoryId;

  CategoryTab({required this.name, required this.categoryId});

  // Factory constructor to create CategoryTab from JSON
  factory CategoryTab.fromJson(Map<String, dynamic> json) {
    return CategoryTab(
      name: json['name'] as String,
      categoryId: json['categoryId'] as int,
    );
  }

  // Convert CategoryTab to JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'categoryId': categoryId,
    };
  }
}