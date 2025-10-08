/// An enumeration of common elliptic curve types used in cryptographic operations.
enum EllipticCurveTypes {
  /// Edwards-curve Digital Signature Algorithm (EdDSA) using ed25519 curve
  ed25519,

  /// EdDSA with Blake2b hash
  ed25519Blake2b,

  /// EdDSA with Kholaw's 25519 curve
  ed25519Kholaw,

  /// EdDSA curve used in Monero
  ed25519Monero,

  /// NIST P-256 elliptic curve
  nist256p1,

  /// Hybrid derivation using NIST P-256 elliptic curve
  nist256p1Hybrid,

  /// SECG secp256k1 elliptic curve
  secp256k1,

  /// Schnorr over Ristretto255 curve
  sr25519;

  /// Retrieves the [EllipticCurveTypes] from its string [name]
  static EllipticCurveTypes fromName(String name) {
    return EllipticCurveTypes.values.firstWhere(
      (element) => element.name == name,
      orElse: () => throw ArgumentError('Invalid curve type name: $name'),
    );
  }
}
