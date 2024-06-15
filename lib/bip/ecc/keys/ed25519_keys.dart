import 'package:blockchain_utils/utils/utils.dart';
import 'package:blockchain_utils/bip/ecc/curve/elliptic_curve_types.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/curve/curves.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/eddsa/privatekey.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/eddsa/publickey.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/point/edwards.dart';
import 'package:blockchain_utils/crypto/crypto/hash/hash.dart';
import 'package:blockchain_utils/exception/exception.dart';

import 'i_keys.dart';

/// Constants related to Ed25519 keys, including public and private keys.
class Ed25519KeysConst {
  /// Public key prefix: A list of bytes that indicates a public key.
  static const List<int> pubKeyPrefix = [0x00];

  /// Public key length in bytes: The length of an Ed25519 public key.
  static const int pubKeyByteLen = 32;

  /// Private key length in bytes: The length of an Ed25519 private key.
  static const int privKeyByteLen = 32;

  /// Public key prefix for xrp: A list of bytes that indicates a public key.
  static const List<int> xrpPubKeyPrefix = [0xed];
}

/// A class representing an Ed25519 public key that implements the IPublicKey interface.
class Ed25519PublicKey implements IPublicKey {
  final EDDSAPublicKey _publicKey;

  /// Private constructor for creating an Ed25519PublicKey instance from an EDDSAPublicKey.
  Ed25519PublicKey._(this._publicKey);

  /// Factory method for creating an Ed25519PublicKey from a byte array.
  /// It checks the length and prefix of the provided keyBytes to ensure validity.
  /// If the keyBytes include a public key prefix, it removes it before creating the instance.
  factory Ed25519PublicKey.fromBytes(List<int> keyBytes) {
    if (keyBytes.length ==
        Ed25519KeysConst.pubKeyByteLen + Ed25519KeysConst.pubKeyPrefix.length) {
      final prefix = keyBytes.sublist(0, Ed25519KeysConst.pubKeyPrefix.length);
      if (BytesUtils.bytesEqual(prefix, Ed25519KeysConst.pubKeyPrefix) ||
          BytesUtils.bytesEqual(prefix, Ed25519KeysConst.xrpPubKeyPrefix)) {
        keyBytes = keyBytes.sublist(1);
      }
    }
    return Ed25519PublicKey._(
        EDDSAPublicKey(Curves.generatorED25519, keyBytes));
  }

  /// curve type
  @override
  EllipticCurveTypes get curve {
    return EllipticCurveTypes.ed25519;
  }

  /// public key compressed length
  @override
  int get length {
    return Ed25519KeysConst.pubKeyByteLen +
        Ed25519KeysConst.pubKeyPrefix.length;
  }

  /// public key uncompressed length
  @override
  int get uncompressedLength {
    return length;
  }

  /// check bytes is valid for this key
  static bool isValidBytes(List<int> keyBytes) {
    try {
      Ed25519PublicKey.fromBytes(keyBytes);
      return true;
      // ignore: empty_catches
    } catch (e) {}
    return false;
  }

  /// public key edwards point
  @override
  EDPoint get point {
    return _publicKey.point;
  }

  /// compressed bytes of public key
  @override
  List<int> get compressed {
    return List<int>.from(
        [...Ed25519KeysConst.pubKeyPrefix, ..._publicKey.point.toBytes()]);
  }

  /// uncompressed bytes of public key
  @override
  List<int> get uncompressed {
    return compressed;
  }

  @override
  String toHex(
      {bool withPrefix = true, bool lowerCase = true, String? prefix = ""}) {
    List<int> key = _publicKey.point.toBytes();
    if (withPrefix) {
      key = compressed;
    }
    return BytesUtils.toHexString(key, prefix: prefix, lowerCase: lowerCase);
  }
}

/// A class representing an Ed25519 private key that implements the IPrivateKey interface.
class Ed25519PrivateKey implements IPrivateKey {
  /// Private constructor for creating an Ed25519PrivateKey instance from an EDDSAPrivateKey.
  Ed25519PrivateKey._(this._privateKey);
  final EDDSAPrivateKey _privateKey;

  /// Factory method for creating an Ed25519PrivateKey from a byte array.
  /// It checks the length of the provided keyBytes to ensure it matches the expected length.
  /// Then, it initializes an EdDSA private key using the Edward generator and SHA512 hash function.
  factory Ed25519PrivateKey.fromBytes(List<int> keyBytes) {
    if (keyBytes.length != Ed25519KeysConst.privKeyByteLen) {
      throw const ArgumentException("invalid private key length");
    }
    final edwardGenerator = Curves.generatorED25519;
    final eddsaPrivateKey =
        EDDSAPrivateKey(edwardGenerator, keyBytes, () => SHA512());
    return Ed25519PrivateKey._(eddsaPrivateKey);
  }

  /// curve type
  @override
  EllipticCurveTypes get curveType {
    return EllipticCurveTypes.ed25519;
  }

  /// check if bytes is valid for this key
  static bool isValidBytes(List<int> keyBytes) {
    try {
      Ed25519PrivateKey.fromBytes(keyBytes);

      return true;
      // ignore: empty_catches
    } catch (e) {}
    return false;
  }

  /// private key length
  @override
  int get length {
    return Ed25519KeysConst.privKeyByteLen;
  }

  /// accsess to public key
  @override
  Ed25519PublicKey get publicKey {
    return Ed25519PublicKey._(_privateKey.publicKey);
  }

  /// private key raw bytes
  @override
  List<int> get raw {
    return _privateKey.privateKey;
  }

  @override
  String toHex({bool lowerCase = true, String? prefix = ""}) {
    return BytesUtils.toHexString(raw, lowerCase: lowerCase, prefix: prefix);
  }
}
