/// Simple model for audio sample preview
class AudioSample {
  final int idProduct;
  final String audioUrl;
  final Duration duration;

  AudioSample({
    required this.idProduct,
    required this.audioUrl,
    required this.duration,
  });

  factory AudioSample.fromJson(Map<String, dynamic> json) {
    return AudioSample(
      idProduct: json['id_product'] ?? 0,
      audioUrl: json['audio_url'] ?? '',
      duration: Duration(seconds: json['duration_seconds'] ?? 0),
    );
  }

  String get formattedDuration {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
