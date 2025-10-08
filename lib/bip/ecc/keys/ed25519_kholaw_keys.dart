import 'package:blockchain_utils/utils/utils.dart';
import 'package:blockchain_utils/bip/ecc/keys/i_keys.dart';
import 'package:blockchain_utils/bip/ecc/curve/elliptic_curve_types.dart';
import 'package:blockchain_utils/bip/ecc/keys/ed25519_keys.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/curve/curves.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/eddsa/keys/privatekey.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/eddsa/keys/publickey.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/point/edwards.dart';
import 'package:blockchain_utils/exception/exceptions.dart';

/// Constants related to Ed25519-Kholaw keys, specifically the private key length in bytes.
class Ed25519KholawKeysConst {
  /// Private key length in bytes: The length of an Ed25519-Kholaw private key.
  static const int privKeyByteLen = 64;
}

/// A class representing an Ed25519-Kholaw public key that implements the IPublicKey interface.
class Ed25519KholawPublicKey implements IPublicKey {
  final EDDSAPublicKey _publicKey;

  /// Private constructor for creating an Ed25519-KholawPublicKey instance from an EDDSAPublicKey.
  Ed25519KholawPublicKey._(this._publicKey);

  /// Factory method for creating an Ed25519-KholawPublicKey from a byte array.
  /// It checks the length and prefix of the provided keyBytes to ensure validity.
  /// If the keyBytes include a public key prefix, it removes it before creating the instance.
  factory Ed25519KholawPublicKey.fromBytes(List<int> keyBytes) {
    if (keyBytes.length ==
            Ed25519KeysConst.pubKeyByteLen +
                Ed25519KeysConst.pubKeyPrefix.length &&
        keyBytes[0] == Ed25519KeysConst.pubKeyPrefix[0]) {
      keyBytes = keyBytes.sublist(1);
    }
    return Ed25519KholawPublicKey._(
        EDDSAPublicKey(Curves.generatorED25519, keyBytes));
  }

  /// check if bytes is valid for this key
  static bool isValidBytes(List<int> keyBytes) {
    try {
      Ed25519KholawPublicKey.fromBytes(keyBytes);

      return true;
    } catch (_) {}
    return false;
  }

  /// accsess to public key edward point
  @override
  EDPoint get point {
    return _publicKey.point;
  }

  /// public key compressed bytes length
  @override
  int get length {
    return Ed25519KeysConst.pubKeyByteLen +
        Ed25519KeysConst.pubKeyPrefix.length;
  }

  /// curve type
  @override
  EllipticCurveTypes get curve {
    return EllipticCurveTypes.ed25519Kholaw;
  }

  /// public key uncompressed bytes length
  @override
  int get uncompressedLength {
    return length;
  }

  /// public key compressed bytes
  @override
  List<int> get compressed {
    return List<int>.from(
        [...Ed25519KeysConst.pubKeyPrefix, ..._publicKey.point.toBytes()]);
  }

  /// public key uncompressed bytes
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

  @override
  operator ==(other) {
    if (other is! Ed25519KholawPublicKey) return false;
    if (identical(this, other)) return true;
    return _publicKey == other._publicKey && curve == other.curve;
  }

  @override
  int get hashCode => HashCodeGenerator.generateHashCode([_publicKey, curve]);
}

/// A class representing an Ed25519-Kholaw private key that implements the IPrivateKey interface.
class Ed25519KholawPrivateKey implements IPrivateKey {
  /// Private constructor for creating an Ed25519-KholawPrivateKey instance from an extended key
  /// and an EDDSAPrivateKey.
  Ed25519KholawPrivateKey._(this._privateKey);
  // final List<int> _extendKey;
  final EDDSAPrivateKey _privateKey;

  factory Ed25519KholawPrivateKey.fromBytes(List<int> keyBytes) {
    if (keyBytes.length != Ed25519KholawKeysConst.privKeyByteLen) {
      throw const ArgumentException("invalid private key length");
    }
    final edwardGenerator = Curves.generatorED25519;
    final eddsaPrivateKey = EDDSAPrivateKey(
        generator: edwardGenerator,
        privateKey: keyBytes,
        type: EllipticCurveTypes.ed25519Kholaw);
    return Ed25519KholawPrivateKey._(eddsaPrivateKey);
  }

  /// check if bytes is valid for this key
  static bool isValidBytes(List<int> keyBytes) {
    try {
      Ed25519KholawPrivateKey.fromBytes(keyBytes);

      return true;
    } catch (_) {}
    return false;
  }

  /// curve type
  @override
  EllipticCurveTypes get curve {
    return EllipticCurveTypes.ed25519Kholaw;
  }

  /// private key length
  @override
  int get length {
    return Ed25519KholawKeysConst.privKeyByteLen;
  }

  /// acsess to public key
  @override
  IPublicKey get publicKey {
    return Ed25519KholawPublicKey._(_privateKey.publicKey);
  }

  /// private key raw bytes
  @override
  List<int> get raw {
    return List<int>.from(
        [..._privateKey.privateKey, ..._privateKey.extendedKey]);
  }

  @override
  String toHex({bool lowerCase = true, String? prefix = ""}) {
    return BytesUtils.toHexString(raw, lowerCase: lowerCase, prefix: prefix);
  }

  @override
  operator ==(other) {
    if (other is! Ed25519KholawPrivateKey) return false;
    if (identical(other, this)) return true;
    return _privateKey == other._privateKey && curve == other.curve;
  }

  @override
  int get hashCode => HashCodeGenerator.generateHashCode([_privateKey, curve]);
}
