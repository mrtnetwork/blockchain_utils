import 'package:blockchain_utils/blockchain_utils.dart';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';

void main() {
  // Define a function to generate a random string of a specified length
  String generateRandomString(int length) {
    // Define a character pool containing allowed characters for the random string
    const String characterPool =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

    // Use the secure random generator
    final random = math.Random.secure();

    // Initialize a buffer to store the random string
    final buffer = StringBuffer();

    // Generate the random string by selecting characters from the pool
    for (var i = 0; i < length; i++) {
      final randomIndex = random.nextInt(characterPool.length);
      buffer.write(characterPool[randomIndex]);
    }

    // Return the generated random string
    return buffer.toString();
  }

  test("secret storage", () {
    // Create a BIP39 instance with the Japanese language
    final BIP39 bip39 = BIP39(language: Bip39Language.japanese);

    // Repeat the following test 100 times
    for (int i = 0; i < 100; i++) {
      // Generate a random password of length 32
      final password = generateRandomString(32);

      // Generate a random 24-word mnemonic
      final mn = bip39.generateMnemonic(strength: Bip39WordLength.words24);

      // Encode the mnemonic with the password and additional parameters
      final secureStorage =
          SecretWallet.encode(mn, password, p: 1, scryptN: 8192);

      // Decode the encoded secure storage using the password
      final decodeWallet = SecretWallet.decode(
          secureStorage.encrypt(encoding: SecretWalletEncoding.json), password);

      // Verify that the credentials in the secure storage match the decoded credentials
      expect(secureStorage.credentials, decodeWallet.credentials);
    }
  });
}
