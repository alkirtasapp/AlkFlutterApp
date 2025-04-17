// lib/models/home_section.dart
import 'package:flutter/material.dart';

class HomeSection {
  final String title;
  final IconData icon;
  final List<CategoryTab> tabs;
  
  HomeSection({required this.title, required this.icon, required this.tabs});
}

class CategoryTab {
  final String name;
  final int categoryId;
  
  CategoryTab({required this.name, required this.categoryId});
}