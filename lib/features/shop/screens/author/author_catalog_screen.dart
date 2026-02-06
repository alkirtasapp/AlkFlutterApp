import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:alkirtas/data/controllers/author_service.dart';
import 'package:alkirtas/features/shop/screens/author/author_products_screen.dart';
import 'package:alkirtas/utils/constants/colors.dart';
import 'package:alkirtas/utils/constants/size.dart';
import 'package:alkirtas/common/widgets/appbar/appbar.dart';

class AuthorCatalogScreen extends StatefulWidget {
  const AuthorCatalogScreen({super.key});

  @override
  State<AuthorCatalogScreen> createState() => _AuthorCatalogScreenState();
}

class _AuthorCatalogScreenState extends State<AuthorCatalogScreen> with SingleTickerProviderStateMixin {
  // Latin letters A-Z
  static const List<String> latinLetters = [
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M',
    'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'
  ];

  // Arabic letters
  static const List<String> arabicLetters = [
    'ا', 'ب', 'ت', 'ث', 'ج', 'ح', 'خ', 'د', 'ذ', 'ر', 'ز', 'س', 'ش',
    'ص', 'ض', 'ط', 'ظ', 'ع', 'غ', 'ف', 'ق', 'ك', 'ل', 'م', 'ن', 'ه', 'و', 'ي'
  ];

  late TabController _tabController;
  bool _showArabic = false;
  Map<String, List<Map<String, dynamic>>> _cachedAuthors = {};
  String _currentLetter = '';
  bool _isLoading = false;

  List<String> get _currentLetters => _showArabic ? arabicLetters : latinLetters;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _currentLetters.length, vsync: this);
    _tabController.addListener(_onTabChanged);
    _currentLetter = _currentLetters.first;
    _loadAuthorsForLetter(_currentLetter);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      final letter = _currentLetters[_tabController.index];
      if (letter != _currentLetter) {
        setState(() => _currentLetter = letter);
        if (!_cachedAuthors.containsKey(letter)) {
          _loadAuthorsForLetter(letter);
        }
      }
    }
  }

  Future<void> _loadAuthorsForLetter(String letter) async {
    if (_cachedAuthors.containsKey(letter)) return;

    setState(() => _isLoading = true);

    final authors = await AuthorService.getAuthorsByLetter(letter);

    setState(() {
      _cachedAuthors[letter] = authors;
      _isLoading = false;
    });
  }

  void _toggleLanguage() {
    setState(() {
      _showArabic = !_showArabic;
      _cachedAuthors.clear();
      _tabController.dispose();
      _tabController = TabController(length: _currentLetters.length, vsync: this);
      _tabController.addListener(_onTabChanged);
      _currentLetter = _currentLetters.first;
    });
    _loadAuthorsForLetter(_currentLetter);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AlkAppBar(
        title: const Text('Auteurs'),
        showBackArrow: true,
        actions: [
          // Language toggle
          GestureDetector(
            onTap: _toggleLanguage,
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AlkColors.AppSecColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _showArabic ? 'A-Z' : 'ع-ي',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AlkColors.AppSecColor,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Alphabet tabs
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey.shade700,
              labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
              indicator: BoxDecoration(
                color: AlkColors.AppSecColor,
                borderRadius: BorderRadius.circular(8),
              ),
              indicatorSize: TabBarIndicatorSize.label,
              indicatorPadding: const EdgeInsets.symmetric(horizontal: -8, vertical: 8),
              tabAlignment: TabAlignment.start,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              tabs: _currentLetters.map((letter) => Tab(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(letter),
                ),
              )).toList(),
            ),
          ),
          const Divider(height: 1),

          // Authors grid
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildAuthorsGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthorsGrid() {
    final authors = _cachedAuthors[_currentLetter] ?? [];

    if (authors.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Aucun auteur trouvé pour "$_currentLetter"',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(AlkSize.defaultSpace),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
      ),
      itemCount: authors.length,
      itemBuilder: (context, index) => _buildAuthorCard(authors[index]),
    );
  }

  Widget _buildAuthorCard(Map<String, dynamic> author) {
    final name = author['name']?.toString() ?? '';
    final imageUrl = author['image_url']?.toString() ?? '';

    return GestureDetector(
      onTap: () => Get.to(() => AuthorProductsScreen(authorName: name)),
      child: Column(
        children: [
          // Author image
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
                    )
                  : _buildPlaceholder(),
            ),
          ),
          const SizedBox(height: 8),
          // Author name
          Text(
            name,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: double.infinity,
      color: AlkColors.AppSecColor.withOpacity(0.1),
      child: Icon(
        Icons.person,
        size: 48,
        color: AlkColors.AppSecColor.withOpacity(0.5),
      ),
    );
  }
}
