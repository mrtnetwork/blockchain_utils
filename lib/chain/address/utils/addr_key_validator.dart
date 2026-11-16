import 'package:blockchain_utils/crypto/crypto/keys/constants/ecdsa.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/crypto/crypto/keys/core/i_keys.dart';
import 'package:blockchain_utils/crypto/crypto/keys/types/types.dart';
import 'package:blockchain_utils/crypto/crypto/keys/ed25519/keys/core.dart';
import 'package:blockchain_utils/crypto/crypto/keys/ml_dsa/keys/keys.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// Class for address utility functions.
class AddrKeyValidator {
  /// Get a required address argument, or throw if missing.
  static T getAddrArg<T extends Object?>(T? obj, String argName) {
    if (obj != null) return obj;
    if (obj == null && null is T) return obj as T;
    throw CoreErrors.missingOrInvalidAddressArguments(
      reason: "$argName must not be null.",
    );
  }

  /// Get a required config argument, or throw if missing.
  static T getConfigArg<T extends Object?>(T? obj, String argName) {
    if (obj != null) return obj;
    if (obj == null && null is T) return null as T;
    throw CoreErrors.missingOrInvalidAddressArguments(
      reason: "Missing coin $argName argument.",
    );
  }

  /// Validate and get an ed25519 public key.
  static IPublicKey validateAndGetEd25519PubKey(
    List<int> pubKey, {
    CryptoKeyType type = CryptoKeyType.ed25519,
  }) {
    if (!type.isED25519()) {
      throw CoreErrors.missingOrInvalidAddressArguments(
        reason: "Ivalid ED25519 key type.",
      );
    }
    return _validateAndGetGenericKey(pubKey, type);
  }

  /// Validate and get compressed ed25519 public key bytes.
  static BuBytes validateAndGetEd25519KeyBytes(List<int> pubKey) {
    return _validateAndGetGenericKey(
      pubKey,
      CryptoKeyType.ed25519,
    ).toBytes(mode: CryptoKeyEncoding.base);
  }

  /// Validate and get an ed25519-blake2b public key.
  static BuBytes validateAndGetEd25519Blake2bKeyBytes(List<int> pubKey) {
    return _validateAndGetGenericKey(
      pubKey,
      CryptoKeyType.ed25519Blake2b,
    ).toBytes();
  }

  /// Validate and get an ed25519-monero public key.
  static BuBytes validateAndGetEd25519MoneroKeyBytes(List<int> pubKey) {
    return _validateAndGetGenericKey(
      pubKey,
      CryptoKeyType.ed25519Monero,
    ).toBytes();
  }

  /// Validate and get a nist256p1 public key.
  static IPublicKey validateAndGetNist256p1Key(List<int> pubKey) {
    return _validateAndGetGenericKey(pubKey, CryptoKeyType.nist256p1);
  }

  /// Validate and get a BLS12-381 G1 public key.
  static IPublicKey validateAndGetBlsG1PublicKey(List<int> pubKey) {
    return _validateAndGetGenericKey(pubKey, CryptoKeyType.bls12G1);
  }

  /// Validate and get an ML-DSA-44 public key.
  static IPublicKey validateAndGetMLDSA44PubKey(List<int> pubKey) {
    try {
      return MLDSA44PublicKey.fromBytes(pubKey);
    } catch (_) {
      throw CoreErrors.addressKeyValidationFailed(
        reason: "Invalid ML-DSA-44 public key.",
      );
    }
  }

  /// Validate and get a secp256k1 public key.
  static IPublicKey validateAndGetSecp256k1Key(List<int> pubKey) {
    return _validateAndGetGenericKey(pubKey, CryptoKeyType.secp256k1);
  }

  /// Validate and get a secp256k1 or Ed25519 public key.
  static IPublicKey validateAndGetSecp256k1OrEd25519(List<int> pubKey) {
    if (pubKey.length == EcdsaKeysConst.pubKeyUncompressedByteLen) {
      return _validateAndGetGenericKey(pubKey, CryptoKeyType.secp256k1);
    }
    if (pubKey.length == Ed25519KeysConst.pubKeyByteLen) {
      return _validateAndGetGenericKey(pubKey, CryptoKeyType.ed25519);
    }
    if (pubKey.length == EcdsaKeysConst.pubKeyCompressedByteLen) {
      if (pubKey[0] == Ed25519KeysConst.pubKeyPrefixInt) {
        return _validateAndGetGenericKey(pubKey, CryptoKeyType.ed25519);
      }
      return _validateAndGetGenericKey(pubKey, CryptoKeyType.secp256k1);
    }

    throw CoreErrors.addressKeyValidationFailed(
      reason: "Invalid Secp256k1 or ED25519 public key.",
    );
  }

  /// Validate and get an sr25519 public key.
  static IPublicKey validateAndGetSr25519Key(List<int> pubKey) {
    return _validateAndGetGenericKey(pubKey, CryptoKeyType.sr25519);
  }

  /// Shared helper: parse pubkey bytes for the given curve type.
  static IPublicKey _validateAndGetGenericKey(
    List<int> pubKey,
    CryptoKeyType type,
  ) {
    try {
      return IPublicKey.fromBytes(pubKey, type);
    } catch (_) {
      throw CoreErrors.addressKeyValidationFailed(
        reason: "Invalid ${type.name} public key.",
      );
    }
  }

  /// Whether bytes form a valid public key for the given curve.
  static bool hasValidPubkeyBytes(List<int> pubKey, CryptoKeyType type) {
    return IPublicKey.isValidBytes(pubKey, type);
  }
}
