import 'package:flutter/material.dart';
import 'package:test/data/controllers/search_controller.dart';

class AutocompleteSearchField extends StatelessWidget {
  final TextEditingController searchTextController;
  final Function(String) onSearch;
  final AlkSearchController searchController;

  AutocompleteSearchField({
    required this.searchTextController,
    required this.onSearch,
    required this.searchController,
  });

  @override
  Widget build(BuildContext context) {
    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue textEditingValue) async {
        if (textEditingValue.text.isEmpty) {
          return const Iterable<String>.empty();
        }
        final List<int>? productIds = await searchController.searchProducts(
          textEditingValue.text,
          offset: 0,
          limit: 10,
        );
        if (productIds == null || productIds.isEmpty) {
          return const Iterable<String>.empty();
        }
        return productIds.map((id) => id.toString());
      },
      onSelected: (String selection) {
        onSearch(selection);
      },
      fieldViewBuilder: (BuildContext context, TextEditingController textEditingController, FocusNode focusNode, VoidCallback onFieldSubmitted) {
        return TextField(
          controller: textEditingController,
          focusNode: focusNode,
          onSubmitted: (String value) {
            onFieldSubmitted();
            onSearch(value);
          },
          decoration: InputDecoration(
            hintText: 'Recherche',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
        );
      },
      optionsViewBuilder: (BuildContext context, AutocompleteOnSelected<String> onSelected, Iterable<String> options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.8,
              child: ListView.builder(
                padding: EdgeInsets.all(8.0),
                itemCount: options.length,
                itemBuilder: (BuildContext context, int index) {
                  final String option = options.elementAt(index);
                  return GestureDetector(
                    onTap: () {
                      onSelected(option);
                    },
                    child: ListTile(
                      title: Text(option),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}