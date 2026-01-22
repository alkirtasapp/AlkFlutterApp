import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/audiobook_model.dart';

/// Repository to fetch audiobooks from server
class AudiobookRepository {
  // URL to your audiobooks JSON file on server (legacy)
  static const String _audiobooksUrl =
      'https://www.alkirtas.com/banners/AudioBooks/audiobooks.json';

  // PrestaShop module API base URL
  static const String _moduleApiUrl =
      'https://www.alkirtas.com/module/alkirtasaudiobooks/api';

  // Singleton
  static final AudiobookRepository _instance = AudiobookRepository._internal();
  factory AudiobookRepository() => _instance;
  AudiobookRepository._internal();

  List<Audiobook>? _cachedAudiobooks;
  DateTime? _lastFetch;
  static const Duration _cacheExpiry = Duration(minutes: 5);

  // Cache for product-specific audiobooks
  final Map<int, Audiobook?> _productAudiobookCache = {};

  /// Fetch audiobooks from server
  Future<List<Audiobook>> fetchAudiobooks({bool forceRefresh = false}) async {
    // Return cache if valid
    if (!forceRefresh &&
        _cachedAudiobooks != null &&
        _lastFetch != null &&
        DateTime.now().difference(_lastFetch!) < _cacheExpiry) {
      return _cachedAudiobooks!;
    }

    try {
      final response = await http.get(
        Uri.parse(_audiobooksUrl),
        headers: {'Accept-Charset': 'utf-8'},
      );

      if (response.statusCode == 200) {
        // Decode with UTF-8 to properly handle French characters (é, è, à, ç)
        final data = json.decode(utf8.decode(response.bodyBytes));
        final audiobooks = _parseAudiobooks(data);

        // Cache the results
        _cachedAudiobooks = audiobooks;
        _lastFetch = DateTime.now();

        return audiobooks;
      } else {
        throw Exception('Failed to load audiobooks: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching audiobooks: $e');
      // Return cached data if available, otherwise empty list
      return _cachedAudiobooks ?? [];
    }
  }

  /// Parse audiobooks from JSON
  List<Audiobook> _parseAudiobooks(Map<String, dynamic> data) {
    final List<Audiobook> audiobooks = [];

    if (data['audiobooks'] != null) {
      for (final item in data['audiobooks']) {
        try {
          audiobooks.add(_parseAudiobook(item));
        } catch (e) {
          print('Error parsing audiobook: $e');
        }
      }
    }

    return audiobooks;
  }

  /// Parse single audiobook from JSON
  Audiobook _parseAudiobook(Map<String, dynamic> json) {
    final chapters = <AudioChapter>[];

    if (json['chapters'] != null) {
      int index = 0;
      for (final ch in json['chapters']) {
        chapters.add(AudioChapter(
          id: ch['id']?.toString() ?? index.toString(),
          title: ch['title'] ?? 'Chapter ${index + 1}',
          audioUrl: ch['audio_url'] ?? '',
          transcriptUrl: ch['transcript_url'],
          duration: Duration(seconds: ch['duration_seconds'] ?? 0),
          index: index,
        ));
        index++;
      }
    }

    // Calculate total duration
    final totalDuration = chapters.fold<Duration>(
      Duration.zero,
      (total, chapter) => total + chapter.duration,
    );

    return Audiobook(
      id: json['id'] ?? '',
      title: json['title'] ?? 'Unknown',
      
      description: json['description'] ?? '',
      coverUrl: json['cover_url'],
      chapters: chapters,
      totalDuration: totalDuration,
   
    );
  }

  /// Fetch audiobook by product ID from PrestaShop module API
  Future<Audiobook?> fetchAudiobookByProductId(int productId, {bool forceRefresh = false}) async {
    // Return cache if available and not forcing refresh
    if (!forceRefresh && _productAudiobookCache.containsKey(productId)) {
      return _productAudiobookCache[productId];
    }

    try {
      final response = await http.get(
        Uri.parse('$_moduleApiUrl?action=getByProduct&id_product=$productId'),
        headers: {'Accept-Charset': 'utf-8'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));

        if (data['success'] == true && data['audiobook'] != null) {
          final audiobook = Audiobook.fromJson(data['audiobook']);
          _productAudiobookCache[productId] = audiobook;
          return audiobook;
        } else {
          // No audiobook for this product
          _productAudiobookCache[productId] = null;
          return null;
        }
      } else {
        print('Failed to fetch audiobook for product $productId: ${response.statusCode}');
        return _productAudiobookCache[productId];
      }
    } catch (e) {
      print('Error fetching audiobook for product $productId: $e');
      return _productAudiobookCache[productId];
    }
  }

  /// Fetch all audiobooks from PrestaShop module API
  Future<List<Audiobook>> fetchAudiobooksFromModule({bool forceRefresh = false}) async {
    try {
      final response = await http.get(
        Uri.parse('$_moduleApiUrl?action=getAll'),
        headers: {'Accept-Charset': 'utf-8'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));

        if (data['success'] == true && data['audiobooks'] != null) {
          final audiobooks = (data['audiobooks'] as List)
              .map((item) => Audiobook.fromJson(item))
              .toList();

          // Update main cache
          _cachedAudiobooks = audiobooks;
          _lastFetch = DateTime.now();

          return audiobooks;
        }
      }
      return _cachedAudiobooks ?? [];
    } catch (e) {
      print('Error fetching audiobooks from module: $e');
      return _cachedAudiobooks ?? [];
    }
  }

  /// Clear cache
  void clearCache() {
    _cachedAudiobooks = null;
    _lastFetch = null;
    _productAudiobookCache.clear();
  }
}
