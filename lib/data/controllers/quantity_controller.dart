import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:alkirtas/config/app_config.dart';

class QuantityController{
Future<int?> fetchQuantity(int productId) async {
    try {
      final stockApi =
          'https://www.alkirtas.com/api/stock_availables?display=full&limit=10&filter[id_product]=[$productId]&output_format=JSON&ws_key=${AppConfig.prestashopApiKey}';

      final response = await http.get(Uri.parse(stockApi));
      //  Log Request
      print('🔍 Fetching stock for Product ID: $productId'); 
      //  Log Full API Response
      print('📥 API Raw Response: ${response.body}'); 

      if (response.statusCode == 200) {
        final stockData = json.decode(utf8.decode(response.bodyBytes));

        // Check if 'stock_availables' exists and is a list
        if (stockData.containsKey('stock_availables') &&
            stockData['stock_availables'] is List &&
            stockData['stock_availables'].isNotEmpty) {
          // Find the correct product entry based on 'id_product'
          final stockEntries = stockData['stock_availables'] as List;
          for (var stock in stockEntries) {
            if (stock['id_product'].toString() == productId.toString()) {
              int quantity = int.tryParse(stock['quantity'].toString()) ?? 0;

              print(
                  '✅ Stock for Product ID $productId: $quantity units'); // ✅ Log Correct Quantity
              return quantity;
            }
          }

          print('⚠️ Product ID $productId not found in stock_availables list');
        } else {
          print('⚠️ No stock data available for Product ID: $productId');
        }
      } else {
        print('❌ API Request Failed. Status Code: ${response.statusCode}');
      }
    } catch (e) {
      print('🔥 Error fetching stock quantity for Product ID $productId: $e');
    }

    print('❌ Returning NULL for Product ID: $productId'); // ✅ Log Null Return
    return null;
  } } 