import 'package:blockchain_utils/api/validation/validate.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// Backend interface for sr25519 (Schnorrkel) key derivation/signing/
/// verification/VRF operations.
abstract interface class Sr25519SigningApi {
  /// True if 32-byte [pk32] is a valid Ristretto-compressed public key, else false, never throws for bad length.
  bool isValidPublicKey(List<int> pk32);

  /// True if [sk] (32-byte seed or 64-byte secret) has a canonical key part, else false, never throws for bad length.
  bool isValidSecretKey(List<int> sk);

  /// Derives 32-byte public key from 32-byte [seed32]; [uniform] selects ExpandSecretKeys expansion over ed25519 expansion. Throws on invalid seed length.
  BuBytes publicKeyFromSeed(List<int> seed32, {bool uniform = false});

  /// Derives 32-byte public key from 64-byte [sk64]. Throws on invalid secret length.
  BuBytes publicKeyFromSecret(List<int> sk64);

  /// 64-byte Schnorrkel signature over [message] with 64-byte [nonce64]; [seedOrSk] is 32-byte seed when [fromSeed] else 64-byte secret, [uniform] selects expansion, optional [context]. Throws on invalid lengths.
  BuBytes sign({
    required List<int> seedOrSk,
    required List<int> message,
    required List<int> nonce64,
    bool fromSeed = true,
    bool uniform = false,
    List<int>? context,
  });

  /// Expands 32-byte [seed] into 64-byte secret (key‖nonce); [uniform] selects ExpandSecretKeys expansion. Throws on invalid seed length.
  BuBytes secretFromSeed(List<int> seed, {bool uniform = false});

  /// Verifies 64-byte [signature] over [message] for 32-byte [publicKey] with optional [context]. Returns true on valid, false on invalid, throws on bad lengths.
  bool verify({
    required List<int> publicKey,
    required List<int> message,
    required List<int> signature,
    List<int>? context,
  });

  /// Converts 64-byte sr25519 secret [sk64] to 64-byte ed25519-expanded bytes (scalar multiplied by cofactor). Throws on invalid length.
  BuBytes toEd25519Bytes(List<int> sk64);

  /// Hard HDKD derive from [seedOrSk] (32-byte seed when [fromSeed] else 64-byte secret) and 32-byte [chainCode32] with optional [message]. Returns (secret64, chainCode32). Throws on invalid lengths.
  (BuBytes, BuBytes) hardDerive({
    required List<int> seedOrSk,
    required List<int> chainCode32,
    List<int>? message,
    bool fromSeed = true,
    bool uniform = false,
  });

  /// Soft HDKD derive from [seedOrSk] (32-byte seed when [fromSeed] else 64-byte secret), 32-byte [chainCode32] and 32-byte [newNonce32] with optional [message]. Returns (secret64, chainCode32). Throws on invalid lengths.
  (BuBytes, BuBytes) softDerive({
    required List<int> seedOrSk,
    required List<int> chainCode32,
    required List<int> newNonce32,
    List<int>? message,
    bool fromSeed = true,
    bool uniform = false,
  });

  /// Public HDKD derive from 32-byte [publicKey] and 32-byte [chainCode32] with optional [message]. Returns (publicKey32, chainCode32). Throws on invalid lengths.
  (BuBytes, BuBytes) derivePublic({
    required List<int> publicKey,
    required List<int> chainCode32,
    List<int>? message,
  });

  /// 96-byte VRF signature (preOut32‖proof64) over [message] with 64-byte [nonce64]; [seedOrSk] is 32-byte seed when [fromSeed] else 64-byte secret, optional [context]/[extra], [kusamaVrf] selects transcript variant. Throws on invalid lengths.
  BuBytes vrfSign({
    required List<int> seedOrSk,
    required List<int> message,
    required List<int> nonce64,
    bool fromSeed = true,
    bool uniform = false,
    List<int>? context,
    List<int>? extra,
    bool kusamaVrf = true,
  });

