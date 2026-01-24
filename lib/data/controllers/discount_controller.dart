import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:alkirtas/config/app_config.dart';
import 'package:alkirtas/utils/logging/logger.dart';

class DiscountController {

  /// Fetches the discount for a product
  Future<Map<String, dynamic>?> fetchDiscount(int productId) async {
    try {
      final discountApi =
          'https://www.alkirtas.com/api/specific_prices?display=full&filter[id_product]=[$productId]&output_format=JSON&ws_key=${AppConfig.prestashopApiKey}';

      final response = await http.get(Uri.parse(discountApi));

      if (response.statusCode == 200) {
        final discountData = json.decode(utf8.decode(response.bodyBytes));

        // API returns empty list [] when no discounts, or a Map with 'specific_prices' key
        if (discountData is! Map || !discountData.containsKey('specific_prices')) {
          return null; // No discount - normal case, no need to log
        }

        final discounts = discountData['specific_prices'] as List<dynamic>?;
        if (discounts == null || discounts.isEmpty) {
          return null;
        }

        DateTime now = DateTime.now();
        Map<String, dynamic>? permanentDiscount;
        Map<String, dynamic>? latestDiscount;

        for (var discount in discounts) {
          if (!discount.containsKey('reduction') ||
              !discount.containsKey('reduction_type')) {
            AlkLoggerHelper.warning('Incomplete discount data for product $productId');
            continue;
          }

          String fromDateStr = discount['from'] ?? "";
          String toDateStr = discount['to'] ?? "";

          DateTime? fromDate = DateTime.tryParse(fromDateStr);
          DateTime? toDate = DateTime.tryParse(toDateStr);

          // Check for permanent discount (always valid)
          if (fromDateStr == "0000-00-00 00:00:00" &&
              toDateStr == "0000-00-00 00:00:00") {
            permanentDiscount = discount;
            continue;
          }

          // Ensure the discount is within the valid period
          if (fromDate != null &&
              toDate != null &&
              (now.isBefore(fromDate) || now.isAfter(toDate))) {
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

        Map<String, dynamic>? selectedDiscount =
            permanentDiscount ?? latestDiscount;

        if (selectedDiscount != null) {
          double parsedReduction =
              double.tryParse(selectedDiscount['reduction']) ?? 0;
          parsedReduction = parsedReduction * 100; // Convert to percentage

          return {
            'reduction': parsedReduction.toString(),
            'reduction_type': 'percentage',
          };
        }
      } else {
        AlkLoggerHelper.error('Failed to fetch discount for product $productId: ${response.statusCode}');
      }
    } catch (e) {
      AlkLoggerHelper.error('Error fetching discount for product $productId', e);
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
