import 'package:bcrypt/bcrypt.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:alkirtas/features/authentication/services/customer_password_verifier.dart';
import 'package:alkirtas/utils/backendData/userData.dart';

void main() {
  final hash = BCrypt.hashpw('correct-password', BCrypt.gensalt(logRounds: 4));
  test('existing bcrypt accounts accept the correct password', () {
    expect(verifyCustomerPassword('correct-password', hash), isTrue);
  });
  test('existing bcrypt accounts reject an incorrect password', () {
    expect(verifyCustomerPassword('wrong-password', hash), isFalse);
  });
  test('PrestaShop bcrypt 2y hashes continue to work', () {
    final phpHash =
        hash.replaceFirst(r'$2a$', r'$2y$').replaceFirst(r'$2b$', r'$2y$');
    expect(verifyCustomerPassword('correct-password', phpHash), isTrue);
    expect(verifyCustomerPassword('wrong-password', phpHash), isFalse);
  });
  test(
      'legacy hash offers recovery without allowing login or throwing salt errors',
      () {
    expect(
        () => verifyCustomerPassword(
            'anything', '0123456789abcdef0123456789abcdef'),
        throwsA(isA<PasswordVerificationException>().having(
            (e) => e.message, 'message', contains('Mot de passe oublié'))));
  });
  test('missing and malformed password data never authenticate', () {
    for (final value in [null, '', 42, {}, r'$2y$10$broken']) {
      expect(() => verifyCustomerPassword('anything', value),
          throwsA(isA<PasswordVerificationException>()));
    }
  });
  test('verification does not change account state used by cart and orders',
      () {
    final previousId = UserData.id;
    final previousEmail = UserData.email;
    addTearDown(() {
      UserData.id = previousId;
      UserData.email = previousEmail;
    });
    UserData.id = '42';
    UserData.email = 'existing@example.com';
    verifyCustomerPassword('correct-password', hash);
    expect(UserData.id, '42');
    expect(UserData.email, 'existing@example.com');
  });
}
