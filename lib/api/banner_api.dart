import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';
import 'package:cached_network_image/cached_network_image.dart';

class BannerApi {
  static const String _boxName = 'bannerBox';
  static const String _key = 'bannerUrls';

  static Future<List<String>> fetchBannerUrls() async {
    // Open the Hive box
    var box = await Hive.openBox(_boxName);

    try {
      final response = await http.get(Uri.parse('https://alkirtas.com/banners/banners.json'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final urls = data.cast<String>();
        // Cache the result
        await box.put(_key, urls);
        return urls;
      } else {
        // If network fails, try to return cached data
        final cached = box.get(_key);
        if (cached != null) return List<String>.from(cached);
        throw Exception('Failed to load banners');
      }
    } catch (e) {
      // On error, return cached data if available
      final cached = box.get(_key);
      if (cached != null) return List<String>.from(cached);
      throw Exception('Failed to load banners');
    }
  }
  
} 


