import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:readmore/readmore.dart';
import 'package:alkirtas/common/widgets/providers/product_provider.dart';
import 'package:alkirtas/features/shop/screens/product_details/widgets/bottom_add_to_cart.dart';
import 'package:alkirtas/features/shop/screens/product_details/widgets/product_features.dart';
import '../../../../common/widgets/texts/section_heading.dart';
import '../../../../utils/constants/size.dart';
import '../../controllers/product_card_controller.dart';
import '../../controllers/product_controller_store.dart'; // Added to fetch product features
import 'widgets/product_detail_image_slider.dart';
import 'widgets/product_metadata.dart';
import 'widgets/reference.dart';

class ProductDetails extends StatefulWidget {
  final String productName;
  final String productReference;
  final String productDiscount;
  final String productBrand;
  final String productOldPrice;
  final String productNewPrice;
  final String productDescription;
  final String productBrandId;
  final String productId;
  final String productImage;
  final List<String> productImageList;
  final String productStock;
  final List<String>? productFeatures;

  const ProductDetails({
    super.key,
    required this.productName,
    required this.productDiscount,
    required this.productBrand,
    required this.productOldPrice,
    required this.productNewPrice,
    required this.productReference,
    required this.productStock,
    required this.productDescription,
    required this.productBrandId,
    required this.productId,
    required this.productImage,
    required this.productImageList,
    this.productFeatures = const [],
  });

  @override
  State<ProductDetails> createState() => _ProductDetailsState();
}

class _ProductDetailsState extends State<ProductDetails> {
  List<String> productFeatures = [];
  bool isLoadingFeatures = true;

  @override
  void initState() {
    super.initState();
    _fetchProductFeatures();
  }

