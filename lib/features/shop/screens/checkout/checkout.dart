import 'package:alkirtas/data/controllers/cart_contoller.dart';
import 'package:alkirtas/data/controllers/discount_controller.dart';
import 'package:alkirtas/data/controllers/order_controller.dart';
import 'package:alkirtas/data/controllers/tax_controller.dart';
import 'package:alkirtas/features/shop/controllers/cart_provider.dart';
import 'package:alkirtas/navigation_menu.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:alkirtas/common/widgets/signIn/AlkTOU.dart';
import 'package:alkirtas/data/controllers/addresses_controller.dart';
import 'package:alkirtas/utils/backendData/addressData.dart';
import 'package:alkirtas/utils/backendData/userData.dart';
import 'package:alkirtas/utils/constants/colors.dart';
import 'package:alkirtas/utils/constants/size.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:alkirtas/common/widgets/providers/product_provider.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key}); // Remove cartId

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>(); // Form Key for validation
  bool isUsingExistingAddress = false;
  bool isLoading = false; // Add loading state
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final phoneController = TextEditingController();
  final adressController = TextEditingController();
  final postalCodeController = TextEditingController();
  final cityController = TextEditingController();
  final gouverneratController = TextEditingController();

  bool isTermsAccepted = false; // Checkbox state
  String selectedDeliveryMethod = "First Delivery"; 
  double deliveryFee = 8.000; 

  void updateDeliveryMethod(String method) {
    setState(() {
      selectedDeliveryMethod = method;
      deliveryFee = (method == "Alkirtas corniche") ? 0.0 : 8.000;
    });
  }

  // Validator for required fields
  String? _validateField(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Ce champ est requis';
    }
    return null;
  }

  //  phone number (must be exactly 8 digits)
  String? _validatePhoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Ce champ est requis';
    } else if (!RegExp(r'^\d{8}$').hasMatch(value)) {
      return 'Le numéro de téléphone doit contenir 8 chiffres';
    }
    return null;
  }

    //  phone number (must be exactly 8 digits)
  String? _validatePostCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Ce champ est requis';
    } else if (!RegExp(r'^\d{4}$').hasMatch(value)) {
      return 'Le code postale doit contenir 4 chiffres';
    }
    return null;
  }

  double getTotalPriceWithDelivery(double cartTotal, double deliveryFee) {
    return cartTotal + deliveryFee;
  }

  /// Calculates the total price of products **after discounts only**.
  Future<double> calculateTotalProducts(List<Map<String, String>> cartItems) async {
    double total = 0.0;

    for (var item in cartItems) {
      final productId = item['productId'];
      final quantity = int.tryParse(item['productQuantity'] ?? '1') ?? 1;

      // Fetch product price from the API
      final response = await http.get(Uri.parse(
          "https://www.alkirtas.com/api/products?display=full&filter[id]=$productId&output_format=JSON&ws_key=Y262WZ22UPBRMJ6UNTHU24KDXT7T66RU"));

      if (response.statusCode == 200) {
        final productData = json.decode(response.body);
        final price = double.tryParse(productData['products'][0]['price'] ?? '0') ?? 0.0;

        // Apply discount using DiscountController
        final discountController = DiscountController();
        final discount = await discountController.fetchDiscount(int.parse(productId ?? '0'));

        double discountedPrice = price;
        if (discount != null && discount['reduction_type'] == 'percentage') {
          final reduction = double.tryParse(discount['reduction'] ?? '0') ?? 0.0;
          discountedPrice = price - (price * (reduction / 100));
        }

        total += discountedPrice * quantity;
      } else {
        print("❌ Failed to fetch product price for product ID: $productId");
      }
    }

    print("✅ Total Products (after discounts): $total");
    return total;
  }

  /// Calculates the total price of products **after taxes and discounts**.
  Future<double> calculateTotalProductsWt(CartProvider cartProvider) async {
    double totalWithTaxAndDiscounts = 0.0;

    for (var item in cartProvider.cartItems) {
      final productId = item['productId'];
      final quantity = int.tryParse(item['productQuantity'] ?? '1') ?? 1;

      // Fetch product price and tax rules group ID from the API
      final response = await http.get(Uri.parse(
          "https://www.alkirtas.com/api/products?display=full&filter[id]=$productId&output_format=JSON&ws_key=Y262WZ22UPBRMJ6UNTHU24KDXT7T66RU"));

      if (response.statusCode == 200) {
        final productData = json.decode(response.body);
        final price = double.tryParse(productData['products'][0]['price'] ?? '0') ?? 0.0;
        final taxRulesGroupId = productData['products'][0]['id_tax_rules_group'] ?? 0;

        // Apply tax using TaxController
        final taxController = TaxController();
        final taxedPrice = await taxController.fetchTTCPrice(
          int.parse(productId ?? '0'),
          price,
          taxRulesGroupId,
        );

        // Apply discount using DiscountController
        final discountController = DiscountController();
        final discount = await discountController.fetchDiscount(int.parse(productId ?? '0'));

        double finalPrice = taxedPrice ?? price; // Use taxed price if available
        if (discount != null && discount['reduction_type'] == 'percentage') {
          final reduction = double.tryParse(discount['reduction'] ?? '0') ?? 0.0;
          finalPrice = finalPrice - (finalPrice * (reduction / 100));
        }

        totalWithTaxAndDiscounts += finalPrice * quantity;
      } else {
        print("❌ Failed to fetch product price for product ID: $productId");
      }
    }

    print("✅ Total Products WT (with tax and discounts): $totalWithTaxAndDiscounts");
    return totalWithTaxAndDiscounts;
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);

    print("🛒 CartProvider is available. Cart items: ${cartProvider.cartItems.length}");

    return Scaffold(
      appBar: AppBar(
        title: Text('Confirmation de commande'), 
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(AlkSize.defaultSpace),
              child: Column(
                children: [
                  // Suggest existing address if available
                  if (AddressData.hasAddress())
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Adresse de livraison", // Translated to French
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        ListTile(
                          title: Text("Utiliser l'adresse existante"), // Translated to French
                          subtitle: Text(
                              "${AddressData.firstname} ${AddressData.lastname}, ${AddressData.address1}, ${AddressData.city}, ${AddressData.postcode}, ${AddressData.phone}"),
                          leading: Radio<bool>(
                            value: true,
                            groupValue: isUsingExistingAddress,
                            onChanged: (value) {
                              setState(() {
                                isUsingExistingAddress = value!;
                              });
                            },
                          ),
                        ),
                        ListTile(
                          title: Text("Créer une nouvelle adresse"), 
                          leading: Radio<bool>(
                            value: false,
                            groupValue: isUsingExistingAddress,
                            onChanged: (value) {
                              setState(() {
                                isUsingExistingAddress = value!;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  if (!isUsingExistingAddress)
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: lastNameController,
                                  decoration: InputDecoration(
                                    labelText: 'Nom',
                                    labelStyle: const TextStyle(color: Colors.grey),
                                    prefixIcon: const Icon(Iconsax.user),
                                  ),
                                  validator: _validateField,
                                ),
                              ),
                              SizedBox(width: AlkSize.spaceBtwInputFields),
                              Expanded(
                                child: TextFormField(
                                  controller: firstNameController,
                                  decoration: InputDecoration(
                                    labelText: 'Prénom',
                                    labelStyle: const TextStyle(color: Colors.grey),
                                    prefixIcon: const Icon(Iconsax.user),
                                  ),
                                  validator: _validateField,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AlkSize.spaceBtwInputFields),
                          TextFormField(
                            controller: phoneController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Téléphone',
                              labelStyle: TextStyle(color: Colors.grey),
                              prefixIcon: Icon(Iconsax.mobile),
                            ),
                            validator: _validatePhoneNumber, // Apply phone number validation
                          ),
                          const SizedBox(height: AlkSize.spaceBtwInputFields),
                          TextFormField(
                            controller: adressController,
                            decoration: const InputDecoration(
                              labelText: 'Adresse ',
                              labelStyle: TextStyle(color: Colors.grey),
                              prefixIcon: Icon(Iconsax.house),
                            ),
                            validator: _validateField,
                          ),
                          const SizedBox(height: AlkSize.spaceBtwInputFields),
                          TextFormField(
                            controller: postalCodeController,
                            decoration: const InputDecoration(
                              labelText: 'Code postale',
                              labelStyle: TextStyle(color: Colors.grey),
                              prefixIcon: Icon(Iconsax.direct),
                            ),
                            validator: _validatePostCode,
                          ),
                          const SizedBox(height: AlkSize.spaceBtwInputFields),
                          TextFormField(
                            controller: cityController,
                            decoration: const InputDecoration(
                              labelText: 'Ville ',
                              labelStyle: TextStyle(color: Colors.grey),
                              prefixIcon: Icon(Iconsax.building),
                            ),
                            validator: _validateField,
                          ),
                          const SizedBox(height: AlkSize.spaceBtwInputFields),
                          TextFormField(
                            controller: gouverneratController,
                            decoration: const InputDecoration(
                              labelText: 'Gouvernorat',
                              labelStyle: TextStyle(color: Colors.grey),
                              prefixIcon: Icon(Iconsax.map_1),
                            ),
                            validator: _validateField,
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: AlkSize.spaceBtwInputFields),

                  // Delivery Method Selection
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Méthode de livraison", // Translated to French
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      ListTile(
                        title: Text("Alkirtas corniche"),
                        leading: Radio<String>(
                          value: "Alkirtas corniche",
                          groupValue: selectedDeliveryMethod,
                          onChanged: (value) {
                            setState(() {
                              selectedDeliveryMethod = value!;
                              deliveryFee = 0.0; // No delivery fee for Alkirtas corniche
                            });
                          },
                        ),
                      ),
                      ListTile(
                        title: Text("First Delivery"),
                        leading: Radio<String>(
                          value: "First Delivery",
                          groupValue: selectedDeliveryMethod,
                          onChanged: (value) {
                            setState(() {
                              selectedDeliveryMethod = value!;
                              deliveryFee = 8.0; // Delivery fee for First Delivery
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AlkSize.spaceBtwInputFields),

                 // Terms & Conditions Checkbox (Always Visible)
                  Row(
                    children: [
                      Checkbox(
                        value: isTermsAccepted,
                        onChanged: (value) {
                          setState(() {
                            isTermsAccepted = value!;
                          });
                        },
                      ),
                      AlkTOUCHeckbox(), // Reintroduced the AlkTOUCHeckbox
                    ],
                  ),
                  const SizedBox(height: AlkSize.spaceBtwInputFields),

                  // Confirm Order Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all(
                          isTermsAccepted ? Colors.purpleAccent[700] : Colors.grey, // Button color changes
                        ),
                      ),
                      onPressed: isTermsAccepted && !isLoading
                          ? () async {
                              setState(() {
                                isLoading = true; // Start loading
                              });

                              try {
                                // Step 1: Create Address (if needed)
                                if (!isUsingExistingAddress) {
                                  if (_formKey.currentState!.validate()) {
                                    _formKey.currentState!.save();

                                    AddressData.id_customer = UserData.id;
                                    AddressData.lastname = lastNameController.text;
                                    AddressData.firstname = firstNameController.text;
                                    AddressData.address1 = adressController.text;
                                    AddressData.postcode = postalCodeController.text;
                                    AddressData.city = cityController.text;
                                    AddressData.phone = phoneController.text;
                                    AddressData.id_country = "208"; // Tunisia

                                    final AddressController addressController =
                                        Get.put(AddressController(), permanent: true);

                                    await addressController.createCustomerAddress();
                                  }
                                }

                                if (AddressData.id.isNotEmpty) {
                                  print("✅ Address confirmed: ${AddressData.id}");

                                  // Step 2: Create Cart
                                  final CartController cartController = Get.put(CartController());
                                  String cartId = await cartController.createCartWithAddress(
                                    cartItems: cartProvider.cartItems,
                                    idAddressDelivery: AddressData.id,
                                    idCarrier: selectedDeliveryMethod == "Alkirtas corniche" ? 4 : 6,
                                  );

                                  print("✅ Cart created successfully with ID: $cartId");

                                  // Step 3: Create Order
                                  final OrderController orderController = OrderController();

                                  final totalProducts = await calculateTotalProducts(cartProvider.cartItems); // After discounts
                                  final totalProductsWt = await calculateTotalProductsWt(cartProvider); // With tax and discounts
                                  final totalPaid = totalProductsWt + deliveryFee;

                                  final orderSuccess = await orderController.createOrder(
                                    idCart: cartId,
                                    deliveryMethod: selectedDeliveryMethod,
                                    cartTotal: totalPaid,
                                    totalProducts: totalProducts,
                                    totalProductsWt: totalProductsWt,
                                  );

                                  if (orderSuccess) {
                                    print("✅ Order created successfully!");

                                    // Show success notification
                                    Get.snackbar(
                                      "Succès",
                                      "Votre commande a été passée avec succès !",
                                      snackPosition: SnackPosition.TOP,
                                      backgroundColor: Colors.green,
                                      colorText: Colors.white,
                                      duration: const Duration(seconds: 3),
                                      isDismissible: true,
                                      dismissDirection: DismissDirection.vertical
                                    );

                                    // Redirect to the home page
                                    Get.offAll(() => const NavigationMenu(selectedMenu: 0));
                                  } else {
                                    print("❌ Order creation failed!");
                                    Get.snackbar(
                                      "Erreur",
                                      "Échec de la création de la commande. Veuillez réessayer.",
                                      snackPosition: SnackPosition.TOP,
                                      backgroundColor: Colors.red,
                                      colorText: Colors.white,
                                       duration: const Duration(seconds: 3),
                                      isDismissible: true,
                                      dismissDirection: DismissDirection.horizontal
                                    );
                                  }
                                } else {
                                  print("❌ Address creation failed! Cannot proceed.");
                                  Get.snackbar(
                                    "Erreur",
                                    "Échec de la création de l'adresse. Veuillez réessayer.",
                                    snackPosition: SnackPosition.TOP,
                                    backgroundColor: Colors.red,
                                    colorText: Colors.white,
                                     duration: const Duration(seconds: 3),
                                      isDismissible: true,
                                      dismissDirection: DismissDirection.horizontal
                                  );
                                }
                              } catch (e) {
                                print("❌ Error during checkout: $e");
                                Get.snackbar(
                                  "Erreur",
                                  "Une erreur s'est produite. Veuillez réessayer.",
                                  snackPosition: SnackPosition.TOP,
                                  backgroundColor: Colors.red,
                                  colorText: Colors.white,
                                   duration: const Duration(seconds: 3),
                                      isDismissible: true,
                                      dismissDirection: DismissDirection.horizontal
                                );
                              } finally {
                                setState(() {
                                  isLoading = false; // Stop loading
                                });
                              }
                            }
                          : null,
                      child: const Text('Confirmer la commande'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isLoading)
            Container(
              color: Colors.purple.withOpacity(0.5),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
