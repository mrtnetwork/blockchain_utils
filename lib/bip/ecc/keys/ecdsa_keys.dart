/// Constants related to ECDSA (Elliptic Curve Digital Signature Algorithm) keys.
class EcdsaKeysConst {
  /// AffinePointt coordinate length in bytes
  static const int pointCoordByteLen = 32;

  /// Private key length in bytes
  static const int privKeyByteLen = 32;

  /// Uncompressed public key prefix
  static const List<int> pubKeyUncompressedPrefix = [0x04];

  /// Compressed public key length in bytes
  static const int pubKeyCompressedByteLen = 33;

  /// Uncompressed public key length in bytes
  static const int pubKeyUncompressedByteLen = 65;
}
