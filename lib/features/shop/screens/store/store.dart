import 'package:alkirtas/features/shop/screens/store/widgets/home_brands.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:alkirtas/common/widgets/appbar/appbar.dart';
import 'package:alkirtas/common/widgets/appbar/tabbar.dart';
import 'package:alkirtas/common/widgets/custom_shapes/containers/searchContainer.dart';
import 'package:alkirtas/common/widgets/products/cart/cart_menu_icon.dart';
import 'package:alkirtas/common/widgets/roundedContainer.dart';
import 'package:alkirtas/common/widgets/texts/section_heading.dart';
import 'package:alkirtas/features/shop/controllers/brand_controller.dart';
import 'package:alkirtas/features/shop/screens/store/widgets/category_tab.dart';
import 'package:alkirtas/utils/constants/size.dart';
import 'package:alkirtas/utils/helpers/helper_functions.dart';

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
                           showQrButton: true,
                         ),
                        SizedBox(height: AlkSize.spaceBtwSections / 2),
                        // Featured  Brands
                        AlkSectionHeading(
                          title: 'Marques populaires',
                          showActionButton: true, /*onPressed: ,*/
                        ),
                        SizedBox(height: AlkSize.spaceBtwItems / 1.5),

                        AlkHomeBrands(brandController: _brandController)],
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
          body: TabBarView(
            children: [
              //categories tabs
              AlkCategoryTab(),
               AlkCategoryTab(),
                AlkCategoryTab(),
                 AlkCategoryTab(),
                  AlkCategoryTab(),
                   AlkCategoryTab(),
                    AlkCategoryTab(),
                     AlkCategoryTab(),
                      AlkCategoryTab(),

             //products
            
           
          ],
          ),
          
        ),
      ),
    );
  }
}



