import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import '../controllers/audio_player_provider.dart';
import '../models/audiobook_model.dart';
import '../services/audiobook_repository.dart';
import '../widgets/mini_player.dart';
import 'audiobook_player_screen.dart';

class AudiobookLibraryScreen extends StatefulWidget {
  const AudiobookLibraryScreen({super.key});

  @override
  State<AudiobookLibraryScreen> createState() => _AudiobookLibraryScreenState();
}

class _AudiobookLibraryScreenState extends State<AudiobookLibraryScreen> {
  final AudiobookRepository _repository = AudiobookRepository();

  List<Audiobook> _audiobooks = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAudiobooks();
  }

  Future<void> _loadAudiobooks({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final audiobooks = await _repository.fetchAudiobooks(forceRefresh: forceRefresh);
      setState(() {
        _audiobooks = audiobooks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Impossible de charger les livres audio';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Livres Audio',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Iconsax.search_normal),
            onPressed: () => _showSearchDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _buildAudiobooksList(),
          ),
          // Mini Player at bottom
          const MiniPlayer(),
        ],
      ),
    );
  }

  Widget _buildAudiobooksList() {
    // Show loading indicator
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // Show error state with retry
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Iconsax.warning_2, size: 60, color: Colors.orange[400]),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _loadAudiobooks(forceRefresh: true),
                icon: const Icon(Iconsax.refresh),
                label: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    // Show empty state
    if (_audiobooks.isEmpty) {
      return _buildEmptyState(
        icon: Iconsax.book,
        title: 'Aucun livre audio',
        subtitle: 'Explorez notre catalogue pour trouver des livres audio',
      );
    }

    // Show audiobooks list with pull-to-refresh
    return RefreshIndicator(
      onRefresh: () => _loadAudiobooks(forceRefresh: true),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _audiobooks.length,
        itemBuilder: (context, index) {
          final audiobook = _audiobooks[index];
          return _buildAudiobookCard(context, audiobook);
        },
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAudiobookCard(BuildContext context, Audiobook audiobook) {
    final primaryColor = Theme.of(context).primaryColor;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: InkWell(
        onTap: () => _playAudiobook(context, audiobook),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Cover
              Container(
                width: 80,
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: primaryColor.withOpacity(0.1),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: audiobook.coverUrl != null
                      ? Image.network(
                          audiobook.coverUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _buildDefaultBookCover(context),
                        )
                      : _buildDefaultBookCover(context),
                ),
              ),

              const SizedBox(width: 16),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      audiobook.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (audiobook.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        audiobook.description!,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Iconsax.clock, size: 14, color: Colors.grey[500]),
                            const SizedBox(width: 4),
                            Text(
                              _formatTotalDuration(audiobook.totalDuration),
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Iconsax.book_1, size: 14, color: Colors.grey[500]),
                            const SizedBox(width: 4),
                            Text(
                              '${audiobook.chapters.length} chap.',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Play button
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primaryColor,
                ),
                child: const Icon(
                  Iconsax.play5,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultBookCover(BuildContext context) {
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
      child: const Center(
        child: Icon(
          Iconsax.book,
          color: Colors.white,
          size: 36,
        ),
      ),
    );
  }

  String _formatTotalDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes} min';
  }

  void _playAudiobook(BuildContext context, Audiobook audiobook) async {
    final audioProvider = Provider.of<AudioPlayerProvider>(context, listen: false);
    await audioProvider.loadAudiobook(audiobook);

    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const AudiobookPlayerScreen(),
        ),
      );
    }
  }

  void _showSearchDialog(BuildContext context) {
    showSearch(
      context: context,
      delegate: AudiobookSearchDelegate(
        audiobooks: _audiobooks,
        onPlay: (audiobook) => _playAudiobook(context, audiobook),
      ),
    );
  }
}

class AudiobookSearchDelegate extends SearchDelegate<Audiobook?> {
  final List<Audiobook> audiobooks;
  final void Function(Audiobook) onPlay;

  AudiobookSearchDelegate({
    required this.audiobooks,
    required this.onPlay,
  });

  @override
  String get searchFieldLabel => 'Rechercher un livre audio...';

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () => query = '',
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults(context);
  }

  Widget _buildSearchResults(BuildContext context) {
    if (query.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.search_normal, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Entrez le titre d\'un livre audio',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    // Filter audiobooks by title
    final searchQuery = query.toLowerCase();
    final results = audiobooks.where((book) {
      return book.title.toLowerCase().contains(searchQuery);
    }).toList();

    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.book, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Aucun résultat pour "$query"',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final audiobook = results[index];
        return _buildSearchResultCard(context, audiobook);
      },
    );
  }

  Widget _buildSearchResultCard(BuildContext context, Audiobook audiobook) {
    final primaryColor = Theme.of(context).primaryColor;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 50,
          height: 65,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: primaryColor.withOpacity(0.1),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: audiobook.coverUrl != null
                ? Image.network(audiobook.coverUrl!, fit: BoxFit.cover)
                : Icon(Iconsax.book, color: primaryColor),
          ),
        ),
        title: Text(
          audiobook.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: audiobook.description != null
            ? Text(
                audiobook.description!,
                style: TextStyle(color: Colors.grey[600]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        trailing: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: primaryColor,
          ),
          child: const Icon(
            Iconsax.play5,
            color: Colors.white,
            size: 20,
          ),
        ),
        onTap: () {
          close(context, audiobook);
          onPlay(audiobook);
        },
      ),
    );
  }
}
