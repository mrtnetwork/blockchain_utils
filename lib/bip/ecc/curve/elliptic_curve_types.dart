import 'package:blockchain_utils/blockchain_utils.dart';

/// An enumeration of common elliptic curve types used in cryptographic operations.
class EllipticCurveTypes {
  /// Edwards-curve Digital Signature Algorithm (EdDSA) using ed25519 curve
  static const EllipticCurveTypes ed25519 = EllipticCurveTypes._('ed25519');

  /// EdDSA with Blake2b hash
  static const EllipticCurveTypes ed25519Blake2b =
      EllipticCurveTypes._('ed25519Blake2b');

  /// EdDSA with Kholaw's 25519 curve
  static const EllipticCurveTypes ed25519Kholaw =
      EllipticCurveTypes._('ed25519Kholaw');

  /// EdDSA curve used in Monero
  static const EllipticCurveTypes ed25519Monero =
      EllipticCurveTypes._('ed25519Monero');

  /// NIST P-256 elliptic curve
  static const EllipticCurveTypes nist256p1 = EllipticCurveTypes._('nist256p1');

  /// SECG secp256k1 elliptic curve
  static const EllipticCurveTypes secp256k1 = EllipticCurveTypes._('secp256k1');

  /// Schnorr over Ristretto255 curve
  static const EllipticCurveTypes sr25519 = EllipticCurveTypes._('sr25519');

  final String name;

  const EllipticCurveTypes._(this.name);
  static const List<EllipticCurveTypes> values = [
    ed25519,
    ed25519Blake2b,
    ed25519Kholaw,
    ed25519Monero,
    nist256p1,
    secp256k1,
    sr25519,
  ];

  static EllipticCurveTypes fromName(String name) {
    return EllipticCurveTypes.values.firstWhere(
        (element) => element.name == name,
        orElse: () => throw MessageException("Invalid curve type name. $name"));
  }

  @override
  String toString() {
    return "EllipticCurveTypes.$name";
  }
}
