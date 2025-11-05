import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:alkirtas/services/url_parser_service.dart';
import 'package:alkirtas/navigation_menu.dart';
import 'package:alkirtas/features/shop/controllers/product_controller_store.dart';
import 'package:alkirtas/features/shop/screens/product_details/product_details.dart';
import 'package:alkirtas/features/shop/controllers/categories_store_controller.dart';

/// Controller for handling QR code navigation and deep linking
class QrNavigationController extends GetxController {
  final NavigationController? _navigationController;

  QrNavigationController(this._navigationController);

  /// Process scanned QR code or barcode and navigate accordingly
  Future<bool> processScannedCode(String scannedCode) async {
    try {
      // Try to parse as URL first (QR code with Alkirtas URL)
      final parsedData = UrlParserService.parseAlkirtasUrl(scannedCode);

      if (parsedData != null) {
        // It's a valid Alkirtas URL (QR Code)
        final String type = parsedData['type'];
        final int id = parsedData['id'];

        // Validate the ID
        if (!_isValidId(id)) {
          _showErrorSnackBar('ID invalide détecté');
          return false;
        }

        // Navigate based on type
        switch (type) {
          case 'category':
            return await _navigateToCategory(id);
          case 'product':
            return await _navigateToProduct(id);
          default:
            _showErrorSnackBar('Type de navigation non reconnu');
            return false;
        }
      } else {
        // Not a valid URL, treat as product barcode (EAN13)
        debugPrint('No valid URL found, treating as barcode: $scannedCode');
        return await _searchProductByBarcode(scannedCode);
      }
    } catch (e) {
      debugPrint('Error processing scanned code: $e');
      _showErrorSnackBar('Erreur lors du traitement du code');
      return false;
    }
  }

  /// Navigate to category screen
  Future<bool> _navigateToCategory(int categoryId) async {
    try {
      // Show loading indicator
      _showLoadingSnackBar('Chargement de la catégorie...');

      // Fetch category details to get the actual category name
      final categoriesController = CategoriesStoreController();
      await categoriesController.fetchAllCategories();

      // Find category name from main categories or category tree
      String? categoryName;

      // Check in main categories first
      for (var entry in categoriesController.mainCategories.entries) {
        if (entry.value == categoryId) {
          categoryName = entry.key;
          break;
        }
      }

      // If not found in main categories, search in category tree
      if (categoryName == null) {
        for (var subcategories in categoriesController.categoryTree.values) {
          for (var subcategory in subcategories) {
            if (subcategory['id'] == categoryId) {
              categoryName = subcategory['name'];
              break;
            }
          }
          if (categoryName != null) break;
        }
      }

      // Close the QR scanner first
      Get.back(); // Close the scanner

      // Small delay to ensure the scanner is closed before navigating
      await Future.delayed(const Duration(milliseconds: 100));

      // Use the existing navigation controller to navigate to store with category
      _navigationController?.navigateToStoreDrawer(
        categoryId: categoryId,
        categoryName: categoryName ?? 'Catégorie $categoryId',
      );

      // Show success message
      _showSuccessSnackBar('Catégorie chargée avec succès');

      return true;
    } catch (e) {
      debugPrint('Error navigating to category: $e');
      _showErrorSnackBar('Erreur lors de la navigation vers la catégorie');
      return false;
    }
  }

  /// Navigate to product details screen
  Future<bool> _navigateToProduct(int productId) async {
    try {
      // Show loading indicator
      _showLoadingSnackBar('Chargement du produit...');

      // Fetch product details from API
      final productController = ProductControllerStore();
      final productData = await productController.fetchProductsByIds([productId]);

      if (productData == null || productData.isEmpty) {
        _showErrorSnackBar('Produit non trouvé');
        return false;
      }

      final product = productData.first;

      // Close the QR scanner first, then navigate to product details
      Get.back(); // Close the scanner

      // Small delay to ensure the scanner is closed before navigating
      await Future.delayed(const Duration(milliseconds: 100));

      // Calculate prices with discount
      final double discount = product['discount']?.toDouble() ?? 0.0;
      final double ttcPrice = product['ttc_price']?.toDouble() ?? product['price']?.toDouble() ?? 0.0;

      String productOldPrice;
      String productNewPrice;

      if (discount > 0) {
        // If there's a discount, oldPrice is the original ttc price
        productOldPrice = ttcPrice.toStringAsFixed(2);
        // newPrice is ttc price with discount applied
        productNewPrice = (ttcPrice * (1 - discount / 100)).toStringAsFixed(2);
      } else {
        // If no discount, both prices are the same
        productOldPrice = ttcPrice.toStringAsFixed(2);
        productNewPrice = ttcPrice.toStringAsFixed(2);
      }

      // Navigate to ProductDetails screen
      Get.to(() => ProductDetails(
        productId: product['id'].toString(),
        productName: product['name'] ?? 'Produit',
        productReference: product['reference'] ?? '',
        productDiscount: discount > 0 ? discount.toStringAsFixed(0) : '0',
        productBrand: product['brand'] ?? '',
        productBrandId: product['id_manufacturer']?.toString() ?? '0',
        productImage: product['image'] ?? '',
        productImageList: product['images'] ?? [],
        productStock: product['stock']?.toString() ?? '0',
        productDescription: product['description'] ?? '',
        productOldPrice: productOldPrice,
        productNewPrice: productNewPrice,
        productFeatures: product['features'] ?? [],
      ));

      // Show success message
      _showSuccessSnackBar('Produit chargé avec succès');

      return true;
    } catch (e) {
      debugPrint('Error navigating to product: $e');
      _showErrorSnackBar('Erreur lors du chargement du produit: ${e.toString()}');
      return false;
    }
  }

