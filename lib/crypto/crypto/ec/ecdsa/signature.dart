import 'package:blockchain_utils/crypto/crypto/ec/ecdsa/public_key.dart';
import 'package:blockchain_utils/crypto/crypto/ec/projective/native/native.dart';
import 'package:blockchain_utils/crypto/crypto/ec/utils/utils.dart';
import 'package:blockchain_utils/exception/exception/exception.dart';
import 'package:blockchain_utils/utils/numbers/utils/bigint_utils.dart';

/// Represents an ECDSA (Elliptic Curve Digital Signature Algorithm) signature
/// containing `r` and `s` components.
class ECDSASignature {
  factory ECDSASignature.fromBytes(
    List<int> signature,
    ProjectiveECCPoint generator,
  ) {
    if (signature.length != generator.curve.baselen * 2) {
      throw ArgumentException.invalidOperationArguments(
        "ECDSASignature",
        name: "signature",
        reason: "Invalid signature bytes length.",
        expecteLen: generator.curve.baselen * 2,
      );
    }
    final r = BigintUtils.fromBytes(
      signature.sublist(0, generator.curve.baselen),
    );
    final s = BigintUtils.fromBytes(
      signature.sublist(generator.curve.baselen, generator.curve.baselen * 2),
    );
    return ECDSASignature(r, s);
  }
  final BigInt r;
  final BigInt s;

  /// Creates an ECDSA signature with `r` and `s` components.
  ///
  /// Parameters:
  ///   - [r]: The `r` component of the signature.
  ///   - [s]: The `s` component of the signature.
  ///
  const ECDSASignature(this.r, this.s);
  @override
  String toString() {
    return "($r, $s)";
  }

  /// Recovers public keys from the ECDSA signature and a hash of the message.
  ///
  /// Parameters:
  ///   - [hash]: A hash of the message to be verified.
  ///   - [generator]: The generator point for the elliptic curve.
  ///
  List<ECDSAPublicKey> recoverPublicKeys(
    List<int> hash,
    ProjectiveECCPoint generator,
  ) {
    final curve = generator.curve;
    final order = generator.order!;
    final e = BigintUtils.fromBytes(hash);
    final alpha =
        (r.modPow(BigInt.from(3), curve.p) + curve.a * r + curve.b) % curve.p;
    final beta = ECDSAUtils.modularSquareRootPrime(alpha, curve.p);
    final y = (beta % BigInt.two == BigInt.zero) ? beta : (curve.p - beta);
    final ProjectiveECCPoint r1 = ProjectiveECCPoint(
      curve: curve,
      x: r,
      y: y,
      z: BigInt.one,
      order: order,
    );
    final inverseR = BigintUtils.inverseMod(r, order);
    final ProjectiveECCPoint q1 =
        ((r1 * s) + (generator * (-e % order))) * inverseR
            as ProjectiveECCPoint;
    final pk1 = ECDSAPublicKey(generator, q1);

    final r2 = ProjectiveECCPoint(
      curve: curve,
      x: r,
      y: -y,
      z: BigInt.one,
      order: order,
    );
    final ProjectiveECCPoint q2 =
        ((r2 * s) + (generator * (-e % order))) * inverseR
            as ProjectiveECCPoint;
    final pk2 = ECDSAPublicKey(generator, q2);

    return [pk1, pk2];
  }

  /// Recovers public key from the ECDSA signature and a hash of the message.
  ///
  /// Parameters:
  ///   - [hash]: A hash of the message to be verified.
  ///   - [generator]: The generator point for the elliptic curve.
  ///   - [recId]: recovery id
  ///
  ECDSAPublicKey recoverPublicKey(
    List<int> hash,
    ProjectiveECCPoint generator,
    int recId,
  ) {
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
      curve: curve,
      x: r,
      y: y,
      z: BigInt.one,
      order: order,
    );
    final ProjectiveECCPoint q1 =
        ((r1 * s) + (generator * (-secret % order))) *
                BigintUtils.inverseMod(r, order)
            as ProjectiveECCPoint;
    return ECDSAPublicKey(generator, q1);
  }

  /// find correct recovery id from signature.
  int? recoverId({required List<int> hash, required ECDSAPublicKey publicKey}) {
    final keys = recoverPublicKeys(hash, publicKey.generator);
    final recId = keys.indexOf(publicKey);
    if (recId.isNegative) {
      return null;
    }
    return recId;
  }

  /// convert signature to bytes.
  List<int> toBytes(int baselen) {
    final sBytes = BigintUtils.toBytes(s, length: baselen);
    final rBytes = BigintUtils.toBytes(r, length: baselen);

    return [...rBytes, ...sBytes];
  }
}
