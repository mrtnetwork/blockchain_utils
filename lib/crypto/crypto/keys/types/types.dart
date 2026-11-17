import 'dart:typed_data';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/chain/signer/const/constants.dart';
import 'package:blockchain_utils/encoding/der/src/codec.dart';
import 'package:blockchain_utils/crypto/crypto/keys/utils/ecdsa.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/utils/binary/src/utils.dart';

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/utils/equatable/equatable.dart';

/// An enumeration of common elliptic curve types used in cryptographic operations.
enum CryptoKeyType {
  /// Edwards-curve Digital Signature Algorithm (EdDSA) using ed25519 curve
  ed25519(0, "Ed25519"),

  /// EdDSA with Blake2b hash
  ed25519Blake2b(1, "Ed25519 Blake2b"),

  /// EdDSA with Kholaw's 25519 curve
  ed25519Kholaw(2, "Ed25519 Kholaw"),

  /// EdDSA curve used in Monero
  ed25519Monero(3, "Ed25519 Monero"),

  /// NIST P-256 elliptic curve
  nist256p1(4, "NIST P-256"),

  /// Hybrid derivation using NIST P-256 elliptic curve
  nist256p1Hybrid(5, "NIST P-256 Hybrid"),

  /// SECG secp256k1 elliptic curve
  secp256k1(6, "Secp256k1"),

  /// Schnorr over Ristretto255 curve
  sr25519(7, "SR25519"),

  bls12G1(8, "BLS12-381 G1"),

  bls12G2(9, "BLS12-381 G2"),

  bls12G1Aggregate(11, "BLS12-381 G1 Aggregate"),

  bls12G2Aggregate(12, "BLS12-381 G2 Aggregate"),

  /// FIPS 204 ML-DSA-44.
  ///
  /// Serialized value 19: fresh identifier, no stored-key history.
  mldsa44(19, "ML-DSA-44"),

  /// FIPS 204 ML-DSA-65.
  ///
  /// Keeps serialized value 13 of the former level-blind `mldsa`: every key
  /// ever stored under it was level 65 (NEP-649 derives only 65 and random
  /// generation defaulted to 65), so stored keys keep decoding to the same
  /// level.
  mldsa65(13, "ML-DSA-65"),

  /// FIPS 204 ML-DSA-87.
  ///
  /// Serialized value 20: fresh identifier, no stored-key history.
  mldsa87(20, "ML-DSA-87"),

  redPallasBinding(14, "RedPallas Binding"),

  redPallasSpend(15, "RedPallas Spend"),

  redJubJubBinding(16, "RedJubJub Binding"),

  redJubJubSpend(17, "RedJubJub Spend"),

  muSig2(18, "MuSig2"),

  dkls23K1(21, "DKLs23 secp256k1"),

  dkls23R1(22, "DKLs23 secp256r1"),

  frostK1(23, "FROST secp256k1"),

  frostEd25519(24, "FROST Ed25519");

  const CryptoKeyType(this.value, this.displayName);

  final int value;
  final String displayName;

  /// Whether this is one of the ed25519-family key types.
  bool isED25519() =>
      this == ed25519Monero ||
      this == ed25519 ||
      this == ed25519Blake2b ||
      this == ed25519Kholaw;

  /// Retrieves the [CryptoKeyType] from its string [name].
  static CryptoKeyType fromName(String name) {
    return CryptoKeyType.values.firstWhere(
      (element) => element.name == name,
      orElse:
          () =>
              throw BuError(
                DefaultErrorType.notFound,
                "No matching CryptoKeyType found for the given value. $name",
                details: {"name": "CryptoKeyType", "value": name.toString()},
              ),
    );
  }

  /// Retrieves the [CryptoKeyType] from its integer [value].
  static CryptoKeyType fromValue(int value) {
    return CryptoKeyType.values.firstWhere(
      (element) => element.value == value,
      orElse:
          () =>
              throw BuError(
                DefaultErrorType.notFound,
                "No matching CryptoKeyType found for the given value. $value",
                details: {"name": "CryptoKeyType", "value": value.toString()},
              ),
    );
  }

  bool hasUncompressed() =>
      this == secp256k1 ||
      this == nist256p1 ||
      this == nist256p1Hybrid ||
      this == bls12G1 ||
      this == bls12G2;
}

