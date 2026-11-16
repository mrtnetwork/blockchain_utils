import 'package:blockchain_utils/api/validation/validate.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// Backend interface for ML-DSA (FIPS 204) key generation/signing/verification.
abstract interface class MLDSASigningApi {
  /// Generate a key pair.
  ///
  /// [level] required for keygen. [seed] null → fresh platform randomness
  /// (32 bytes); explicit seeds give deterministic keys.
  (BuBytes, BuBytes) keygen({required int level, List<int>? seed});

  /// Derive public key from secret key.
  ///
  /// [level] optional; inferred from [sk].length.
  BuBytes publicKeyFromSecret({int? level, required List<int> sk});

  /// Sign [message].
  ///
  /// [level] optional (from [sk].length). [rnd] null → fresh platform
  /// randomness; pass 32 zero bytes for deterministic (KAT) signing.
  /// [context] default empty.
  BuBytes sign({
    int? level,
    required List<int> sk,
    required List<int> message,
    List<int>? rnd,
    List<int>? context,
  });

  /// Verify [signature].
  ///
  /// [level] optional (from [pk].length). [context] must match sign-time.
  bool verify({
    int? level,
    required List<int> pk,
    required List<int> message,
    required List<int> signature,
    List<int>? context,
  });
}

/// Validates arguments before delegating to the inner backend.
class ValidatedMLDSASigningApi implements MLDSASigningApi {
  ValidatedMLDSASigningApi(this.inner);
  final MLDSASigningApi inner;
  static const _tag = 'MLDSA';

  @override
  (BuBytes, BuBytes) keygen({required int level, List<int>? seed}) {
    ApiValidate.levelMlDsa(level, '$_tag.keygen');
    if (seed != null) {
      ApiValidate.nonEmpty(seed, operation: '$_tag.keygen', name: 'seed');
    }
    return ApiValidate.call(
      '$_tag.keygen',
      () => inner.keygen(level: level, seed: seed),
    );
  }

  @override
  BuBytes publicKeyFromSecret({int? level, required List<int> sk}) {
    ApiValidate.nonEmpty(
      sk,
      operation: '$_tag.publicKeyFromSecret',
      name: 'sk',
    );
    if (level != null) {
      ApiValidate.levelMlDsa(level, '$_tag.publicKeyFromSecret');
    }
    return ApiValidate.call(
      '$_tag.publicKeyFromSecret',
      () => inner.publicKeyFromSecret(level: level, sk: sk),
    );
  }

  @override
  BuBytes sign({
    int? level,
    required List<int> sk,
    required List<int> message,
    List<int>? rnd,
    List<int>? context,
  }) {
    ApiValidate.nonEmpty(sk, operation: '$_tag.sign', name: 'sk');
    if (level != null) ApiValidate.levelMlDsa(level, '$_tag.sign');
    if (context != null && context.length > 255) {
      throw CoreErrors.invalidOperationArguments(
        '$_tag.sign',
        name: 'context',
        reason: 'context length must be <= 255',
      );
    }
    return ApiValidate.call(
      '$_tag.sign',
      () => inner.sign(
        level: level,
        sk: sk,
        message: message,
        rnd: rnd,
        context: context,
      ),
    );
  }

  @override
  bool verify({
    int? level,
    required List<int> pk,
    required List<int> message,
    required List<int> signature,
    List<int>? context,
  }) {
    ApiValidate.nonEmpty(pk, operation: '$_tag.verify', name: 'pk');
    ApiValidate.nonEmpty(
      signature,
      operation: '$_tag.verify',
      name: 'signature',
    );
    if (level != null) ApiValidate.levelMlDsa(level, '$_tag.verify');
    return ApiValidate.call(
      '$_tag.verify',
      () => inner.verify(
        level: level,
        pk: pk,
        message: message,
        signature: signature,
        context: context,
      ),
    );
  }
}
