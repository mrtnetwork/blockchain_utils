import 'package:blockchain_utils/bip/ecc/keys/ed25519_keys.dart';
import 'package:blockchain_utils/bip/ecc/keys/ed25519_blake2b_keys.dart';
import 'package:blockchain_utils/bip/ecc/keys/ed25519_kholaw_keys.dart';
import 'package:blockchain_utils/bip/ecc/keys/ed25519_monero_keys.dart';
import 'package:blockchain_utils/bip/ecc/keys/nist256p1_keys.dart';
import 'package:blockchain_utils/bip/ecc/keys/secp256k1_keys_ecdsa.dart';
import 'package:blockchain_utils/bip/ecc/keys/sr25519_keys.dart';
import 'package:blockchain_utils/bip/ecc/curve/elliptic_curve_types.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/point/base.dart';
import 'package:blockchain_utils/utils/binary/utils.dart';

/// An abstract class representing a generic public key interface for different elliptic curve types.
abstract class IPublicKey {
  /// Factory method for creating an IPublicKey instance from a byte array and an elliptic curve type.
  factory IPublicKey.fromBytes(List<int> keybytes, EllipticCurveTypes type) {
    switch (type) {
      case EllipticCurveTypes.nist256p1:
        return Nist256p1PublicKey.fromBytes(keybytes);
      case EllipticCurveTypes.sr25519:
        return Sr25519PublicKey.fromBytes(keybytes);
      case EllipticCurveTypes.ed25519:
        return Ed25519PublicKey.fromBytes(keybytes);
      case EllipticCurveTypes.ed25519Kholaw:
        return Ed25519KholawPublicKey.fromBytes(keybytes);
      case EllipticCurveTypes.ed25519Monero:
        return MoneroPublicKey.fromBytes(keybytes);
      case EllipticCurveTypes.ed25519Blake2b:
        return Ed25519Blake2bPublicKey.fromBytes(keybytes);
      default:
        return Secp256k1PublicKeyEcdsa.fromBytes(keybytes);
    }
  }
  factory IPublicKey.fromHex(String keyHex, EllipticCurveTypes type) {
    return IPublicKey.fromBytes(BytesUtils.fromHexString(keyHex), type);
  }

  /// Static method to check the validity of a byte array as a public key for a specific elliptic curve type.
  static bool isValidBytes(List<int> keyBytes, EllipticCurveTypes type) {
    switch (type) {
      case EllipticCurveTypes.nist256p1:
        return Nist256p1PublicKey.isValidBytes(keyBytes);
      case EllipticCurveTypes.sr25519:
        return Sr25519PublicKey.isValidBytes(keyBytes);
      case EllipticCurveTypes.ed25519:
        return Ed25519PublicKey.isValidBytes(keyBytes);
      case EllipticCurveTypes.ed25519Kholaw:
        return Ed25519KholawPublicKey.isValidBytes(keyBytes);
      case EllipticCurveTypes.ed25519Monero:
        return MoneroPublicKey.isValidBytes(keyBytes);
      case EllipticCurveTypes.ed25519Blake2b:
        return Ed25519Blake2bPublicKey.isValidBytes(keyBytes);
      default:
        return Secp256k1PublicKeyEcdsa.isValidBytes(keyBytes);
    }
  }

  /// Get the elliptic curve type associated with the public key.
  EllipticCurveTypes get curve;

  /// Get the compressed length of the public key in bytes.
  int get length;

  /// Get the length of the uncompressed public key in bytes.
  int get uncompressedLength;

  /// Get the compressed form of the public key as a byte array.
  List<int> get compressed;

  /// Get the uncompressed form of the public key as a byte array.
  List<int> get uncompressed;

  /// Get the abstract point representation of the public key.
  AbstractPoint get point;

  String toHex(
      {bool withPrefix = true, bool lowerCase = true, String? prefix = ""});
}

/// An abstract class representing a generic private key interface for different elliptic curve types.
abstract class IPrivateKey {
  /// Get the elliptic curve type associated with the private key.
  EllipticCurveTypes get curve;

  /// Factory method for creating an IPrivateKey instance from a byte array and an elliptic curve type.
  factory IPrivateKey.fromBytes(List<int> keyBytes, EllipticCurveTypes type) {
    switch (type) {
      case EllipticCurveTypes.nist256p1:
        return Nist256p1PrivateKey.fromBytes(keyBytes);
      case EllipticCurveTypes.ed25519:
        return Ed25519PrivateKey.fromBytes(keyBytes);
      case EllipticCurveTypes.ed25519Kholaw:
        return Ed25519KholawPrivateKey.fromBytes(keyBytes);
      case EllipticCurveTypes.ed25519Blake2b:
        return Ed25519Blake2bPrivateKey.fromBytes(keyBytes);
      case EllipticCurveTypes.ed25519Monero:
        return MoneroPrivateKey.fromBytes(keyBytes);
      case EllipticCurveTypes.sr25519:
        return Sr25519PrivateKey.fromBytes(keyBytes);

      default:
    }
    return Secp256k1PrivateKeyEcdsa.fromBytes(keyBytes);
  }

  factory IPrivateKey.fromHex(String keyHex, EllipticCurveTypes type) {
    return IPrivateKey.fromBytes(BytesUtils.fromHexString(keyHex), type);
  }

  /// Get the length of the private key in bytes.
  int get length;

  /// Get the raw private key as a byte array.
  List<int> get raw;

  /// Get the associated public key.
  IPublicKey get publicKey;

  /// Static method to check the validity of key bytes for a specific elliptic curve type.
  static bool isValidBytes(List<int> keyBytes, EllipticCurveTypes type) {
    switch (type) {
      case EllipticCurveTypes.nist256p1:
        return Nist256p1PrivateKey.isValidBytes(keyBytes);
      case EllipticCurveTypes.ed25519:
        return Ed25519PrivateKey.isValidBytes(keyBytes);
      case EllipticCurveTypes.ed25519Kholaw:
        return Ed25519KholawPrivateKey.isValidBytes(keyBytes);
      case EllipticCurveTypes.ed25519Blake2b:
        return Ed25519Blake2bPrivateKey.isValidBytes(keyBytes);
      case EllipticCurveTypes.ed25519Monero:
        return MoneroPrivateKey.isValidBytes(keyBytes);
      case EllipticCurveTypes.sr25519:
        return Sr25519PrivateKey.isValidBytes(keyBytes);
      default:
        return Secp256k1PrivateKeyEcdsa.isValidBytes(keyBytes);
    }
  }

  String toHex({bool lowerCase = true, String? prefix = ""});
}