enum CryptoKeyEncoding {
  base(0),
  uncompressed(1);

  const CryptoKeyEncoding(this.value);
  final int value;

  bool get isCompressed => this == base;

  static CryptoKeyEncoding fromValue(
    int? value, {
    CryptoKeyEncoding? defaultValue,
  }) {
    return values.firstWhere(
      (e) => e.value == value,
      orElse: () {
        if (defaultValue != null && value == null) return defaultValue;
        throw BuError(
          DefaultErrorType.notFound,
          "No matching item found for the given value. $value",
        );
      },
    );
  }
}

/// Marker for a signing scheme's parameters (e.g. hash to sign).
abstract class ISigningParams {}

/// Common interface every signature type implements.
abstract class ISignature with Equality {
  const ISignature();
  BuBytes toBytes();

  /// Casts this signature to a specific subtype, or throws.
  T cast<T extends ISignature>() {
    if (this is! T) {
      throw BuError(
        DefaultErrorType.castFailed,
        "Failed to cast value",
        details: {"expected": "T", "value": runtimeType.toString()},
      );
    }
    return this as T;
  }
}

/// Common interface every private (signing) key implements.
abstract class ISigningKey<
  SIGNATURE extends ISignature,
  SIGNPARAMS extends ISigningParams,
  VK extends IVerifiyingKey
>
    with SecretState {
  SecretBytes toBytes({SecretTransform? transform});
  SIGNATURE sign(SIGNPARAMS params);
  VK verificationKey();
  CryptoKeyType get type;

  /// Returns the live secret key object (not a copy). Do not zero,
  /// transform-destructively, or retain it past the key's [dispose];
  /// after [dispose]
  SecretBytes takeSecretKey();
}

/// Marker for a verification scheme's parameters (e.g. message + signature).
abstract class IVerifiyingParams {}

/// Common interface every public (verification) key implements.
abstract class IVerifiyingKey<VERIFYPARAMS extends IVerifiyingParams> {
  bool verify(VERIFYPARAMS params);
  CryptoKeyType get type;
  BuBytes toBytes({CryptoKeyEncoding mode = CryptoKeyEncoding.base});
}

/// Byte layouts for an ECDSA signature: [raw]=r+s only; [suffixRecoveryId]/
/// [prefixRecoveryId] add a recovery byte after/before r+s; [ethereumLegacy]
/// is r+s+v (v = recovery id + 27); [der] is ASN.1 DER; [bip137] is a
/// header byte (encoding recovery id + compression) followed by r+s.
enum ECDSASignatureEncoding {
  raw,
  suffixRecoveryId,
  prefixRecoveryId,
  ethereumLegacy,
  der,
  bip137,
}

/// An ECDSA signature (r, s, and an optional recovery id).
class IECDSASignature extends ISignature {
  final BuBytes r;
  final BuBytes s;
  final int? recoveryId;
  IECDSASignature({required List<int> r, required List<int> s, int? recoveryId})
    : r =
          BytesUtils.padBytesLeft(
            r.max(
              length: 32,
              operation: "IECDSASignature",
              reason: "Invalid signature bytes.",
            ),
            32,
          ).asImmutableBytes,
      s =
          BytesUtils.padBytesLeft(
            s.max(
              length: 32,
              operation: "IECDSASignature",
              reason: "Invalid signature bytes.",
            ),
            32,
          ).asImmutableBytes,
      recoveryId = recoveryId?.asU8;

