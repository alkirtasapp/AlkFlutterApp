import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:alkirtas/config/app_config.dart';


class DiscountController {

  /// Fetches the discount for a product
  Future<Map<String, dynamic>?> fetchDiscount(int productId) async {
    try {
      final discountApi =
          'https://www.alkirtas.com/api/specific_prices?display=full&filter[id_product]=[$productId]&output_format=JSON&ws_key=${AppConfig.prestashopApiKey}';

      final response = await http.get(Uri.parse(discountApi));

     
      // Check if the response is successful
      if (response.statusCode == 200) {
        final discountData = json.decode(utf8.decode(response.bodyBytes));

        if (!discountData.containsKey('specific_prices')) {
          print('No specific_prices key in response for product $productId');
          return null;
        }
         // Extract the discounts from the response
        final discounts = discountData['specific_prices'] as List<dynamic>?;
        if (discounts == null || discounts.isEmpty) {
          print('No discounts found for product $productId');
          return null;
        }
        // Get the current date and time
        DateTime now = DateTime.now();
        Map<String, dynamic>? permanentDiscount;
        Map<String, dynamic>? latestDiscount;

        // Iterate through the discounts to find the latest valid discount
        for (var discount in discounts) {
          if (!discount.containsKey('reduction') ||
              !discount.containsKey('reduction_type')) {
            print(
                'Skipping discount for product $productId: Incomplete data ${discount}');
            continue;
          }
          // Extract the 'from' and 'to' dates
          String fromDateStr = discount['from'] ?? "";
          String toDateStr = discount['to'] ?? "";

          DateTime? fromDate = DateTime.tryParse(fromDateStr);
          DateTime? toDate = DateTime.tryParse(toDateStr);

          // Check for permanent discount (always valid)
          if (fromDateStr == "0000-00-00 00:00:00" &&
              toDateStr == "0000-00-00 00:00:00") {
            print('Permanent discount found for product $productId');
            permanentDiscount = discount;
            continue; // Still check for other discounts
          }

          // Ensure the discount is within the valid period
          if (fromDate != null &&
              toDate != null &&
              (now.isBefore(fromDate) || now.isAfter(toDate))) {
            print(
                'Skipping expired discount for product $productId: From $fromDate to $toDate');
            continue;
          }

          // Select the latest valid discount (based on 'to' date)
          if (latestDiscount == null ||
              (toDate != null &&
                  toDate.isAfter(DateTime.tryParse(latestDiscount['to']) ??
                      DateTime(1900)))) {
            latestDiscount = discount;
          }
        }

        // Apply permanent discount if available; otherwise, use the latest valid discount
        Map<String, dynamic>? selectedDiscount =
            permanentDiscount ?? latestDiscount;

        if (selectedDiscount != null) {
          double parsedReduction =
              double.tryParse(selectedDiscount['reduction']) ?? 0;
          parsedReduction = parsedReduction * 100; // Convert to percentage

          print(
              'Final selected discount for product $productId: $parsedReduction%');

          return {
            'reduction': parsedReduction.toString(), // Ensure string format
            'reduction_type': 'percentage',
          };
        }

        print('No valid discount available for product $productId');
      } else {
        print(
            'Failed to fetch discount for product $productId: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching discount for product $productId: $e');
    }
    return null;
  }
}

/// Fetches the total price including taxes for a product
/// using the  specific_prices APi to fetch the Discounted prices !
///1. we gotta Fetches the discount for a product
///2. Extract the discounts from the response
///3. Get the current date and time
///4. Iterate through the discounts to find the latest valid discount
///5. Extract the 'from' and 'to' dates
///6. Check for permanent discount (always valid)
///7. Ensure the discount is within the valid period
///8. Select the latest valid discount (based on 'to' date) 
///9. Apply permanent discount if available; otherwise, use the latest valid discount