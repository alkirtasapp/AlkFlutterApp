import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:test/utils/backendData/addressData.dart';
import 'package:test/utils/backendData/userData.dart';

class AddressController extends GetxController {
 
  var isLoading = false.obs; // track loading state

  Future<void> fetchCustomerAddress() async {
    try {
      isLoading.value = true; // set loading state to true
      String url = "https://www.alkirtas.com/api/addresses?limit=1&filter[id_customer]=${UserData.id}&display=full&output_format=JSON&ws_key=Y262WZ22UPBRMJ6UNTHU24KDXT7T66RU";
      
      var response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        var jsonResponse = json.decode(response.body);
        if (jsonResponse["addresses"] != null && jsonResponse["addresses"].isNotEmpty) {
          var address = jsonResponse["addresses"][0];
          AddressData.id = address["id"].toString();
          AddressData.id_customer = address["id_customer"].toString();
          AddressData.alias = address["alias"] ?? '';
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
          clearAddressData();
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

  void clearAddressData() {
    AddressData.id = '';
    AddressData.id_customer = '';
    AddressData.alias = '';
    AddressData.lastname = '';
    AddressData.firstname = '';
    AddressData.address1 = '';
    AddressData.address2 = '';
    AddressData.postcode = '';
    AddressData.city = '';
    AddressData.id_country = '';
    AddressData.id_state = '';
    AddressData.phone = '';
    AddressData.phone_mobile = '';
    AddressData.id = '';
  }
}
