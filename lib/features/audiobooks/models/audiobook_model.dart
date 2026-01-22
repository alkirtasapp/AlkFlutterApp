/// Model representing an audiobook with its chapters/tracks
class Audiobook {
  final String id;
  final int? idProduct; // Link to PrestaShop product ID
  final String title;
  final String? description;
  final String? coverUrl;
  final List<AudioChapter> chapters;
  final Duration totalDuration;

  // Keep author for backwards compatibility but make it optional
  String get author => '';

  Audiobook({
    required this.id,
    this.idProduct,
    required this.title,
    this.description,
    this.coverUrl,
    required this.chapters,
    required this.totalDuration,
  });

  factory Audiobook.fromJson(Map<String, dynamic> json) {
    final chapters = (json['chapters'] as List?)
            ?.map((c) => AudioChapter.fromJson(c))
            .toList() ??
        [];
    return Audiobook(
      id: json['id']?.toString() ?? '',
      idProduct: json['id_product'] != null ? int.tryParse(json['id_product'].toString()) : null,
      title: json['title'] ?? 'Unknown Title',
      description: json['description'],
      coverUrl: json['cover_url'],
      chapters: chapters,
      totalDuration: Duration(seconds: json['total_duration_seconds'] ?? json['total_duration'] ?? 0),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'id_product': idProduct,
        'title': title,
        'description': description,
        'cover_url': coverUrl,
        'chapters': chapters.map((c) => c.toJson()).toList(),
        'total_duration_seconds': totalDuration.inSeconds,
      };
}

/// Model representing a single chapter/track in an audiobook
class AudioChapter {
  final String id;
  final String title;
  final String audioUrl;
  final String? transcriptUrl; // URL to JSON file with timestamps
  final Duration duration;
  final int index;

  AudioChapter({
    required this.id,
    required this.title,
    required this.audioUrl,
    this.transcriptUrl,
    required this.duration,
    required this.index,
  });

  factory AudioChapter.fromJson(Map<String, dynamic> json) {
    return AudioChapter(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? 'Chapter ${json['index'] ?? 0}',
      audioUrl: json['audio_url'] ?? '',
      transcriptUrl: json['transcript_url'],
      duration: Duration(seconds: json['duration_seconds'] ?? json['duration'] ?? 0),
      index: json['index'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'audio_url': audioUrl,
        'transcript_url': transcriptUrl,
        'duration': duration.inSeconds,
        'index': index,
      };
}

/// Model representing a text segment with timing info
class TextSegment {
  final int index;
  final String text;
  final double startTime; // in seconds
  final double endTime;   // in seconds

  TextSegment({
    required this.index,
    required this.text,
    required this.startTime,
    required this.endTime,
  });

  factory TextSegment.fromJson(Map<String, dynamic> json) {
    return TextSegment(
      index: json['index'] ?? 0,
      text: json['text'] ?? '',
      startTime: (json['start'] ?? 0).toDouble(),
      endTime: (json['end'] ?? 0).toDouble(),
    );
  }

  /// Check if current position is within this segment
  bool isActive(Duration position) {
    final positionSec = position.inMilliseconds / 1000.0;
    return positionSec >= startTime && positionSec < endTime;
  }
}

/// Model for the full transcript data
class AudioTranscript {
  final String audioFile;
  final double durationSeconds;
  final String language;
  final List<TextSegment> segments;

  AudioTranscript({
    required this.audioFile,
    required this.durationSeconds,
    required this.language,
    required this.segments,
  });

  factory AudioTranscript.fromJson(Map<String, dynamic> json) {
    final segmentsList = (json['segments'] as List?)
            ?.map((s) => TextSegment.fromJson(s))
            .toList() ??
        [];
    return AudioTranscript(
      audioFile: json['audio_file'] ?? '',
      durationSeconds: (json['duration_seconds'] ?? 0).toDouble(),
      language: json['language'] ?? 'en',
      segments: segmentsList,
    );
  }

  /// Find the active segment index for a given position
  int? findActiveSegmentIndex(Duration position) {
    final positionSec = position.inMilliseconds / 1000.0;
    for (int i = 0; i < segments.length; i++) {
      if (positionSec >= segments[i].startTime && positionSec < segments[i].endTime) {
        return i;
      }
    }
    return null;
  }
}

/// Player state enum
enum AudioPlayState {
  idle,
  loading,
  playing,
  paused,
  completed,
  error,
}

/// Position data for the audio player
class PositionData {
  final Duration position;
  final Duration bufferedPosition;
  final Duration duration;

  PositionData({
    required this.position,
    required this.bufferedPosition,
    required this.duration,
  });
}
