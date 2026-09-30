import 'package:bcrypt/bcrypt.dart';

class PasswordVerificationException implements Exception {
  final String message;
  const PasswordVerificationException(this.message);
  @override
  String toString() => message;
}

/// Verifies the existing customer webservice password without changing session data.
/// Legacy/Google-generated hashes cannot be verified with bcrypt on the device.
bool verifyCustomerPassword(String password, dynamic storedHash) {
  if (storedHash is! String || storedHash.isEmpty) {
    throw const PasswordVerificationException(
      'Le serveur ne permet pas de vérifier votre mot de passe. Veuillez contacter le support.',
    );
  }
  if (!RegExp(r'^\$2[aby]\$(0[4-9]|[12][0-9]|3[01])\$[./A-Za-z0-9]{53}$')
      .hasMatch(storedHash)) {
    throw const PasswordVerificationException(
      'Ce compte utilise un ancien format de mot de passe ou a été créé avec Google. '
      'Utilisez « Mot de passe oublié ? » pour définir un mot de passe compatible. '
      'Si vous utilisez Google, vous pouvez continuer avec Google.',
    );
  }
  return BCrypt.checkpw(password, storedHash);
}
