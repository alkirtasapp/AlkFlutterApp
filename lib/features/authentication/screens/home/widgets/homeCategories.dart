import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../../../../common/widgets/image_text_widgets/vertical_image_text.dart';
import '../../../../../utils/constants/colors.dart';

class AlkHomeCategories extends StatefulWidget {
  const AlkHomeCategories({Key? key}) : super(key: key);

  @override
  _AlkHomeCategoriesState createState() => _AlkHomeCategoriesState();
}

class _AlkHomeCategoriesState extends State<AlkHomeCategories> {
  List<dynamic> categories = []; // Holds the categories data
  bool isLoading = true; // Loading state

  @override
  void initState() {
    super.initState();
    fetchCategories();
  }

  Future<void> fetchCategories() async {
    const apiUrl =
        'https://www.alkirtas.com/api/categories?filter[level_depth]=2&display=[id,name]&limit=20&output_format=JSON&ws_key=Y262WZ22UPBRMJ6UNTHU24KDXT7T66RU';

    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          categories = data['categories'] ?? [];
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load categories');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error fetching categories: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator() ,
);
    }

    if (categories.isEmpty) {
      return const Center(child: Text('No categories found.'));
    }

    return SizedBox(
      height: 80,
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: categories.length,
        scrollDirection: Axis.horizontal,
        itemBuilder: (_, index) {
          final category = categories[index];
          return AlkVerticalImageText(
            title: category['name'] ?? 'Unknown',
            textColor: AlkColors.white,
            onTap: () {
           
             
            },
            backgroundColor: Colors.white,
            
          );
        },
      ),
    );
  }
}
