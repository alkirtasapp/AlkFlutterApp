import 'package:alkirtas/features/shop/controllers/cart_provider.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:alkirtas/utils/backendData/cartData.dart';
import 'dart:convert';
import 'package:xml/xml.dart' as xml;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:alkirtas/utils/backendData/userData.dart';
import 'package:alkirtas/utils/backendData/addressData.dart';
import 'package:alkirtas/common/widgets/providers/product_provider.dart';

class CartController extends GetxController {
  var isLoading = false.obs;

  Future<void> fetchCustomerCart() async {
    try {
      isLoading.value = true;
      String url = "https://www.alkirtas.com/api/carts?filter[id_customer]=${UserData.id}&sort=[id_DESC]&limit=1&display=full&output_format=JSON&ws_key=Y262WZ22UPBRMJ6UNTHU24KDXT7T66RU";
      
      var response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        var jsonResponse = json.decode(response.body);
        if (jsonResponse["carts"] != null && jsonResponse["carts"].isNotEmpty) {
          var cart = jsonResponse["carts"][0];
          CartData.id = cart["id"].toString();
        } else {
          await createNewCart(ProductProvider().cartItems);
        }
      } else {
        print("Failed to load cart: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching cart: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> createNewCart(List<Map<String, String>> cartItems) async {
    try {
      print("Creating new cart for customer ${UserData.id}");
      String url = "https://www.alkirtas.com/api/carts?ws_key=Y262WZ22UPBRMJ6UNTHU24KDXT7T66RU";
      
      String cartRowsXml = cartItems.map((item) {
        return """
        <cart_row>
          <id_product>${item['productId']}</id_product>
          <id_product_attribute><![CDATA[]]></id_product_attribute>
          <id_address_delivery>${AddressData.id}</id_address_delivery>
          <id_customization><![CDATA[]]></id_customization>
          <quantity>${item['productQuantity']}</quantity>
        </cart_row>
        """;
      }).join();

      String xmlBody = """
      <?xml version="1.0" encoding="UTF-8"?>
      <prestashop xmlns:xlink="http://www.w3.org/1999/xlink">
        <cart>
          <id_currency>1</id_currency>
          <id_lang>1</id_lang>
          <id_customer>${UserData.id}</id_customer>
          <associations>
            <cart_rows>
              $cartRowsXml
            </cart_rows>
          </associations>
        </cart>
      </prestashop>
      """;
      
      var response = await http.post(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/xml",
        },
        body: xmlBody,
      );
      
      if (response.statusCode == 201) {
        var jsonResponse = json.decode(response.body);
        CartData.id = jsonResponse["cart"]["id"].toString();
        print("New cart created successfully with ID: ${CartData.id}");
      } else {
        print("Failed to create cart: ${response.statusCode}, ${response.body}");
      }
    } catch (e) {
      print("Error creating cart: $e");
    }
  }

  Future<String> createCart(BuildContext context) async {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    if (cartProvider.cartItems.isEmpty) {
      throw Exception("❌ Cart is empty. Cannot create cart.");
    }

    String url =
        "https://www.alkirtas.com/api/carts?ws_key=Y262WZ22UPBRMJ6UNTHU24KDXT7T66RU";

    String cartRowsXml = cartProvider.cartItems.map((item) {
      return """
      <cart_row>
        <id_product><![CDATA[${item['productId']}]]></id_product>
        <id_product_attribute><![CDATA[]]></id_product_attribute>
        <id_address_delivery><![CDATA[${AddressData.id}]]></id_address_delivery>
        <id_customization><![CDATA[]]></id_customization>
        <quantity><![CDATA[${item['productQuantity']}]]></quantity>
      </cart_row>
      """;
    }).join();

    String xmlBody = '''<?xml version="1.0" encoding="UTF-8"?>
  <prestashop xmlns:xlink="http://www.w3.org/1999/xlink">
    <cart>
      <id_currency>1</id_currency>
      <id_lang>1</id_lang>
      <id_customer><![CDATA[${UserData.id}]]></id_customer>
      <associations>
        <cart_rows>
          $cartRowsXml
        </cart_rows>
      </associations>
    </cart>
  </prestashop>''';

    var response = await http.post(
      Uri.parse(url),
      headers: {
        "Content-Type": "application/xml",
        "Accept": "application/xml",
      },
      body: xmlBody.trim(),
    );

    print("Response Status: ${response.statusCode}");
    print("Response Body: ${response.body}");

    if (response.statusCode == 201 || response.statusCode == 200) {
      final document = xml.XmlDocument.parse(response.body);
      final cartIdElement = document.findAllElements("id").first;
      return cartIdElement.text;
    } else {
      throw Exception(
          "${UserData.id} USER Failed to create cart: ${response.statusCode}, ${response.body}");
    }
  }

  Future<void> fetchCartItems(String cartId) async {
    String url =
        "https://www.alkirtas.com/api/carts/$cartId?ws_key=Y262WZ22UPBRMJ6UNTHU24KDXT7T66RU&output_format=JSON";

    var response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final cartData = json.decode(response.body);
      final cartRows = cartData['cart']['associations']['cart_rows'];

      // Update the CartProvider with the fetched cart items
      final cartProvider = Get.find<CartProvider>();
      cartProvider.clearCart(); // Clear existing cart items

      for (var row in cartRows) {
        cartProvider.addToCart(
          productId: row['id_product'],
          productName: row['product_name'], // Ensure this field exists in the API
          productPrice: row['unit_price_tax_incl'], // Ensure this field exists
          quantity: int.parse(row['quantity']),
        );
      }

      print("✅ Cart items synced successfully!");
    } else {
      print("❌ Failed to fetch cart items: ${response.body}");
    }
  }

