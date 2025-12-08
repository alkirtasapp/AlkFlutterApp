import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:http/http.dart' as http;
import '../models/audiobook_model.dart';

/// Provider for managing audio playback state
class AudioPlayerProvider extends ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();

  Audiobook? _currentAudiobook;
  int _currentChapterIndex = 0;
  AudioPlayState _playerState = AudioPlayState.idle;
  Duration _position = Duration.zero;
  Duration _bufferedPosition = Duration.zero;
  Duration _duration = Duration.zero;
  double _playbackSpeed = 1.0;
  LoopMode _loopMode = LoopMode.off;
  String? _errorMessage;
  AudioTranscript? _currentTranscript;

  // Stream subscriptions
  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration>? _bufferedPositionSubscription;
  StreamSubscription<Duration?>? _durationSubscription;

  AudioPlayerProvider() {
    _initializeListeners();
  }

  // Getters
  AudioPlayer get audioPlayer => _audioPlayer;
  Audiobook? get currentAudiobook => _currentAudiobook;
  AudioChapter? get currentChapter =>
      _currentAudiobook?.chapters.isNotEmpty == true
          ? _currentAudiobook!.chapters[_currentChapterIndex]
          : null;
  int get currentChapterIndex => _currentChapterIndex;
  AudioPlayState get playerState => _playerState;
  Duration get position => _position;
  Duration get bufferedPosition => _bufferedPosition;
  Duration get duration => _duration;
  double get playbackSpeed => _playbackSpeed;
  LoopMode get loopMode => _loopMode;
  String? get errorMessage => _errorMessage;
  AudioTranscript? get currentTranscript => _currentTranscript;

  bool get isPlaying => _playerState == AudioPlayState.playing;
  bool get isPaused => _playerState == AudioPlayState.paused;
  bool get isLoading => _playerState == AudioPlayState.loading;
  bool get hasError => _playerState == AudioPlayState.error;
  bool get hasAudiobook => _currentAudiobook != null;

  /// Initialize stream listeners
  void _initializeListeners() {
    // Listen to player state changes - SAVE the handle!
    _playerStateSubscription = _audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.loading) {
        _playerState = AudioPlayState.loading;
      } else if (state.processingState == ProcessingState.buffering) {
        _playerState = AudioPlayState.loading;
      } else if (state.processingState == ProcessingState.ready) {
        _playerState = state.playing ? AudioPlayState.playing : AudioPlayState.paused;
      } else if (state.processingState == ProcessingState.completed) {
        _playerState = AudioPlayState.completed;
        _handleChapterCompletion();
      } else if (state.processingState == ProcessingState.idle) {
        _playerState = AudioPlayState.idle;
      }
      notifyListeners();
    });

    // Listen to position changes - SAVE the handle!
    _positionSubscription = _audioPlayer.positionStream.listen((position) {
      _position = position;
      notifyListeners();
    });

    // Listen to buffered position changes - SAVE the handle!
    _bufferedPositionSubscription = _audioPlayer.bufferedPositionStream.listen((bufferedPosition) {
      _bufferedPosition = bufferedPosition;
      notifyListeners();
    });

    // Listen to duration changes - SAVE the handle!
    _durationSubscription = _audioPlayer.durationStream.listen((duration) {
      _duration = duration ?? Duration.zero;
      notifyListeners();
    });
  }

  /// Load and play an audiobook
  Future<void> loadAudiobook(Audiobook audiobook, {int startChapter = 0}) async {
    try {
      _currentAudiobook = audiobook;
      _currentChapterIndex = startChapter;
      _playerState = AudioPlayState.loading;
      _errorMessage = null;
      notifyListeners();

      if (audiobook.chapters.isEmpty) {
        throw Exception('Audiobook has no chapters');
      }

      await _loadChapter(startChapter);
    } catch (e) {
      _playerState = AudioPlayState.error;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Load a single audio file (for testing/simple playback)
  Future<void> loadSingleAudio({
    required String audioUrl,
    required String title,
    String author = 'Unknown',
    String? coverUrl,
  }) async {
    final audiobook = Audiobook(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      author: author,
      coverUrl: coverUrl,
      chapters: [
        AudioChapter(
          id: '1',
          title: title,
          audioUrl: audioUrl,
          duration: Duration.zero,
          index: 0,
        ),
      ],
      totalDuration: Duration.zero,
    );
    await loadAudiobook(audiobook);
  }

  /// Load a specific chapter
  Future<void> _loadChapter(int index) async {
    if (_currentAudiobook == null ||
        index < 0 ||
        index >= _currentAudiobook!.chapters.length) {
      return;
    }

    try {
      _currentChapterIndex = index;
      _playerState = AudioPlayState.loading;
      _currentTranscript = null; // Clear previous transcript
      notifyListeners();

      final chapter = _currentAudiobook!.chapters[index];

      // Load transcript if available (don't wait for it)
      if (chapter.transcriptUrl != null) {
        _loadTranscript(chapter.transcriptUrl!);
      }

      // Determine audio source type
      if (chapter.audioUrl.startsWith('http')) {
        // Remote URL
        await _audioPlayer.setUrl(chapter.audioUrl);
      } else if (chapter.audioUrl.startsWith('asset:')) {
        // Flutter asset - just_audio uses setAsset with path after 'asset:'
        final assetPath = chapter.audioUrl.replaceFirst('asset:', '');
        await _audioPlayer.setAsset(assetPath);
      } else {
        // Local file path
        await _audioPlayer.setFilePath(chapter.audioUrl);
      }

      await _audioPlayer.setSpeed(_playbackSpeed);
      await _audioPlayer.play();
    } catch (e) {
      _playerState = AudioPlayState.error;
      _errorMessage = 'Failed to load audio: $e';
      notifyListeners();
    }
  }

  /// Load transcript JSON from URL
  Future<void> _loadTranscript(String url) async {
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'Accept-Charset': 'utf-8'},
      );
      if (response.statusCode == 200) {
        // Decode with UTF-8 to properly handle French and special characters
        final json = jsonDecode(utf8.decode(response.bodyBytes));
        _currentTranscript = AudioTranscript.fromJson(json);
        notifyListeners();
      }
    } catch (e) {
      // Transcript loading failed - not critical, just log it
      debugPrint('Failed to load transcript: $e');
    }
  }

  /// Manually set transcript (for testing or preloaded data)
  void setTranscript(AudioTranscript? transcript) {
    _currentTranscript = transcript;
    notifyListeners();
  }

  /// Handle chapter completion - auto-play next
  void _handleChapterCompletion() {
    if (_currentAudiobook == null) return;

    if (_loopMode == LoopMode.one) {
      // Repeat current chapter
      seekTo(Duration.zero);
      play();
    } else if (_currentChapterIndex < _currentAudiobook!.chapters.length - 1) {
      // Play next chapter
      skipToNext();
    } else if (_loopMode == LoopMode.all) {
      // Loop back to first chapter
      skipToChapter(0);
    }
  }

  /// Play/Resume playback
  Future<void> play() async {
    await _audioPlayer.play();
  }

  /// Pause playback
  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  /// Toggle play/pause
  Future<void> togglePlayPause() async {
    if (isPlaying) {
      await pause();
    } else {
      await play();
    }
  }

  /// Stop playback
  Future<void> stop() async {
    await _audioPlayer.stop();
    _playerState = AudioPlayState.idle;
    notifyListeners();
  }

  /// Seek to a specific position
  Future<void> seekTo(Duration position) async {
    await _audioPlayer.seek(position);
  }

  /// Seek forward by specified duration
  Future<void> seekForward({Duration duration = const Duration(seconds: 10)}) async {
    final newPosition = _position + duration;
    if (newPosition < _duration) {
      await seekTo(newPosition);
    } else {
      await seekTo(_duration);
    }
  }

  /// Seek backward by specified duration
  Future<void> seekBackward({Duration duration = const Duration(seconds: 10)}) async {
    final newPosition = _position - duration;
    if (newPosition > Duration.zero) {
      await seekTo(newPosition);
    } else {
      await seekTo(Duration.zero);
    }
  }

  /// Skip to next chapter
  Future<void> skipToNext() async {
    if (_currentAudiobook == null) return;

    if (_currentChapterIndex < _currentAudiobook!.chapters.length - 1) {
      await _loadChapter(_currentChapterIndex + 1);
    }
  }

  /// Skip to previous chapter
  Future<void> skipToPrevious() async {
    if (_currentAudiobook == null) return;

    // If more than 3 seconds in, restart current chapter
    if (_position.inSeconds > 3) {
      await seekTo(Duration.zero);
    } else if (_currentChapterIndex > 0) {
      await _loadChapter(_currentChapterIndex - 1);
    }
  }

  /// Skip to a specific chapter
  Future<void> skipToChapter(int index) async {
    await _loadChapter(index);
  }

  /// Set playback speed
  Future<void> setPlaybackSpeed(double speed) async {
    _playbackSpeed = speed;
    await _audioPlayer.setSpeed(speed);
    notifyListeners();
  }

  /// Cycle through loop modes
  void cycleLoopMode() {
    switch (_loopMode) {
      case LoopMode.off:
        _loopMode = LoopMode.all;
        break;
      case LoopMode.all:
        _loopMode = LoopMode.one;
        break;
      case LoopMode.one:
        _loopMode = LoopMode.off;
        break;
    }
    notifyListeners();
  }

  /// Format duration to string (MM:SS or HH:MM:SS)
  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
    return '${twoDigits(minutes)}:${twoDigits(seconds)}';
  }

  /// Get progress percentage (0.0 - 1.0)
  double get progress {
    if (_duration.inMilliseconds == 0) return 0.0;
    return _position.inMilliseconds / _duration.inMilliseconds;
  }

  /// Clear current audiobook
  void clearAudiobook() {
    _audioPlayer.stop();
    _currentAudiobook = null;
    _currentChapterIndex = 0;
    _playerState = AudioPlayState.idle;
    _position = Duration.zero;
    _bufferedPosition = Duration.zero;
    _duration = Duration.zero;
    _currentTranscript = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _playerStateSubscription?.cancel();
    _positionSubscription?.cancel();
    _bufferedPositionSubscription?.cancel();
    _durationSubscription?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }
}

/// Loop mode enum
enum LoopMode {
  off,
  all,
  one,
}
