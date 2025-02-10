import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../common/widgets/providers/product_provider.dart'; // Import your provider

class AppProviders extends StatelessWidget {
  final Widget child;

  const AppProviders({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ProductProvider>(create: (context) => ProductProvider()), // ✅ Register Provider
      ],
      child: child,
    );
  }
}
