import 'package:blockchain_utils/utils/utils.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/ecdsa/signature.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/point/base.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/point/ec_projective_point.dart';
import 'package:blockchain_utils/exception/exception.dart';

/// Represents an ECDSA (Elliptic Curve Digital Signature Algorithm) public key.
class ECDSAPublicKey {
  final ProjectiveECCPoint generator;
  final ProjectiveECCPoint point;
  ECDSAPublicKey._(this.generator, this.point);

  /// Creates an ECDSA public key with a generator and a point.
  ///
  /// Parameters:
  ///   - generator: The generator point for the elliptic curve.
  ///   - point: The public key point.
  ///   - verify: Set to `true` to verify that the point is on the curve and
  ///     has a valid order (default is `true`).
  ///
  factory ECDSAPublicKey(ProjectiveECCPoint generator, ProjectiveECCPoint point,
      {bool verify = true}) {
    final curve = generator.curve;
    final n = generator.order;
    final p = curve.p;

    if (!(BigInt.zero <= point.x && point.x < p) ||
        !(BigInt.zero <= point.y && point.y < p)) {
      throw const ArgumentException(
          "The public point has x or y out of range.");
    }

    if (verify && !curve.containsPoint(point.x, point.y)) {
      throw const ArgumentException("AffinePointt does not lay on the curve");
    }

    if (n == null) {
      throw const ArgumentException("Generator point must have order.");
    }

    if (verify && curve.cofactor() != BigInt.one && !(point * n).isInfinity) {
      throw const ArgumentException("Generator point order is bad.");
    }
    return ECDSAPublicKey._(generator, point);
  }

  @override
  bool operator ==(Object other) {
    if (other is ECDSAPublicKey) {
      return generator.curve == other.generator.curve && point == other.point;
    }
    return false;
  }

  /// Verifies an ECDSA signature against a hash value.
  ///
  /// Parameters:
  ///   - hash: A hash value of the message to be verified.
  ///   - signature: An ECDSA signature to be verified.
  ///
  /// Returns:
  ///   `true` if the signature is valid, `false` otherwise.
  ///
  bool verifies(BigInt hash, ECDSASignature signature) {
    final ProjectiveECCPoint G = generator;
    final BigInt n = G.order!;
    final r = signature.r;
    final s = signature.s;

    if (r < BigInt.one || r > n - BigInt.one) {
      return false;
    }

    if (s < BigInt.one || s > n - BigInt.one) {
      return false;
    }
    final c = BigintUtils.inverseMod(s, n);
    final u1 = (hash * c) % n;
    final u2 = (r * c) % n;

    final xy = G.mulAdd(u1, point, u2);

    final v = xy.x % n;

    return v == r;
  }

  @override
  int get hashCode => generator.hashCode ^ point.hashCode;

  List<int> toBytes([EncodeType encodeType = EncodeType.comprossed]) {
    return point.toBytes(encodeType);
  }
}
