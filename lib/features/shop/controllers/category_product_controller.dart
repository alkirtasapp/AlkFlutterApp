// d:\flutter\test\lib\features\shop\controllers\category_product_controller.dart (Corrected Discount Logic)
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as htmlParser;
import 'package:alkirtas/data/controllers/product_list_Category.dart';
import 'dart:async'; // Import for Completer/Future

// Import the dedicated controllers
import 'package:alkirtas/data/controllers/discount_controller.dart';
import 'package:alkirtas/data/controllers/tax_controller.dart';
// Note: DetailsController is not used in this specific refactoring based on the request,
// but could be added similarly if feature fetching were needed here.

class CategoryProductController {
// --- Static Cache and State Management (Unchanged) ---
static final Map<int, List<Map<String, dynamic>>> _staticCachedProducts = {};
static final Map<int, bool> _staticIsLoading = {};
static final Map<int, String?> _staticError = {};
static final Map<int, Completer<void>> _staticFetchCompleters = {};

// --- Instance Variables (Unchanged) ---
final int categoryId;
final int limit; // Target number of active products

// --- Instantiate Dedicated Controllers ---
final DiscountController _discountController = DiscountController();
final TaxController _taxController = TaxController();
// final DetailsController _detailsController = DetailsController(); // Instantiate if needed later

CategoryProductController({required this.categoryId, this.limit = 8});

// --- Instance Getters (Unchanged) ---
bool get isLoading => _staticIsLoading[categoryId] ?? false;
String? get error => _staticError[categoryId];
List<Map<String, dynamic>>? get products => _staticCachedProducts[categoryId];

// --- Static Clear Method (Unchanged) ---
static void clearCache() {
_staticCachedProducts.clear();
_staticIsLoading.clear();
_staticError.clear();
_staticFetchCompleters.clear();
print("🧹 CategoryProductController static cache cleared.");
}

// --- Fetch Logic (Looping Fetch - Unchanged from previous version) ---
Future<void> fetchCategoryProducts() async {
// Check if already loading or completed (Unchanged)
if (_staticFetchCompleters.containsKey(categoryId)) {
print("ℹ️ Fetch already in progress or completed for Category ID: $categoryId. Awaiting completion.");
await _staticFetchCompleters[categoryId]!.future;
return;
}
// Check cache (Unchanged)
if (_staticCachedProducts.containsKey(categoryId)) {
print("✅ Cache hit for Category ID: $categoryId. Skipping fetch.");
_staticIsLoading[categoryId] = false;
_staticError[categoryId] = null;
return;
}

// Create Completer and set initial state (Unchanged)
final completer = Completer<void>();
_staticFetchCompleters[categoryId] = completer;
_staticIsLoading[categoryId] = true;
_staticError[categoryId] = null;

print("🔄 Starting product fetch loop for Category ID: $categoryId (Target: $limit active)...");

List<Map<String, dynamic>> activeProductsFound = [];
List<Map<String, dynamic>> productsToProcess = [];

try {
final ProductListCategory productListCategory = ProductListCategory();

// Step 1: Fetch ALL Product IDs (Unchanged)
print("📡 Fetching ALL product IDs for Category ID: $categoryId using ProductListCategory...");
List<int> allProductIds = await productListCategory.fetchProductIdsFromCategory(categoryId);
if (allProductIds.isEmpty) { /* ... handle empty IDs ... */
print("ℹ️ No product IDs found for Category ID: $categoryId via ProductListCategory.");
_staticCachedProducts[categoryId] = []; completer.complete(); _staticIsLoading[categoryId] = false; return;
}
print("✅ Found ${allProductIds.length} total product IDs for Category ID: $categoryId.");

// Step 2: Loop Fetching Details in Batches (Unchanged)
int currentIdIndex = 0;
const int batchSize = 10;
while (activeProductsFound.length < limit && currentIdIndex < allProductIds.length) {
int endIndex = currentIdIndex + batchSize;
if (endIndex > allProductIds.length) endIndex = allProductIds.length;
List<int> batchIds = allProductIds.sublist(currentIdIndex, endIndex);
if (batchIds.isEmpty) break;

print(" -> Fetching details batch (${currentIdIndex + 1}-${endIndex}) for Category ID: $categoryId...");
String idFilter = batchIds.join('|');
final productDetailsApi = 'https://www.alkirtas.com/api/products?display=full&filter[id]=[$idFilter]&output_format=JSON&ws_key=Y262WZ22UPBRMJ6UNTHU24KDXT7T66RU';
final response = await http.get(Uri.parse(productDetailsApi));
currentIdIndex = endIndex; // Move index

if (response.statusCode != 200) { /* ... handle batch error ... */
print(" ⚠️ Failed to load product details batch (Status: ${response.statusCode}). Skipping batch."); continue;
}
final productData = json.decode(utf8.decode(response.bodyBytes));
if (productData == null || !productData.containsKey('products') || productData['products'] == null) { /* ... handle empty batch data ... */
print(" ⚠️ No product details returned in batch. Skipping batch."); continue;
}

List<Map<String, dynamic>> rawProductsBatch = List<Map<String, dynamic>>.from(productData['products']);
print(" ✅ Received details for ${rawProductsBatch.length} products in batch.");

// Filter for active and add to list (Unchanged)
for (var product in rawProductsBatch) {
if (product.containsKey('active') && product['active'].toString() == '1') {
if (activeProductsFound.length < limit) {
activeProductsFound.add(product);
productsToProcess.add(product);
print(" + Found active product ${product['id']}. Total active: ${activeProductsFound.length}");
} else {
print(" - Limit ($limit) reached. Stopping search within batch."); break;
}
}
}
if (activeProductsFound.length >= limit) { /* ... break outer loop ... */
print(" 🏁 Target of $limit active products reached. Stopping fetch loop."); break;
}
} // End while loop

// --- Step 3: Process Details for Found Active Products (Using Delegated Methods) ---
if (productsToProcess.isNotEmpty) {
print("⚙️ Processing details for ${productsToProcess.length} active products found...");
List<Future<void>> processingTasks = [];
for (var product in productsToProcess) {
// *** Call the REFACTORED _processProductDetails ***
processingTasks.add(_processProductDetails(product));
}
await Future.wait(processingTasks);
} else {
print("ℹ️ No active products found to process details for Category ID: $categoryId.");
}

// Step 4: Cache the final list (Unchanged)
_staticCachedProducts[categoryId] = activeProductsFound;
print("✅✅ Successfully fetched and processed ${activeProductsFound.length} active products for Category ID: $categoryId (Target was $limit).");
completer.complete();

} catch (e) { /* ... handle overall error ... */
print('❌❌ Error during product fetch/process loop for category $categoryId: $e');
_staticError[categoryId] = 'Failed to load products: $e';
_staticCachedProducts.remove(categoryId);
completer.completeError(e);
} finally {
_staticIsLoading[categoryId] = false;
}
}

// --- Helper Method: _processProductDetails (Refactored & Corrected Discount Logic) ---
Future<void> _processProductDetails(Map<String, dynamic> product) async {
try {
// Ensure ID and Price are correctly typed before passing
int productId = int.tryParse(product['id'].toString()) ?? 0;
double priceHT = double.tryParse(product['price'].toString()) ?? 0.0;
dynamic taxRulesGroupId = product['id_tax_rules_group']; // Keep dynamic for TaxController

if (productId == 0) {
print("❌ Skipping detail processing for product with invalid ID: ${product['id']}");
return; // Cannot process without a valid ID
}

List<Future<void>> tasks = [];

// --- Fetch discount using DiscountController ---
tasks.add(_discountController.fetchDiscount(productId).then((discountData) {
// Process the result from DiscountController
if (discountData != null && discountData['reduction_type'] == 'percentage') {
// *** CORRECTION: DiscountController returns 'reduction' as the final percentage string (e.g., "10.0"). Just parse it. ***
double reductionValue = double.tryParse(discountData['reduction'].toString()) ?? 0.0;
product['discount'] = reductionValue; // Store final percentage value (e.g., 10.0)
} else {
product['discount'] = 0.0; // Default to 0.0 if no valid percentage discount
}
}));

// --- Fetch tax-inclusive price (TTC) using TaxController ---
tasks.add(_taxController.fetchTTCPrice(productId, priceHT, taxRulesGroupId)
.then((ttcPrice) {
// Assign the result or fallback to priceHT
product['ttc_price'] = ttcPrice ?? priceHT;
}));

// --- Image URL processing (remains internal) ---
tasks.add(Future(() {
if (product.containsKey('associations') &&
product['associations'].containsKey('images')) {
final images = product['associations']['images'] as List;
List<String> imageUrls =
images.map((image) => constructImageUrl(image['id'])).toList();
product['image_urls'] = imageUrls;
} else {
product['image_urls'] = <String>[];
}
product['default_image_url'] = constructImageUrl(product['id_default_image']);
}));



// Wait for all detail processing tasks to complete
await Future.wait(tasks);

} catch (e) {
print("❌ Error processing product details via external controllers for ${product['id']}: $e");
// Apply default values on error
product['discount'] ??= 0.0;
product['ttc_price'] ??= double.tryParse(product['price'].toString()) ?? 0.0;
product['image_urls'] ??= <String>[];
product['default_image_url'] ??= constructImageUrl(product['id_default_image']);
// product['features_map'] ??= <String, String>{};
// product['features_list'] ??= <String>[];
}
}

// --- Image URL construction (remains internal) ---
String constructImageUrl(dynamic imageId) {
if (imageId == null || imageId.toString().isEmpty) return 'https://via.placeholder.com/150?text=No+Image';
final imageIdStr = imageId.toString();
final path = imageIdStr.split('').join('/');
return 'https://www.alkirtas.com/img/p/$path/$imageIdStr.jpg';
}

// --- Description cleaning (remains internal static method) ---
static String cleanDescription(String? description) {
if (description == null || description.isEmpty) return "No description available";
final document = htmlParser.parse(description);
String cleanText = document.body?.text ?? "";
cleanText = cleanText.replaceAll(RegExp(r'\s+'), ' ').trim();
return cleanText;
}
}