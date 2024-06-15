import 'package:blockchain_utils/bip/ecc/keys/i_keys.dart';
import 'package:blockchain_utils/bip/ecc/curve/elliptic_curve_types.dart';
import 'exception/exception.dart';

/// Class for address utility functions.
class AddrKeyValidator {
  /// validate argrument by key
  static T validateAddressArgs<T>(Map<String, dynamic> kwargs, String key) {
    if (!kwargs.containsKey(key) || kwargs[key] is! T) {
      throw AddressConverterException(
          'Invalid or Missing required parameters: $key as type $T');
    }
    return kwargs[key] as T;
  }

  static T? nullOrValidateAddressArgs<T>(
      Map<String, dynamic> kwargs, String key) {
    if (kwargs[key] == null) return null;
    return validateAddressArgs<T>(kwargs, key);
  }

  /// Validate and get an ed25519 public key.
  static IPublicKey validateAndGetEd25519Key(List<int> pubKey) {
    return _validateAndGetGenericKey(pubKey, EllipticCurveTypes.ed25519);
  }

  /// Validate and get an ed25519-blake2b public key.
  static IPublicKey validateAndGetEd25519Blake2bKey(List<int> pubKey) {
    return _validateAndGetGenericKey(pubKey, EllipticCurveTypes.ed25519Blake2b);
  }

  /// Validate and get an ed25519-monero public key.
  static IPublicKey validateAndGetEd25519MoneroKey(List<int> pubKey) {
    return _validateAndGetGenericKey(pubKey, EllipticCurveTypes.ed25519Monero);
  }

  /// Validate and get a nist256p1 public key.
  static IPublicKey validateAndGetNist256p1Key(List<int> pubKey) {
    return _validateAndGetGenericKey(pubKey, EllipticCurveTypes.nist256p1);
  }

  /// Validate and get a secp256k1 public key.
  static IPublicKey validateAndGetSecp256k1Key(List<int> pubKey) {
    return _validateAndGetGenericKey(pubKey, EllipticCurveTypes.secp256k1);
  }

  /// Validate and get an sr25519 public key.
  static IPublicKey validateAndGetSr25519Key(List<int> pubKey) {
    return _validateAndGetGenericKey(pubKey, EllipticCurveTypes.sr25519);
  }

  static IPublicKey _validateAndGetGenericKey(
      List<int> pubKey, EllipticCurveTypes type) {
    return IPublicKey.fromBytes(pubKey, type);
  }

  static bool hasValidPubkeyBytes(List<int> pubKey, EllipticCurveTypes type) {
    return IPublicKey.isValidBytes(pubKey, type);
  }
}
