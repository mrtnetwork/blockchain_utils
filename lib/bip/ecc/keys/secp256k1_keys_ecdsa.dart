import 'package:blockchain_utils/utils/utils.dart';
import 'package:blockchain_utils/bip/ecc/keys/ecdsa_keys.dart';
import 'package:blockchain_utils/bip/ecc/keys/i_keys.dart';
import 'package:blockchain_utils/bip/ecc/curve/elliptic_curve_types.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/curve/curves.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/ecdsa/private_key.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/ecdsa/public_key.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/point/base.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/point/ec_projective_point.dart';

/// A class representing a Secp256k1 public key using the ECDSA algorithm that implements the IPublicKey interface.
class Secp256k1PublicKeyEcdsa implements IPublicKey {
  final ECDSAPublicKey publicKey;

  /// Private constructor for creating a Secp256k1PublicKeyEcdsa instance from an ECDSAPublicKey.
  Secp256k1PublicKeyEcdsa._(this.publicKey);

  /// Factory method for creating a Secp256k1PublicKeyEcdsa from a byte array.
  factory Secp256k1PublicKeyEcdsa.fromBytes(List<int> keyBytes) {
    final point = ProjectiveECCPoint.fromBytes(
        curve: Curves.curveSecp256k1, data: keyBytes, order: null);
    final pub = ECDSAPublicKey(Curves.generatorSecp256k1, point);
    return Secp256k1PublicKeyEcdsa._(pub);
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
      Secp256k1PublicKeyEcdsa.fromBytes(keyBytes);
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
  String toHex(
      {bool withPrefix = true, bool lowerCase = true, String? prefix = ""}) {
    return BytesUtils.toHexString(compressed,
        prefix: prefix, lowerCase: lowerCase);
  }
}

/// A class representing a Secp256k1 private key using the ECDSA algorithm that implements the IPrivateKey interface.
class Secp256k1PrivateKeyEcdsa implements IPrivateKey {
  final ECDSAPrivateKey privateKey;

  /// Private constructor for creating a Secp256k1PrivateKeyEcdsa instance from an ECDSAPrivateKey.
  Secp256k1PrivateKeyEcdsa._(this.privateKey);

  /// Factory method for creating a Secp256k1PrivateKeyEcdsa from a byte array.
  factory Secp256k1PrivateKeyEcdsa.fromBytes(List<int> keyBytes) {
    final prv = ECDSAPrivateKey.fromBytes(keyBytes, Curves.generatorSecp256k1);
    return Secp256k1PrivateKeyEcdsa._(prv);
  }

  /// curve type
  @override
  EllipticCurveTypes get curveType {
    return EllipticCurveTypes.secp256k1;
  }

  /// check if bytes is valid for this key.
  static bool isValidBytes(List<int> keyBytes) {
    try {
      ECDSAPrivateKey.fromBytes(keyBytes, Curves.generatorSecp256k1);
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
  IPublicKey get publicKey {
    return Secp256k1PublicKeyEcdsa._(privateKey.publicKey);
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
}
