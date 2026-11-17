import 'package:blockchain_utils/crypto/crypto/cipher/blockcipher/core/blockcipher.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/utils/binary/src/binary_operation.dart';

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

import 'package:blockchain_utils/crypto/crypto/cipher/blockcipher/aes/aes_lib.dart'
    as aes_lib;

/// AES block cipher (128/192/256-bit keys), operating on single 16-byte
/// blocks. Wrap in [CBC] or [CTR] for a mode of operation.
class AES implements BlockCipher {
  static final aes_lib.AESLib _lib = aes_lib.AESLib();
  static const List<int> allowedKeysLength = [16, 24, 32];

  /// Block size for AES cipher
  @override
  final blockSize = 16;

  /// The length of the encryption key
  late int _keyLen;

  /// The encryption key schedule
  List<int>? _encKey;

  /// The decryption key schedule
  List<int>? _decKey;

  /// Creates an AES cipher keyed with [key]. Pass [noDecryption] to skip
  /// building the decryption key schedule.
  AES(List<int> key, [bool noDecryption = false]) {
    _keyLen = key.length;
    setKey(key, noDecryption);
  }

  /// Re-keys this instance. [key] must be 16, 24, or 32 bytes, and the
  /// same size this instance was created with.
  AES setKey(List<int> key, [bool noDecryption = false]) {
    if (!allowedKeysLength.contains(key.length)) {
      throw CoreErrors.invalidOperationArguments(
        "setKey",
        reason: "Invalid key bytes length.",
      );
    }
    if (_keyLen != key.length) {
      throw CoreErrors.invalidOperationArguments(
        "setKey",
        name: "key",
        reason: "AES instance was initialized with a different key size.",
      );
    }

    _encKey ??= List<int>.filled(key.length + 28, 0, growable: false);
    if (noDecryption) {
      BinaryOps.tryZero(_decKey);
      _decKey = null;
    } else {
      BinaryOps.tryZero(_decKey);
      _decKey ??= List<int>.filled(key.length + 28, 0, growable: false);
    }
    _lib.expandKey(key, _encKey!, _decKey);
    return this;
  }

  /// Zeroes and releases both key schedules.
  @override
  AES clean() {
    BinaryOps.tryZero(_encKey);
    _encKey = null;
    BinaryOps.tryZero(_decKey);
    _decKey = null;
    return this;
  }

  /// Encrypts one 16-byte block, writing into [dst] if given.
  @override
  BuBytes encryptBlock(List<int> src, [List<int>? dst]) {
    final out = BuBytes.unsafeMutable(dst ?? List<int>.filled(blockSize, 0));
    if (src.length != blockSize) {
      throw CoreErrors.invalidOperationArguments(
        "encryptBlock",
        name: "src",
        reason: "Invalid source bytes length.",
      );
    }
    if (out.length != blockSize) {
      throw CoreErrors.invalidOperationArguments(
        "encryptBlock",
        name: "dst",
        reason: "Invalid destination bytes length.",
      );
    }
    final encKey = _encKey;
    if (encKey == null) {
      throw CoreErrors.cryptoFailed(
        "encryptBlock",
        reason: "Encryption key is not available.",
      );
    }
    _lib.encryptBlock(encKey, src.asBytes, out);

    return out;
  }

  /// Decrypts one 16-byte block, writing into [dst] if given. Throws if
  /// this instance was created with `noDecryption`.
  @override
  BuBytes decryptBlock(List<int> src, [List<int>? dst]) {
    final out = BuBytes.unsafeMutable(dst ?? List<int>.filled(blockSize, 0));
    if (src.length != blockSize) {
      throw CoreErrors.invalidOperationArguments(
        "decryptBlock",
        name: "src",
        reason: "Invalid source bytes length.",
      );
    }
    if (out.length != blockSize) {
      throw CoreErrors.invalidOperationArguments(
        "decryptBlock",
        name: "dst",
        reason: "Invalid destination bytes length.",
      );
    }

    final decKey = _decKey;

    if (decKey == null) {
      throw CoreErrors.cryptoFailed(
        "decryptBlock",
        reason: "Decryption key is not available.",
      );
    } else {
      _lib.decryptBlock(decKey, src.asBytes, out);
    }

    return out;
  }
}
