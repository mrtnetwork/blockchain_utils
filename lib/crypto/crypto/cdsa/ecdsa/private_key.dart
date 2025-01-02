import 'dart:typed_data';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/ecdsa/signature.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/point/ec_projective_point.dart';
import 'public_key.dart';

/// Represents an ECDSA (Elliptic Curve Digital Signature Algorithm) private key.
class ECDSAPrivateKey {
  final ECDSAPublicKey publicKey;
  final BigInt secretMultiplier;
  ECDSAPrivateKey._(this.publicKey, this.secretMultiplier);

  /// Creates an ECDSA private key from bytes.
  ///
  /// Parameters:
  ///   - bytes: A byte representation of the private key.
  ///   - curve: The elliptic curve used for the key pair.
  ///
  /// Returns:
  ///   An ECDSA private key.
  ///
  factory ECDSAPrivateKey.fromBytes(List<int> bytes, ProjectiveECCPoint curve) {
    if (bytes.length != curve.curve.baselen) {
      throw const ArgumentException("Invalid length of private key");
    }
    final secexp = BigintUtils.fromBytes(bytes, byteOrder: Endian.big);
    final ECDSAPublicKey publicKey = ECDSAPublicKey(curve, curve * secexp);
    return ECDSAPrivateKey._(publicKey, secexp);
  }

  /// Signs a hash value using the private key.
  ///
  /// Parameters:
  ///   - hash: A hash value of the message to be signed.
  ///   - randomK: A random value for signature generation.
  ///
  /// Returns:
  ///   An ECDSA signature.
  ///
  ECDSASignature sign(BigInt hash, BigInt randomK) {
    final BigInt n = publicKey.generator.order!;
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
      throw const MessageException("unlucky random number r");
    }

    final BigInt s =
        (BigintUtils.inverseMod(k, n) * (hash + (secretMultiplier * r) % n)) %
            n;

    if (s == BigInt.zero) {
      throw const MessageException("unlucky random number s");
    }

    return ECDSASignature(r, s);
  }

  /// Converts the private key to bytes.
  ///
  /// Returns:
  ///   A byte representation of the private key.
  ///
  List<int> toBytes() {
    final tob = BigintUtils.toBytes(secretMultiplier,
        length: publicKey.generator.curve.baselen);
    return tob;
  }

  @override
  bool operator ==(other) {
    if (other is ECDSAPrivateKey) {
      if (identical(this, other)) return true;
      return publicKey == other.publicKey &&
          secretMultiplier == other.secretMultiplier;
    }
    return false;
  }

  @override
  int get hashCode =>
      HashCodeGenerator.generateHashCode([publicKey, secretMultiplier]);
}
