class AddressData {
  static String id = '';
  static String id_customer = '';
  static String alias = 'Mon adresse';
  static String lastname = '';
  static String firstname = '';
  static String address1 = '';
  static String address2 = '';
  static String postcode = '';
  static String city = '';
  static String id_country = '208'; // dima Tunisie 
  static String id_state = '';
  static String phone = '';
  static String phone_mobile = '';

  // Check if an address exists
  static bool hasAddress() {
    return id.isNotEmpty;
  }
  static void clearAddress() {
    id = '';
    id_customer = '';
    lastname = '';
    firstname = '';
    address1 = '';
    postcode = '';
    city = '';
    phone = '';
    alias = 'Mon adresse';
    id_country = '208';
   
  }

}

