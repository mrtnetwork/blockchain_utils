import 'package:blockchain_utils/api/validation/validate.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/crypto/crypto/protocol/musig2/types/types.dart';
import 'package:blockchain_utils/crypto/crypto/protocol/musig2/utils/utils_const.dart';
import 'package:blockchain_utils/crypto/crypto/group/weierstrass/weierstrass.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// BIP-327 MuSig2 — public factory returns [BuResult] only.
abstract interface class MuSig2Api {
  /// Aggregates non-empty [pubnonces] (each 66 bytes) into a 66-byte aggregate nonce. Throws on empty or malformed input.
  BuBytes nonceAgg(List<List<int>> pubnonces);

  /// Generates a MuSig2 nonce for signing
  /// [publicKey] is 33 bytes (compressed); optional 32-byte [rand] (random if null) and 32-byte [sk] (binds nonce to key); [aggPubKey], [msg] and [extra] bind the nonce hash. Returns the 97-byte secret nonce with its 66-byte public nonce. Throws on invalid lengths.
  MuSig2Nonce nonceGenerate({
    required List<int> publicKey,
    List<int>? rand,
    List<int>? sk,
    List<int>? aggPubKey,
    List<int>? msg,
    List<int>? extra,
  });

  /// sort public keys
  /// Sorts [keys] (each 33-byte compressed) in ascending lexicographic byte order. Throws on malformed keys.
  List<BuBytes> sortPublicKeys(List<List<int>> keys) {
    return MuSig2UtilsConst.sortPublicKeys(
      keys.map((e) => e.asImmutableBytes).toList(),
    );
  }

  /// Aggregates public keys for MuSig2
  /// Aggregates non-empty [keys] (each 33-byte compressed secp256k1) with key-agg coefficients into the aggregate point. Throws on empty or malformed input.
  Secp256k1Point aggPublicKeys(List<List<int>> keys);

  /// Verifies a MuSig2 partial signature
  /// Verifies 32-byte partial [signature] from signer [pk] with 66-byte [pubnonce] against [session]. Returns false if the equation fails; throws on malformed lengths or keys.
  bool partialSigVerify({
    required List<int> signature,
    required List<int> pubnonce,
    required List<int> pk,
    required MuSig2Session session,
  });

  /// Generates a MuSig2 partial signature
  /// Creates a 32-byte partial signature with 32-byte [sk] and 97-byte [secnonce] for [session]; [secnonce] must embed the signer's public key. Throws on invalid nonce/key or failed self-verification.
  BuBytes sign({
    required List<int> secnonce,
    required List<int> sk,
    required MuSig2Session session,
  });

  /// Aggregates MuSig2 partial signatures
  /// Sums non-empty 32-byte partial [signatures] for [session] and adds the tweak accumulator; returns 64-byte `R_x || s`. Throws on empty or out-of-range signatures.
  BuBytes partialSigAgg({
    required List<List<int>> signatures,
    required MuSig2Session session,
  });

  /// Aggregates non-empty [publicKeys] and applies [tweaks]; returns the tweaked aggregate point. Throws on empty or malformed input.
  Secp256k1Point keyAggAndTweak({
    required List<List<int>> publicKeys,
    required List<MuSig2Tweak> tweaks,
  });

  /// Generates a deterministic MuSig2 signature
  /// Derives a nonce deterministically from 32-byte [sk], 66-byte [aggotherNonce] and [msg], aggregates it with [publicKeys]/[tweaks] into a session and partial-signs it. Optional [rand] overrides the nonce randomness. Returns the partial signature with its 66-byte pubnonce. Throws on invalid input.
  MuSig2DeterministicSignature deterministicSign({
    required List<int> sk,
    required List<int> aggotherNonce,
    required List<List<int>> publicKeys,
    List<MuSig2Tweak> tweaks = const [],
    required List<int> msg,
    List<int>? rand,
  });

  /// Verifies 64-byte Schnorr [signature] over [message] against 32-byte [aggXOnly]. Returns false if invalid; throws on malformed lengths.
  bool verifyAggregate({
    required List<int> message,
    required List<int> signature,
    required List<int> aggXOnly,
  });
}

/// [MuSig2Api] wrapper that validates argument lengths before delegating.
class ValidatedMuSig2Api implements MuSig2Api {
  ValidatedMuSig2Api(this.inner);
  final MuSig2Api inner;
  static const _tag = 'MuSig2';

  @override
  BuBytes nonceAgg(List<List<int>> pubnonces) {
    if (pubnonces.isEmpty) {
      throw CoreErrors.invalidOperationArguments(
        '$_tag.nonceAgg',
        name: 'pubnonces',
        reason: 'must not be empty',
      );
    }
    for (final n in pubnonces) {
      ApiValidate.length(n, 66, operation: '$_tag.nonceAgg', name: 'pubnonce');
    }
    return ApiValidate.call('$_tag.nonceAgg', () => inner.nonceAgg(pubnonces));
  }

