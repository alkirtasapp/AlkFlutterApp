import 'package:flutter/material.dart';

class PaginationController extends ChangeNotifier {
  List<Map<String, dynamic>> allProducts = []; // ✅ Store all fetched products
  List<Map<String, dynamic>> displayedProducts = []; // ✅ Only products for current page
  int currentPage = 1; // ✅ Track current page
  final int productsPerPage = 8; // ✅ 8 products per page

  void setProducts(List<Map<String, dynamic>> products) {
    allProducts = products;
    currentPage = 1;
    _updateDisplayedProducts();
  }

  void _updateDisplayedProducts() {
    int startIndex = (currentPage - 1) * productsPerPage;
    int endIndex = startIndex + productsPerPage;

    displayedProducts = allProducts.sublist(
      startIndex,
      endIndex > allProducts.length ? allProducts.length : endIndex,
    );

    notifyListeners();
  }

  void changePage(int pageNumber) {
    currentPage = pageNumber;
    _updateDisplayedProducts();
  }

  Widget buildPaginationControls(VoidCallback updateUI) {
    int totalPages = (allProducts.length / productsPerPage).ceil();
    if (totalPages <= 1) return SizedBox();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, size: 18),
            onPressed: currentPage > 1 ? () {
              changePage(currentPage - 1);
              updateUI();
            } : null,
          ),
          Wrap(
            spacing: 3,
            children: List.generate(totalPages, (index) {
              int pageNumber = index + 1;
              return ElevatedButton(
                onPressed: () {
                  changePage(pageNumber);
                  updateUI();
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(30, 30),
                  padding: EdgeInsets.all(6),
                  backgroundColor: currentPage == pageNumber ? Colors.blue : Colors.grey,
                ),
                child: Text("$pageNumber", style: TextStyle(fontSize: 12)),
              );
            }),
          ),
          IconButton(
            icon: Icon(Icons.arrow_forward, size: 18),
            onPressed: currentPage < totalPages ? () {
              changePage(currentPage + 1);
              updateUI();
            } : null,
          ),
        ],
      ),
    );
  }
}
