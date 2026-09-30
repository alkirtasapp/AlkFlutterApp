import 'package:alkirtas/config/home_sections_config.dart';
import 'package:alkirtas/data/controllers/product_enriched_service.dart';
import 'package:alkirtas/models/home_section.dart';
import 'editorial_product.dart';

/// One request per category for the lifetime of the home screen.
class EditorialRepository {
  final Map<int, Future<List<EditorialProduct>>> _categories = {};
  Future<List<HomeSection>> sections() => getHomeSections();
  Future<List<EditorialProduct>> deals() async =>
      (await ProductEnrichedService.fetchHomeSellingProducts())
          .map(EditorialProduct.fromEnriched)
          .toList();
  Future<List<EditorialProduct>> category(int id) =>
      _categories.putIfAbsent(id, () async {
        final rows =
            await ProductEnrichedService.fetchEnrichedByCategory(id, limit: 8);
        return rows
            .where((row) => row['is_active'] != 0 && row['is_active'] != '0')
            .map(EditorialProduct.fromEnriched)
            .toList();
      });
  void clear() {
    _categories.clear();
    ProductEnrichedService.clearHomeSellingCache();
  }
}
