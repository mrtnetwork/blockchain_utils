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

/// A class representing a Secp256k1 public key using the ECDSA algorithm that implements the IPublicKey interface.
class Secp256k1PublicKey with Equality implements IPublicKey {
  final ECDSAPublicKey publicKey;

  /// Private constructor for creating a Secp256k1PublicKey instance from an ECDSAPublicKey.
  Secp256k1PublicKey._(this.publicKey);

  /// Factory method for creating a Secp256k1PublicKey from a byte array.
  factory Secp256k1PublicKey.fromBytes(List<int> keyBytes) {
    final point = ProjectiveECCPoint.fromBytes(
      curve: Curves.curveSecp256k1,
      data: keyBytes,
      order: null,
    );
    final pub = ECDSAPublicKey(Curves.generatorSecp256k1, point);
    return Secp256k1PublicKey._(pub);
  }

  /// public key compressed bytes length
  @override
  int get length {
    return EcdsaKeysConst.pubKeyCompressedByteLen;
  }

  /// curve type.
  @override
  EllipticCurveTypes get curve {
    return EllipticCurveTypes.secp256k1;
  }

  /// check if bytes is valid for this key.
  static bool isValidBytes(List<int> keyBytes) {
    try {
      Secp256k1PublicKey.fromBytes(keyBytes);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// accsess to public key point.
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

  /// public key uncompressed bytes length;
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

/// A class representing a Secp256k1 private key using the ECDSA algorithm that implements the IPrivateKey interface.
class Secp256k1PrivateKey with Equality implements IPrivateKey {
  final ECDSAPrivateKey privateKey;

  /// Private constructor for creating a Secp256k1PrivateKey instance from an ECDSAPrivateKey.
  Secp256k1PrivateKey._(this.privateKey);

  /// Factory method for creating a Secp256k1PrivateKey from a byte array.
  factory Secp256k1PrivateKey.fromBytes(List<int> keyBytes) {
    final prv = ECDSAPrivateKey.fromBytesConst(secretKey: keyBytes);
    return Secp256k1PrivateKey._(prv);
  }

  /// curve type
  @override
  EllipticCurveTypes get curve {
    return EllipticCurveTypes.secp256k1;
  }

  /// check if bytes is valid for this key.
  static bool isValidBytes(List<int> keyBytes) {
    try {
      Secp256k1PrivateKey.fromBytes(keyBytes);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// private key bytes length.
  @override
  int get length {
    return EcdsaKeysConst.privKeyByteLen;
  }

  /// accsess to public key.
  @override
  Secp256k1PublicKey get publicKey {
    return Secp256k1PublicKey._(privateKey.publicKey);
  }

  /// private key raw bytes.
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