  /// Search for product by barcode and navigate
  Future<bool> _searchProductByBarcode(String barcode) async {
    try {
      // Show loading indicator
      _showLoadingSnackBar('Recherche du produit par code-barres...');

      // Search product by barcode
      final productController = ProductControllerStore();
      final product = await productController.searchProductByBarcode(barcode);

      if (product == null) {
        _showErrorSnackBar('Aucun produit trouvé avec ce code-barres');
        return false;
      }

      // Check if product is active
      if (product['active']?.toString() != '1') {
        _showErrorSnackBar('Ce produit n\'est plus disponible');
        return false;
      }

      // Close the QR scanner first, then navigate to product details
      Get.back(); // Close the scanner

      // Small delay to ensure the scanner is closed before navigating
      await Future.delayed(const Duration(milliseconds: 100));

      // Calculate prices with discount
      final double discount = product['discount']?.toDouble() ?? 0.0;
      final double ttcPrice = product['ttc_price']?.toDouble() ?? product['price']?.toDouble() ?? 0.0;

      String productOldPrice;
      String productNewPrice;

      if (discount > 0) {
        // If there's a discount, oldPrice is the original ttc price
        productOldPrice = ttcPrice.toStringAsFixed(2);
        // newPrice is ttc price with discount applied
        productNewPrice = (ttcPrice * (1 - discount / 100)).toStringAsFixed(2);
      } else {
        // If no discount, both prices are the same
        productOldPrice = ttcPrice.toStringAsFixed(2);
        productNewPrice = ttcPrice.toStringAsFixed(2);
      }

      // Navigate to ProductDetails screen
      Get.to(() => ProductDetails(
        productId: product['id'].toString(),
        productName: product['name'] ?? 'Produit',
        productReference: product['reference'] ?? '',
        productDiscount: discount > 0 ? discount.toStringAsFixed(0) : '0',
        productBrand: product['brand'] ?? '',
        productBrandId: product['id_manufacturer']?.toString() ?? '0',
        productImage: product['image_urls']?.isNotEmpty == true
            ? product['image_urls'][0]
            : '',
        productImageList: List<String>.from(product['image_urls'] ?? []),
        productStock: product['quantity']?.toString() ?? '0',
        productDescription: product['description'] ?? '',
        productOldPrice: productOldPrice,
        productNewPrice: productNewPrice,
        productFeatures: [],
      ));

      // Show success message
      _showSuccessSnackBar('Produit trouvé : ${product['name']}');

      return true;
    } catch (e) {
      debugPrint('Error searching product by barcode: $e');
      _showErrorSnackBar('Erreur lors de la recherche du produit');
      return false;
    }
  }

  /// Validate if ID is within acceptable range
  bool _isValidId(int id) {
    return id > 0 && id < 999999;
  }

  /// Show loading snackbar
  void _showLoadingSnackBar(String message) {
    Get.snackbar(
      'Chargement',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.blue.withOpacity(0.8),
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
    );
  }

  /// Show success snackbar
  void _showSuccessSnackBar(String message) {
    Get.snackbar(
      'Succès',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green.withOpacity(0.8),
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
      icon: const Icon(Icons.check_circle, color: Colors.white),
    );
  }

  /// Show error snackbar
  void _showErrorSnackBar(String message) {
    Get.snackbar(
      'Erreur',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red.withOpacity(0.8),
      colorText: Colors.white,
      duration: const Duration(seconds: 4),
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
      icon: const Icon(Icons.error, color: Colors.white),
    );
  }

  /// Get user-friendly type name in French
  String getTypeName(String type) {
    switch (type) {
      case 'category':
        return 'catégorie';
      case 'product':
        return 'produit';
      default:
        return 'élément';
    }
  }

  /// Format ID for display
  String formatId(String type, int id) {
    return '${getTypeName(type)} (ID: $id)';
  }
}