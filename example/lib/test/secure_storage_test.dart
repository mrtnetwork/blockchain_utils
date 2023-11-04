import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:example/test/quick_hex.dart';

void testSecureStorage() {
  // Repeat the following test 5 times
  for (int i = 0; i < 5; i++) {
    // Generate a random password of length 32
    final password = QuickCrypto.generateRandom(32).toHex();

    // Generate a random 24-word mnemonic
    final mn = QuickCrypto.generateRandom(128);

    // Encode the mnemonic with the password and additional parameters
    final secureStorage =
        SecretWallet.encode(mn.toHex(), password, p: 1, scryptN: 8192);
    final toJson = secureStorage.encrypt(encoding: SecretWalletEncoding.base64);

    // Decode the encoded secure storage using the password
    final decodeWallet = SecretWallet.decode(toJson, password);

    // Verify that the credentials in the secure storage match the decoded credentials
    assert(secureStorage.credentials == decodeWallet.credentials);
  }
}
