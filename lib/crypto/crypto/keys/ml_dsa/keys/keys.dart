import 'package:blockchain_utils/api/api.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/crypto/crypto/keys/types/types.dart';
import 'package:blockchain_utils/crypto/crypto/keys/core/i_keys.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/crypto/crypto/keys/ml_dsa/keys/verify_signing.dart';
import 'package:blockchain_utils/crypto/crypto/keys/utils/ecdsa.dart';
import 'package:blockchain_utils/crypto/crypto/lattice/ml/dsa/ml_dsa.dart';
import 'package:blockchain_utils/helper/helper.dart';

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';
import 'package:blockchain_utils/utils/equatable/equatable.dart';

/// Base of every ML-DSA (FIPS 204) public key.
///
/// The security level lives in the concrete subclass ([MLDSA44PublicKey],
/// [MLDSA65PublicKey], [MLDSA87PublicKey]): a key's level is its type, so a
/// wrong-level key is a type error instead of a runtime length check at each
/// call site. Length-based dispatch across levels stays available through
/// [BaseMLDSAPublicKey.fromBytes] for untagged inputs (e.g. raw hex import).
abstract class BaseMLDSAPublicKey extends IMLDSAVerificationKey
    with Equality
    implements IPublicKey<MLDSAVerifyingParams> {
  @override
  BuBytes get bytes;

  MLDSAParams get params;

  /// Parses untagged bytes into the matching level key. Throws when the
  /// length matches no ML-DSA parameter set.
  static BaseMLDSAPublicKey fromBytes(List<int> bytes) {
    final params = MLDSAParams.fromPublicKey(bytes);
    return switch (params.level) {
      44 => MLDSA44PublicKey.fromBytes(bytes),
      65 => MLDSA65PublicKey.fromBytes(bytes),
      87 => MLDSA87PublicKey.fromBytes(bytes),
      _ =>
        throw CoreErrors.cryptoFailed(
          "BaseMLDSAPublicKey.fromBytes",
          reason: 'Unsupported ML-DSA public key level.',
        ),
    };
  }

  static bool isValidBytes(List<int> bytes) {
    try {
      BaseMLDSAPublicKey.fromBytes(bytes);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Checks whether [keyBytes] has a valid length for the given [encoding]
  /// under any ML-DSA level.
  ///
  /// This check validates only the key length and does not verify whether
  /// [keyBytes] represents a valid public key.
  static bool isValidKeyEncoding(
    List<int> keyBytes,
    CryptoKeyEncoding encoding,
  ) {
    return switch (encoding) {
      CryptoKeyEncoding.base
          when MLDSAParams.isValidPublicKeyBytesLength(keyBytes) =>
        true,
      _ => false,
    };
  }

  @override
  List<dynamic> get variables => [bytes];

  @override
  BuBytes toBytes({CryptoKeyEncoding mode = CryptoKeyEncoding.base}) {
    return CryptoKeysUtils.ensureSupportPubKeyMode(
      mode: mode,
      type: type,
      onModeBytes:
          (mode) => switch (mode) {
            CryptoKeyEncoding.base => bytes.cloneBytes(),
            CryptoKeyEncoding.uncompressed => null,
          },
    );
  }
}

/// ML-DSA-44 public key (1312 bytes).
final class MLDSA44PublicKey extends BaseMLDSAPublicKey {
  @override
  final BuBytes bytes;

  MLDSA44PublicKey._(List<int> bytes) : bytes = bytes.asImmutableBytes;

  factory MLDSA44PublicKey.fromBytes(List<int> bytes) {
    if (bytes.length != MLDSAParams.mldsa44Params.publicKeyBytes) {
      throw CoreErrors.cryptoFailed(
        "MLDSA44PublicKey.fromBytes",
        reason: 'Invalid ML-DSA-44 public bytes length.',
      );
    }
    return MLDSA44PublicKey._(bytes);
  }

  static bool isValidBytes(List<int> bytes) {
    try {
      MLDSA44PublicKey.fromBytes(bytes);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Checks whether [keyBytes] has a valid ML-DSA-44 length for [encoding].
  static bool isValidKeyEncoding(
    List<int> keyBytes,
    CryptoKeyEncoding encoding,
  ) {
    return switch (encoding) {
      CryptoKeyEncoding.base
          when keyBytes.length == MLDSAParams.mldsa44Params.publicKeyBytes =>
        true,
      _ => false,
    };
  }

  @override
  MLDSAParams get params => MLDSAParams.mldsa44Params;

  @override
  CryptoKeyType get type => CryptoKeyType.mldsa44;
}

/// ML-DSA-65 public key (1952 bytes).
final class MLDSA65PublicKey extends BaseMLDSAPublicKey {
  @override
  final BuBytes bytes;

  MLDSA65PublicKey._(List<int> bytes) : bytes = bytes.asImmutableBytes;

  factory MLDSA65PublicKey.fromBytes(List<int> bytes) {
    if (bytes.length != MLDSAParams.mldsa65Params.publicKeyBytes) {
      throw CoreErrors.cryptoFailed(
        "MLDSA65PublicKey.fromBytes",
        reason: 'Invalid ML-DSA-65 public bytes length.',
      );
    }
    return MLDSA65PublicKey._(bytes);
  }

  static bool isValidBytes(List<int> bytes) {
    try {
      MLDSA65PublicKey.fromBytes(bytes);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Checks whether [keyBytes] has a valid ML-DSA-65 length for [encoding].
  static bool isValidKeyEncoding(
    List<int> keyBytes,
    CryptoKeyEncoding encoding,
  ) {
    return switch (encoding) {
      CryptoKeyEncoding.base
          when keyBytes.length == MLDSAParams.mldsa65Params.publicKeyBytes =>
        true,
      _ => false,
    };
  }

  @override
  MLDSAParams get params => MLDSAParams.mldsa65Params;

  @override
  CryptoKeyType get type => CryptoKeyType.mldsa65;
}

/// ML-DSA-87 public key (2592 bytes).
final class MLDSA87PublicKey extends BaseMLDSAPublicKey {
  @override
  final BuBytes bytes;

  MLDSA87PublicKey._(List<int> bytes) : bytes = bytes.asImmutableBytes;

  factory MLDSA87PublicKey.fromBytes(List<int> bytes) {
    if (bytes.length != MLDSAParams.mldsa87Params.publicKeyBytes) {
      throw CoreErrors.cryptoFailed(
        "MLDSA87PublicKey.fromBytes",
        reason: 'Invalid ML-DSA-87 public bytes length.',
      );
    }
    return MLDSA87PublicKey._(bytes);
  }

  static bool isValidBytes(List<int> bytes) {
    try {
      MLDSA87PublicKey.fromBytes(bytes);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Checks whether [keyBytes] has a valid ML-DSA-87 length for [encoding].
  static bool isValidKeyEncoding(
    List<int> keyBytes,
    CryptoKeyEncoding encoding,
  ) {
    return switch (encoding) {
      CryptoKeyEncoding.base
          when keyBytes.length == MLDSAParams.mldsa87Params.publicKeyBytes =>
        true,
      _ => false,
    };
  }

  @override
  MLDSAParams get params => MLDSAParams.mldsa87Params;

  @override
  CryptoKeyType get type => CryptoKeyType.mldsa87;
}

/// Base of every ML-DSA (FIPS 204) private key.
///
/// Mirrors [BaseMLDSAPublicKey]: the level is the subclass
/// ([MLDSA44PrivateKey], [MLDSA65PrivateKey], [MLDSA87PrivateKey]), and
/// length-based dispatch across levels stays available through
/// [BaseMLDSAPrivateKey.fromBytes] and [BaseMLDSAPrivateKey.generate].
abstract class BaseMLDSAPrivateKey extends IMLDSASigningKey<BaseMLDSAPublicKey>
    with Equality
    implements
        IPrivateKey<MLDSASignature, MLDSASigningParams, BaseMLDSAPublicKey> {
  final SecretBytes sk;

  @override
  final BaseMLDSAPublicKey publicKey;

  BaseMLDSAPrivateKey(List<int> keyBytes, this.publicKey)
    : sk = SecretBytes(keyBytes);

  /// Parses untagged bytes into the matching level key. Throws when the
  /// length matches no ML-DSA parameter set.
  static BaseMLDSAPrivateKey fromBytes(List<int> bytes) {
    final params = MLDSAParams.fromSecretKey(bytes);
    return switch (params.level) {
      44 => MLDSA44PrivateKey.fromBytes(bytes),
      65 => MLDSA65PrivateKey.fromBytes(bytes),
      87 => MLDSA87PrivateKey.fromBytes(bytes),
      _ =>
        throw CoreErrors.cryptoFailed(
          "BaseMLDSAPrivateKey.fromBytes",
          reason: 'Unsupported ML-DSA secret key level.',
        ),
    };
  }

  /// Generates a key of the given parameter set's level.
  static BaseMLDSAPrivateKey generate(MLDSAParams params, {List<int>? seed}) {
    return switch (params.level) {
      44 => MLDSA44PrivateKey.generate(seed: seed),
      65 => MLDSA65PrivateKey.generate(seed: seed),
      87 => MLDSA87PrivateKey.generate(seed: seed),
      _ =>
        throw CoreErrors.cryptoFailed(
          "BaseMLDSAPrivateKey.generate",
          reason: 'Unsupported ML-DSA level.',
        ),
    };
  }

  static bool isValidBytes(List<int> bytes) {
    try {
      BaseMLDSAPrivateKey.fromBytes(bytes);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  BaseMLDSAPublicKey verificationKey() => publicKey;

  void _ensureAlive(String operation) {
    if (sk.isZeroed) {
      throw CoreErrors.badState(
        operation,
        reason: "Private key has been disposed.",
      );
    }
  }

  @override
  List<dynamic> get variables => [publicKey];

  @override
  SecretBytes takeSecretKey() {
    _ensureAlive("BaseMLDSAPrivateKey.takeSecretKey");
    return sk;
  }

  @override
  SecretBytes toBytes({SecretTransform? transform}) {
    _ensureAlive("BaseMLDSAPrivateKey.toBytes");
    return sk.cloneBytes(transform: transform);
  }

  @override
  void dispose() {
    sk.zero();
  }
}

/// ML-DSA-44 private key.
final class MLDSA44PrivateKey extends BaseMLDSAPrivateKey {
  MLDSA44PrivateKey._(super.keyBytes, MLDSA44PublicKey super.publicKey);

  factory MLDSA44PrivateKey.fromBytes(List<int> bytes) {
    final params = MLDSAParams.mldsa44Params;
    if (bytes.length != params.secretKeyBytes) {
      throw CoreErrors.cryptoFailed(
        "MLDSA44PrivateKey.fromBytes",
        reason: 'Invalid ML-DSA-44 secret key bytes length.',
      );
    }
    final pk = blockchainUtils.api.signing.mldsa.publicKeyFromSecret(
      sk: bytes,
      level: params.level,
    );
    return MLDSA44PrivateKey._(bytes, MLDSA44PublicKey.fromBytes(pk));
  }

  factory MLDSA44PrivateKey.generate({List<int>? seed}) {
    const params = MLDSAParams.mldsa44Params;
    final (pk, sk) = blockchainUtils.api.signing.mldsa.keygen(
      level: params.level,
      seed: seed,
    );
    try {
      return MLDSA44PrivateKey._(sk, MLDSA44PublicKey.fromBytes(pk));
    } finally {
      sk.forceZero();
    }
  }

  static bool isValidBytes(List<int> bytes) {
    try {
      MLDSA44PrivateKey.fromBytes(bytes);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  MLDSA44PublicKey verificationKey() => publicKey as MLDSA44PublicKey;

  @override
  CryptoKeyType get type => CryptoKeyType.mldsa44;
}

/// ML-DSA-65 private key.
final class MLDSA65PrivateKey extends BaseMLDSAPrivateKey {
  MLDSA65PrivateKey._(super.keyBytes, MLDSA65PublicKey super.publicKey);

  factory MLDSA65PrivateKey.fromBytes(List<int> bytes) {
    final params = MLDSAParams.mldsa65Params;
    if (bytes.length != params.secretKeyBytes) {
      throw CoreErrors.cryptoFailed(
        "MLDSA65PrivateKey.fromBytes",
        reason: 'Invalid ML-DSA-65 secret key bytes length.',
      );
    }
    final pk = blockchainUtils.api.signing.mldsa.publicKeyFromSecret(
      sk: bytes,
      level: params.level,
    );
    return MLDSA65PrivateKey._(bytes, MLDSA65PublicKey.fromBytes(pk));
  }

  factory MLDSA65PrivateKey.generate({List<int>? seed}) {
    const params = MLDSAParams.mldsa65Params;
    final (pk, sk) = blockchainUtils.api.signing.mldsa.keygen(
      level: params.level,
      seed: seed,
    );
    try {
      return MLDSA65PrivateKey._(sk, MLDSA65PublicKey.fromBytes(pk));
    } finally {
      sk.forceZero();
    }
  }

  static bool isValidBytes(List<int> bytes) {
    try {
      MLDSA65PrivateKey.fromBytes(bytes);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  MLDSA65PublicKey verificationKey() => publicKey as MLDSA65PublicKey;

  @override
  CryptoKeyType get type => CryptoKeyType.mldsa65;
}

/// ML-DSA-87 private key.
final class MLDSA87PrivateKey extends BaseMLDSAPrivateKey {
  MLDSA87PrivateKey._(super.keyBytes, MLDSA87PublicKey super.publicKey);

  factory MLDSA87PrivateKey.fromBytes(List<int> bytes) {
    final params = MLDSAParams.mldsa87Params;
    if (bytes.length != params.secretKeyBytes) {
      throw CoreErrors.cryptoFailed(
        "MLDSA87PrivateKey.fromBytes",
        reason: 'Invalid ML-DSA-87 secret key bytes length.',
      );
    }
    final pk = blockchainUtils.api.signing.mldsa.publicKeyFromSecret(
      sk: bytes,
      level: params.level,
    );
    return MLDSA87PrivateKey._(bytes, MLDSA87PublicKey.fromBytes(pk));
  }

  factory MLDSA87PrivateKey.generate({List<int>? seed}) {
    const params = MLDSAParams.mldsa87Params;
    final (pk, sk) = blockchainUtils.api.signing.mldsa.keygen(
      level: params.level,
      seed: seed,
    );
    try {
      return MLDSA87PrivateKey._(sk, MLDSA87PublicKey.fromBytes(pk));
    } finally {
      sk.forceZero();
    }
  }

  static bool isValidBytes(List<int> bytes) {
    try {
      MLDSA87PrivateKey.fromBytes(bytes);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  MLDSA87PublicKey verificationKey() => publicKey as MLDSA87PublicKey;

  @override
  CryptoKeyType get type => CryptoKeyType.mldsa87;
}
