import 'package:blockchain_utils/utils/utils.dart';
import 'package:blockchain_utils/bip/ecc/keys/i_keys.dart';
import 'package:blockchain_utils/bip/ecc/curve/elliptic_curve_types.dart';
import 'package:blockchain_utils/bip/ecc/keys/ed25519_keys.dart';
import 'package:blockchain_utils/bip/ecc/keys/ed25519_monero_keys.dart';
import 'package:blockchain_utils/bip/monero/monero_exc.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/point/base.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/point/edwards.dart';

/// A class representing a Monero public key that implements the IPublicKey interface.
///
/// This class is used to represent Monero public keys and provides methods for creating
/// them from byte data or Edwards points and validating their byte representation.
class MoneroPublicKey implements IPublicKey {
  final IPublicKey pubKey;

  /// Private constructor for MoneroPublicKey.
  ///
  /// This constructor is used internally to create a MoneroPublicKey instance
  /// from a given public key `pubKey`.
  MoneroPublicKey._(this.pubKey);

  /// Factory method to create a MoneroPublicKey from its byte representation.
  ///
  /// Given a [List<int>] `pubKey`, this method creates a new [MoneroPublicKey] instance
  /// by invoking the private constructor [_keyFromBytes] with the provided byte data.
  factory MoneroPublicKey.fromBytes(List<int> pubKey) {
    return MoneroPublicKey._(_keyFromBytes(pubKey));
  }

  /// Factory method to create a MoneroPublicKey from an Edwards point.
  ///
  /// This method creates a new [MoneroPublicKey] instance from an [EDPoint]
  /// `point` by calling the private constructor [_keyFromPoint] with the given point.
  factory MoneroPublicKey.fromPoint(EDPoint point) {
    return MoneroPublicKey._(_keyFromPoint(point));
  }

  /// Static method to validate the byte representation of a Monero public key.
  ///
  /// This method checks the validity of a Monero public key's byte representation
  /// by invoking the [isValidBytes] method from the [Ed25519MoneroPublicKey] class.
  /// It returns `true` if the key bytes are valid and `false` otherwise.
  static bool isValidBytes(List<int> keyBytes) {
    return Ed25519MoneroPublicKey.isValidBytes(keyBytes);
  }

  /// public key compressed bytes.
  @override
  List<int> get compressed {
    return pubKey.point.toBytes();
  }

  /// public key uncompressed bytes.
  @override
  List<int> get uncompressed {
    return pubKey.uncompressed;
  }

  /// Create a Monero public key from its byte representation.
  ///
  /// This method attempts to create a Monero public key from a byte representation
  /// `keyBytes` by invoking the `fromBytes` method of [Ed25519MoneroPublicKey].
  /// If the byte representation is invalid, it throws a [MoneroKeyError] exception.
  ///
  /// Returns an implementation of the [IPublicKey] interface.
  static IPublicKey _keyFromBytes(List<int> keyBytes) {
    try {
      return Ed25519MoneroPublicKey.fromBytes(keyBytes);
    } catch (ex) {
      throw const MoneroKeyError('Invalid public key');
    }
  }

  /// Create a Monero public key from an Edwards point.
  ///
  /// This method attempts to create a Monero public key from an [EDPoint]
  /// `keyPoint` by invoking the `fromPoint` method of [Ed25519MoneroPublicKey].
  /// If the conversion is unsuccessful, it throws a [MoneroKeyError] exception.
  ///
  /// Returns an implementation of the [IPublicKey] interface.
  static IPublicKey _keyFromPoint(EDPoint keyPoint) {
    try {
      return Ed25519MoneroPublicKey.fromPoint(keyPoint);
    } catch (ex) {
      throw const MoneroKeyError('Invalid key point');
    }
  }

  /// public key compressed bytes length.
  @override
  int get length {
    return Ed25519KeysConst.pubKeyByteLen;
  }

  /// curve type.
  @override
  EllipticCurveTypes get curve {
    return EllipticCurveTypes.ed25519Monero;
  }

  /// public key uncompressed bytes length.
  @override
  int get uncompressedLength {
    return length;
  }

  /// public key point.
  @override
  AbstractPoint get point {
    return pubKey.point;
  }

  @override
  String toHex(
      {bool withPrefix = true, bool lowerCase = true, String? prefix = ""}) {
    return BytesUtils.toHexString(compressed,
        prefix: prefix, lowerCase: lowerCase);
  }
}

/// A class representing a Monero private key that implements the IPrivateKey interface.
///
/// This class serves as a wrapper for a private key, implementing the [IPrivateKey] interface.
class MoneroPrivateKey implements IPrivateKey {
  final IPrivateKey privKey;

  /// Private constructor for MoneroPrivateKey.
  ///
  /// This constructor is used internally to create a MoneroPrivateKey instance
  /// from an existing private key `privKey`.
  MoneroPrivateKey._(this.privKey);

  /// Factory method to create a MoneroPrivateKey from its byte representation.
  ///
  /// Given a [List<int>] `keyBytes`, this method creates a new [MoneroPrivateKey] instance
  /// by invoking the private constructor [_keyFromBytes] with the provided byte data
  factory MoneroPrivateKey.fromBytes(List<int> keyBytes) {
    return MoneroPrivateKey._(_keyFromBytes(keyBytes));
  }

  /// Static method to validate the byte representation of a Monero public key.
  ///
  /// This method checks the validity of a Monero public key's byte representation
  /// by invoking the [isValidBytes] method from the [Ed25519MoneroPublicKey] class.
  /// It returns `true` if the key bytes are valid and `false` otherwise.
  static bool isValidBytes(List<int> keyBytes) {
    return Ed25519MoneroPublicKey.isValidBytes(keyBytes);
  }

  /// private key raw bytes.
  @override
  List<int> get raw {
    return privKey.raw;
  }

  /// accsess to public key.
  @override
  MoneroPublicKey get publicKey {
    return MoneroPublicKey._(privKey.publicKey);
  }

  /// Create a Monero private key from its byte representation.
  ///
  /// This method attempts to create a Monero private key from a byte representation
  /// `keyBytes` by invoking the `fromBytes` method of [Ed25519MoneroPrivateKey].
  /// If the byte representation is invalid or the conversion fails, it throws a
  /// [MoneroKeyError] exception with the message 'Invalid private key.'
  ///
  /// Returns an implementation of the [IPrivateKey] interface.
  static IPrivateKey _keyFromBytes(List<int> keyBytes) {
    try {
      return Ed25519MoneroPrivateKey.fromBytes(keyBytes);
    } catch (ex) {
      throw const MoneroKeyError('Invalid private key');
    }
  }

  /// curve type.
  @override
  EllipticCurveTypes get curveType {
    return EllipticCurveTypes.ed25519Monero;
  }

  /// private key bytes length.
  @override
  int get length {
    return privKey.length;
  }

  @override
  String toHex({bool lowerCase = true, String? prefix = ""}) {
    return BytesUtils.toHexString(raw, lowerCase: lowerCase, prefix: prefix);
  }
}
