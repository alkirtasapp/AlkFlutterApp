import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:alkirtas/common/widgets/icons/circularIcons.dart';
import 'package:alkirtas/utils/constants/colors.dart';
import 'package:alkirtas/utils/constants/size.dart';
import 'package:alkirtas/common/widgets/providers/product_provider.dart';
import 'package:alkirtas/data/controllers/quantity_controller.dart'; // Import QuantityController

import '../../cart/cart.dart';

class AlkBottomAddToCart extends StatefulWidget {
  final String productId;
  final String productName;
  final String productBrand;
  final String productImage;
  final String productPrice;
  final String productDiscount;
  final String productBrandId;
  final String productOldPrice;
  final String productNewPrice;
  final String productStock;
  final String productDescription;
  final String productReference;
  final List<String> productImageList;
  final List<String>? productFeatures;

  const AlkBottomAddToCart({
    super.key,
    required this.productName,
    required this.productBrand,
    required this.productImage,
    required this.productPrice,
    required this.productDiscount,
    required this.productBrandId,
    required this.productOldPrice,
    required this.productNewPrice,
    required this.productStock,
    required this.productDescription,
    required this.productReference,
    required this.productImageList,
    required this.productFeatures,
    required this.productId,
  });

  @override
  _AlkBottomAddToCartState createState() => _AlkBottomAddToCartState();
}

class _AlkBottomAddToCartState extends State<AlkBottomAddToCart> {
  int quantity = 1; // Initial quantity
  int? productStock; // To store the fetched stock
  bool isLoadingStock = true; // Initially loading

  @override
  void initState() {
    super.initState();
    _fetchStock();
  }

  // Function to fetch the stock
  Future<void> _fetchStock() async {
    final QuantityController quantityController = QuantityController();
    int? stock = await quantityController.fetchQuantity(int.parse(widget.productId));

    setState(() {
      productStock = stock;
      isLoadingStock = false;
    });
  }

  void _increaseQuantity() {
    // Only increase if there's stock available and the current quantity doesn't exceed the available stock
    if (productStock != null && productStock! > 0 && quantity < productStock!) {
      setState(() {
        quantity++;
      });
    }
  }

