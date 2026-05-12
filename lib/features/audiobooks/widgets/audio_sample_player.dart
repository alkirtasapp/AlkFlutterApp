import 'dart:async';

import 'package:alkirtas/features/authentication/screens/login/log_in.dart';
import 'package:alkirtas/utils/backendData/userData.dart';
import 'package:alkirtas/utils/constants/colors.dart' show AlkColors;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
  static const List<String> _generationPhases = [
    'Recherche de la description...',
    'Analyse du contenu...',
    'Génération de la voix...',
    'Finalisation de l\'audio...',
    'Presque prêt...',
  ];

  final AudioSampleService _service = AudioSampleService();
  final AudioPlayer _player = AudioPlayer();

  AudioSample? _sample;
  bool _isLoading = true;
  bool _eligible = false;
  bool _isPlaying = false;
  bool _isGenerating = false;
  int _generationPhaseIndex = 0;
  Timer? _phaseTimer;
  String? _generationError;
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
    final lookup = await _service.fetchSampleByProductId(widget.productId);
    if (mounted) {
      setState(() {
        _sample = lookup.sample;
        _eligible = lookup.eligible;
        _isLoading = false;
      });

      if (lookup.sample != null) {
        try {
          await _player.setUrl(lookup.sample!.audioUrl);
        } catch (e) {
          AlkLoggerHelper.error("Audio URL load failed", e);
        }
      }
    }
  }

  void _togglePlayPause(BuildContext context) async {
    if (_isGenerating) return;

    if (!_isPlaying && UserData.id.isEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Connexion requise'),
          content: const Text('Vous devez être connecté pour écouter les extraits audio.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AlkColors.AppFirstColor, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10)),
              onPressed: () {
                Navigator.of(ctx).pop();
                Get.to(() => LoginScreen());
              },
              child: const Text('Se connecter', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      return;
    }

    if (_sample == null) {
      await _generateAndPlay();
      return;
    }

    if (_isPlaying) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  Future<void> _generateAndPlay() async {
    setState(() {
      _isGenerating = true;
      _generationPhaseIndex = 0;
      _generationError = null;
    });
    _phaseTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      if (_generationPhaseIndex < _generationPhases.length - 1) {
        setState(() => _generationPhaseIndex++);
      }
    });

    final result = await _service.generateSample(widget.productId);

    _phaseTimer?.cancel();
    _phaseTimer = null;
    if (!mounted) return;

    if (result.isSuccess) {
      setState(() {
        _sample = result.sample;
        _isGenerating = false;
      });
      try {
        await _player.setUrl(result.sample!.audioUrl);
        await _player.play();
      } catch (e) {
        AlkLoggerHelper.error('Audio URL load failed', e);
      }
    } else {
      setState(() {
        _isGenerating = false;
        _generationError = _errorMessageFor(result.error);
      });
    }
  }

  String _errorMessageFor(GenerateSampleErrorKind? kind) {
    switch (kind) {
      case GenerateSampleErrorKind.noBlurb:
        return "Description du livre introuvable.";
      case GenerateSampleErrorKind.timeout:
        return "Délai dépassé. Réessayez.";
      case GenerateSampleErrorKind.network:
        return "Erreur réseau. Réessayez.";
      case GenerateSampleErrorKind.ttsFailed:
      case GenerateSampleErrorKind.unknown:
      default:
        return "Échec de la génération. Réessayez.";
    }
  }

  @override
  void dispose() {
    _phaseTimer?.cancel();
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
    if (_isLoading) {
      return const SizedBox.shrink();
    }

    // Mirror the website hook gate: only render on book products
    // (sample exists, or product belongs to allowed categories 13/14/15).
    if (_sample == null && !_eligible) {
      return const SizedBox.shrink();
    }

    final progress = _duration.inMilliseconds > 0
        ? _position.inMilliseconds / _duration.inMilliseconds
        : 0.0;

    // Gradient colors from app theme
    final gradientStart = AlkColors.AppSecColor;
    final gradientEnd = AlkColors.AppFirstColor;

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
            onTap: () => _togglePlayPause(context),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: _isGenerating
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Icon(
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
                    Expanded(
                      child: Text(
                        _isGenerating
                            ? _generationPhases[_generationPhaseIndex]
                            : (_generationError ?? 'Extrait audio'),
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    if (!_isGenerating && _sample != null) ...[
                      const SizedBox(width: 8),
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