  /// Verifies VRF [proof64] and 32-byte [preOut32] over [message] for 32-byte [publicKey] with optional [context]/[extra]. Returns true on valid, false on invalid, throws on bad lengths.
  bool vrfVerify({
    required List<int> publicKey,
    required List<int> message,
    required List<int> preOut32,
    required List<int> proof64,
    List<int>? context,
    List<int>? extra,
    bool kusamaVrf = true,
  });

  /// VRF input point H from SigningContext + message + pk.
  BuBytes vrfHash({
    required List<int> publicKey,
    required List<int> message,
    List<int>? context,
  });

  /// VRF (input32‖output32).
  BuBytes vrfInOut({
    required List<int> seedOrSk,
    required List<int> message,
    bool fromSeed = true,
    bool uniform = false,
    List<int>? context,
  });

  /// DLEQ proof (c‖s = 64). [inout64] = input‖output.
  BuBytes dleqProve({
    required List<int> seedOrSk,
    required List<int> inout64,
    required List<int> nonce64,
    List<int>? extra,
    bool fromSeed = true,
    bool uniform = false,
    bool kusamaVrf = true,
  });

  /// Verifies 64-byte DLEQ [proof64] over 64-byte [inout64] (input‖output) for 32-byte [publicKey] with optional [extra]. Returns true on valid, false on invalid, throws on bad lengths.
  bool dleqVerify({
    required List<int> publicKey,
    required List<int> inout64,
    required List<int> proof64,
    List<int>? extra,
    bool kusamaVrf = true,
  });

  /// Validates 32-byte [publicKey] and returns its canonical base encoding,
  /// or null when invalid (bad length, range, curve membership, or identity).
  BuBytes? normalizePublicKey(List<int> publicKey);
}

/// Validates argument lengths before delegating to the inner backend.
class ValidatedSr25519SigningApi implements Sr25519SigningApi {
  ValidatedSr25519SigningApi(this.inner);
  final Sr25519SigningApi inner;
  static const _tag = 'Sr25519';

  @override
  bool isValidPublicKey(List<int> pk32) {
    if (pk32.length != 32) return false;
    return inner.isValidPublicKey(pk32);
  }

  @override
  bool isValidSecretKey(List<int> sk) {
    if (sk.length != 32 && sk.length != 64) return false;
    return inner.isValidSecretKey(sk);
  }

  @override
  BuBytes publicKeyFromSeed(List<int> seed32, {bool uniform = false}) {
    ApiValidate.length(
      seed32,
      32,
      operation: '$_tag.publicKeyFromSeed',
      name: 'seed',
    );
    return ApiValidate.call(
      '$_tag.publicKeyFromSeed',
      () => inner.publicKeyFromSeed(seed32, uniform: uniform),
    );
  }

  @override
  BuBytes publicKeyFromSecret(List<int> sk64) {
    ApiValidate.length(
      sk64,
      64,
      operation: '$_tag.publicKeyFromSecret',
      name: 'sk',
    );
    return ApiValidate.call(
      '$_tag.publicKeyFromSecret',
      () => inner.publicKeyFromSecret(sk64),
    );
  }

  @override
  BuBytes sign({
    required List<int> seedOrSk,
    required List<int> message,
    required List<int> nonce64,
    bool fromSeed = true,
    bool uniform = false,
    List<int>? context,
  }) {
    ApiValidate.length(
      seedOrSk,
      fromSeed ? 32 : 64,
      operation: '$_tag.sign',
      name: 'seedOrSk',
    );
    ApiValidate.length(nonce64, 64, operation: '$_tag.sign', name: 'nonce64');
    return ApiValidate.call(
      '$_tag.sign',
      () => inner.sign(
        seedOrSk: seedOrSk,
        message: message,
        nonce64: nonce64,
        fromSeed: fromSeed,
        uniform: uniform,
        context: context,
      ),
    );
  }

  @override
  bool verify({
    required List<int> publicKey,
    required List<int> message,
    required List<int> signature,
    List<int>? context,
  }) {
    ApiValidate.length(
      publicKey,
      32,
      operation: '$_tag.verify',
      name: 'publicKey',
    );
    ApiValidate.length(
      signature,
      64,
      operation: '$_tag.verify',
      name: 'signature',
    );
    return ApiValidate.call(
      '$_tag.verify',
      () => inner.verify(
        publicKey: publicKey,
        message: message,
        signature: signature,
        context: context,
      ),
    );
  }