  void _decreaseQuantity() {
    if (quantity > 1) {
      setState(() {
        quantity--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = Get.find<ProductProvider>();
    // If loading, show a loading indicator
    if (isLoadingStock) {
      return Container(
          height: 100,
          child: Center(child: CircularProgressIndicator())); // Or any loading indicator
    }

    // Check if product is in stock based on the fetched stock
    bool isInStock = productStock != null && productStock! > 0;

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AlkSize.defaultSpace, vertical: AlkSize.defaultSpace / 2),
      decoration: BoxDecoration(
        color: AlkColors.light,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AlkSize.cardRadiusLg),
          topRight: Radius.circular(AlkSize.cardRadiusLg),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              AlkCircularIcon(
                icon: Iconsax.minus,
                size: 25,
                backgroundColor: Colors.purple[400],
                height: 40,
                width: 40,
                color: Colors.white,
                onPressed: _decreaseQuantity,
              ),
              const SizedBox(width: AlkSize.spaceBtwItems),
              Text('$quantity', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(width: AlkSize.spaceBtwItems),
              AlkCircularIcon(
                icon: Iconsax.add,
                size: 25,
                backgroundColor: Colors.purple[400],
                height: 40,
                width: 40,
                color: Colors.white,
                onPressed: _increaseQuantity,
              ),
            ],
          ),
          ElevatedButton(
            onPressed: isInStock
                ? () {
                    productProvider.addToCart(
                      productId: widget.productId,
                      productName: widget.productName,
                      productBrand: widget.productBrand,
                      productImage: widget.productImage,
                      productPrice: widget.productPrice,
                      productDiscount: widget.productDiscount,
                      productBrandId: widget.productBrandId,
                      productOldPrice: widget.productOldPrice,
                      productNewPrice: widget.productNewPrice,
                      productStock: productStock.toString(), // Use fetched stock
                      productDescription: widget.productDescription,
                      productReference: widget.productReference,
                      productImageList: widget.productImageList,
                      productFeatures: widget.productFeatures,
                      quantity: quantity,
                    );

                    Get.snackbar(
                      "Ajouté au Panier",
                      "${widget.productName} a été ajouté au panier en quantité: $quantity",
                      snackPosition: SnackPosition.TOP,
                      duration: Duration(seconds: 2),
                      backgroundColor: Colors.purple.shade300,
                      colorText: Colors.white,
                      onTap: (snack) => Get.to(() => CartScreen()),
                      isDismissible: true,
                    );
                  }
                : null, // Disable button when out of stock
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.all(AlkSize.md),
              backgroundColor: isInStock ? Colors.purple[400] : Colors.grey,
              side: const BorderSide(color: Colors.grey),
            ),
            child: Text(isInStock ? 'Ajouter au Panier' : 'Rupture de stock',style: Theme.of(context).textTheme.titleMedium!.apply(color: Colors.white),),
          ),
        ],
      ),
    );
  }
}
/*
  This file defines the AlkBottomAddToCart widget, which is a bottom bar component 
  typically used on product detail screens to allow users to add products to their cart.

  **Key Features:**

  1.  **Stateful Widget:**
      -   `AlkBottomAddToCart` is a `StatefulWidget` because it manages internal state, such as the quantity of the product to add and the loading state of the stock.

  2.  **Product Information:**
      -   It receives various product details through its constructor, including:
          -   `productId`: Unique identifier of the product.
          -   `productName`: Name of the product.
          -   `productBrand`: Brand of the product.
          -   `productImage`: URL or path to the product's main image.
          -   `productPrice`: Price of the product.
          -   `productDiscount`: Discount applied to the product.
          -   `productBrandId`: ID of the product's brand.
          -   `productOldPrice`: Original price of the product before discount.
          -   `productNewPrice`: Discounted price of the product.
          -   `productStock`: String representation of the product's stock (not used directly, stock is fetched).
          -   `productDescription`: Detailed description of the product.
          -   `productReference`: Reference or code of the product.
          -   `productImageList`: List of URLs or paths to product images.
          - `productFeatures`: Optional list of product features
    

  3.  **Quantity Management:**
      -   `quantity`: An integer that tracks the number of items to add to the cart (starts at 1).
      -   `_increaseQuantity()`: Increments the `quantity` (up to the available stock).
      -   `_decreaseQuantity()`: Decrements the `quantity` (minimum 1).
        
  4. **Stock fetching:**
      -   `productStock`: An integer that stores the current stock of the product (fetched dynamically).
      -   `isLoadingStock`: A boolean that indicates if the stock is currently being fetched.
      -   `_fetchStock()`: An asynchronous function to fetch the product stock using `QuantityController`.

  5.  **Loading State:**
      -   While `isLoadingStock` is `true`, a `CircularProgressIndicator` is displayed.
        
  6.  **Add to Cart Button:**
      -   `ElevatedButton`: The main button for adding the product to the cart.
      -   `onPressed`:
          -   Conditionally enabled based on `isInStock`.
          -   If `isInStock` is `true`, it calls `productProvider.addToCart()` to add the product to the cart and shows a success message with `Get.snackbar`.
          -   If `isInStock` is `false`, it's `null` (disabled).
      -   `style`: Button color changes based on `isInStock`.
      -   `child`: Text changes between "Ajouter au Panier" and "Rupture de stock" based on `isInStock`.

  7.  **UI Components:**
      -   `AlkCircularIcon`: Used for the plus and minus buttons.
      -   `Text`: Used to display the quantity and the button text.
      -   `Container`: Used for styling the bottom bar.
      - `ElevatedButton` : the add to cart button.
      - `Row` : used to display quantity, increase and decrease quantity buttons.

  8.  **Dependencies:**
      -   `get`: For state management (`Get.find<ProductProvider>()`) and showing snack bars (`Get.snackbar`).
      -   `iconsax`: For icons (`Iconsax.minus`, `Iconsax.add`).
      -   `alkirtas/common/widgets/icons/circularIcons.dart`: Custom circular icon widget.
      -   `alkirtas/utils/constants/colors.dart`: App color constants.
      -   `alkirtas/utils/constants/size.dart`: App size constants.
      -   `alkirtas/common/widgets/providers/product_provider.dart`: The `ProductProvider` for managing the cart.
      -   `alkirtas/data/controllers/quantity_controller.dart`: The `QuantityController` to fetch the stock.
      - `../../cart/cart.dart`: The cart screen destination.

  9. **Functionality**
      - The button to add to cart will be clickable only if the product is in stock, else it will be greyed out and not clickable, also the text will be 'Rupture de stock' (out of stock)
      - we can only increase the quantity if there is stock available and if the quantity is less than the stock available.
      - if the product stock is being fetched, we display a loading indicator.
      - when pressing the add to cart button, it will add the product and its details to the cart and will display a snackbar that will lead to the cart screen when tapped.

  **In summary,** this widget provides a reusable and dynamic "Add to Cart" component that handles stock checks, quantity management, and user feedback, making it a key part of the product detail experience.
*/