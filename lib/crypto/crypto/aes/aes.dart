import 'package:blockchain_utils/crypto/crypto/blockcipher/blockcipher.dart';
import 'package:blockchain_utils/crypto/crypto/exception/exception.dart';
import 'package:blockchain_utils/exception/exception/exception.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/utils/binary/binary_operation.dart';

import 'aes_lib.dart' as aes_lib;

/// Represents an Advanced Encryption Standard (AES) block cipher.
class AES implements BlockCipher {
  static final aes_lib.AESLib _lib = aes_lib.AESLib();

  /// Block size for AES cipher
  @override
  final blockSize = 16;

  /// The length of the encryption key
  late int _keyLen;

  /// The encryption key schedule
  List<int>? _encKey;

  /// The decryption key schedule
  List<int>? _decKey;

  /// Creates an AES cipher instance with the given encryption key.
  ///
  /// The [noDecryption] flag can be set to `true` to disable decryption functionality.
  AES(List<int> key, [bool noDecryption = false]) {
    _keyLen = key.length;
    setKey(key, noDecryption);
  }

  /// Initializes the AES cipher with the provided encryption key.
  ///
  /// Parameters:
  /// - [key]: The encryption key. It must be 16, 24, or 32 bytes in length
  ///   for AES-128, AES-192, or AES-256, respectively.
  /// - [noDecryption]: An optional boolean flag. If set to `true`, it disables decryption functionality
  ///   by securely wiping the decryption key schedule.
  ///
  /// Throws:
  /// - [ArgumentException] if the provided key size is invalid or if the instance was previously
  ///   initialized with a different key size.
  AES setKey(List<int> key, [bool noDecryption = false]) {
    if (key.length != 16 && key.length != 24 && key.length != 32) {
      throw ArgumentException.invalidOperationArguments(
        "setKey",
        reason: "Invalid key bytes length.",
      );
    }
    if (_keyLen != key.length) {
      throw ArgumentException.invalidOperationArguments(
        "setKey",
        reason: "aes Initialized with different key size.",
      );
    }

    _encKey ??= List<int>.filled(key.length + 28, 0, growable: false);
    if (noDecryption) {
      if (_decKey != null) {
        BinaryOps.zero(_decKey!);
        _decKey = null;
      }
    } else {
      _decKey ??= List<int>.filled(key.length + 28, 0, growable: false);
    }
    _lib.expandKey(key, _encKey!, _decKey);
    return this;
  }

  /// Clears and releases internal key schedule data for security and memory management.
  ///
  /// This method securely zeros and releases the internal encryption and decryption key schedules
  /// to ensure that no sensitive key data is left in memory. It is an essential step for maintaining
  /// the security of the AES cipher instance after use.
  ///
  /// Returns:
  /// - The same AES instance after cleaning for method chaining.
  @override
  AES clean() {
    if (_encKey != null) {
      BinaryOps.zero(_encKey!);
      _encKey = null;
    }
    if (_decKey != null) {
      BinaryOps.zero(_decKey!);
      _decKey = null;
    }
    return this;
  }

  /// Encrypt block
  ///
  /// Parameters:
  /// - [src]: The source block of plaintext to be encrypted, which must have a length of 16 bytes.
  /// - [dst]: An optional destination block to store the encrypted ciphertext. If not provided,
  ///   a new block is created.
  ///
  /// Throws:
  /// - [ArgumentException] if the source or destination block size is not 16 bytes.
  /// - [CryptoException] if the encryption key is not available, indicating that the instance is not properly initialized.
  @override
  List<int> encryptBlock(List<int> src, [List<int>? dst]) {
    final out = dst ?? List<int>.filled(blockSize, 0);
    if (src.length != blockSize) {
      throw ArgumentException.invalidOperationArguments(
        "encryptBlock",
        name: "src",
        reason: "Invalid source bytes length.",
      );
    }
    if (out.length != blockSize) {
      throw ArgumentException.invalidOperationArguments(
        "encryptBlock",
        name: "dst",
        reason: "Invalid destination bytes length.",
      );
    }

    if (_encKey == null) {
      throw CryptoException.failed(
        "encryptBlock",
        reason: "Encryption key is not available.",
      );
    }
    _lib.encryptBlock(_encKey!, src.asBytes, out);

    return out;
  }

  /// Decrypt block
  ///
  /// Parameters:
  /// - [src]: The source block of ciphertext to be decrypted, which must have a length of 16 bytes.
  /// - [dst]: An optional destination block to store the decrypted plaintext. If not provided,
  ///   a new block is created.
  ///
  /// Throws:
  /// - [ArgumentException] if the source or destination block size is not 16 bytes.
  /// - [CryptoException] if the instance was created with the `noDecryption` option, indicating that
  ///   decryption is not supported by this instance.
  @override
  List<int> decryptBlock(List<int> src, [List<int>? dst]) {
    final out = dst ?? List<int>.filled(blockSize, 0);
    if (src.length != blockSize) {
      throw ArgumentException.invalidOperationArguments(
        "decryptBlock",
        name: "src",
        reason: "Invalid source bytes length.",
      );
    }
    if (out.length != blockSize) {
      throw ArgumentException.invalidOperationArguments(
        "decryptBlock",
        name: "dst",
        reason: "Invalid destination bytes length.",
      );
    }

    if (_decKey == null) {
      throw CryptoException.failed(
        "decryptBlock",
        reason: "Decryption key is not available.",
      );
    } else {
      _lib.decryptBlock(_decKey!, src.asBytes, out);
    }

    return out;
  }
}
