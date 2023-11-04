import 'package:blockchain_utils/numbers/bigint_utils.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/ecdsa/public_key.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/point/ec_projective_point.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/utils/utils.dart';

/// Represents an ECDSA (Elliptic Curve Digital Signature Algorithm) signature
/// containing `r` and `s` components.
class ECDSASignature {
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
    final n = generator.order;
    final e = BigintUtils.fromBytes(hash);

    final x = r;

    final alpha =
        (x.modPow(BigInt.from(3), curve.p) + curve.a * x + curve.b) % curve.p;
    final beta = ECDSAUtils.modularSquareRootPrime(alpha, curve.p);
    final y = (beta % BigInt.two == BigInt.zero) ? beta : (curve.p - beta);

    final r1 =
        ProjectiveECCPoint(curve: curve, x: x, y: y, z: BigInt.one, order: n);
    final q1 =
        (r1 * s) + (generator * (-e % n!)) * BigintUtils.inverseMod(r, n);
    final pk1 = ECDSAPublicKey(generator, q1);

    final r2 =
        ProjectiveECCPoint(curve: curve, x: x, y: -y, z: BigInt.one, order: n);
    final q2 = (r2 * s) + (generator * (-e % n)) * BigintUtils.inverseMod(r, n);
    final pk2 = ECDSAPublicKey(generator, q2);

    return [pk1, pk2];
  }
}
