import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:example/test/quick_hex.dart';

void testSecureStorage() {
// Repeat the following test 100 times
  for (int i = 0; i < 5; i++) {
    // Generate a random password of length 32
    final password = QuickCrypto.generateRandom(32).toHex();
    final message = QuickCrypto.generateRandom(64);

    // Encode the mnemonic with the password and additional parameters
    final secureStorage = Web3SecretStorageDefinationV3.encode(
        message, password,
        p: 1, scryptN: 8192);

    // Decode the encoded secure storage using the password
    final decodeWallet = Web3SecretStorageDefinationV3.decode(
        secureStorage.encrypt(encoding: SecretWalletEncoding.base64), password,
        encoding: SecretWalletEncoding.base64);

    // Verify that the credentials in the secure storage match the decoded credentials
    assert(BytesUtils.bytesEqual(secureStorage.data, decodeWallet.data), true);
    assert(BytesUtils.bytesEqual(decodeWallet.data, message), true);
  }
  // Repeat the following test 100 times
  for (int i = 0; i < 5; i++) {
    // Generate a random password of length 32
    final password = QuickCrypto.generateRandom(32).toHex();
    final message = QuickCrypto.generateRandom(64);

    // Encode the mnemonic with the password and additional parameters
    final secureStorage = Web3SecretStorageDefinationV3.encode(
        message, password,
        p: 1, scryptN: 8192);

    // Decode the encoded secure storage using the password
    final decodeWallet = Web3SecretStorageDefinationV3.decode(
        secureStorage.encrypt(encoding: SecretWalletEncoding.json), password,
        encoding: SecretWalletEncoding.json);

    // Verify that the credentials in the secure storage match the decoded credentials
    assert(BytesUtils.bytesEqual(secureStorage.data, decodeWallet.data), true);
    assert(BytesUtils.bytesEqual(decodeWallet.data, message), true);
  }
}