  @override
  BuBytes toEd25519Bytes(List<int> sk64) {
    ApiValidate.length(sk64, 64, operation: '$_tag.toEd25519Bytes', name: 'sk');
    return ApiValidate.call(
      '$_tag.toEd25519Bytes',
      () => inner.toEd25519Bytes(sk64),
    );
  }

  @override
  (BuBytes, BuBytes) hardDerive({
    required List<int> seedOrSk,
    required List<int> chainCode32,
    List<int>? message,
    bool fromSeed = true,
    bool uniform = false,
  }) {
    ApiValidate.length(
      seedOrSk,
      fromSeed ? 32 : 64,
      operation: '$_tag.hardDerive',
      name: 'seedOrSk',
    );
    ApiValidate.length(
      chainCode32,
      32,
      operation: '$_tag.hardDerive',
      name: 'chainCode',
    );
    return ApiValidate.call(
      '$_tag.hardDerive',
      () => inner.hardDerive(
        seedOrSk: seedOrSk,
        chainCode32: chainCode32,
        message: message,
        fromSeed: fromSeed,
        uniform: uniform,
      ),
    );
  }

  @override
  (BuBytes, BuBytes) softDerive({
    required List<int> seedOrSk,
    required List<int> chainCode32,
    required List<int> newNonce32,
    List<int>? message,
    bool fromSeed = true,
    bool uniform = false,
  }) {
    ApiValidate.length(
      seedOrSk,
      fromSeed ? 32 : 64,
      operation: '$_tag.softDerive',
      name: 'seedOrSk',
    );
    ApiValidate.length(
      chainCode32,
      32,
      operation: '$_tag.softDerive',
      name: 'chainCode',
    );
    ApiValidate.length(
      newNonce32,
      32,
      operation: '$_tag.softDerive',
      name: 'newNonce',
    );
    return ApiValidate.call(
      '$_tag.softDerive',
      () => inner.softDerive(
        seedOrSk: seedOrSk,
        chainCode32: chainCode32,
        newNonce32: newNonce32,
        message: message,
        fromSeed: fromSeed,
        uniform: uniform,
      ),
    );
  }

  @override
  (BuBytes, BuBytes) derivePublic({
    required List<int> publicKey,
    required List<int> chainCode32,
    List<int>? message,
  }) {
    ApiValidate.length(
      publicKey,
      32,
      operation: '$_tag.derivePublic',
      name: 'publicKey',
    );
    ApiValidate.length(
      chainCode32,
      32,
      operation: '$_tag.derivePublic',
      name: 'chainCode',
    );
    return ApiValidate.call(
      '$_tag.derivePublic',
      () => inner.derivePublic(
        publicKey: publicKey,
        chainCode32: chainCode32,
        message: message,
      ),
    );
  }

  @override
  BuBytes vrfSign({
    required List<int> seedOrSk,
    required List<int> message,
    required List<int> nonce64,
    List<int>? extra,
    bool fromSeed = true,
    bool uniform = false,
    List<int>? context,
    bool kusamaVrf = true,
  }) {
    ApiValidate.length(
      seedOrSk,
      fromSeed ? 32 : 64,
      operation: '$_tag.vrfSign',
      name: 'seedOrSk',
    );
    ApiValidate.length(
      nonce64,
      64,
      operation: '$_tag.vrfSign',
      name: 'nonce64',
    );
    return ApiValidate.call(
      '$_tag.vrfSign',
      () => inner.vrfSign(
        seedOrSk: seedOrSk,
        message: message,
        nonce64: nonce64,
        fromSeed: fromSeed,
        uniform: uniform,
        context: context,
        extra: extra,
        kusamaVrf: kusamaVrf,
      ),
    );
  }