  Future<String> createCartWithAddress({
    required List<Map<String, String>> cartItems,
    required String idAddressDelivery,
    required int idCarrier,
    // Removed couponId
  }) async {
    try {
      String url = "https://www.alkirtas.com/api/carts?ws_key=Y262WZ22UPBRMJ6UNTHU24KDXT7T66RU";

      String cartRowsXml = cartItems.map((item) {
        return """
        <cart_row>
          <id_product><![CDATA[${item['productId']}]]></id_product>
          <id_product_attribute><![CDATA[]]></id_product_attribute>
          <id_address_delivery><![CDATA[$idAddressDelivery]]></id_address_delivery>
          <id_customization><![CDATA[]]></id_customization>
          <quantity><![CDATA[${item['productQuantity']}]]></quantity>
        </cart_row>
        """;
      }).join();

      // Removed cartRulesXml

      String xmlBody = '''
      <prestashop xmlns:xlink="http://www.w3.org/1999/xlink">
        <cart>
          <id_currency>1</id_currency>
          <id_lang>1</id_lang>
          <id_customer><![CDATA[${UserData.id}]]></id_customer>
          <id_carrier>$idCarrier</id_carrier>
          <id_address_delivery><![CDATA[$idAddressDelivery]]></id_address_delivery>
          <id_address_invoice><![CDATA[$idAddressDelivery]]></id_address_invoice>
          <delivery_option>{"$idAddressDelivery":"$idCarrier,"}</delivery_option>
          <associations>
            <cart_rows>
              $cartRowsXml
            </cart_rows>
          </associations>
        </cart>
      </prestashop>
      ''';

      var response = await http.post(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/xml",
          "Accept": "application/xml",
        },
        body: xmlBody.trim(),
      );

      print("Response Status: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 201 || response.statusCode == 200) {
        final document = xml.XmlDocument.parse(response.body);
        final cartIdElement = document.findAllElements("id").first;
        return cartIdElement.text;
      } else {
        throw Exception("Failed to create cart: ${response.statusCode}, ${response.body}");
      }
    } catch (e) {
      print("❌ Error creating cart: $e");
      rethrow;
    }
  }
}