  factory IECDSASignature.fromBytes(
    List<int> bytes, {
    ECDSASignatureEncoding? encoding,
  }) {
    int? recoverId(int id) {
      if (id >= 27) {
        id -= 27;
      }
      if (id == 0 || id == 1) return id;
      return null;
    }

    if (encoding == null) {
      final length = bytes.length;
      const int wRecoveryId =
          CryptoSignerConst.ecdsaSignatureLength +
          CryptoSignerConst.ecdsaRecoveryIdLength;
      if (length == CryptoSignerConst.ecdsaSignatureLength) {
        encoding = ECDSASignatureEncoding.raw;
      } else if (length > wRecoveryId) {
        encoding = ECDSASignatureEncoding.der;
      }
    }
    if (encoding == null) {
      throw BuError(
        DefaultErrorType.invalidSignature,
        "Unknown signature encoding.",
      );
    }
    const invalidLength = BuError(
      DefaultErrorType.invalidLength,
      "Invalid signature bytes length.",
    );

    switch (encoding) {
      case ECDSASignatureEncoding.raw:
        if (bytes.length != CryptoSignerConst.ecdsaSignatureLength) {
          throw invalidLength;
        }
        return IECDSASignature(r: bytes.sublist(0, 32), s: bytes.sublist(32));
      case ECDSASignatureEncoding.suffixRecoveryId:
      case ECDSASignatureEncoding.prefixRecoveryId:
      case ECDSASignatureEncoding.ethereumLegacy:
        if (bytes.length !=
            CryptoSignerConst.ecdsaSignatureLength +
                CryptoSignerConst.ecdsaRecoveryIdLength) {
          throw invalidLength;
        }
        final recoveryId = recoverId(
          encoding == ECDSASignatureEncoding.prefixRecoveryId
              ? bytes.first
              : bytes.last,
        );
        if (recoveryId == null) {
          throw BuError(
            DefaultErrorType.invalidSignature,
            "Invalid ECDSA signature recovery ID.",
          );
        }
        if (encoding == ECDSASignatureEncoding.prefixRecoveryId) {
          return IECDSASignature(
            r: bytes.sublist(1, 33),
            s: bytes.sublist(33),
            recoveryId: recoveryId,
          );
        }
        return IECDSASignature(
          r: bytes.sublist(0, 32),
          s: bytes.sublist(32, CryptoSignerConst.ecdsaSignatureLength),
          recoveryId: recoveryId,
        );
      case ECDSASignatureEncoding.der:
        try {
          final (r, s) = DerCodec.decodeEcdsaSignatureDer(bytes);
          return IECDSASignature(r: r, s: s);
        } catch (e) {
          throw BuError(
            DefaultErrorType.invalidSignature,
            "Invalid ECDSA Der signature.",
            details: {"reason": e.toString()},
          );
        }
      case ECDSASignatureEncoding.bip137:
        if (bytes.length !=
            CryptoSignerConst.ecdsaSignatureLength +
                CryptoSignerConst.ecdsaRecoveryIdLength) {
          throw invalidLength;
        }
        return IECDSASignature(
          r: bytes.sublist(1, 33),
          s: bytes.sublist(33),
          recoveryId: EcdsaKeysUtils.getBip137Header(bytes[0]),
        );
    }
  }

  BigInt rInt({Endian byteOrder = Endian.big}) =>
      r.toBigInt(byteOrder: byteOrder);
  BigInt sInt({Endian byteOrder = Endian.big}) =>
      s.toBigInt(byteOrder: byteOrder);

  @override
  BuBytes toBytes({
    ECDSASignatureEncoding encoding = ECDSASignatureEncoding.raw,
  }) {
    final recoveryId = this.recoveryId;
    if (encoding != ECDSASignatureEncoding.raw && recoveryId == null) {
      throw CoreErrors.cryptoFailed(
        "IECDSASignature.toBytes",
        reason: "Missing recoveryId",
      );
    }
    return switch (encoding) {
      ECDSASignatureEncoding.raw => BuBytes.unsafeMutable([...r, ...s]),
      ECDSASignatureEncoding.suffixRecoveryId => BuBytes.unsafeMutable([
        ...r,
        ...s,
        recoveryId!,
      ]),
      ECDSASignatureEncoding.prefixRecoveryId => BuBytes.unsafeMutable([
        recoveryId!,
        ...r,
        ...s,
      ]),
      ECDSASignatureEncoding.ethereumLegacy => BuBytes.unsafeMutable([
        ...r,
        ...s,
        recoveryId! + 27,
      ]),
      ECDSASignatureEncoding.der => DerCodec.encodeEcdsaSignatureDer(r, s),
      ECDSASignatureEncoding.bip137 => BuBytes.unsafeMutable([
        recoveryId! + 27,
        ...r,
        ...s,
      ]),
    };
  }

  @override
  List<dynamic> get variables => [r, s];
}
