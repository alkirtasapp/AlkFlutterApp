import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:alkirtas/data/controllers/product_enriched_service.dart';
import 'package:alkirtas/features/authentication/screens/login/log_in.dart';
import 'package:alkirtas/features/shop/controllers/cart_provider.dart';
import 'package:alkirtas/features/shop/screens/product_details/product_details.dart';
import 'package:alkirtas/utils/backendData/userData.dart';
import 'package:alkirtas/utils/constants/colors.dart';

class EditorialProduct {
  EditorialProduct({
    required this.id,
    required this.name,
    required this.brand,
    required this.brandId,
    required this.reference,
    required this.description,
    required this.stock,
    required this.imageUrl,
    required this.imageUrls,
    required this.discountText,
    required this.oldPrice,
    required this.newPrice,
  });

  final String id;
  final String name;
  final String brand;
  final String brandId;
  final String reference;
  final String description;
  final int stock;
  final String imageUrl;
  final List<String> imageUrls;
  final String discountText;
  final String oldPrice;
  final String newPrice;

  factory EditorialProduct.fromEnriched(Map<String, dynamic> enriched) {
    final product = ProductEnrichedService.buildProductFromEnriched(enriched);
    final imageUrls = (product['image_urls'] as List<String>?) ?? [];
    final taxGroup = product['id_tax_rules_group'] as int? ?? 0;
    final basePrice = taxGroup == 0
        ? (product['price'] as double? ?? 0.0)
        : (product['ttc_price'] as double? ?? 0.0);
    final discount = product['discount'] as double? ?? 0.0;
    final finalPrice =
        discount > 0 ? basePrice * (1 - discount / 100) : basePrice;

    return EditorialProduct(
      id: product['id'].toString(),
      name: product['name'].toString(),
      brand: product['manufacturer_name'].toString(),
      brandId: product['id_manufacturer'].toString(),
      reference: product['reference'].toString(),
      description: product['description_short'].toString(),
      stock: int.tryParse(product['quantity'].toString()) ?? 0,
      imageUrl: imageUrls.isNotEmpty ? imageUrls.first : '',
      imageUrls: imageUrls,
      discountText: discount > 0 ? '${discount.toStringAsFixed(0)}%' : '',
      oldPrice: discount > 0 ? basePrice.toStringAsFixed(2) : '',
      newPrice: finalPrice.toStringAsFixed(2),
    );
  }

  void openDetails() {
    Get.to(() => ProductDetails(
          productId: id,
          productName: name,
          productReference: reference,
          productDiscount: discountText,
          productBrand: brand,
          productBrandId: brandId,
          productOldPrice: oldPrice,
          productNewPrice: newPrice,
          productDescription: description,
          productImage: imageUrl,
          productImageList: imageUrls,
          productStock: stock.toString(),
        ));
  }

  void addToCart(BuildContext context) {
    if (stock <= 0) return;
    if (UserData.id.isEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Connexion requise'),
          content: const Text(
              'Vous devez etre connecte pour ajouter des articles au panier.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Annuler')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AlkColors.AppFirstColor),
              onPressed: () {
                Navigator.of(ctx).pop();
                Get.to(() => LoginScreen());
              },
              child: const Text('Se connecter',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      return;
    }

    context.read<CartProvider>().addToCart(
          productId: id,
          productName: name,
          productBrand: brand,
          productImage: imageUrl,
          productPrice: newPrice,
          productDiscount: discountText,
          productBrandId: brandId,
          productOldPrice: oldPrice,
          productNewPrice: newPrice,
          productStock: stock.toString(),
          productDescription: description,
          productReference: reference,
          productImageList: imageUrls,
          productFeatures: const [],
          quantity: 1,
        );

    Get.snackbar(
      'Produit ajoute',
      '$name a ete ajoute au panier',
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 2),
      backgroundColor: AlkColors.success,
      colorText: Colors.white,
    );
  }
}