  @override
  bool vrfVerify({
    required List<int> publicKey,
    required List<int> message,
    required List<int> preOut32,
    required List<int> proof64,
    List<int>? context,
    List<int>? extra,
    bool kusamaVrf = true,
  }) {
    ApiValidate.length(
      publicKey,
      32,
      operation: '$_tag.vrfVerify',
      name: 'publicKey',
    );
    ApiValidate.length(
      preOut32,
      32,
      operation: '$_tag.vrfVerify',
      name: 'preOut',
    );
    ApiValidate.length(
      proof64,
      64,
      operation: '$_tag.vrfVerify',
      name: 'proof',
    );
    return ApiValidate.call(
      '$_tag.vrfVerify',
      () => inner.vrfVerify(
        publicKey: publicKey,
        message: message,
        preOut32: preOut32,
        proof64: proof64,
        context: context,
        kusamaVrf: kusamaVrf,
        extra: extra,
      ),
    );
  }

  @override
  BuBytes dleqProve({
    required List<int> seedOrSk,
    required List<int> inout64,
    required List<int> nonce64,
    List<int>? extra,
    bool fromSeed = true,
    bool uniform = false,
    bool kusamaVrf = true,
  }) {
    ApiValidate.length(
      seedOrSk,
      fromSeed ? 32 : 64,
      operation: '$_tag.dleqProve',
      name: 'seedOrSk',
    );
    ApiValidate.length(
      nonce64,
      64,
      operation: '$_tag.dleqProve',
      name: 'nonce64',
    );
    ApiValidate.length(
      inout64,
      64,
      operation: '$_tag.dleqProve',
      name: 'inout64',
    );
    return ApiValidate.call(
      '$_tag.dleqProve',
      () => inner.dleqProve(
        seedOrSk: seedOrSk,
        nonce64: nonce64,
        inout64: inout64,
        fromSeed: fromSeed,
        uniform: uniform,
        kusamaVrf: kusamaVrf,
        extra: extra,
      ),
    );
  }

  @override
  bool dleqVerify({
    required List<int> publicKey,
    required List<int> inout64,
    required List<int> proof64,
    List<int>? extra,
    bool kusamaVrf = true,
  }) {
    ApiValidate.length(
      proof64,
      64,
      operation: '$_tag.dleqVerify',
      name: 'proof64',
    );
    ApiValidate.length(
      inout64,
      64,
      operation: '$_tag.dleqVerify',
      name: 'inout64',
    );
    ApiValidate.length(
      publicKey,
      32,
      operation: '$_tag.dleqVerify',
      name: 'publicKey',
    );
    return ApiValidate.call(
      '$_tag.dleqVerify',
      () => inner.dleqVerify(
        proof64: proof64,
        publicKey: publicKey,
        extra: extra,
        inout64: inout64,
        kusamaVrf: kusamaVrf,
      ),
    );
  }

  @override
  BuBytes secretFromSeed(List<int> seed, {bool uniform = false}) {
    ApiValidate.length(
      seed,
      32,
      operation: '$_tag.secretFromSeed',
      name: 'seed',
    );
    return ApiValidate.call(
      '$_tag.secretFromSeed',
      () => inner.secretFromSeed(seed, uniform: uniform),
    );
  }

  @override
  BuBytes vrfHash({
    required List<int> publicKey,
    required List<int> message,
    List<int>? context,
  }) {
    ApiValidate.length(
      publicKey,
      32,
      operation: '$_tag.vrfHash',
      name: 'publicKey',
    );
    return ApiValidate.call(
      '$_tag.vrfHash',
      () => inner.vrfHash(
        message: message,
        publicKey: publicKey,
        context: context,
      ),
    );
  }

  @override
  BuBytes vrfInOut({
    required List<int> seedOrSk,
    required List<int> message,
    bool fromSeed = true,
    bool uniform = false,
    List<int>? context,
  }) {
    ApiValidate.length(
      seedOrSk,
      fromSeed ? 32 : 64,
      operation: '$_tag.vrfInOut',
      name: 'seedOrSk',
    );
    return ApiValidate.call(
      '$_tag.vrfInOut',
      () => inner.vrfInOut(
        message: message,
        context: context,
        seedOrSk: seedOrSk,
        fromSeed: fromSeed,
        uniform: uniform,
      ),
    );
  }

  @override
  BuBytes? normalizePublicKey(List<int> publicKey) {
    return inner.normalizePublicKey(publicKey);
  }
}
