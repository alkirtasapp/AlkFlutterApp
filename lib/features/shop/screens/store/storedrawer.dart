import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:test/common/widgets/custom_shapes/containers/searchContainer.dart';
import 'package:test/utils/constants/size.dart';

import '../../../../common/widgets/layout/store_grid_drawer.dart';

class StoreDrawer extends StatefulWidget {
  const StoreDrawer({super.key});

  @override
  State<StoreDrawer> createState() => _StorePageState();
}

class _StorePageState extends State<StoreDrawer> {
  final Map<String, int> categoryMap = {
    "Livres": 10,
    "Papeterie": 11,
    "Bagagerie": 12,
    "Parascolaires": 17,
    "Fournitures": 486,
    "Cadeaux et Fêtes": 544,
    "Bureautique": 558,
    "Jeux et Jouets": 590,
    "Art et Loisirs": 743,
  };

  String selectedCategory = "Livres"; // Default category
  Key productListKey = UniqueKey(); // Declare the key at the class level

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(selectedCategory),
          leading: Builder(builder: (context) {
            return IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          }),
        ),
        drawer: Drawer(
          child: ListView(
            children: [
              for (var category in categoryMap.keys)
                ListTile(
                  title: Text(category),
                  onTap: () {
                    setState(() {
                      selectedCategory = category;
                      productListKey = UniqueKey(); // Force refresh
                    });

                    print(
                        '🔄 Changing category to: $selectedCategory'); // Debugging
                    Navigator.pop(context);
                  },
                ),
            ],
          ),
        ),
        body: Padding(
          padding: EdgeInsets.only(top : 1),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Container
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                child: Align(
                  alignment: Alignment.centerLeft, // Ensures proper positioning
                  child: AlkSearchContainer(
                    text: 'Recherche',
                    icon: Iconsax.search_normal,
                    showBackground: true,                    
                  ),
                ),
              ),

              // Product Grid
              Expanded(

                child: Column(
                  children: [
                    
                    AlkStoreGridDrawer(
                      key: productListKey,
                      itemCount: 10,
                      categoryId: categoryMap[selectedCategory]!,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ));
  }
}
 