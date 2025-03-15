import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:alkirtas/utils/backendData/cartData.dart';
import 'dart:convert';

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
}
