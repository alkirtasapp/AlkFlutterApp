import 'package:flutter/material.dart';
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
        padding: const EdgeInsets.all(1.0),  
        child: AlkStoreGridDrawer(
          key: productListKey, // Assign unique key to force refresh
          itemCount: 10,
          categoryId: categoryMap[selectedCategory]!,
        ),
      ),
    );
  }
}
