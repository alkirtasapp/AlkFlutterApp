import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:readmore/readmore.dart';
import 'package:test/common/widgets/providers/product_provider.dart';
import 'package:test/features/shop/screens/product_details/widgets/bottom_add_to_cart.dart';
import '../../../../common/widgets/texts/section_heading.dart';
import '../../../../utils/constants/size.dart';
import '../../controllers/product_card_controller.dart';
import 'widgets/product_detail_image_slider.dart';
import 'widgets/product_metadata.dart';
import 'widgets/reference.dart';

class ProductDetails extends StatelessWidget {
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
  });

  @override
  Widget build(BuildContext context) {
    final productPrice = productDiscount.isNotEmpty
        ? productNewPrice
        : (productOldPrice.isNotEmpty ? productOldPrice : productNewPrice);

    print("Product Price: $productPrice");
    print("Product discount: $productDiscount");
    print("Product OLD Price: $productOldPrice");
    print("Product NEW  Price: $productNewPrice");

    return Scaffold(
      bottomNavigationBar: AlkBottomAddToCart(
        productName: productName,
        productBrand: productBrand,
        productImage: productImage,
        productPrice: productPrice,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            AlkProductImageSlider(
              productImages: productImageList,
              productName: productName,
            ),
            Padding(
              padding: EdgeInsets.only(
                  right: AlkSize.defaultSpace,
                  left: AlkSize.defaultSpace,
                  bottom: AlkSize.defaultSpace),
              child: Column(
                children: [
                  AlkRef(title: 'Réference ',icon: Iconsax.component5,productReference: productReference),
                  SizedBox(height: AlkSize.spaceBtwItems),
                  AlkProductMetadata(
                    productName: productName,
                    productDiscount: productDiscount,
                    productBrand: productBrand,
                    productBrandId: productBrandId,
                    productOldPrice: productOldPrice,
                    productNewPrice: productNewPrice,
                    productStock: productStock,
                  ),
                  SizedBox(height: AlkSize.spaceBtwItems),
            
                      AlkRef(title: 'Déscription',icon: Iconsax.document_text5, productReference: '',),
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
                  AlkRef(title: 'Détails de produit',icon: Iconsax.receipt_text5, productReference: '',),
                
                  DataTable(
                    columns: <DataColumn>[
                      DataColumn(
                        label: Expanded(
                          child: Text(
                            'Name',
                            style: TextStyle(fontStyle: FontStyle.italic),
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Expanded(
                          child: Text(
                            'Age',
                            style: TextStyle(fontStyle: FontStyle.italic),
                          ),
                        ),
                      ),
                    ],
                    rows: const <DataRow>[
                      DataRow(
                        cells: <DataCell>[
                          DataCell(Text('Sarah')),
                          DataCell(Text('19')),
                        ],
                      ),
                      DataRow(
                        cells: <DataCell>[
                          DataCell(Text('Janine')),
                          DataCell(Text('43')),
                        ],
                      ),
                      DataRow(
                        cells: <DataCell>[
                          DataCell(Text('William')),
                          DataCell(Text('27')),
                        ],
                      ),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
