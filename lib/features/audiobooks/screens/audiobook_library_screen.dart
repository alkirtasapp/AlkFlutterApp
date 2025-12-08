import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import '../controllers/audio_player_provider.dart';
import '../models/audiobook_model.dart';
import '../services/audiobook_repository.dart';
import '../services/audiobook_unlock_service.dart';
import '../widgets/mini_player.dart';
import '../widgets/unlock_code_dialog.dart';
import 'audiobook_player_screen.dart';

class AudiobookLibraryScreen extends StatefulWidget {
  const AudiobookLibraryScreen({super.key});

  @override
  State<AudiobookLibraryScreen> createState() => _AudiobookLibraryScreenState();
}

class _AudiobookLibraryScreenState extends State<AudiobookLibraryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AudiobookUnlockService _unlockService = AudiobookUnlockService();
  final AudiobookRepository _repository = AudiobookRepository();

  List<Audiobook> _audiobooks = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initServices();
  }

  Future<void> _initServices() async {
    await _unlockService.init();
    await _loadAudiobooks();
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
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Iconsax.book),
              text: 'Catalogue',
            ),
            Tab(
              icon: Icon(Iconsax.heart),
              text: 'Ma Bibliothèque',
            ),
          ],
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Theme.of(context).primaryColor,
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCatalogTab(),
                _buildMyLibraryTab(),
              ],
            ),
          ),
          // Mini Player at bottom
          const MiniPlayer(),
        ],
      ),
    );
  }

  Widget _buildCatalogTab() {
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
          final isUnlocked = _unlockService.isUnlocked(audiobook.id);
          return _buildAudiobookCard(context, audiobook, isUnlocked);
        },
      ),
    );
  }

  Widget _buildMyLibraryTab() {
    // Show loading indicator
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // Filter only unlocked audiobooks
    final unlockedAudiobooks = _audiobooks
        .where((audiobook) => _unlockService.isUnlocked(audiobook.id))
        .toList();

    // Show empty state if no unlocked books
    if (unlockedAudiobooks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Iconsax.lock_1,
                size: 80,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              const Text(
                'Aucun livre audio déverrouillé',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Déverrouillez des livres audio avec des codes pour les voir ici',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    // Show unlocked audiobooks with pull-to-refresh
    return RefreshIndicator(
      onRefresh: () => _loadAudiobooks(forceRefresh: true),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: unlockedAudiobooks.length,
        itemBuilder: (context, index) {
          final audiobook = unlockedAudiobooks[index];
          return _buildAudiobookCard(context, audiobook, true);
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

  Widget _buildAudiobookCard(BuildContext context, Audiobook audiobook, bool isUnlocked) {
    final primaryColor = Theme.of(context).primaryColor;

    return Opacity(
      opacity: isUnlocked ? 1.0 : 0.7,
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 2,
        child: InkWell(
          onTap: () => _handleAudiobookTap(context, audiobook, isUnlocked),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Cover with lock overlay
                Stack(
                  children: [
                    Container(
                      width: 80,
                      height: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: primaryColor.withOpacity(0.1),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: ColorFiltered(
                          colorFilter: isUnlocked
                              ? const ColorFilter.mode(
                                  Colors.transparent,
                                  BlendMode.multiply,
                                )
                              : ColorFilter.mode(
                                  Colors.grey.shade400,
                                  BlendMode.saturation,
                                ),
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
                    ),
                    // Lock icon overlay
                    if (!isUnlocked)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.black.withOpacity(0.3),
                          ),
                          child: const Center(
                            child: Icon(
                              Iconsax.lock,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(width: 16),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              audiobook.title,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: isUnlocked ? null : Colors.grey[600],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (!isUnlocked)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Verrouillé',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.orange.shade800,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        audiobook.author,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
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

                // Play/Lock button
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isUnlocked ? primaryColor : Colors.grey.shade400,
                  ),
                  child: Icon(
                    isUnlocked ? Iconsax.play5 : Iconsax.lock_1,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ],
            ),
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

  Future<void> _handleAudiobookTap(
    BuildContext context,
    Audiobook audiobook,
    bool isUnlocked,
  ) async {
    if (isUnlocked) {
      // Play the audiobook
      _playAudiobook(context, audiobook);
    } else {
      // Show unlock dialog
      final unlocked = await UnlockCodeDialog.show(
        context,
        audiobookTitle: audiobook.title,
      );

      if (unlocked) {
        // Refresh UI to show unlocked state
        setState(() {});
      }
    }
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
        unlockService: _unlockService,
        onPlay: (audiobook) => _playAudiobook(context, audiobook),
        onUnlock: (audiobook) async {
          final unlocked = await UnlockCodeDialog.show(
            context,
            audiobookTitle: audiobook.title,
          );
          if (unlocked) setState(() {});
          return unlocked;
        },
      ),
    );
  }
}

class AudiobookSearchDelegate extends SearchDelegate<Audiobook?> {
  final List<Audiobook> audiobooks;
  final AudiobookUnlockService unlockService;
  final void Function(Audiobook) onPlay;
  final Future<bool> Function(Audiobook) onUnlock;

  AudiobookSearchDelegate({
    required this.audiobooks,
    required this.unlockService,
    required this.onPlay,
    required this.onUnlock,
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
              'Entrez le titre ou l\'auteur d\'un livre audio',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    // Filter audiobooks by title or author
    final searchQuery = query.toLowerCase();
    final results = audiobooks.where((book) {
      return book.title.toLowerCase().contains(searchQuery) ||
          book.author.toLowerCase().contains(searchQuery);
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
        final isUnlocked = unlockService.isUnlocked(audiobook.id);
        return _buildSearchResultCard(context, audiobook, isUnlocked);
      },
    );
  }

  Widget _buildSearchResultCard(BuildContext context, Audiobook audiobook, bool isUnlocked) {
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
        subtitle: Text(
          audiobook.author,
          style: TextStyle(color: Colors.grey[600]),
        ),
        trailing: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isUnlocked ? primaryColor : Colors.grey.shade400,
          ),
          child: Icon(
            isUnlocked ? Iconsax.play5 : Iconsax.lock_1,
            color: Colors.white,
            size: 20,
          ),
        ),
        onTap: () async {
          if (isUnlocked) {
            close(context, audiobook);
            onPlay(audiobook);
          } else {
            final unlocked = await onUnlock(audiobook);
            if (unlocked && context.mounted) {
              close(context, audiobook);
              onPlay(audiobook);
            }
          }
        },
      ),
    );
  }
}
