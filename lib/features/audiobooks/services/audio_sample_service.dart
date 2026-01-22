import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/audio_sample.dart';

class AudioSampleService {
  static const String _baseUrl = 'https://www.alkirtas.com/module/alkirtasaudiobooks/api';

  /// Fetch audio sample for a product
  Future<AudioSample?> fetchSampleByProductId(int productId) async {
    try {
      final url = '$_baseUrl?action=getSample&id_product=$productId';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true && data['sample'] != null) {
          return AudioSample.fromJson(data['sample']);
        }
      }
      return null;
    } catch (e) {
      print('Error fetching audio sample: $e');
      return null;
    }
  }
}
