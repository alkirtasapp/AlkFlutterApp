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

  /// Process scanned QR code and navigate accordingly
  Future<bool> processScannedCode(String qrCode) async {
    try {
      // Parse the URL to extract type and ID
      final parsedData = UrlParserService.parseAlkirtasUrl(qrCode);

      if (parsedData == null) {
        _showErrorSnackBar(UrlParserService.getErrorMessage(qrCode));
        return false;
      }

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
    } catch (e) {
      debugPrint('Error processing QR code: $e');
      _showErrorSnackBar('Erreur lors du traitement du QR code');
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

      // Navigate to ProductDetails screen
      Get.to(() => ProductDetails(
        productId: product['id'].toString(),
        productName: product['name'] ?? 'Produit',
        productReference: product['reference'] ?? '',
        productDiscount: product['discount']?.toString() ?? '0',
        productBrand: product['brand'] ?? '',
        productBrandId: product['id_manufacturer']?.toString() ?? '0',
        productImage: product['image'] ?? '',
        productImageList: product['images'] ?? [],
        productStock: product['stock']?.toString() ?? '0',
        productDescription: product['description'] ?? '',
        productOldPrice: product['price']?.toString() ?? '0',
        productNewPrice: product['price']?.toString() ?? '0',
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