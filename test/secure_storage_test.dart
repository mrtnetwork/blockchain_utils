import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:test/test.dart';
import 'quick_hex.dart';

void main() {
  /// https://github.com/ethereum/wiki/wiki/Web3-Secret-Storage-Definition#pbkdf2-sha-256
  test("PBKDF2-SHA-256", () {
    final js = {
      "crypto": {
        "cipher": "aes-128-ctr",
        "cipherparams": {"iv": "6087dab2f9fdbbfaddc31a909735c1e6"},
        "ciphertext":
            "5318b4d5bcd28de64ee5559e671353e16f075ecae9f99c7a79a38af5f869aa46",
        "kdf": "pbkdf2",
        "kdfparams": {
          "c": 262144,
          "dklen": 32,
          "prf": "hmac-sha256",
          "salt":
              "ae3cd4e7013836a3df6bd7241b12db061dbe2c6785853cce422d148a624ce0bd"
        },
        "mac":
            "517ead924a9d0dc3124507e3393d175ce3ff7c1e96529c6c555ce9e51205e9b2"
      },
      "id": "3198bc9c-6672-5ab3-d995-4942343ae5b6",
      "version": 3
    };
    final decode = Web3SecretStorageDefinationV3.decode(
        StringUtils.fromJson(js), "testpassword");
    expect(BytesUtils.toHexString(decode.data),
        "7a28b5ba57c53603b0b07b56bba752f7784bf506fa95edc395f5cf6c7514fe9d");
    expect(decode.uuid, "3198bc9c-6672-5ab3-d995-4942343ae5b6");
    final encode = decode.encrypt();
    expect(StringUtils.toJson(encode), js);
  });

  /// https://github.com/ethereum/wiki/wiki/Web3-Secret-Storage-Definition#scrypt
  test("Scrypt", () {
    final js = {
      "crypto": {
        "cipher": "aes-128-ctr",
        "cipherparams": {"iv": "83dbcc02d8ccb40e466191a123791e0e"},
        "ciphertext":
            "d172bf743a674da9cdad04534d56926ef8358534d458fffccd4e6ad2fbde479c",
        "kdf": "scrypt",
        "kdfparams": {
          "dklen": 32,
          "n": 262144,
          "p": 8,
          "r": 1,
          "salt":
              "ab0c7876052600dd703518d6fc3fe8984592145b591fc8fb5c6d43190334ba19"
        },
        "mac":
            "2103ac29920d71da29f15d75b4a16dbe95cfd7ff8faea1056c33131d846e3097"
      },
      "id": "3198bc9c-6672-5ab3-d995-4942343ae5b6",
      "version": 3
    };
    final decode = Web3SecretStorageDefinationV3.decode(
        StringUtils.fromJson(js), "testpassword");
    expect(BytesUtils.toHexString(decode.data),
        "7a28b5ba57c53603b0b07b56bba752f7784bf506fa95edc395f5cf6c7514fe9d");
    expect(decode.uuid, "3198bc9c-6672-5ab3-d995-4942343ae5b6");
    final encode = decode.encrypt();
    expect(StringUtils.toJson(encode), js);
  });

  test("secret storage", () {
    // Repeat the following test 100 times
    for (int i = 0; i < 2; i++) {
      // Generate a random password of length 32
      final password = QuickCrypto.generateRandom(32).toHex();
      final message = QuickCrypto.generateRandom(64);

      // Encode the mnemonic with the password and additional parameters
      final secureStorage = Web3SecretStorageDefinationV3.encode(
          message, password,
          p: 1, scryptN: 8192);

      // Decode the encoded secure storage using the password
      final decodeWallet = Web3SecretStorageDefinationV3.decode(
          secureStorage.encrypt(encoding: SecretWalletEncoding.base64),
          password,
          encoding: SecretWalletEncoding.base64);
      // Verify that the credentials in the secure storage match the decoded credentials
      expect(
          BytesUtils.bytesEqual(secureStorage.data, decodeWallet.data), true);
      expect(BytesUtils.bytesEqual(decodeWallet.data, message), true);
    }
    // Repeat the following test 100 times
    for (int i = 0; i < 2; i++) {
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
      expect(
          BytesUtils.bytesEqual(secureStorage.data, decodeWallet.data), true);
      expect(BytesUtils.bytesEqual(decodeWallet.data, message), true);
    }
    for (int i = 0; i < 2; i++) {
      // Generate a random password of length 32
      final password = QuickCrypto.generateRandom(32).toHex();
      final message = QuickCrypto.generateRandom(64);

      // Encode the mnemonic with the password and additional parameters
      final secureStorage = Web3SecretStorageDefinationV3.encode(
          message, password,
          p: 1, scryptN: 8192);

      // Decode the encoded secure storage using the password
      final decodeWallet = Web3SecretStorageDefinationV3.decode(
          secureStorage.encrypt(encoding: SecretWalletEncoding.cbor), password,
          encoding: SecretWalletEncoding.cbor);

      // Verify that the credentials in the secure storage match the decoded credentials
      expect(
          BytesUtils.bytesEqual(secureStorage.data, decodeWallet.data), true);
      expect(BytesUtils.bytesEqual(decodeWallet.data, message), true);
    }
  });
}
