import 'package:blockchain_utils/bip/ecc/curve/elliptic_curve_types.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/curve/curves.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/point/base.dart';

/// A utility class for obtaining elliptic curve generators based on curve types.
class EllipticCurveGetter {
  /// Retrieves the elliptic curve generator based on the specified curve type.
  ///
  /// Parameters:
  /// - `type`: The type of elliptic curve.
  ///
  /// Returns an abstract elliptic curve point generator.
  static AbstractPoint generatorFromType(EllipticCurveTypes type) {
    switch (type) {
      case EllipticCurveTypes.secp256k1:
        return Curves.generatorSecp256k1;
      case EllipticCurveTypes.nist256p1:
        return Curves.generator256;
      case EllipticCurveTypes.ed25519:
      case EllipticCurveTypes.ed25519Kholaw:
        return Curves.generatorED25519;
      default:
        throw UnimplementedError("generatorFromType does not provide curve.");
    }
  }
}
