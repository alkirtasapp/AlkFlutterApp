import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:iconsax/iconsax.dart';
import '../controllers/audio_player_provider.dart';
import '../models/audiobook_model.dart';
import '../widgets/synced_text_display.dart';

class AudiobookPlayerScreen extends StatefulWidget {
  final String? audioPath;
  final String? title;
  final String? author;
  final String? coverUrl;

  const AudiobookPlayerScreen({
    super.key,
    this.audioPath,
    this.title,
    this.author,
    this.coverUrl,
  });

  @override
  State<AudiobookPlayerScreen> createState() => _AudiobookPlayerScreenState();
}

class _AudiobookPlayerScreenState extends State<AudiobookPlayerScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              primaryColor.withOpacity(0.12),
              primaryColor.withOpacity(0.04),
              theme.scaffoldBackgroundColor,
            ],
            stops: const [0.0, 0.35, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context),
              _buildCoverArt(context),
              Expanded(
                child: _buildMainTextView(context),
              ),
              _buildBottomControls(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Iconsax.arrow_down_1),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            // Only rebuilds when chapter/audiobook changes
            child: Selector<AudioPlayerProvider, String>(
              selector: (_, p) => widget.title ??
                  p.currentChapter?.title ??
                  p.currentAudiobook?.title ??
                  'Livre Audio',
              builder: (_, displayTitle, __) => Column(
                children: [
                  Text(
                    'Lecture en cours',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    displayTitle,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Iconsax.menu),
            onPressed: () => _showChaptersSheet(context),
          ),
        ],
      ),
    );
  }

  Widget _buildCoverArt(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final screenHeight = MediaQuery.of(context).size.height;
    // Cover takes max 25% of screen height for balance with transcript
    final coverSize = (screenHeight * 0.22).clamp(120.0, 200.0);

    return Selector<AudioPlayerProvider, String?>(
      selector: (_, p) => widget.coverUrl ?? p.currentAudiobook?.coverUrl,
      builder: (_, coverUrl, __) {
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 12),
          child: Center(
            child: Container(
              width: coverSize,
              height: coverSize,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.3),
                    blurRadius: 25,
                    offset: const Offset(0, 12),
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: coverUrl != null && coverUrl.isNotEmpty
                    ? Image.network(
                        coverUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return _buildCoverPlaceholder(primaryColor);
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return _buildCoverPlaceholder(primaryColor);
                        },
                      )
                    : _buildCoverPlaceholder(primaryColor),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCoverPlaceholder(Color primaryColor) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryColor.withOpacity(0.3),
            primaryColor.withOpacity(0.1),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Iconsax.book,
          size: 80,
          color: primaryColor.withOpacity(0.5),
        ),
      ),
    );
  }

  Widget _buildMainTextView(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white.withOpacity(0.6),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        // Only rebuilds when transcript or position changes
        child: Selector<AudioPlayerProvider, ({AudioTranscript? transcript, Duration position})>(
          selector: (_, p) => (transcript: p.currentTranscript, position: p.position),
          builder: (_, data, __) {
            final audioProvider = Provider.of<AudioPlayerProvider>(context, listen: false);
            return SyncedTextDisplay(
              transcript: data.transcript,
              currentPosition: data.position,
              onSegmentTap: audioProvider.seekTo,
            );
          },
        ),
      ),
    );
  }

  Widget _buildBottomControls(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          _buildProgressBar(context),
          const SizedBox(height: 20),
          _buildPlaybackControls(context),
          const SizedBox(height: 12),
          _buildAdditionalControls(context),
        ],
      ),
    );
  }

  Widget _buildProgressBar(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    // Only rebuilds when position/buffered/duration changes
    return Selector<AudioPlayerProvider, ({Duration position, Duration buffered, Duration total})>(
      selector: (_, p) => (position: p.position, buffered: p.bufferedPosition, total: p.duration),
      builder: (_, data, __) {
        final audioProvider = Provider.of<AudioPlayerProvider>(context, listen: false);
        return ProgressBar(
          progress: data.position,
          buffered: data.buffered,
          total: data.total,
          onSeek: audioProvider.seekTo,
          progressBarColor: primaryColor,
          bufferedBarColor: primaryColor.withOpacity(0.3),
          baseBarColor: Colors.grey[300],
          thumbColor: primaryColor,
          thumbRadius: 8,
          barHeight: 4,
          timeLabelTextStyle: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        );
      },
    );
  }

  Widget _buildPlaybackControls(BuildContext context) {
    final audioProvider = Provider.of<AudioPlayerProvider>(context, listen: false);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Iconsax.previous, size: 28),
          onPressed: audioProvider.skipToPrevious,
          padding: const EdgeInsets.all(8),
        ),
        IconButton(
          icon: const Icon(Iconsax.backward_10_seconds, size: 24),
          onPressed: audioProvider.seekBackward,
          padding: const EdgeInsets.all(8),
        ),
        const SizedBox(width: 8),
        _buildPlayPauseButton(context),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Iconsax.forward_10_seconds, size: 24),
          onPressed: audioProvider.seekForward,
          padding: const EdgeInsets.all(8),
        ),
        IconButton(
          icon: const Icon(Iconsax.next, size: 28),
          onPressed: audioProvider.skipToNext,
          padding: const EdgeInsets.all(8),
        ),
      ],
    );
  }

  Widget _buildPlayPauseButton(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryColor,
            primaryColor.withOpacity(0.8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      // Only rebuilds when isPlaying or isLoading changes
      child: Selector<AudioPlayerProvider, ({bool isPlaying, bool isLoading})>(
        selector: (_, p) => (isPlaying: p.isPlaying, isLoading: p.isLoading),
        builder: (_, data, __) {
          final audioProvider = Provider.of<AudioPlayerProvider>(context, listen: false);
          return data.isLoading
              ? const Center(
                  child: SizedBox(
                    width: 30,
                    height: 30,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                  ),
                )
              : IconButton(
                  icon: Icon(
                    data.isPlaying ? Iconsax.pause : Iconsax.play5,
                    color: Colors.white,
                    size: 35,
                  ),
                  onPressed: audioProvider.togglePlayPause,
                );
        },
      ),
    );
  }

  Widget _buildAdditionalControls(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final audioProvider = Provider.of<AudioPlayerProvider>(context, listen: false);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildSpeedButton(context),
        // Loop button - only rebuilds when loopMode changes
        Selector<AudioPlayerProvider, LoopMode>(
          selector: (_, p) => p.loopMode,
          builder: (_, loopMode, __) => IconButton(
            icon: Icon(
              loopMode == LoopMode.one ? Iconsax.repeate_one : Iconsax.repeat,
              color: loopMode != LoopMode.off ? primaryColor : Colors.grey[600],
            ),
            onPressed: audioProvider.cycleLoopMode,
          ),
        ),
      ],
    );
  }

  Widget _buildSpeedButton(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    // Only rebuilds when playbackSpeed changes
    return Selector<AudioPlayerProvider, double>(
      selector: (_, p) => p.playbackSpeed,
      builder: (_, playbackSpeed, __) => InkWell(
        onTap: () => _showSpeedSheet(context),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: primaryColor.withOpacity(0.3),
            ),
          ),
          child: Text(
            '${playbackSpeed}x',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: primaryColor,
            ),
          ),
        ),
      ),
    );
  }

  void _showSpeedSheet(BuildContext context) {
    final speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];
    final primaryColor = Theme.of(context).primaryColor;
    final audioProvider = Provider.of<AudioPlayerProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Vitesse de lecture',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Selector<AudioPlayerProvider, double>(
              selector: (_, p) => p.playbackSpeed,
              builder: (_, currentSpeed, __) => Wrap(
                spacing: 12,
                runSpacing: 12,
                children: speeds.map((speed) {
                  final isSelected = currentSpeed == speed;
                  return ChoiceChip(
                    label: Text('${speed}x'),
                    selected: isSelected,
                    onSelected: (_) {
                      audioProvider.setPlaybackSpeed(speed);
                      Navigator.pop(sheetContext);
                    },
                    selectedColor: primaryColor,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                      fontWeight: FontWeight.w500,
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showChaptersSheet(BuildContext context) {
    final audioProvider =
        Provider.of<AudioPlayerProvider>(context, listen: false);
    final chapters = audioProvider.currentAudiobook?.chapters ?? [];
    final primaryColor = Theme.of(context).primaryColor;

    if (chapters.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucun chapitre disponible')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Chapitres',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: chapters.length,
                itemBuilder: (context, index) {
                  final chapter = chapters[index];
                  final isPlaying = index == audioProvider.currentChapterIndex;

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isPlaying
                          ? primaryColor
                          : Colors.grey[200],
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: isPlaying ? Colors.white : Colors.black,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    title: Text(
                      chapter.title,
                      style: TextStyle(
                        fontWeight:
                            isPlaying ? FontWeight.bold : FontWeight.normal,
                        color: isPlaying ? primaryColor : null,
                      ),
                    ),
                    subtitle: Text(audioProvider.formatDuration(chapter.duration)),
                    trailing: isPlaying
                        ? Icon(Iconsax.volume_high, color: primaryColor)
                        : null,
                    onTap: () {
                      audioProvider.skipToChapter(index);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

}
