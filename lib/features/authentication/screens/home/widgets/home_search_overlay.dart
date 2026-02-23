import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:alkirtas/utils/constants/colors.dart';
import 'package:alkirtas/common/widgets/images/AlkCircularImage.dart';
import 'package:alkirtas/data/controllers/search_controller.dart';
import 'package:alkirtas/data/controllers/product_enriched_service.dart';
import 'package:alkirtas/data/controllers/author_service.dart';
import 'package:alkirtas/features/shop/controllers/product_controller_store.dart';
import 'package:alkirtas/features/shop/screens/brand/brand_products_screen.dart';
import 'package:alkirtas/features/shop/screens/author/author_products_screen.dart';
import 'package:alkirtas/navigation_menu.dart';

/// Inline search bar for the home screen with overlay suggestions.
/// Works like the store search bar — text field + dropdown overlay.
class HomeSearchBar extends StatefulWidget {
  final VoidCallback onClose;

  const HomeSearchBar({super.key, required this.onClose});

  @override
  State<HomeSearchBar> createState() => _HomeSearchBarState();
}

class _HomeSearchBarState extends State<HomeSearchBar> {
  final TextEditingController _textController = TextEditingController();
  final AlkSearchController _searchController = AlkSearchController();
  final ProductControllerStore _productController = ProductControllerStore();
  Timer? _debounceTimer;
  OverlayEntry? _overlayEntry;

  List<String> _productSuggestions = [];
  List<Map<String, dynamic>> _matchedBrands = [];
  List<Map<String, dynamic>> _matchedAuthors = [];

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _onTextChanged() {
    _debounceTimer?.cancel();

    if (_textController.text.trim().isEmpty) {
      _removeOverlay();
      _productSuggestions = [];
      _matchedBrands = [];
      _matchedAuthors = [];
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      _fetchSuggestions(_textController.text.trim());
    });
  }

  Future<void> _fetchSuggestions(String query) async {
    if (query.isEmpty) return;

    final results = await Future.wait([
      _searchController.searchProducts(query, offset: 0, limit: 8),
      ProductEnrichedService.searchBrands(query),
      AuthorService.searchAuthors(query),
    ]);

    if (!mounted || _textController.text.trim() != query) return;

    final List<int>? productIds = results[0] as List<int>?;
    _matchedBrands = results[1] as List<Map<String, dynamic>>;
    _matchedAuthors = results[2] as List<Map<String, dynamic>>;

    if (productIds != null && productIds.isNotEmpty) {
      final products = await _productController.fetchProductsByIds(productIds);
      if (mounted && _textController.text.trim() == query) {
        _productSuggestions = products
                ?.map((p) => p['name']?.toString() ?? '')
                .where((name) => name.isNotEmpty)
                .toSet()
                .toList() ??
            [];
      }
    } else {
      _productSuggestions = [];
    }

    if (!mounted) return;

    final hasSuggestions = _matchedBrands.isNotEmpty ||
        _matchedAuthors.isNotEmpty ||
        _productSuggestions.isNotEmpty;

    if (hasSuggestions) {
      _showSuggestionsOverlay();
    } else {
      _removeOverlay();
    }
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showSuggestionsOverlay() {
    _removeOverlay();

    _overlayEntry = OverlayEntry(
      builder: (overlayContext) {
        final brands = _matchedBrands;
        final authors = _matchedAuthors;
        final products = _productSuggestions;

        if (brands.isEmpty && authors.isEmpty && products.isEmpty) {
          return const SizedBox.shrink();
        }

        return Positioned(
          top: MediaQuery.of(overlayContext).padding.top + kToolbarHeight + 70,
          left: 12,
          right: 12,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 350),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: ListView(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                children: [
                  // Brands section
                  if (brands.isNotEmpty) ...[
                    _buildSectionHeader('Marques', Iconsax.shop),
                    ...brands.map((brand) => _buildBrandTile(brand)),
                    const Divider(height: 1),
                  ],
                  // Authors section
                  if (authors.isNotEmpty) ...[
                    _buildSectionHeader('Auteurs', Iconsax.pen_tool),
                    ...authors.map((author) => _buildAuthorTile(author)),
                    const Divider(height: 1),
                  ],
                  // Products section
                  if (products.isNotEmpty) ...[
                    _buildSectionHeader('Produits', Iconsax.box_1),
                    ...products.map((name) => _buildProductTile(name)),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _performSearch(String query) {
    if (query.trim().isEmpty) return;
    _removeOverlay();
    final navController = Get.find<NavigationController>();
    navController.navigateToStoreDrawer(searchQuery: query.trim());
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: Colors.grey.shade100,
      child: Row(
        children: [
          Icon(icon, size: 14, color: AlkColors.AppSecColor),
          const SizedBox(width: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AlkColors.AppSecColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandTile(Map<String, dynamic> brand) {
    final brandId = int.tryParse(brand['id_manufacturer'].toString()) ?? 0;
    final brandName = brand['manufacturer_name']?.toString() ?? '';
    final productCount = int.tryParse(brand['product_count'].toString()) ?? 0;

    return ListTile(
      dense: true,
      leading: AlkCircularImage(
        image: 'https://www.alkirtas.com/img/m/$brandId.jpg',
        backgroundColor: Colors.transparent,
        isNetworkImage: true,
        fit: BoxFit.contain,
        width: 28,
        height: 28,
      ),
      title: Text(
        brandName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 14),
      ),
      trailing: Text(
        '$productCount',
        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
      ),
      onTap: () {
        _removeOverlay();
        Get.to(() => BrandProductsScreen(
          brandId: brandId,
          brandName: brandName,
        ));
      },
    );
  }

  Widget _buildAuthorTile(Map<String, dynamic> author) {
    final authorName = author['name']?.toString() ?? '';
    final imageUrl = author['image_url']?.toString() ?? '';

    return ListTile(
      dense: true,
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: imageUrl.isNotEmpty
            ? Image.network(
                imageUrl,
                width: 28,
                height: 28,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AlkColors.AppSecColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.person, size: 16, color: AlkColors.AppSecColor),
                ),
              )
            : Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AlkColors.AppSecColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.person, size: 16, color: AlkColors.AppSecColor),
              ),
      ),
      title: Text(
        authorName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 14),
      ),
      onTap: () {
        _removeOverlay();
        Get.to(() => AuthorProductsScreen(authorName: authorName));
      },
    );
  }

  Widget _buildProductTile(String productName) {
    return ListTile(
      dense: true,
      leading: const Icon(Iconsax.search_normal, size: 18, color: Colors.grey),
      title: Text(
        productName,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 14),
      ),
      onTap: () {
        _textController.removeListener(_onTextChanged);
        _textController.text = productName;
        _textController.addListener(_onTextChanged);
        _removeOverlay();
        _performSearch(productName);
      },
    );
  }

  void _handleClear() {
    if (_textController.text.isNotEmpty) {
      _textController.clear();
      _removeOverlay();
    } else {
      _removeOverlay();
      widget.onClose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: TextField(
        controller: _textController,
        autofocus: true,
        decoration: InputDecoration(
          hintText: 'Rechercher un produit, marque, auteur...',
          prefixIcon: const Icon(Iconsax.search_normal),
          suffixIcon: IconButton(
            icon: const Icon(Icons.clear, size: 20),
            onPressed: _handleClear,
            tooltip: 'Fermer',
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
        onSubmitted: _performSearch,
        onChanged: (value) {
          setState(() {}); // Rebuild for clear button visibility
        },
      ),
    );
  }
}
