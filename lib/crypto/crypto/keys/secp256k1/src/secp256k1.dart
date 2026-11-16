import 'package:blockchain_utils/api/api.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/crypto/crypto/group/weierstrass/src/points.dart';
import 'package:blockchain_utils/encoding/der/src/codec.dart';
import 'package:blockchain_utils/crypto/crypto/keys/secp256k1/src/core.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/crypto/crypto/keys/types/types.dart';
import 'package:blockchain_utils/crypto/crypto/keys/constants/ecdsa.dart';

/// A secp256k1 public key implementing IPublicKey.
class Secp256k1PublicKey extends BaseSecp256k1PublicKey {
  Secp256k1PublicKey._(super.keyBytes);
  factory Secp256k1PublicKey.fromBytes(List<int> keyBytes) {
    final normalized = BaseSecp256k1PublicKey.normalizePublicKey(keyBytes);
    if (normalized == null) {
      throw CoreErrors.invalidOperationArguments(
        "Secp256k1PublicKey.fromBytes",
        reason: "Invalid public key bytes.",
      );
    }
    return Secp256k1PublicKey._(normalized);
  }
  factory Secp256k1PublicKey.fromDer(List<int> derBytes) {
    final rawBytes = DerCodec.decodeSecp256k1PublicKeySpki(derBytes);
    return Secp256k1PublicKey.fromBytes(rawBytes);
  }

  @override
  CryptoKeyType get type {
    return CryptoKeyType.secp256k1;
  }

  /// check if bytes is valid for this key.
  static bool isValidBytes(List<int> keyBytes) =>
      BaseSecp256k1PublicKey.isValidBytes(keyBytes);

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

  @override
  Secp256k1Point toPoint() => Secp256k1Point.fromBytes(toBytes());

  @override
  BuBytes toXOnlyBytes() => toPoint().toXOnly();
}

/// A secp256k1 private key implementing IPrivateKey.
class Secp256k1PrivateKey extends BaseSecp256k1PrivateKey<Secp256k1PublicKey> {
  Secp256k1PrivateKey._(super.sk, super.publicKey);

  factory Secp256k1PrivateKey.fromBytes(List<int> keyBytes) {
    if (keyBytes.length != EcdsaKeysConst.privKeyByteLen) {
      throw CoreErrors.invalidOperationArguments(
        "Secp256k1PrivateKey.fromBytes",
        name: "keyBytes",
        reason: "Invalid secret key bytes length.",
      );
    }
    try {
      final pubkeyBytes = blockchainUtils.api.secp256k1.multBase(keyBytes);
      return Secp256k1PrivateKey._(
        keyBytes,
        Secp256k1PublicKey.fromBytes(pubkeyBytes),
      );
    } catch (_) {
      throw CoreErrors.invalidOperationArguments(
        "Secp256k1PrivateKey.fromBytes",
        name: "keyBytes",
        reason: "Invalid secret key bytes.",
      );
    }
  }

  factory Secp256k1PrivateKey.fromDer(List<int> keyBytes) {
    final raw = DerCodec.decodeSecp256k1PrivateKeyPkcs8(keyBytes);
    final sk = raw.privateKey.takeBytes();
    try {
      return Secp256k1PrivateKey.fromBytes(sk);
    } finally {
      sk.forceZero();
    }
  }
  factory Secp256k1PrivateKey.random() {
    final rand = QuickCrypto.generateRandom(
      length: EcdsaKeysConst.privKeyByteLen,
    );
    try {
      final scalar = blockchainUtils.api.secp256k1.scReduce(rand);
      try {
        return Secp256k1PrivateKey.fromBytes(scalar);
      } finally {
        scalar.forceZero();
      }
    } finally {
      rand.forceZero();
    }
  }

  /// curve type.
  @override
  CryptoKeyType get type {
    return CryptoKeyType.secp256k1;
  }

  /// check if bytes is valid for this key.
  static bool isValidBytes(List<int> keyBytes) =>
      BaseSecp256k1PrivateKey.isValidBytes(keyBytes);
}
