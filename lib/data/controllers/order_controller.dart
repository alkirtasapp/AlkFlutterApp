import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:alkirtas/utils/backendData/userData.dart';
import 'package:alkirtas/utils/backendData/addressData.dart';

class OrderController {
  final String apiKey = 'Y262WZ22UPBRMJ6UNTHU24KDXT7T66RU';
  final String baseUrl = 'https://www.alkirtas.com/api/orders';

  Future<bool> createOrder({
    required String idCart,
    required String deliveryMethod,
    required double cartTotal,
    required double totalProducts,
    required double totalProductsWt,
  }) async {
    try {
      // Determine the carrier ID and shipping cost based on the delivery method
      int idCarrier = (deliveryMethod == "Alkirtas corniche") ? 4 : 6; // 4 for Alkirtas corniche, 6 for First Delivery
      double shippingCost = (deliveryMethod == "Alkirtas corniche") ? 0.0 : 8.0;

      // Calculate the total paid (including shipping)
      double totalPaid = totalProductsWt + shippingCost;

      // Set the correct current_state
      int currentState = 13;

      print("🛒 Creating order with the following details:");
      print("Delivery Method: $deliveryMethod");
      print("Carrier ID: $idCarrier");
      print("Shipping Cost: $shippingCost");
      print("Total Paid: $totalPaid");
      print("Total Paid Real:$totalPaid");
      print("Total Products: $totalProducts");
      print("Total Products WT: $totalProductsWt");

      String xmlBody = '''
      <prestashop xmlns:xlink="http://www.w3.org/1999/xlink">
        <order>
          <id_address_delivery>${AddressData.id}</id_address_delivery>
          <id_address_invoice>${AddressData.id}</id_address_invoice>
          <id_cart>$idCart</id_cart>
          <id_currency>1</id_currency>
          <id_lang>1</id_lang>
          <id_customer>${UserData.id}</id_customer>
          <id_carrier>$idCarrier</id_carrier> 
          <current_state>$currentState</current_state>
          <module>ps_cashondelivery</module>
          <payment>Paiement comptant à la livraison (Cash on delivery)</payment>
          <total_paid>$totalPaid</total_paid>
          <total_paid_real>0</total_paid_real> 
          <total_products>$totalProducts</total_products> 
          <total_products_wt>$totalProductsWt</total_products_wt> 
          <total_shipping>$shippingCost</total_shipping> 
          <total_shipping_tax_incl>$shippingCost</total_shipping_tax_incl>
          <total_shipping_tax_excl>$shippingCost</total_shipping_tax_excl>
          <conversion_rate>1</conversion_rate>
          
        </order>
      </prestashop>
      ''';

      final response = await http.post(
        Uri.parse('$baseUrl?ws_key=$apiKey'),
        headers: {'Content-Type': 'application/xml'},
        body: xmlBody,
      );

      if (response.statusCode == 201) {
        print("✅ Order created successfully!");
        print("Response Body: ${response.body}");
        return true;
      } else {
        print("❌ Failed to create order: ${response.body}");
        return false;
      }
    } catch (e) {
      print("❌ Error creating order: $e");
      return false;
    }
  }

  void debugOrderResponse(String jsonResponse) {
    try {
      // Parse the JSON response
      final Map<String, dynamic> responseData = json.decode(jsonResponse);

      // Extract the order details
      final order = responseData['orders'][0];

      // Print the relevant fields
      print("Order ID: ${order['id']}");
      print("Customer ID: ${order['id_customer']}");
      print("Cart ID: ${order['id_cart']}");
      print("Delivery Address ID: ${order['id_address_delivery']}");
      print("Invoice Address ID: ${order['id_address_invoice']}");
      print("Carrier ID: ${order['id_carrier']}");
      print("Current State: ${order['current_state']}");
      print("Payment Module: ${order['module']}");
      print("Total Paid: ${order['total_paid']}");
      print("Total Products: ${order['total_products']}");
      print("Total Products (with tax): ${order['total_products_wt']}");
      print("Total Shipping: ${order['total_shipping']}");
      print("Order Reference: ${order['reference']}");

      // Print associated products
      final orderRows = order['associations']['order_rows'];
      for (var row in orderRows) {
        print("Product ID: ${row['product_id']}");
        print("Product Name: ${row['product_name']}");
        print("Product Quantity: ${row['product_quantity']}");
        print("Product Price: ${row['product_price']}");
      }
    } catch (e) {
      print("❌ Error parsing order response: $e");
    }
  }
}