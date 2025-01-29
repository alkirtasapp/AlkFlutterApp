import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:test/common/widgets/appbar/appbar.dart';
import 'package:test/common/widgets/appbar/tabbar.dart';
import 'package:test/common/widgets/custom_shapes/containers/searchContainer.dart';
import 'package:test/common/widgets/products/cart/cart_menu_icon.dart';
import 'package:test/common/widgets/roundedContainer.dart';
import 'package:test/common/widgets/texts/section_heading.dart';
import 'package:test/features/shop/controllers/brand_controller.dart';
import 'package:test/utils/constants/colors.dart';
import 'package:test/utils/constants/images_strings.dart';
import 'package:test/utils/constants/size.dart';
import 'package:test/utils/helpers/helper_functions.dart';

import '../../../../common/widgets/images/AlkCircularImage.dart';
import '../../../../common/widgets/layout/brandGridLayout.dart';

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});
   @override 
   State<StoreScreen> createState() => _StoreScreenState();
}
class _StoreScreenState extends State<StoreScreen>{
  final BrandController _brandController = BrandController(); 
  late Future<Map<String, dynamic>?> brandsFuture;
 @override
 void initState(){
  super.initState();
  brandsFuture = _brandController.fetchBrandData(0);
}

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 9,
      child: Scaffold(
        // APP BAR
        appBar: AlkAppBar(
          title: Text(
            'Boutique',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          actions: [
            AlkCartCounterIcon(
              onPressed: () {},
              iconColor: Colors.black,
            ),
          ],
          showBackArrow: false,
        ),
        body: NestedScrollView(
          headerSliverBuilder: (_, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                  automaticallyImplyLeading: false,
                  pinned: true,
                  floating: true,
                  backgroundColor: AlkHelperFunctions.isDarkMode(context)
                      ? Colors.black
                      : Colors.white,
                  expandedHeight: 380,
                  flexibleSpace: Padding(
                    padding: EdgeInsets.all(AlkSize.defaultSpace),
                    child: ListView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        // search bar
                        AlkSearchContainer(
                          text: 'Recherche',
                          showBorder: true,
                          showBackground: false,
                          icon: Iconsax.search_normal,
                          padding: EdgeInsets.zero,
                        ),
                        SizedBox(height: AlkSize.spaceBtwSections / 2),
                        // Featured  Brands
                        AlkSectionHeading(
                          title: 'Marques populaires',
                          showActionButton: true, /*onPressed: ,*/
                        ),
                        SizedBox(height: AlkSize.spaceBtwItems / 1.5),

                        AlkBrandGridLayout(
                          itemCount: 8,
                          mainAxisExtent: 60,
                          
                          itemBuilder: (_, index) {
                            //adding fetching brands logic here
                            return  FutureBuilder<Map<String, dynamic>?>(
                              future: _brandController.fetchBrandData(index),
                              builder: (context, snapshot) {
                                if ( !snapshot.hasData){
                                  return const Center(
                                    child: CircularProgressIndicator() );
                                }
                                  final brand = snapshot.data!;
                            return GestureDetector(
                              onTap: () {},
                              child: AlkRoundedContainer(
                                padding: EdgeInsets.all(AlkSize.sm),
                                showBorder: true,
                                backgroundColor: Colors.transparent,
                                child: Row(
                                  children: [
                                    // brand Image
                                    Flexible(
                                      child: AlkCircularImage(
                                        image: 'https://www.alkirtas.com/img/m/${brand['id']}.jpg', // logo brand li jebneh bessif 
                                        backgroundColor: Colors.transparent,
                                        isNetworkImage: true,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                    /*
                                    const SizedBox(
                                        width: AlkSize.spaceBtwItems / 2),



                                    // Text
                                    Expanded(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          AlkBrandTitleText(
                                            title: brand['name'],
                                            brandTextSize: TextSizes.medium,
                                          ),
                                          /* Text('256 produits',
                               overflow: TextOverflow.ellipsis,
                               style: Theme.of(context).textTheme.labelMedium ,),*/
                                        ],
                                      ),
                                    )*/
                                  ],
                                ),
                              ),
                            );
                          },
                        );
          })],
                    ),
                  ),

                  /// LIST OF TABS
                  bottom: const AlkTabBar(tabs: [
                    Tab(child: Text('Livres')),
                    Tab(child: Text('Papetrie')),
                    Tab(child: Text('Bagagerie')),
                    Tab(child: Text('Parascolaires')),
                    Tab(child: Text('Fournitures')),
                    Tab(child: Text('Cadeaux et Fêtes')),
                    Tab(child: Text('Bureautique')),
                    Tab(child: Text('Jeux et Jouets')),
                    Tab(child: Text('Art et Loisir')),
                  ])),
            ];
          },
          body: TabBarView(children: [
            Padding(
              padding: EdgeInsets.all(AlkSize.defaultSpace),
              child: Column(
                children: [
                  //brands
                  AlkRoundedContainer(
                    showBorder: true,
                    borderColor: AlkColors.darkGrey,
                    backgroundColor: Colors.transparent,
                    margin:
                        const EdgeInsets.only(bottom: AlkSize.spaceBtwItems),
                    child: Column(
                      children: [
                        //brands wit product contianer
                        // brand top 3 product images
                        Row(
                          children: [
                            Expanded(
                              child: AlkRoundedContainer(
                                height: 100,
                                backgroundColor:
                                    AlkHelperFunctions.isDarkMode(context)
                                        ? Colors.black
                                        : Colors.white,
                                margin:
                                    const EdgeInsets.only(right: AlkSize.sm),
                                padding: const EdgeInsets.all(AlkSize.sm),
                                child: Image(
                                  fit: BoxFit.contain,
                                  image: AssetImage(AlkImages.darkAppLogo),
                                ),
                              ),
                            ),
                            Expanded(
                              child: AlkRoundedContainer(
                                height: 100,
                                backgroundColor:
                                    AlkHelperFunctions.isDarkMode(context)
                                        ? Colors.black
                                        : Colors.white,
                                margin:
                                    const EdgeInsets.only(right: AlkSize.sm),
                                padding: const EdgeInsets.all(AlkSize.sm),
                                child: Image(
                                  fit: BoxFit.contain,
                                  image: AssetImage(AlkImages.darkAppLogo),
                                ),
                              ),
                            ),
                            Expanded(
                              child: AlkRoundedContainer(
                                height: 100,
                                backgroundColor:
                                    AlkHelperFunctions.isDarkMode(context)
                                        ? Colors.black
                                        : Colors.white,
                                margin:
                                    const EdgeInsets.only(right: AlkSize.sm),
                                padding: const EdgeInsets.all(AlkSize.sm),
                                child: Image(
                                  fit: BoxFit.contain,
                                  image: AssetImage(AlkImages.darkAppLogo),
                                ),
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                  //products
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
