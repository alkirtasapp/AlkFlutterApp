import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:alkirtas/utils/logging/logger.dart';
import '../models/audio_sample.dart';

enum GenerateSampleErrorKind { noBlurb, ttsFailed, network, timeout, unknown }

class SampleLookup {
  final AudioSample? sample;
  final bool eligible;

  const SampleLookup({this.sample, required this.eligible});

  bool get hasSampleOrEligible => sample != null || eligible;
}

class GenerateSampleResult {
  final AudioSample? sample;
  final GenerateSampleErrorKind? error;
  final String? message;

  const GenerateSampleResult.success(this.sample)
      : error = null,
        message = null;
  const GenerateSampleResult.failure(this.error, this.message) : sample = null;

  bool get isSuccess => sample != null;
}

class AudioSampleService {
  static const String _baseUrl = 'https://www.alkirtas.com/module/alkirtasaudiobooks/api';

  /// Fetch audio sample for a product, plus whether the product is eligible
  /// for sample generation (i.e. a book — categories 13/14/15 server-side).
  Future<SampleLookup> fetchSampleByProductId(int productId) async {
    try {
      final url = '$_baseUrl?action=getSample&id_product=$productId';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          final sampleJson = data['sample'];
          return SampleLookup(
            sample: sampleJson != null ? AudioSample.fromJson(sampleJson) : null,
            eligible: data['eligible'] == true,
          );
        }
      }
      return const SampleLookup(eligible: false);
    } catch (e) {
      AlkLoggerHelper.error("Audio sample fetch failed", e);
      return const SampleLookup(eligible: false);
    }
  }

  /// Trigger server-side TTS generation of a sample. Returns existing one
  /// immediately if it's already generated. Server-side call to Gemini can
  /// take 30-90s, so we use a 100s timeout client-side.
  Future<GenerateSampleResult> generateSample(int productId) async {
    try {
      final url = '$_baseUrl?action=generateSample';
      final response = await http
          .post(
            Uri.parse(url),
            headers: const {'Content-Type': 'application/x-www-form-urlencoded'},
            body: 'id_product=$productId',
          )
          .timeout(const Duration(seconds: 100));

      if (response.statusCode != 200) {
        return GenerateSampleResult.failure(
          GenerateSampleErrorKind.network,
          'HTTP ${response.statusCode}',
        );
      }

      final data = json.decode(response.body) as Map<String, dynamic>;

      if (data['success'] == true && data['audio_url'] != null) {
        final sample = AudioSample(
          idProduct: productId,
          audioUrl: data['audio_url'] as String,
          duration: Duration(seconds: (data['duration'] as num?)?.toInt() ?? 0),
        );
        return GenerateSampleResult.success(sample);
      }

      final errorCode = data['error']?.toString();
      final kind = switch (errorCode) {
        'no_blurb' => GenerateSampleErrorKind.noBlurb,
        'tts_failed' => GenerateSampleErrorKind.ttsFailed,
        _ => GenerateSampleErrorKind.unknown,
      };
      return GenerateSampleResult.failure(kind, data['message']?.toString());
    } catch (e) {
      AlkLoggerHelper.error('Audio sample generation failed', e);
      final kind = e.toString().contains('TimeoutException')
          ? GenerateSampleErrorKind.timeout
          : GenerateSampleErrorKind.network;
      return GenerateSampleResult.failure(kind, e.toString());
    }
  }
}
