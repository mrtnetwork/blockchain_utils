import 'package:blockchain_utils/binary/utils.dart';
import 'package:blockchain_utils/bip/ecc/keys/i_keys.dart';
import 'package:blockchain_utils/bip/ecc/curve/elliptic_curve_types.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/point/ristretto_point.dart';
import 'package:blockchain_utils/crypto/crypto/schnorrkel/keys/keys.dart';

/// Constants related to Sr25519 keys, including public and private key lengths.
class Sr25519KeysConst {
  /// Public key length in bytes: The length of an Sr25519 public key.
  static const int pubKeyByteLen = 32;

  /// Private key length in bytes: The length of an Sr25519 private key.
  static const int privKeyByteLen = 64;
}

/// A class representing an Sr25519 public key that implements the IPublicKey interface.
class Sr25519PublicKey implements IPublicKey {
  final SchnorrkelPublicKey publicKey;

  /// Private constructor for creating an Sr25519PublicKey instance from a SchnorrkelPublicKey.
  Sr25519PublicKey._(this.publicKey);

  /// Factory method for creating an Sr25519PublicKey from a byte array.
  factory Sr25519PublicKey.fromBytes(List<int> keyBytes) {
    return Sr25519PublicKey._(SchnorrkelPublicKey(keyBytes));
  }

  /// public key compressed bytes length.
  @override
  int get length {
    return Sr25519KeysConst.pubKeyByteLen;
  }

  /// curve type.
  @override
  EllipticCurveTypes get curve {
    return EllipticCurveTypes.sr25519;
  }

  /// check if bytes is valid for this key.
  static bool isValidBytes(List<int> keyBytes) {
    try {
      SchnorrkelPublicKey(keyBytes);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// accsess to public key point.
  @override
  RistrettoPoint get point {
    return publicKey.toPoint();
  }

  /// public key compressed bytes.
  @override
  List<int> get compressed {
    return publicKey.toBytes();
  }

  /// public key uncompressed bytes.
  @override
  List<int> get uncompressed {
    return compressed;
  }

  /// public key uncompressed bytes length.
  @override
  int get uncompressedLength {
    return length;
  }

  @override
  String toHex() {
    return BytesUtils.toHexString(compressed);
  }
}

/// A class representing an Sr25519 private key that implements the IPrivateKey interface.
class Sr25519PrivateKey implements IPrivateKey {
  final SchnorrkelSecretKey secretKey;

  /// Private constructor for creating an Sr25519PrivateKey instance from a SchnorrkelSecretKey.
  Sr25519PrivateKey._(this.secretKey);

  /// Factory method for creating an Sr25519PrivateKey from a byte array.
  factory Sr25519PrivateKey.fromBytes(List<int> keyBytes) {
    return Sr25519PrivateKey._(SchnorrkelSecretKey.fromBytes(keyBytes));
  }

  /// curve type.
  @override
  EllipticCurveTypes get curveType {
    return EllipticCurveTypes.sr25519;
  }

  /// check if bytes is valid for this key.
  static bool isValidBytes(List<int> keyBytes) {
    try {
      SchnorrkelSecretKey.fromBytes(keyBytes);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// private key bytes length.
  @override
  int get length {
    return Sr25519KeysConst.privKeyByteLen;
  }

  /// accsess to public key.
  @override
  Sr25519PublicKey get publicKey {
    return Sr25519PublicKey._(secretKey.publicKey());
  }

  /// private key raw bytes.
  @override
  List<int> get raw {
    return secretKey.toBytes();
  }

  @override
  String toHex() {
    return BytesUtils.toHexString(raw);
  }
}
