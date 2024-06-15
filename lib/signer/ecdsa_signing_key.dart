import 'package:blockchain_utils/crypto/crypto/cdsa/ecdsa/private_key.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/ecdsa/public_key.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/ecdsa/signature.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/point/ec_projective_point.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/rfc6979/rfc6979.dart';
import 'package:blockchain_utils/crypto/crypto/hash/hash.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'dart:math' as math;
import 'package:blockchain_utils/exception/exception.dart';

/// The [EcdsaSigningKey] class represents a key pair for ECDSA (Elliptic Curve Digital Signature Algorithm) signing.
/// It encapsulates the private key and provides methods for signing digests and generating deterministic signatures.
class EcdsaSigningKey {
  /// The ECDSA private key associated with this signing key.
  final ECDSAPrivateKey privateKey;

  /// Constructs an [EcdsaSigningKey] instance with the given private key.
  EcdsaSigningKey(this.privateKey) : generator = privateKey.publicKey.generator;

  /// The projective ECC (Elliptic Curve Cryptography) point generator associated with the key.
  final ProjectiveECCPoint generator;

  /// Truncates and converts a digest into a BigInt, based on the provided [generator].
  ///
  /// Throws an [ArgumentException] if the digest length exceeds the curve's base length when [truncate] is false.
  static BigInt _truncateAndConvertDigest(
      List<int> digest, ProjectiveECCPoint generator,
      {bool truncate = false}) {
    List<int> digestBytes = List.from(digest);
    if (!truncate) {
      if (digest.length > generator.curve.baselen) {
        throw const ArgumentException(
            "this curve is too short for digest length");
      }
    } else {
      digestBytes = digest.sublist(0, generator.curve.baselen);
    }

    BigInt toBig = BigintUtils.fromBytes(digest);
    if (truncate) {
      int maxLength = toBig.bitLength;
      int digestLen = digestBytes.length * 8;

      toBig >>= math.max(0, digestLen - maxLength);
    }
    return toBig;
  }

  /// Signs a given digest using the private key and a specified value of 'k'.
  ECDSASignature signDigest(
      {required List<int> digest,
      List<int>? entropy,
      required BigInt k,
      bool truncate = false}) {
    final digestInt =
        _truncateAndConvertDigest(digest, generator, truncate: truncate);
    final sign = privateKey.sign(digestInt, k);
    return sign;
  }

  /// Generates a deterministic signature for a given digest using the private key.
  ///
  /// Uses RFC 6979 for 'k' value generation to mitigate certain vulnerabilities associated with random 'k' generation.
  ECDSASignature signDigestDeterminstic({
    required List<int> digest,
    required HashFunc hashFunc,
    List<int> extraEntropy = const [],
    bool truncate = false,
  }) {
    ECDSASignature sig;
    int retry = 0;
    while (true) {
      final k = RFC6979.generateK(
          generator.order!, privateKey.secretMultiplier, hashFunc, digest,
          extraEntropy: extraEntropy, retryGn: retry);

      try {
        sig = signDigest(digest: digest, k: k, truncate: truncate);

        break;
      } on StateError {
        retry++;
      }
    }
    return sig;
  }
}

/// The [ECDSAVerifyKey] class represents a key for ECDSA (Elliptic Curve Digital Signature Algorithm) verification.
/// It encapsulates the public key and provides a method for verifying ECDSA signatures against a given digest.
class ECDSAVerifyKey {
  /// The ECDSA public key associated with this verification key.
  final ECDSAPublicKey publicKey;

  /// Constructs an [ECDSAVerifyKey] instance with the given public key.
  ECDSAVerifyKey(this.publicKey);

  /// Verifies a given ECDSA signature against a digest using the associated public key.
  ///
  /// It internally converts the digest into a BigInt using the truncate-and-convert method,
  /// and then calls the 'verifies' method of the associated public key.
  ///
  /// Returns true if the signature is valid for the provided digest, false otherwise.
  bool verify(ECDSASignature signature, List<int> digest) {
    final digestNumber =
        EcdsaSigningKey._truncateAndConvertDigest(digest, publicKey.generator);
    return publicKey.verifies(digestNumber, signature);
  }
}
