import 'dart:convert';
import 'package:http/http.dart' as http;

class DetailsController {
  final String apiKey = 'Y262WZ22UPBRMJ6UNTHU24KDXT7T66RU';
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
      print('❌ Error fetching feature name: $e');
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
      print('❌ Error fetching feature value: $e');
    }
    return null;
  }

  /// Fetch and map product features `{Feature Name: Feature Value}`
  Future<Map<String, String>> fetchProductFeatures(List<Map<String, dynamic>> featuresList) async {
    Map<String, String> productFeatures = {};

    for (var feature in featuresList) {
      if (feature.containsKey('id') && feature.containsKey('id_feature_value')) {
        int featureId = int.parse(feature['id'].toString());
        int featureValueId = int.parse(feature['id_feature_value'].toString());

        String? featureName = await fetchFeatureName(featureId);
        String? featureValue = await fetchFeatureValue(featureValueId);

        if (featureName != null && featureValue != null) {
          productFeatures[featureName] = featureValue;
        }
      }
    }

    return productFeatures;
  }
}
