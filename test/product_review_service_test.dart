import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:alkirtas/features/shop/services/product_review_service.dart';

void main() {
  http.Response response(int status, bool success, List<String> errors) =>
      http.Response(
          jsonEncode({
            'success': success,
            'data': {'errors': errors}
          }),
          status);

  test('published and moderation-pending success are accepted', () {
    expect(
        ProductReviewService.parseSubmissionResponse(response(200, true, [])),
        isTrue);
  });
  test('authentication rejection retains its reason and HTTP status', () {
    expect(
        () => ProductReviewService.parseSubmissionResponse(
            response(401, false, ['Unauthorized'])),
        throwsA(isA<ProductReviewException>()
            .having((e) => e.statusCode, 'status', 401)
            .having(
                (e) => e.message, 'message', contains('authentification'))));
  });
  test('duplicate review is explained without reporting new submission success',
      () {
    expect(
        () => ProductReviewService.parseSubmissionResponse(
            response(422, false, ['This product has already been reviewed'])),
        throwsA(isA<ProductReviewException>()
            .having((e) => e.message, 'message', contains('déjà envoyé'))));
  });
  test('order validation rejection retains its specific reason', () {
    expect(
        () => ProductReviewService.parseSubmissionResponse(
            response(422, false, ['Product is not part of this order'])),
        throwsA(isA<ProductReviewException>().having(
            (e) => e.message, 'message', contains('ne fait pas partie'))));
  });
  test('HTML server failures produce a safe readable message', () {
    expect(
        () => ProductReviewService.parseSubmissionResponse(
            http.Response('<html>error</html>', 500)),
        throwsA(isA<ProductReviewException>().having(
            (e) => e.message, 'message', contains('réponse invalide'))));
  });
  test('unknown server details are not exposed to customers', () {
    expect(
        () => ProductReviewService.parseSubmissionResponse(
            response(500, false, ['private server details'])),
        throwsA(isA<ProductReviewException>().having((e) => e.message,
            'message', isNot(contains('private server details')))));
  });
}
