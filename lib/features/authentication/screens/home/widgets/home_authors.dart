import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:alkirtas/data/controllers/author_service.dart';
import 'package:alkirtas/features/shop/screens/author/author_products_screen.dart';
import 'package:alkirtas/utils/constants/colors.dart';
import 'package:alkirtas/utils/constants/size.dart';
import 'package:alkirtas/common/widgets/texts/section_heading.dart';

class HomeAuthorsSection extends StatefulWidget {
  const HomeAuthorsSection({super.key});

  @override
  State<HomeAuthorsSection> createState() => _HomeAuthorsSectionState();
}

class _HomeAuthorsSectionState extends State<HomeAuthorsSection> {
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

  String _selectedLetter = 'A';
  bool _showArabic = false;
  List<Map<String, dynamic>> _authors = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAuthors();
  }

  Future<void> _loadAuthors() async {
    setState(() => _isLoading = true);

    final authors = await AuthorService.getAuthorsByLetter(_selectedLetter);

    setState(() {
      _authors = authors;
      _isLoading = false;
    });
  }

  void _selectLetter(String letter) {
    if (letter != _selectedLetter) {
      setState(() => _selectedLetter = letter);
      _loadAuthors();
    }
  }

  void _toggleLanguage() {
    setState(() {
      _showArabic = !_showArabic;
      _selectedLetter = _showArabic ? arabicLetters.first : latinLetters.first;
    });
    _loadAuthors();
  }

  @override
  Widget build(BuildContext context) {
    final letters = _showArabic ? arabicLetters : latinLetters;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AlkSize.defaultSpace),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const AlkSectionHeading(
                title: 'Auteurs',
                showActionButton: false,
              ),
              // Language toggle button
              GestureDetector(
                onTap: _toggleLanguage,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AlkColors.AppSecColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _showArabic ? 'A-Z' : 'ع-ي',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AlkColors.AppSecColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AlkSize.spaceBtwItems / 2),

        // Alphabet filter bar
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AlkSize.defaultSpace / 2),
            itemCount: letters.length,
            itemBuilder: (context, index) {
              final letter = letters[index];
              final isSelected = letter == _selectedLetter;

              return GestureDetector(
                onTap: () => _selectLetter(letter),
                child: Container(
                  width: 36,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: isSelected ? AlkColors.AppSecColor : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    letter,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : Colors.grey.shade700,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AlkSize.spaceBtwItems),

        // Authors grid
        SizedBox(
          height: 130,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _authors.isEmpty
                  ? Center(
                      child: Text(
                        'Aucun auteur trouvé',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    )
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: AlkSize.defaultSpace / 2),
                      itemCount: _authors.length,
                      itemBuilder: (context, index) {
                        final author = _authors[index];
                        return _buildAuthorCard(author);
                      },
                    ),
        ),
        const SizedBox(height: AlkSize.spaceBtwItems),
      ],
    );
  }

  Widget _buildAuthorCard(Map<String, dynamic> author) {
    final name = author['name']?.toString() ?? '';
    final imageUrl = author['image_url']?.toString() ?? '';

    return GestureDetector(
      onTap: () => Get.to(() => AuthorProductsScreen(authorName: name)),
      child: Container(
        width: 100,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          children: [
            // Author image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 80,
                        height: 80,
                        color: AlkColors.AppSecColor.withOpacity(0.1),
                        child: Icon(
                          Icons.person,
                          size: 40,
                          color: AlkColors.AppSecColor,
                        ),
                      ),
                    )
                  : Container(
                      width: 80,
                      height: 80,
                      color: AlkColors.AppSecColor.withOpacity(0.1),
                      child: Icon(
                        Icons.person,
                        size: 40,
                        color: AlkColors.AppSecColor,
                      ),
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
      ),
    );
  }
}
