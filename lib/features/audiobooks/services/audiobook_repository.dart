import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/audiobook_model.dart';

/// Repository to fetch audiobooks from server
class AudiobookRepository {
  // URL to your audiobooks JSON file on server
  static const String _audiobooksUrl =
      'https://www.alkirtas.com/banners/AudioBooks/audiobooks.json';

  // Singleton
  static final AudiobookRepository _instance = AudiobookRepository._internal();
  factory AudiobookRepository() => _instance;
  AudiobookRepository._internal();

  List<Audiobook>? _cachedAudiobooks;
  DateTime? _lastFetch;
  static const Duration _cacheExpiry = Duration(minutes: 5);

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
      author: json['author'] ?? 'Unknown',
      description: json['description'] ?? '',
      coverUrl: json['cover_url'],
      chapters: chapters,
      totalDuration: totalDuration,
      narrator: json['narrator'],
      language: json['language'] ?? 'fr',
    );
  }

  /// Clear cache
  void clearCache() {
    _cachedAudiobooks = null;
    _lastFetch = null;
  }
}
