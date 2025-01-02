import 'package:blockchain_utils/crypto/crypto/cdsa/ecdsa/public_key.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/point/ec_projective_point.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/utils/utils.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/utils/utils.dart';

/// Represents an ECDSA (Elliptic Curve Digital Signature Algorithm) signature
/// containing `r` and `s` components.
class ECDSASignature {
  factory ECDSASignature.fromBytes(
      List<int> bytes, ProjectiveECCPoint generator) {
    if (bytes.length != generator.curve.baselen * 2) {
      throw ArgumentException(
          "incorrect signatureBytes length ${bytes.length}");
    }
    final r = BigintUtils.fromBytes(bytes.sublist(0, generator.curve.baselen));
    final s = BigintUtils.fromBytes(
        bytes.sublist(generator.curve.baselen, generator.curve.baselen * 2));
    return ECDSASignature(r, s);
  }
  final BigInt r;
  final BigInt s;

  /// Creates an ECDSA signature with `r` and `s` components.
  ///
  /// Parameters:
  ///   - r: The `r` component of the signature.
  ///   - s: The `s` component of the signature.
  ///
  ECDSASignature(this.r, this.s);
  @override
  String toString() {
    return "($r, $s)";
  }

  /// Recovers public keys from the ECDSA signature and a hash of the message.
  ///
  /// This method attempts to recover the public keys associated with the private
  /// key used to create this signature. It returns a list of possible public keys.
  ///
  /// Parameters:
  ///   - hash: A hash of the message to be verified.
  ///   - generator: The generator point for the elliptic curve.
  ///
  /// Returns:
  ///   A list of recovered ECDSAPublicKey objects.
  ///
  List<ECDSAPublicKey> recoverPublicKeys(
      List<int> hash, ProjectiveECCPoint generator) {
    final curve = generator.curve;
    final order = generator.order!;
    final e = BigintUtils.fromBytes(hash);
    final alpha =
        (r.modPow(BigInt.from(3), curve.p) + curve.a * r + curve.b) % curve.p;
    final beta = ECDSAUtils.modularSquareRootPrime(alpha, curve.p);
    final y = (beta % BigInt.two == BigInt.zero) ? beta : (curve.p - beta);
    final ProjectiveECCPoint r1 = ProjectiveECCPoint(
        curve: curve, x: r, y: y, z: BigInt.one, order: order);
    final inverseR = BigintUtils.inverseMod(r, order);
    final ProjectiveECCPoint q1 = ((r1 * s) + (generator * (-e % order))) *
        inverseR as ProjectiveECCPoint;
    final pk1 = ECDSAPublicKey(generator, q1);

    final r2 = ProjectiveECCPoint(
        curve: curve, x: r, y: -y, z: BigInt.one, order: order);
    final ProjectiveECCPoint q2 = ((r2 * s) + (generator * (-e % order))) *
        inverseR as ProjectiveECCPoint;
    final pk2 = ECDSAPublicKey(generator, q2);

    return [pk1, pk2];
  }

  ECDSAPublicKey? recoverPublicKey(
      List<int> hash, ProjectiveECCPoint generator, int recId) {
    final curve = generator.curve;
    final order = generator.order!;
    final secret = BigintUtils.fromBytes(hash);
    final alpha =
        (r.modPow(BigInt.from(3), curve.p) + curve.a * r + curve.b) % curve.p;
    final beta = ECDSAUtils.modularSquareRootPrime(alpha, curve.p);
    BigInt y = (beta % BigInt.two == BigInt.zero) ? beta : (curve.p - beta);
    if (recId > 0) {
      y = -y;
    }
    final ProjectiveECCPoint r1 = ProjectiveECCPoint(
        curve: curve, x: r, y: y, z: BigInt.one, order: order);
    final ProjectiveECCPoint q1 = ((r1 * s) + (generator * (-secret % order))) *
        BigintUtils.inverseMod(r, order) as ProjectiveECCPoint;
    return ECDSAPublicKey(generator, q1);
  }

  List<int> toBytes(int baselen) {
    final sBytes = BigintUtils.toBytes(s, length: baselen);
    final rBytes = BigintUtils.toBytes(r, length: baselen);

    return [...rBytes, ...sBytes];
  }
}
