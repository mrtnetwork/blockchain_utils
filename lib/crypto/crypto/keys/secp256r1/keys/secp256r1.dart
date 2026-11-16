import 'package:blockchain_utils/api/api/api.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/encoding/der/src/codec.dart';
import 'package:blockchain_utils/crypto/crypto/keys/secp256r1/keys/core.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/crypto/crypto/keys/types/types.dart';
import 'package:blockchain_utils/crypto/crypto/keys/constants/ecdsa.dart';

/// A NIST P-256 (secp256r1) public key.
class Secp256r1PublicKey extends BaseSecp256r1PublicKey {
  Secp256r1PublicKey._(super.keyBytes);
  factory Secp256r1PublicKey.fromBytes(List<int> keyBytes) {
    final normalized = BaseSecp256r1PublicKey.normalizePublicKey(keyBytes);
    if (normalized == null) {
      throw CoreErrors.invalidOperationArguments(
        "Secp256r1PublicKey.fromBytes",
        reason: "Invalid public key bytes.",
      );
    }
    return Secp256r1PublicKey._(normalized);
  }

  @override
  CryptoKeyType get type {
    return CryptoKeyType.nist256p1;
  }

  /// check if bytes is valid for this key.
  static bool isValidBytes(List<int> keyBytes) =>
      BaseSecp256r1PublicKey.isValidBytes(keyBytes);

  /// Checks whether [keyBytes] has a valid length for the given [encoding].
  ///
  /// This check validates only the key length and does not verify whether
  /// [keyBytes] represents a valid public key.
  static bool isValidKeyEncoding(
    List<int> keyBytes,
    CryptoKeyEncoding encoding,
  ) {
    return switch (encoding) {
      CryptoKeyEncoding.base
          when keyBytes.length == EcdsaKeysConst.pubKeyCompressedByteLen &&
              (keyBytes[0] == 0x02 || keyBytes[0] == 0x03) =>
        true,
      CryptoKeyEncoding.uncompressed
          when keyBytes.length == EcdsaKeysConst.pubKeyUncompressedByteLen &&
              keyBytes[0] == 0x04 =>
        true,
      _ => false,
    };
  }
}

/// A NIST P-256 (secp256r1) private key.
class Secp256r1PrivateKey extends BaseSecp256r1PrivateKey<Secp256r1PublicKey> {
  Secp256r1PrivateKey._(super.sk, super.publicKey);

  factory Secp256r1PrivateKey.fromBytes(List<int> keyBytes) {
    if (keyBytes.length != EcdsaKeysConst.privKeyByteLen) {
      throw CoreErrors.invalidOperationArguments(
        "Secp256r1PrivateKey.fromBytes",
        name: "keyBytes",
        reason: "Invalid secret key bytes length.",
      );
    }
    try {
      final pubkeyBytes = blockchainUtils.api.secp256r1.multBase(keyBytes);
      return Secp256r1PrivateKey._(
        keyBytes,
        Secp256r1PublicKey.fromBytes(pubkeyBytes),
      );
    } catch (_) {
      throw CoreErrors.invalidOperationArguments(
        "Secp256r1PrivateKey.fromBytes",
        name: "keyBytes",
        reason: "Invalid secret key bytes.",
      );
    }
  }
  factory Secp256r1PrivateKey.random() {
    for (int attempts = 0; attempts < 255; attempts++) {
      final key = QuickCrypto.generateRandom(
        length: EcdsaKeysConst.privKeyByteLen,
      );
      try {
        final scalar = blockchainUtils.api.secp256r1.scReduce(key);
        try {
          if (scalar.every((b) => b == 0)) continue;
          return Secp256r1PrivateKey.fromBytes(scalar);
        } finally {
          scalar.forceZero();
        }
      } finally {
        key.forceZero();
      }
    }
    throw CoreErrors.cryptoFailed(
      "Secp256r1PrivateKey.random",
      reason: "Failed to generate a valid secret scalar.",
    );
  }
  factory Secp256r1PrivateKey.fromDer(List<int> keyBytes) {
    final raw = DerCodec.decodeSecp256r1PrivateKeyPkcs8(keyBytes);
    final sk = raw.privateKey.takeBytes();
    try {
      return Secp256r1PrivateKey.fromBytes(sk);
    } finally {
      sk.forceZero();
    }
  }

  /// curve type.
  @override
  CryptoKeyType get type {
    return CryptoKeyType.nist256p1;
  }

  /// check if bytes is valid for this key.
  static bool isValidBytes(List<int> keyBytes) =>
      BaseSecp256r1PrivateKey.isValidBytes(keyBytes);
}