  Future<void> _fetchProductFeatures() async {
    try {
      print("🟡 Fetching product features for ID: ${widget.productId}");

      final ProductControllerStore productController = ProductControllerStore();
      List<String> fetchedFeatures = await productController.fetchProductFeatures(widget.productId);

      print("✅ Features Fetched: $fetchedFeatures");

      setState(() {
        productFeatures = fetchedFeatures;
        isLoadingFeatures = false;
      });
    } catch (e) {
      print("❌ Error fetching product features: $e");
      setState(() {
        isLoadingFeatures = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final productPrice = widget.productDiscount.isNotEmpty
        ? widget.productNewPrice
        : (widget.productOldPrice.isNotEmpty ? widget.productOldPrice : widget.productNewPrice);

    final productImage = widget.productImage.isNotEmpty
        ? widget.productImage
        : 'https://www.alkirtas.com/img/default.jpg'; // Fallback image URL

    final productDescription = widget.productDescription.isNotEmpty
        ? widget.productDescription
        : 'Description non disponible'; // Fallback description

    print("Product Price: ${productPrice.isNotEmpty ? productPrice : 'N/A'}");
    print("Product discount: ${widget.productDiscount}");
    print("Product OLD Price: ${widget.productOldPrice}");
    print("Product NEW Price: ${widget.productNewPrice}");
    print("product features: $productFeatures");

    return Scaffold(
      bottomNavigationBar: AlkBottomAddToCart(
        productId: widget.productId,
        productName: widget.productName,
        productBrand: widget.productBrand,
        productImage: productImage,
        productPrice: productPrice,
        productDiscount: widget.productDiscount,
        productBrandId: widget.productBrandId,
        productOldPrice: widget.productOldPrice,
        productNewPrice: widget.productNewPrice,
        productStock: widget.productStock,
        productDescription: widget.productDescription,
        productReference: widget.productReference,
        productImageList: widget.productImageList,
        productFeatures: productFeatures,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            AlkProductImageSlider(
              productImages: widget.productImageList,
              productName: widget.productName,
            ),
            Padding(
              padding: EdgeInsets.only(
                  right: AlkSize.defaultSpace,
                  left: AlkSize.defaultSpace,
                  bottom: AlkSize.defaultSpace),
              child: Column(
                children: [
                  AlkRef(
                      title: 'Réference ',
                      icon: Iconsax.component5,
                      size: 15,
                      productReference: widget.productReference),
                  SizedBox(height: AlkSize.spaceBtwItems),
                  AlkProductMetadata(
                    productId: widget.productId,
                    productName: widget.productName,
                    productDiscount: widget.productDiscount,
                    productBrand: widget.productBrand,
                    productBrandId: widget.productBrandId,
                    productOldPrice: widget.productOldPrice,
                    productNewPrice: widget.productNewPrice,
                    //productStock: widget.productStock,
                  ),
                  SizedBox(height: AlkSize.spaceBtwItems),
                  AlkRef(
                    title: 'Déscription',
                    icon: Iconsax.document_text5,
                    size: 25,
                    productReference: '',
                  ),
                  SizedBox(height: AlkSize.spaceBtwItems),
                  ReadMoreText(
                    ProductCardControllerTax.cleanDescription(
                        productDescription),
                    trimLines: 2,
                    trimMode: TrimMode.Line,
                    trimCollapsedText: 'voir plus',
                    trimExpandedText: '.. moins ',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  SizedBox(height: AlkSize.spaceBtwItems),
                  AlkRef(
                    title: 'Détails du produit',
                    icon: Iconsax.receipt_text5,
                    size: 25,
                    productReference: '',
                  ),
                  SizedBox(height: AlkSize.spaceBtwItems),

                  // Show loading indicator while fetching product features

                  isLoadingFeatures
                      ? const CircularProgressIndicator()
                      : (productFeatures.isNotEmpty
                          ? AlkProductFeatures(productFeatures: productFeatures)
                          : const Text(
                              "Aucune information sur le produit disponible.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontStyle: FontStyle.italic, fontSize: 14),
                            )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/*
  This file defines the ProductDetails widget, which is a screen for displaying 
  detailed information about a specific product. It's designed to provide an 
  immersive product viewing experience, 



  1.  Stateful Widget:
      -   `ProductDetails` is a `StatefulWidget` because it manages the state of 
          product features, including loading states and fetched data.

  2.  Product Information:
      -   It receives detailed product information through its constructor, including:
          -   `productName`: Name of the product.
          -   `productReference`: The product reference or code.
          -   `productDiscount`: Discount applied to the product.
          -   `productBrand`: Brand of the product.
          -   `productOldPrice`: Original price of the product (before discount).
          -   `productNewPrice`: Discounted price of the product.
          -   `productDescription`: Detailed description of the product.
          -   `productBrandId`: ID of the product's brand.
          -   `productId`: Unique identifier of the product.
          -   `productImage`: URL or path to the main product image.
          -   `productImageList`: List of URLs or paths to additional product images.
          -   `productStock`: The stock quantity of the product (used by nested widgets).
          -   `productFeatures`: Optional list of product features.

  3.  Dynamic Feature Fetching:
      -   `productFeatures`: A list to store product features (fetched dynamically).
      -   `isLoadingFeatures`: A flag to indicate whether features are being fetched.
      -   `initState()`: Calls `_fetchProductFeatures()` to start fetching when the widget initializes.
      -   `_fetchProductFeatures()`:
          -   Uses `ProductControllerStore` to get product features.
          -   Updates `productFeatures` and `isLoadingFeatures` when the fetch completes.
          -   Handles potential errors during the fetch.

  4.  UI Structure:
      -   `Scaffold`: The base layout.
      -   `bottomNavigationBar`: Uses the `AlkBottomAddToCart` widget to provide 
          "Add to Cart" functionality.
      -   `SingleChildScrollView`: Enables scrolling for long content.
      -   `Column`: Organizes the main layout vertically.
      -   `AlkProductImageSlider`: Displays a carousel of product images.
      -   `Padding`: Adds spacing around the product details.
      -   `AlkRef`: Custom widget for displaying product reference and description titles.
      -   `AlkProductMetadata`: Displays main product details (name, price, brand).
      -   `ReadMoreText`: Used for truncating and expanding the product description.
      -   `AlkProductFeatures`: Displays a list of product features (if available).
      -   `CircularProgressIndicator`: Shown while product features are loading.

  5.  Add to Cart Integration:
      -   `AlkBottomAddToCart`: Used in the `bottomNavigationBar` to integrate the 
          "Add to Cart" feature. It passes relevant product details.

  6.  Dependencies:
      -   `get`: For state management (`Get.find<ProductProvider>()`) and navigation (`Get.to()`).
      -   `iconsax`: For icons (`Iconsax.component5`, `Iconsax.document_text5`, `Iconsax.receipt_text5`).
      -   `readmore`: For truncating and expanding text (`ReadMoreText`).
      -   `alkirtas/common/widgets/providers/product_provider.dart`: 
         The `ProductProvider` for managing the cart.
      -   `alkirtas/features/shop/screens/product_details/widgets/bottom_add_to_cart.dart`: 
          The "Add to Cart" bottom bar.
      -   `alkirtas/features/shop/screens/product_details/widgets/product_features.dart`: 
          Widget to display product features.
      -   `alkirtas/common/widgets/texts/section_heading.dart`: Custom section heading widget.
      -   `alkirtas/utils/constants/size.dart`: App size constants.
      -   `alkirtas/features/shop/controllers/product_card_controller.dart`: 
        `ProductCardControllerTax` for cleaning the product description.
      -   `alkirtas/features/shop/controllers/product_controller_store.dart`: 
        `ProductControllerStore` for fetching product features.
      -   `alkirtas/features/shop/screens/product_details/widgets/product_detail_image_slider.dart`: 
         Image slider for the product.
      -   `alkirtas/features/shop/screens/product_details/widgets/product_metadata.dart`: 
         Widget to display product metadata.
      -   `alkirtas/features/shop/screens/product_details/widgets/reference.dart`:
         Custom widget for displaying product reference

  7. Functionality:
    - When initialising the widget, it will fetch the product features by calling `_fetchProductFeatures()`
    - If the features are still being fetched, a loading indicator will be displayed.
    - If no features are available, it will display a message "Aucune information sur le produit disponible."
    - the price to be displayed in the bottom add to cart will be chosen regarding the existence of the discount, if there is a discount, the `productNewPrice` will be chosen, else if there is no discount, the `productOldPrice` will be chosen, else the `productNewPrice` will be chosen as a default.
    - The product Description will be cleaned from html using `ProductCardControllerTax.cleanDescription()`
    - it uses a bottom navigation bar `AlkBottomAddToCart` to add to cart.

  In Summary:

  The `ProductDetails` widget is a comprehensive screen for presenting detailed 
  product information and integrating the "Add to Cart" functionality. It 
  dynamically fetches product features, handles loading states, and displays 
  various product details in a structured and user-friendly way.
*/
