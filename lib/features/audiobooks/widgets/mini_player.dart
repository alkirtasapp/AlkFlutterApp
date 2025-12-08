import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import '../controllers/audio_player_provider.dart';
import '../screens/audiobook_player_screen.dart';

/// A compact mini-player widget that appears at the bottom of screens
/// when audio is playing
class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioPlayerProvider>(
      builder: (context, audioProvider, child) {
        // Don't show if no audiobook is loaded
        if (!audioProvider.hasAudiobook) {
          return const SizedBox.shrink();
        }

        return GestureDetector(
          onTap: () => _openFullPlayer(context),
          child: Container(
            height: 72,
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Progress indicator
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: LinearProgressIndicator(
                    value: audioProvider.progress,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).primaryColor,
                    ),
                    minHeight: 3,
                  ),
                ),

                // Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        // Cover
                        _buildCover(context, audioProvider),

                        const SizedBox(width: 12),

                        // Title & Author
                        Expanded(
                          child: _buildInfo(context, audioProvider),
                        ),

                        // Controls
                        _buildControls(context, audioProvider),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCover(BuildContext context, AudioPlayerProvider audioProvider) {
    final coverUrl = audioProvider.currentAudiobook?.coverUrl;

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Theme.of(context).primaryColor.withOpacity(0.1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: coverUrl != null && coverUrl.isNotEmpty
            ? Image.network(
                coverUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildDefaultCover(context),
              )
            : _buildDefaultCover(context),
      ),
    );
  }

  Widget _buildDefaultCover(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.7),
          ],
        ),
      ),
      child: const Icon(
        Iconsax.book,
        color: Colors.white,
        size: 24,
      ),
    );
  }

  Widget _buildInfo(BuildContext context, AudioPlayerProvider audioProvider) {
    final title = audioProvider.currentChapter?.title ??
        audioProvider.currentAudiobook?.title ??
        'Livre Audio';
    final author = audioProvider.currentAudiobook?.author ?? '';

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (author.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            author,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  Widget _buildControls(BuildContext context, AudioPlayerProvider audioProvider) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Rewind 10s
        IconButton(
          icon: const Icon(Iconsax.backward_10_seconds, size: 22),
          onPressed: audioProvider.seekBackward,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        ),

        // Play/Pause
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context).primaryColor,
          ),
          child: audioProvider.isLoading
              ? const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                )
              : IconButton(
                  icon: Icon(
                    audioProvider.isPlaying ? Iconsax.pause : Iconsax.play5,
                    color: Colors.white,
                    size: 22,
                  ),
                  onPressed: audioProvider.togglePlayPause,
                  padding: EdgeInsets.zero,
                ),
        ),

        // Forward 10s
        IconButton(
          icon: const Icon(Iconsax.forward_10_seconds, size: 22),
          onPressed: audioProvider.seekForward,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        ),

        // Close
        IconButton(
          icon: Icon(Iconsax.close_circle, size: 22, color: Colors.grey[600]),
          onPressed: () {
            audioProvider.stop();
            audioProvider.clearAudiobook();
          },
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        ),
      ],
    );
  }

  void _openFullPlayer(BuildContext context) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const AudiobookPlayerScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeOutCubic;

          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }
}
