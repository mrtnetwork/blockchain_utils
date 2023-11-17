import 'package:blockchain_utils/blockchain_utils.dart';

import 'package:test/test.dart';

import 'quick_hex.dart';

void main() {
  test("secret storage", () {
    // Repeat the following test 100 times
    for (int i = 0; i < 5; i++) {
      // Generate a random password of length 32
      final password = QuickCrypto.generateRandom(32).toHex();
      final message = QuickCrypto.generateRandom(64).toHex();

      // Encode the mnemonic with the password and additional parameters
      final secureStorage =
          SecretWallet.encode(message, password, p: 1, scryptN: 8192);

      // Decode the encoded secure storage using the password
      final decodeWallet = SecretWallet.decode(
          secureStorage.encrypt(encoding: SecretWalletEncoding.cbor), password,
          encoding: SecretWalletEncoding.cbor);

      // Verify that the credentials in the secure storage match the decoded credentials
      expect(secureStorage.credentials, decodeWallet.credentials);
      expect(decodeWallet.credentials, message);
    }
    // Repeat the following test 100 times
    for (int i = 0; i < 5; i++) {
      // Generate a random password of length 32
      final password = QuickCrypto.generateRandom(32).toHex();
      final message = QuickCrypto.generateRandom(64).toHex();

      // Encode the mnemonic with the password and additional parameters
      final secureStorage =
          SecretWallet.encode(message, password, p: 1, scryptN: 8192);

      // Decode the encoded secure storage using the password
      final decodeWallet = SecretWallet.decode(
          secureStorage.encrypt(encoding: SecretWalletEncoding.json), password,
          encoding: SecretWalletEncoding.json);

      // Verify that the credentials in the secure storage match the decoded credentials
      expect(secureStorage.credentials, decodeWallet.credentials);
      expect(decodeWallet.credentials, message);
    }
  });
}