  @override
  MuSig2Nonce nonceGenerate({
    required List<int> publicKey,
    List<int>? rand,
    List<int>? sk,
    List<int>? aggPubKey,
    List<int>? msg,
    List<int>? extra,
  }) {
    ApiValidate.length(
      publicKey,
      33,
      operation: '$_tag.nonceGenerate',
      name: 'publicKey',
    );
    if (sk != null) {
      ApiValidate.length(sk, 32, operation: '$_tag.nonceGenerate', name: 'sk');
    }
    if (rand != null) {
      ApiValidate.length(
        rand,
        32,
        operation: '$_tag.nonceGenerate',
        name: 'rand',
      );
    }
    return ApiValidate.call(
      '$_tag.nonceGenerate',
      () => inner.nonceGenerate(
        publicKey: publicKey,
        rand: rand,
        sk: sk,
        aggPubKey: aggPubKey,
        msg: msg,
        extra: extra,
      ),
    );
  }

  @override
  List<BuBytes> sortPublicKeys(List<List<int>> keys) => ApiValidate.call(
    '$_tag.sortPublicKeys',
    () => inner.sortPublicKeys(keys),
  );

  @override
  Secp256k1Point aggPublicKeys(List<List<int>> keys) {
    if (keys.isEmpty) {
      throw CoreErrors.invalidOperationArguments(
        '$_tag.aggPublicKeys',
        name: 'keys',
        reason: 'must not be empty',
      );
    }
    return ApiValidate.call(
      '$_tag.aggPublicKeys',
      () => inner.aggPublicKeys(keys),
    );
  }

  @override
  bool partialSigVerify({
    required List<int> signature,
    required List<int> pubnonce,
    required List<int> pk,
    required MuSig2Session session,
  }) {
    ApiValidate.length(
      signature,
      32,
      operation: '$_tag.partialSigVerify',
      name: 'signature',
    );
    ApiValidate.length(
      pubnonce,
      66,
      operation: '$_tag.partialSigVerify',
      name: 'pubnonce',
    );
    return ApiValidate.call(
      '$_tag.partialSigVerify',
      () => inner.partialSigVerify(
        signature: signature,
        pubnonce: pubnonce,
        pk: pk,
        session: session,
      ),
    );
  }

  @override
  BuBytes sign({
    required List<int> secnonce,
    required List<int> sk,
    required MuSig2Session session,
  }) {
    ApiValidate.length(sk, 32, operation: '$_tag.sign', name: 'sk');
    return ApiValidate.call(
      '$_tag.sign',
      () => inner.sign(secnonce: secnonce, sk: sk, session: session),
    );
  }

  @override
  BuBytes partialSigAgg({
    required List<List<int>> signatures,
    required MuSig2Session session,
  }) {
    if (signatures.isEmpty) {
      throw CoreErrors.invalidOperationArguments(
        '$_tag.partialSigAgg',
        name: 'signatures',
        reason: 'must not be empty',
      );
    }
    return ApiValidate.call(
      '$_tag.partialSigAgg',
      () => inner.partialSigAgg(signatures: signatures, session: session),
    );
  }

  @override
  Secp256k1Point keyAggAndTweak({
    required List<List<int>> publicKeys,
    required List<MuSig2Tweak> tweaks,
  }) {
    if (publicKeys.isEmpty) {
      throw CoreErrors.invalidOperationArguments(
        '$_tag.keyAggAndTweak',
        name: 'publicKeys',
        reason: 'must not be empty',
      );
    }
    return ApiValidate.call(
      '$_tag.keyAggAndTweak',
      () => inner.keyAggAndTweak(publicKeys: publicKeys, tweaks: tweaks),
    );
  }

  @override
  MuSig2DeterministicSignature deterministicSign({
    required List<int> sk,
    required List<int> aggotherNonce,
    required List<List<int>> publicKeys,
    List<MuSig2Tweak> tweaks = const [],
    required List<int> msg,
    List<int>? rand,
  }) {
    ApiValidate.length(
      sk,
      32,
      operation: '$_tag.deterministicSign',
      name: 'sk',
    );
    if (publicKeys.isEmpty) {
      throw CoreErrors.invalidOperationArguments(
        '$_tag.deterministicSign',
        name: 'publicKeys',
        reason: 'must not be empty',
      );
    }
    return ApiValidate.call(
      '$_tag.deterministicSign',
      () => inner.deterministicSign(
        sk: sk,
        aggotherNonce: aggotherNonce,
        publicKeys: publicKeys,
        tweaks: tweaks,
        msg: msg,
        rand: rand,
      ),
    );
  }

  @override
  bool verifyAggregate({
    required List<int> message,
    required List<int> signature,
    required List<int> aggXOnly,
  }) {
    ApiValidate.length(
      signature,
      64,
      operation: '$_tag.verifyAggregate',
      name: 'signature',
    );
    ApiValidate.length(
      aggXOnly,
      32,
      operation: '$_tag.verifyAggregate',
      name: 'aggXOnly',
    );
    return ApiValidate.call(
      '$_tag.verifyAggregate',
      () => inner.verifyAggregate(
        message: message,
        signature: signature,
        aggXOnly: aggXOnly,
      ),
    );
  }
}
