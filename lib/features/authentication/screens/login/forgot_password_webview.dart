import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ForgotPasswordWebView extends StatelessWidget {
  const ForgotPasswordWebView({super.key});

  @override
  Widget build(BuildContext context) {
    // Create a WebViewController
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            debugPrint('Loading progress: $progress%');
          },
          onPageStarted: (String url) {
            debugPrint('Page started loading: $url');
          },
          onPageFinished: (String url) {
            debugPrint('Page finished loading: $url');
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('Error loading page: ${error.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse('https://www.alkirtas.com/recuperation-mot-de-passe'));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Réinitialiser le mot de passe'),
      ),
      body: WebViewWidget(controller: controller), // Use WebViewWidget
    );
  }
}