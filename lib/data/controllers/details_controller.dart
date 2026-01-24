import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:alkirtas/config/app_config.dart';
import 'package:alkirtas/utils/logging/logger.dart';

class DetailsController {
  String get apiKey => AppConfig.prestashopApiKey;
  final String baseUrl = 'https://www.alkirtas.com/api';

  /// Fetch feature name by feature ID
  Future<String?> fetchFeatureName(int featureId) async {
    try {
      final response = await http.get(Uri.parse(
          '$baseUrl/product_features?display=full&filter[id]=$featureId&limit=1&output_format=JSON&ws_key=$apiKey'));

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        if (data.containsKey('product_features') &&
            data['product_features'].isNotEmpty) {
          return data['product_features'][0]['name'] ?? 'Unknown Feature';
        }
      }
    } catch (e) {
      AlkLoggerHelper.error('Error fetching feature name for ID $featureId', e);
    }
    return null;
  }

  /// Fetch feature value by feature value ID
  Future<String?> fetchFeatureValue(int featureValueId) async {
    try {
      final response = await http.get(Uri.parse(
          '$baseUrl/product_feature_values?display=full&filter[id]=$featureValueId&output_format=JSON&ws_key=$apiKey'));

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        if (data.containsKey('product_feature_values') &&
            data['product_feature_values'].isNotEmpty) {
          return data['product_feature_values'][0]['value'] ?? 'Unknown Value';
        }
      }
    } catch (e) {
      AlkLoggerHelper.error('Error fetching feature value for ID $featureValueId', e);
    }
    return null;
  }

  /// Fetch a single feature (name + value) in parallel
  Future<MapEntry<String, String>?> _fetchSingleFeature(int featureId, int featureValueId) async {
    // Fetch name and value in parallel
    final results = await Future.wait([
      fetchFeatureName(featureId),
      fetchFeatureValue(featureValueId),
    ]);

    final featureName = results[0];
    final featureValue = results[1];

    if (featureName != null && featureValue != null) {
      return MapEntry(featureName, featureValue);
    }
    return null;
  }

  /// Fetch and map product features `{Feature Name: Feature Value}` - OPTIMIZED with parallel fetching
  Future<Map<String, String>> fetchProductFeatures(List<Map<String, dynamic>> featuresList) async {
    Map<String, String> productFeatures = {};

    // Create list of parallel fetch tasks
    List<Future<MapEntry<String, String>?>> fetchTasks = [];

    for (var feature in featuresList) {
      if (feature.containsKey('id') && feature.containsKey('id_feature_value')) {
        int featureId = int.parse(feature['id'].toString());
        int featureValueId = int.parse(feature['id_feature_value'].toString());

        // Add parallel task for each feature
        fetchTasks.add(_fetchSingleFeature(featureId, featureValueId));
      }
    }

    // Execute all fetch tasks in parallel
    final results = await Future.wait(fetchTasks);

    // Collect results
    for (var entry in results) {
      if (entry != null) {
        productFeatures[entry.key] = entry.value;
      }
    }

    return productFeatures;
  }
}
