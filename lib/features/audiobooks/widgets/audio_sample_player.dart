import 'package:alkirtas/utils/constants/colors.dart' show AlkColors;
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:alkirtas/utils/logging/logger.dart';
import '../models/audio_sample.dart';
import '../services/audio_sample_service.dart';

/// WhatsApp-style voice message player for audio samples
class AudioSamplePlayer extends StatefulWidget {
  final int productId;

  const AudioSamplePlayer({
    super.key,
    required this.productId,
  });

  @override
  State<AudioSamplePlayer> createState() => _AudioSamplePlayerState();
}

class _AudioSamplePlayerState extends State<AudioSamplePlayer> {
  final AudioSampleService _service = AudioSampleService();
  final AudioPlayer _player = AudioPlayer();

  AudioSample? _sample;
  bool _isLoading = true;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _loadSample();
    _setupPlayerListeners();
  }

  void _setupPlayerListeners() {
    _player.positionStream.listen((position) {
      if (mounted) setState(() => _position = position);
    });

    _player.durationStream.listen((duration) {
      if (mounted && duration != null) setState(() => _duration = duration);
    });

    _player.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state.playing;
          if (state.processingState == ProcessingState.completed) {
            _position = Duration.zero;
            _player.seek(Duration.zero);
            _player.pause();
          }
        });
      }
    });
  }

  Future<void> _loadSample() async {
    final sample = await _service.fetchSampleByProductId(widget.productId);
    if (mounted) {
      setState(() {
        _sample = sample;
        _isLoading = false;
      });

      if (sample != null) {
        try {
          await _player.setUrl(sample.audioUrl);
        } catch (e) {
          AlkLoggerHelper.error("Audio URL load failed", e);
        }
      }
    }
  }

  void _togglePlayPause() async {
    if (_isPlaying) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _sample == null) {
      return const SizedBox.shrink();
    }

    final progress = _duration.inMilliseconds > 0
        ? _position.inMilliseconds / _duration.inMilliseconds
        : 0.0;

    // Gradient colors from app theme
    final gradientStart = AlkColors.AppSecColor;
    final gradientEnd = AlkColors.AppFirstColor;
    const textColor = Color(0xFF6C757D);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [gradientStart, gradientEnd],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradientEnd.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Play/Pause button
          GestureDetector(
            onTap: _togglePlayPause,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Middle section
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Label row
                Row(
                  children: [
                    const Icon(
                      Icons.headphones_rounded,
                      size: 14,
                      color: Colors.white70,
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Extrait audio',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _isPlaying || _position.inSeconds > 0
                          ? _formatDuration(_position)
                          : _formatDuration(_duration.inSeconds > 0 ? _duration : _sample!.duration),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Progress bar
                LayoutBuilder(
                  builder: (context, constraints) {
                    final progressWidth = constraints.maxWidth;
                    return GestureDetector(
                      onTapDown: (details) {
                        final tapX = details.localPosition.dx;
                        final newProgress = (tapX / progressWidth).clamp(0.0, 1.0);
                        final newPosition = Duration(
                          milliseconds: (newProgress * _duration.inMilliseconds).round(),
                        );
                        _player.seek(newPosition);
                      },
                      onHorizontalDragUpdate: (details) {
                        final tapX = details.localPosition.dx;
                        final newProgress = (tapX / progressWidth).clamp(0.0, 1.0);
                        final newPosition = Duration(
                          milliseconds: (newProgress * _duration.inMilliseconds).round(),
                        );
                        _player.seek(newPosition);
                      },
                      child: Container(
                        height: 20,
                        alignment: Alignment.center,
                        child: Stack(
                          alignment: Alignment.centerLeft,
                          clipBehavior: Clip.none,
                          children: [
                            // Track background
                            Container(
                              height: 4,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            // Progress fill
                            Container(
                              height: 4,
                              width: progressWidth * progress.clamp(0.0, 1.0),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            // Thumb
                            Positioned(
                              left: (progressWidth * progress.clamp(0.0, 1.0)) - 6,
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
