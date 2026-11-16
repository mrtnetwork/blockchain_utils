import 'package:blockchain_utils/encoding/der/src/codec.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/crypto/crypto/keys/secp256r1/keys/core.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/crypto/crypto/keys/types/types.dart';
import 'package:blockchain_utils/crypto/crypto/group/weierstrass/weierstrass.dart';
import 'package:blockchain_utils/crypto/crypto/keys/constants/ecdsa.dart';

/// A NIST P-256 public key using Sui's hybrid (compressed+flag) encoding.
class SuiHybridSecp256r1PublicKey extends BaseSecp256r1PublicKey {
  SuiHybridSecp256r1PublicKey._(super.keyBytes);
  factory SuiHybridSecp256r1PublicKey.fromBytes(List<int> keyBytes) {
    final normalized = BaseSecp256r1PublicKey.normalizePublicKey(keyBytes);
    if (normalized == null) {
      throw CoreErrors.invalidOperationArguments(
        "SuiHybridSecp256r1PublicKey.fromBytes",
        reason: "Invalid public key bytes.",
      );
    }
    return SuiHybridSecp256r1PublicKey._(normalized);
  }

  @override
  CryptoKeyType get type {
    return CryptoKeyType.nist256p1Hybrid;
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

/// A NIST P-256 private key using Sui's hybrid (compressed+flag) encoding.
class SuiHybridSecp256r1PrivateKey
    extends BaseSecp256r1PrivateKey<SuiHybridSecp256r1PublicKey> {
  SuiHybridSecp256r1PrivateKey._(super.sk, super.publicKey);

  factory SuiHybridSecp256r1PrivateKey.fromBytes(List<int> keyBytes) {
    if (keyBytes.length != EcdsaKeysConst.privKeyByteLen) {
      throw CoreErrors.invalidOperationArguments(
        "SuiHybridSecp256r1PrivateKey.fromBytes",
        name: "keyBytes",
        reason: "Invalid secret key bytes length.",
      );
    }
    final pkPoint = Secp256r1Point.generator_ * Secp256r1Fr.fromBytes(keyBytes);
    return SuiHybridSecp256r1PrivateKey._(
      keyBytes,
      SuiHybridSecp256r1PublicKey.fromBytes(pkPoint.toBytes()),
    );
  }

  factory SuiHybridSecp256r1PrivateKey.fromDer(List<int> keyBytes) {
    final raw = DerCodec.decodeSecp256r1PrivateKeyPkcs8(keyBytes);
    final sk = raw.privateKey.takeBytes();
    try {
      return SuiHybridSecp256r1PrivateKey.fromBytes(sk);
    } finally {
      sk.forceZero();
    }
  }

  /// curve type.
  @override
  CryptoKeyType get type {
    return CryptoKeyType.nist256p1Hybrid;
  }

  /// check if bytes is valid for this key.
  static bool isValidBytes(List<int> keyBytes) =>
      BaseSecp256r1PrivateKey.isValidBytes(keyBytes);
}
