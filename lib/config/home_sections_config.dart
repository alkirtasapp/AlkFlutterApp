import 'package:alkirtas/models/home_section.dart';
import 'package:alkirtas/api/sections_api.dart';

// This list is now loaded dynamically from the server
// Use getHomeSections() to fetch the sections
List<HomeSection> _cachedHomeSections = [];

// Getter for accessing home sections
List<HomeSection> get homeSections => _cachedHomeSections;

// Function to load home sections from server
Future<List<HomeSection>> getHomeSections() async {
  try {
    final sections = await SectionsApi.fetchHomeSections();
    _cachedHomeSections = sections;
    return sections;
  } catch (e) {
    print('Error loading home sections: $e');
    // Return empty list if loading fails
    return [];
  }
}