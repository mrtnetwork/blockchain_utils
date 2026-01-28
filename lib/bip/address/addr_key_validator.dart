import 'package:blockchain_utils/bip/ecc/keys/i_keys.dart';
import 'package:blockchain_utils/bip/ecc/curve/elliptic_curve_types.dart';
import 'exception/exception.dart';

/// Class for address utility functions.
class AddrKeyValidator {
  static T getAddrArg<T extends Object?>(T? obj, String argName) {
    if (obj != null) return obj;
    if (obj == null && null is T) return obj as T;
    throw AddressConverterException.missingOrInvalidAddressArguments(
      reason: "$argName must not be null.",
    );
  }

  static T getConfigArg<T extends Object?>(T? obj, String argName) {
    if (obj != null) return obj;
    if (obj == null && null is T) return null as T;
    throw AddressConverterException.missingOrInvalidAddressArguments(
      reason: "Missing coin $argName argument.",
    );
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
    List<int> pubKey,
    EllipticCurveTypes type,
  ) {
    try {
      return IPublicKey.fromBytes(pubKey, type);
    } catch (_) {
      throw AddressConverterException.addressKeyValidationFailed(
        reason: "Invalid ${type.name} public key.",
      );
    }
  }

  static bool hasValidPubkeyBytes(List<int> pubKey, EllipticCurveTypes type) {
    return IPublicKey.isValidBytes(pubKey, type);
  }
}
