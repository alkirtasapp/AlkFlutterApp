import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:readmore/readmore.dart';
import 'package:test/common/widgets/providers/product_provider.dart';
import 'package:test/features/shop/screens/product_details/widgets/bottom_add_to_cart.dart';
import 'package:test/features/shop/screens/product_details/widgets/product_features.dart';
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
  final List<String>? productFeatures; // Allow null
  
  

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

    print("Product Price: $productPrice");
    print("Product discount: ${widget.productDiscount}");
    print("Product OLD Price: ${widget.productOldPrice}");
    print("Product NEW Price: ${widget.productNewPrice}");
    print("product features: $productFeatures");
  
   

    return Scaffold(
      bottomNavigationBar: AlkBottomAddToCart(
        productId: widget.productId,
        productName: widget.productName,
        productBrand: widget.productBrand,
        productImage: widget.productImage,
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
                        widget.productDescription),
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
