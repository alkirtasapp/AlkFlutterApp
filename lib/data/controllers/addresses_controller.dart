import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:test/utils/backendData/addressData.dart';
import 'package:test/utils/backendData/userData.dart';

class AddressController extends GetxController {
  var isLoading = false.obs;

// Track loading state

  /// Fetch the customer address from PrestaShop API
  Future<void> fetchCustomerAddress() async {
  try {
    isLoading.value = true;
    print(" Skipping address check, creating a new address...");

    // Always create a new address
    await createCustomerAddress();
  } catch (e) {
    print("Error while creating address: $e");
  } finally {
    isLoading.value = false;
  }
}
  /*Future<void> fetchCustomerAddress() async {
    try {
      isLoading.value = true;
      String url =
          "https://www.alkirtas.com/api/addresses?limit=1&filter[id_customer]=${UserData.id}&display=full&output_format=JSON&ws_key=Y262WZ22UPBRMJ6UNTHU24KDXT7T66RU";

      var response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        var jsonResponse = json.decode(response.body);
        if (jsonResponse["addresses"] != null && jsonResponse["addresses"].isNotEmpty) {
          var address = jsonResponse["addresses"][0];

          // Store the address in AddressData
          AddressData.id = address["id"].toString();
          AddressData.id_customer = address["id_customer"].toString();
          AddressData.alias = address["alias"] ?? 'My Address';
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
          // If no address exists, create one automatically
          await createCustomerAddress();
        }
      } else {
        print("Failed to load address: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching address: $e");
    } finally {
      isLoading.value = false;
    }
  }*/

  /// Create a new address if none exists
 Future<void> createCustomerAddress() async {
  try {
    isLoading.value = true;

    print("📤 Sending request to create a new address for customer ID: ${UserData.id}");

    String url = "https://www.alkirtas.com/api/addresses?ws_key=Y262WZ22UPBRMJ6UNTHU24KDXT7T66RU&output_format=JSON";

    String xmlBody = """
    <prestashop xmlns:xlink="http://www.w3.org/1999/xlink">
      <address>
        <id_customer>${UserData.id}</id_customer>
        <alias>My Address</alias>
        <lastname>${AddressData.lastname}</lastname>
        <firstname>${AddressData.firstname}</firstname>
        <address1>${AddressData.address1}</address1>
        <address2>${AddressData.address2}</address2>
        <postcode>${AddressData.postcode}</postcode>
        <city>${AddressData.city}</city>
        <id_country>208</id_country>
        <phone>${AddressData.phone}</phone>
        <phone_mobile>${AddressData.phone_mobile}</phone_mobile>
      </address>
    </prestashop>
    """;
    // Send the request
    var response = await http.post(
      Uri.parse(url),
      headers: {
        "Content-Type": "application/xml",
      },
      body: xmlBody,
    );
    // Check the response
    if (response.statusCode == 201) {
      print(" Address created successfully!");
      // Extract the ID from the response
      var jsonResponse = json.decode(response.body);
      if (jsonResponse.containsKey("address") && jsonResponse["address"].containsKey("id")) {
        AddressData.id = jsonResponse["address"]["id"].toString();
        print("✅ New Address ID: ${AddressData.id}");
      } else {
        print(" Could not extract Address ID from response.");
      }
    } else {
      print(" Failed to create address. Status code: ${response.statusCode}");
     
    }
  } catch (e) {
    print(" Error creating address: $e");
  } finally {
    isLoading.value = false;
  }
}


    

}

  /// 1.  Track the loading state
  /// 2.  Fetch the customer address from PrestaShop API  
  /// 3.  Create a new address if none exists
  /// 4.  Send a request to create a new address for the customer
  /// 5.  Extract the ID from the response(to be uses in the step 8)
  /// 6.  Handle errors and exceptions
  /// 7.  The address is now created automatically if none exists
  /// 8.  now the address id is gonna be used as address_delivery and address_invoice in the order creation

