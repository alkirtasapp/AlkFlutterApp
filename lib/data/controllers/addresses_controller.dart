import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:alkirtas/utils/backendData/addressData.dart';
import 'package:alkirtas/utils/backendData/userData.dart';

class AddressController extends GetxController {
  var isLoading = false.obs;

  /// Fetch the customer address from PrestaShop API
  Future<void> fetchCustomerAddress() async {
    try {
      isLoading.value = true;

      String url =
          "https://www.alkirtas.com/api/addresses?limit=1&filter[id_customer]=${UserData.id}&display=full&filter[deleted]=0&output_format=JSON&ws_key=Y262WZ22UPBRMJ6UNTHU24KDXT7T66RU";

      var response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        // Decode the response body as UTF-8
        var jsonResponse = json.decode(utf8.decode(response.bodyBytes));

        if (jsonResponse["addresses"] != null && jsonResponse["addresses"].isNotEmpty) {
          var address = jsonResponse["addresses"][0];

          // Store the address in AddressData
          AddressData.id = address["id"].toString();
          AddressData.id_customer = address["id_customer"].toString();
          AddressData.alias = address["alias"] ?? 'Mon adresse';
          AddressData.lastname = address["lastname"] ?? '';
          AddressData.firstname = address["firstname"] ?? '';
          AddressData.address1 = address["address1"] ?? '';
          AddressData.address2 = address["address2"] ?? '';
          AddressData.postcode = address["postcode"] ?? '';
          AddressData.city = address["city"] ?? '';
          AddressData.id_country = address["id_country"].toString();
          AddressData.id_state = address["id_state"].toString();
          AddressData.phone = address["phone"] ?? '';
          AddressData.phone_mobile = address["phone_mobile"] ?? '';
        } else {
          // If no address exists, clear AddressData
          AddressData.clearAddress();
        }
      } else {
        print("Failed to load address: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching address: $e");
    } finally {
      isLoading.value = false;
    }
  }

  /// Create a new address
  Future<void> createCustomerAddress() async {
    try {
      isLoading.value = true;

      String url = "https://www.alkirtas.com/api/addresses?ws_key=Y262WZ22UPBRMJ6UNTHU24KDXT7T66RU&output_format=JSON";

      String xmlBody = """
      <prestashop xmlns:xlink="http://www.w3.org/1999/xlink">
        <address>
          <id_customer>${UserData.id}</id_customer>
          <alias>${AddressData.alias}</alias>
          <lastname>${AddressData.lastname}</lastname>
          <firstname>${AddressData.firstname}</firstname>
          <address1>${AddressData.address1}</address1>
          <address2>${AddressData.address2}</address2>
          <postcode>${AddressData.postcode}</postcode>
          <city>${AddressData.city}</city>
          <id_country>${AddressData.id_country}</id_country>
          <phone>${AddressData.phone}</phone>
          <phone_mobile>${AddressData.phone_mobile}</phone_mobile>
        </address>
      </prestashop>
      """;

      var response = await http.post(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/xml; charset=utf-8",
        },
        body: utf8.encode(xmlBody), // Encode the body as UTF-8
      );

      if (response.statusCode == 201) {
        print("Address created successfully!");

        var jsonResponse = json.decode(utf8.decode(response.bodyBytes));
        if (jsonResponse['address'] != null) {
          AddressData.id = jsonResponse['address']['id'];
        }
      } else {
        print("Failed to create address. Status code: ${response.statusCode}");
      }
    } catch (e) {
      print("Error creating address: $e");
    } finally {
      isLoading.value = false;
    }
  }
}

