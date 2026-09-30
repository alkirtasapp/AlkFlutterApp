import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:alkirtas/models/home_section.dart';

/// Bundled artwork enriches existing server entries; it never adds or reorders them.
class SectionArtwork {
  static Future<Map<String, dynamic>>? _presentation;

  static Future<List<HomeSection>> apply(List<HomeSection> sections) async {
    try {
      final presentation = await (_presentation ??= _load());
      return applyDefaults(sections, presentation);
    } catch (_) {
      // Missing local art must not prevent the remote departments from loading.
      return sections;
    }
  }

  static Future<Map<String, dynamic>> _load() async {
    final source = await rootBundle
        .loadString('lib/assets/images/departments/presentation.json');
    return Map<String, dynamic>.from(json.decode(source) as Map);
  }

  static List<HomeSection> applyDefaults(
      List<HomeSection> sections, Map<String, dynamic> presentation) {
    return sections.map((section) {
      final raw = presentation[section.title.trim().toLowerCase()];
      if (raw is! Map) return section;
      final defaults = Map<String, dynamic>.from(raw);
      final tabImages = defaults['tabs'] as Map? ?? const {};
      return HomeSection(
        title: section.title,
        icon: section.icon,
        categoryId: section.categoryId,
        layout: section.layout == 'auto'
            ? defaults['layout']?.toString() ?? 'auto'
            : section.layout,
        image: section.image ?? defaults['image']?.toString(),
        headline: section.headline ?? defaults['headline']?.toString(),
        backgroundColor:
            section.backgroundColor ?? defaults['backgroundColor']?.toString(),
        tabs: section.tabs
            .map((tab) => CategoryTab(
                  name: tab.name,
                  categoryId: tab.categoryId,
                  image: tab.image ??
                      tabImages[tab.categoryId.toString()]?.toString(),
                ))
            .toList(),
      );
    }).toList();
  }
}
