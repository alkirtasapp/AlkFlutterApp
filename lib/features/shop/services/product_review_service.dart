import 'dart:convert';

import 'package:alkirtas/config/app_config.dart';
import 'package:alkirtas/utils/backendData/userData.dart';
import 'package:http/http.dart' as http;
import 'package:alkirtas/utils/logging/logger.dart';

class ProductReviewSubmission {
  final String orderId;
  final String productId;
  final int rating;
  final String title;
  final String comment;

  const ProductReviewSubmission({
    required this.orderId,
    required this.productId,
    required this.rating,
    required this.title,
    required this.comment,
  });
}

class ProductReviewService {
  static const String _mobileEndpoint =
      'https://www.alkirtas.com/module/iqitreviews/mobile';
  static final Map<String, String> _imageCache = {};

  Future<bool> submitReview(ProductReviewSubmission review) async {
    final response = await http.post(
      Uri.parse(
        '$_mobileEndpoint?process=addProductReview&ajax=1&ws_key=${AppConfig.prestashopApiKey}',
      ),
      headers: const {
        'Accept': 'application/json',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'id_customer': UserData.id,
        'customer_name': '${UserData.firstname} ${UserData.lastname}'.trim(),
        'order_id': review.orderId,
        'iqitreviews_id_product': review.productId,
        'iqitreviews_rating': review.rating.toString(),
        'iqitreviews_title': review.title,
        'iqitreviews_comment': review.comment,
      },
    ).timeout(const Duration(seconds: 12));

    return parseSubmissionResponse(response);
  }

  static bool parseSubmissionResponse(http.Response response) {
    dynamic data;
    try {
      data = jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      throw ProductReviewException(
          'Le serveur a renvoyé une réponse invalide. Veuillez réessayer.',
          response.statusCode);
    }
    if (response.statusCode == 200 && data is Map && data['success'] == true) {
      return true;
    }

    final details = data is Map ? data['data'] : null;
    final errors = details is Map ? details['errors'] : null;
    const messages = <String, String>{
      'Unauthorized':
          'Le service d’avis refuse l’authentification de l’application. Veuillez contacter le support.',
      'Customer not found': 'Votre compte client est introuvable ou inactif.',
      'Order not found for this customer':
          'Cette commande ne correspond pas à votre compte.',
      'Order is not delivered':
          'Vous pourrez donner votre avis après la livraison de cette commande.',
      'Product not found': 'Ce produit est introuvable.',
      'Rating must be between 1 and 5':
          'Choisissez une note entre 1 et 5 étoiles.',
      'Title is incorrect':
          'Le titre de l’avis contient des caractères non autorisés.',
      'Comment is incorrect':
          'Votre commentaire contient des caractères non autorisés.',
      'Product is not part of this order':
          'Ce produit ne fait pas partie de cette commande.',
      'This product has already been reviewed':
          'Vous avez déjà envoyé un avis pour ce produit, éventuellement en attente de validation.',
      'Review could not be saved':
          'Le serveur n’a pas pu enregistrer votre avis. Veuillez réessayer.',
    };
    final knownErrors = errors is List
        ? errors.whereType<String>().where(messages.containsKey).toList()
        : <String>[];
    // Only log recognized error codes, never response bodies or credentials.
    AlkLoggerHelper.warning(
        'Product review submission failed: HTTP ${response.statusCode}; ${knownErrors.isEmpty ? "unrecognized response" : knownErrors.join(", ")}');
    throw ProductReviewException(
        knownErrors.isNotEmpty
            ? knownErrors.map((error) => messages[error]!).join('\n')
            : 'Impossible d’envoyer votre avis pour le moment (HTTP ${response.statusCode}).',
        response.statusCode);
  }

  Future<String> fetchProductImageUrl(String productId) async {
    if (productId.isEmpty) return '';
    final cachedImage = _imageCache[productId];
    if (cachedImage != null && cachedImage.isNotEmpty) return cachedImage;

    try {
      final response = await http
          .get(
            Uri.parse(
              'https://www.alkirtas.com/api/products/$productId?display=[id_default_image]&ws_key=${AppConfig.prestashopApiKey}&output_format=JSON',
            ),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        dynamic product = data['product'];
        final products = data['products'];
        if (product is! Map && products is List && products.isNotEmpty) {
          product = products.first;
        }
        dynamic rawImageId =
            product is Map ? product['id_default_image'] : null;
        if (rawImageId is Map) rawImageId = rawImageId['id'];

        final imageId = rawImageId?.toString() ?? '';
        if (imageId.isNotEmpty && imageId != '0' && imageId != 'null') {
          final imagePath = imageId.split('').join('/');
          final imageUrl =
              'https://www.alkirtas.com/img/p/$imagePath/$imageId.jpg';
          _imageCache[productId] = imageUrl;
          return imageUrl;
        }
      }
    } catch (_) {
      // The sheet has a product placeholder when image loading fails.
    }

    return '';
  }
}

class ProductReviewException implements Exception {
  final String message;
  final int statusCode;

  const ProductReviewException(this.message, this.statusCode);

  @override
  String toString() => message;
}
