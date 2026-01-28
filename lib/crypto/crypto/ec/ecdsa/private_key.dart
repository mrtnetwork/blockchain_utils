import 'dart:typed_data';
import 'package:blockchain_utils/bip/ecc/curve/elliptic_curve_types.dart';
import 'package:blockchain_utils/crypto/crypto/ec/curve/curves.dart';
import 'package:blockchain_utils/crypto/crypto/ec/utils/secp256k1.dart';
import 'package:blockchain_utils/exception/exception/exception.dart';
import 'package:blockchain_utils/signer/exception/signing_exception.dart';

import 'package:blockchain_utils/crypto/crypto/ec/ecdsa/signature.dart';
import 'package:blockchain_utils/crypto/crypto/ec/projective/native/native.dart';
import 'package:blockchain_utils/utils/compare/compare.dart';
import 'package:blockchain_utils/utils/equatable/equatable.dart';
import 'package:blockchain_utils/utils/numbers/utils/bigint_utils.dart';
import 'public_key.dart';

/// Represents an ECDSA (Elliptic Curve Digital Signature Algorithm) private key.
class ECDSAPrivateKey with ConstantEquality<ECDSAPrivateKey> {
  final ECDSAPublicKey publicKey;
  final BigInt secretMultiplier;
  ECDSAPrivateKey(this.publicKey, this.secretMultiplier);

  /// Creates an ECDSA private key from bytes.
  ///
  /// Parameters:
  ///   - [secrentKey]: A byte representation of the private key.
  ///   - [curve]: The elliptic curve used for the key pair.
  ///
  /// Returns:
  ///   An ECDSA private key.
  ///
  factory ECDSAPrivateKey.fromBytes(
    List<int> secrentKey,
    ProjectiveECCPoint curve,
  ) {
    if (secrentKey.length != curve.curve.baselen) {
      throw ArgumentException.invalidOperationArguments(
        "ECDSAPrivateKey",
        name: "secrentKey",
        reason: "Invalid secret key bytes length.",
        expecteLen: curve.curve.baselen,
      );
    }
    final secexp = BigintUtils.fromBytes(secrentKey, byteOrder: Endian.big);
    final ECDSAPublicKey publicKey = ECDSAPublicKey(curve, curve * secexp);
    return ECDSAPrivateKey(publicKey, secexp);
  }

  /// Creates an ECDSA private key from bytes.
  ///
  /// Parameters:
  ///   - [secretKey]: A byte representation of the private key.
  ///   - [type]: The elliptic curve used for the key pair.
  ///
  factory ECDSAPrivateKey.fromBytesConst({
    required List<int> secretKey,
    EllipticCurveTypes type = EllipticCurveTypes.secp256k1,
  }) {
    if (type != EllipticCurveTypes.secp256k1) {
      throw ArgumentException.invalidOperationArguments(
        "ECDSAPrivateKey",
        name: "secretKey",
        reason:
            "Unsupported curve. constant-time ECDSA private key derivation is restricted to secp256k1.",
      );
    }
    final generator = Curves.generatorSecp256k1;
    if (secretKey.length != generator.curve.baselen) {
      throw ArgumentException.invalidOperationArguments(
        "ECDSAPrivateKey",
        name: "secretKey",
        reason: "Invalid secret key bytes length.",
        expecteLen: generator.curve.baselen,
      );
    }
    final pubkeyBytes = Secp256k1Utils.generatePublicKeyBlind(
      scalarBytes: secretKey,
      secp: true,
    );
    if (pubkeyBytes == null) {
      throw ArgumentException.invalidOperationArguments(
        "ECDSAPrivateKey",
        name: "secretKey",
        reason: "Invalid secret key.",
      );
    }
    final publicKey = ECDSAPublicKey.fromBytes(pubkeyBytes, generator);
    final secexp = BigintUtils.fromBytes(secretKey, byteOrder: Endian.big);
    return ECDSAPrivateKey(publicKey, secexp);
  }

  /// Signs a hash value using the private key.
  ///
  /// Parameters:
  ///   - [hash]: A hash value of the message to be signed.
  ///   - [randomK]: A random value for signature generation.
  ///
  /// Returns:
  ///   An ECDSA signature.
  ///
  ECDSASignature sign(BigInt hash, BigInt randomK) {
    final BigInt? n = publicKey.generator.order;
    if (n == null) {
      throw ArgumentException.invalidOperationArguments(
        "sign",
        reason: "Invalid curve generator.",
      );
    }

    final BigInt k = randomK % n;
    final BigInt ks = k + n;
    final BigInt kt = ks + n;

    BigInt r;
    if (ks.bitLength == n.bitLength) {
      r = (publicKey.generator * kt).x % n;
    } else {
      r = (publicKey.generator * ks).x % n;
    }

    if (r == BigInt.zero) {
      throw const CryptoSignException(
        "ECDSA signing aborted. nonce generation failed.",
      );
    }

    final BigInt s =
        (BigintUtils.inverseMod(k, n) * (hash + (secretMultiplier * r) % n)) %
        n;

    if (s == BigInt.zero) {
      throw const CryptoSignException(
        "ECDSA signing aborted. s generation failed.",
      );
    }

    return ECDSASignature(r, s);
  }

  /// Converts the private key to bytes.
  List<int> toBytes() {
    final tob = BigintUtils.toBytes(
      secretMultiplier,
      length: publicKey.generator.curve.baselen,
    );
    return tob;
  }

  @override
  bool constantEquality(ECDSAPrivateKey other) {
    return CompareUtils.constantTimeBigIntEquals(
      [secretMultiplier],
      [other.secretMultiplier],
    );
  }

  @override
  List<Object?> get publicFields => [publicKey];
}
