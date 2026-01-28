import 'package:blockchain_utils/bip/ecc/keys/ecdsa_keys.dart';
import 'package:blockchain_utils/bip/ecc/keys/i_keys.dart';
import 'package:blockchain_utils/bip/ecc/curve/elliptic_curve_types.dart';
import 'package:blockchain_utils/crypto/crypto/ec/core/point.dart';
import 'package:blockchain_utils/crypto/crypto/ec/curve/curves.dart';
import 'package:blockchain_utils/crypto/crypto/ec/ecdsa/private_key.dart';
import 'package:blockchain_utils/crypto/crypto/ec/ecdsa/public_key.dart';
import 'package:blockchain_utils/crypto/crypto/ec/projective/native/native.dart';
import 'package:blockchain_utils/utils/binary/utils.dart';
import 'package:blockchain_utils/utils/equatable/equatable.dart';

/// A class representing a NIST P-256 public key that implements the IPublicKey interface.
class Nist256p1HybridPublicKey with Equality implements IPublicKey {
  final ECDSAPublicKey publicKey;

  /// Private constructor for creating a Nist256p1HybridPublicKey instance from an ECDSAPublicKey.
  Nist256p1HybridPublicKey._(this.publicKey);

  /// Factory method for creating a Nist256p1HybridPublicKey from a byte array.
  factory Nist256p1HybridPublicKey.fromBytes(List<int> keyBytes) {
    final point = ProjectiveECCPoint.fromBytes(
      curve: Curves.curve256,
      data: keyBytes,
      order: null,
    );
    final pub = ECDSAPublicKey(Curves.generator256, point);
    return Nist256p1HybridPublicKey._(pub);
  }

  /// public key compressed bytes length.
  @override
  int get length {
    return EcdsaKeysConst.pubKeyCompressedByteLen;
  }

  /// curve type
  @override
  EllipticCurveTypes get curve {
    return EllipticCurveTypes.nist256p1Hybrid;
  }

  /// check if bytes is valid for this key.
  static bool isValidBytes(List<int> keyBytes) {
    try {
      Nist256p1HybridPublicKey.fromBytes(keyBytes);
      return true;
      // ignore: empty_catches
    } catch (e) {}
    return false;
  }

  /// public key point.
  @override
  ProjectiveECCPoint get point {
    return publicKey.point;
  }

  /// public key compressed bytes.
  @override
  List<int> get compressed {
    return publicKey.point.toBytes(EncodeType.comprossed);
  }

  /// public key uncompressed bytes.
  @override
  List<int> get uncompressed {
    return publicKey.point.toBytes(EncodeType.uncompressed);
  }

  @override
  int get uncompressedLength {
    return EcdsaKeysConst.pubKeyUncompressedByteLen;
  }

  @override
  String toHex({
    bool withPrefix = true,
    bool lowerCase = true,
    String? prefix = "",
  }) {
    return BytesUtils.toHexString(
      compressed,
      prefix: prefix,
      lowerCase: lowerCase,
    );
  }

  @override
  List<dynamic> get variables => [publicKey];
}

/// A class representing a NIST P-256 private key that implements the IPrivateKey interface.
class Nist256p1HybridPrivateKey with Equality implements IPrivateKey {
  final ECDSAPrivateKey privateKey;

  /// Private constructor for creating a Nist256p1HybridPrivateKey instance from an ECDSAPrivateKey.
  Nist256p1HybridPrivateKey._(this.privateKey);

  /// Factory method for creating a Nist256p1HybridPrivateKey from a byte array.
  factory Nist256p1HybridPrivateKey.fromBytes(List<int> keyBytes) {
    final prv = ECDSAPrivateKey.fromBytes(keyBytes, Curves.generator256);
    return Nist256p1HybridPrivateKey._(prv);
  }

  /// curve type.
  @override
  EllipticCurveTypes get curve {
    return EllipticCurveTypes.nist256p1Hybrid;
  }

  /// check if bytes is valid for this key.
  static bool isValidBytes(List<int> keyBytes) {
    try {
      ECDSAPrivateKey.fromBytes(keyBytes, Curves.generator256);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// private key bytes length
  @override
  int get length {
    return EcdsaKeysConst.privKeyByteLen;
  }

  /// accsess to public key
  @override
  IPublicKey get publicKey {
    return Nist256p1HybridPublicKey._(privateKey.publicKey);
  }

  /// private key raw bytes
  @override
  List<int> get raw {
    return privateKey.toBytes();
  }

  @override
  String toHex({bool lowerCase = true, String? prefix = ""}) {
    return BytesUtils.toHexString(raw, lowerCase: lowerCase, prefix: prefix);
  }

  @override
  List<dynamic> get variables => [privateKey];
}
