import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:alkirtas/data/models/carrier_model.dart';
import 'package:alkirtas/config/app_config.dart';

class CarrierController {
  String get apiKey => AppConfig.prestashopApiKey;
  final String baseUrl = 'https://www.alkirtas.com/api';

  /// Fetches all active carriers from the API
  Future<List<Carrier>> fetchCarriers() async {
    try {
      // Fetch carriers
      final carriersUrl = '$baseUrl/carriers?filter[active]=1&filter[deleted]=0&display=full&ws_key=$apiKey&output_format=JSON';

      final response = await http.get(Uri.parse(carriersUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final carriersList = data['carriers'] as List<dynamic>? ?? [];

        // Fetch delivery costs for each carrier
        final deliveryCosts = await _fetchDeliveryCosts();

        List<Carrier> carriers = [];
        for (var carrierJson in carriersList) {
          final carrierId = int.tryParse(carrierJson['id']?.toString() ?? '0') ?? 0;
          final cost = deliveryCosts[carrierId] ?? 9.0; // Default to 9 TND if not found

          final carrier = Carrier.fromJson(carrierJson, cost: cost);
          carriers.add(carrier);

          print('📦 Loaded carrier: ${carrier.name} (ID: ${carrier.id}, Free: ${carrier.isFree}, Cost: ${carrier.shippingCost})');
        }

        return carriers;
      } else {
        print('❌ Failed to fetch carriers: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ Error fetching carriers: $e');
      return [];
    }
  }

  /// Fetches delivery costs from the deliveries API
  /// Returns a map of carrier_id -> price
  Future<Map<int, double>> _fetchDeliveryCosts() async {
    try {
      // Fetch delivery ranges to get shipping costs
      // Using zone 1 (Tunisia) as default
      final deliveriesUrl = '$baseUrl/deliveries?display=full&ws_key=$apiKey&output_format=JSON';

      final response = await http.get(Uri.parse(deliveriesUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final deliveries = data['deliveries'] as List<dynamic>? ?? [];

        Map<int, double> costs = {};

        for (var delivery in deliveries) {
          final carrierId = int.tryParse(delivery['id_carrier']?.toString() ?? '0') ?? 0;
          final price = double.tryParse(delivery['price']?.toString() ?? '0') ?? 0.0;

          // Keep the highest price for each carrier (in case of multiple ranges)
          if (!costs.containsKey(carrierId) || costs[carrierId]! < price) {
            costs[carrierId] = price;
          }
        }

        print('📦 Delivery costs loaded: $costs');
        return costs;
      } else {
        print('❌ Failed to fetch delivery costs: ${response.statusCode}');
        return {};
      }
    } catch (e) {
      print('❌ Error fetching delivery costs: $e');
      return {};
    }
  }
}
