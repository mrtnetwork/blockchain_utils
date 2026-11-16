import 'package:blockchain_utils/api/validation/validate.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/exception/exceptions.dart';

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// DKLs23 threshold ECDSA curve selector (`0` = secp256k1, `1` = secp256r1
/// on the native boundary).
enum Dkls23Curve {
  secp256k1(0),
  secp256r1(1);

  const Dkls23Curve(this.id);
  final int id;
}

/// Backend interface for the DKLs23 threshold key family.
///
/// Shares cross the boundary as framed blobs of fixed-size keyshare
/// records: DKG and refresh return such blobs, sign consumes one (any
/// `>= t` subset with per-share seeds aligned by position). Signatures
/// are compact `r(32) || s(32)` (64 bytes, low-S); message hashes and
/// per-party seeds are 32 bytes; group/member keys are 33-byte
/// compressed points.
abstract interface class Dkls23KeysApi {
  /// Full DKG ceremony (`n` parties, threshold `t`) from `n` 32-byte
  /// seeds → framed shares blob. Throws on bad `n`/`t`/seed lengths.
  BuBytes dkg({
    required Dkls23Curve curve,
    required List<int> sid,
    required int n,
    required int t,
    required List<int> seeds,
  });

  /// Threshold-sign a 32-byte message hash → 64-byte compact signature.
  BuBytes sign({
    required Dkls23Curve curve,
    required List<int> sid,
    required List<int> msgHash,
    required List<int> sharesBlob,
    required List<int> seeds,
  });

  /// Rotate shares (group key unchanged) → framed shares blob.
  BuBytes refresh({
    required List<int> sid,
    required List<int> sharesBlob,
    required List<int> seeds,
  });

  /// Verify a compact signature against a 33-byte group key. Returns
  /// false if the equation fails; throws on malformed lengths/keys.
  bool verify({
    required Dkls23Curve curve,
    required List<int> groupPk,
    required List<int> msgHash,
    required List<int> signature,
  });

  /// Aggregate member public keys (`n` × 33 bytes) → group key (33 bytes).
  /// `threshold` is metadata only (the sum is threshold-independent):
  /// validated as `2 <= t <= n`, defaults to `n` when null.
  BuBytes aggPublicKeys({
    required Dkls23Curve curve,
    required List<int> members,
    required int n,
    int? threshold,
  });

  /// X-only form of a group key → 32 bytes.
  BuBytes xOnly({required Dkls23Curve curve, required List<int> groupPk});

  /// Import existing secrets as an additive n-of-n quorum (no DKG):
  /// `n` × 32-byte secrets → framed shares blob.
  BuBytes importSecrets({
    required Dkls23Curve curve,
    required List<int> secrets,
    required int n,
  });
}

/// [Dkls23KeysApi] wrapper that validates argument lengths before delegating.
class ValidatedDkls23KeysApi implements Dkls23KeysApi {
  ValidatedDkls23KeysApi(this.inner);
  final Dkls23KeysApi inner;
  static const _tag = 'Dkls23';

  @override
  BuBytes dkg({
    required Dkls23Curve curve,
    required List<int> sid,
    required int n,
    required int t,
    required List<int> seeds,
  }) {
    if (n < 2) {
      throw CoreErrors.invalidOperationArguments(
        '$_tag.dkg',
        name: 'n',
        reason: 'at least 2 parties required',
      );
    }
    if (sid.isEmpty) {
      throw CoreErrors.invalidOperationArguments(
        '$_tag.dkg',
        name: 'sid',
        reason: 'session id must not be empty.',
      );
    }
    if (t < 2 || t > n) {
      throw CoreErrors.invalidOperationArguments(
        '$_tag.dkg',
        name: 't',
        reason: 'need 2 <= t <= n',
      );
    }
    ApiValidate.length(
      seeds,
      n * 32,
      operation: '$_tag.dkg',
      name: 'seeds',
    );
    return ApiValidate.call(
      '$_tag.dkg',
      () => inner.dkg(curve: curve, sid: sid, n: n, t: t, seeds: seeds),
    );
  }

  @override
  BuBytes sign({
    required Dkls23Curve curve,
    required List<int> sid,
    required List<int> msgHash,
    required List<int> sharesBlob,
    required List<int> seeds,
  }) {
    ApiValidate.length(
      msgHash,
      32,
      operation: '$_tag.sign',
      name: 'msgHash',
    );
    if (sid.isEmpty) {
      throw CoreErrors.invalidOperationArguments(
        '$_tag.sign',
        name: 'sid',
        reason: 'session id must not be empty.',
      );
    }
    if (sharesBlob.isEmpty) {
      throw CoreErrors.invalidOperationArguments(
        '$_tag.sign',
        name: 'sharesBlob',
        reason: 'must not be empty',
      );
    }
    return ApiValidate.call(
      '$_tag.sign',
      () => inner.sign(
        curve: curve,
        sid: sid,
        msgHash: msgHash,
        sharesBlob: sharesBlob,
        seeds: seeds,
      ),
    );
  }

  @override
  BuBytes refresh({
    required List<int> sid,
    required List<int> sharesBlob,
    required List<int> seeds,
  }) {
    if (sid.isEmpty) {
      throw CoreErrors.invalidOperationArguments(
        '$_tag.refresh',
        name: 'sid',
        reason: 'session id must not be empty.',
      );
    }
    if (sharesBlob.isEmpty) {
      throw CoreErrors.invalidOperationArguments(
        '$_tag.refresh',
        name: 'sharesBlob',
        reason: 'must not be empty',
      );
    }
    return ApiValidate.call(
      '$_tag.refresh',
      () => inner.refresh(sid: sid, sharesBlob: sharesBlob, seeds: seeds),
    );
  }

  @override
  bool verify({
    required Dkls23Curve curve,
    required List<int> groupPk,
    required List<int> msgHash,
    required List<int> signature,
  }) {
    ApiValidate.length(
      groupPk,
      33,
      operation: '$_tag.verify',
      name: 'groupPk',
    );
    ApiValidate.length(
      msgHash,
      32,
      operation: '$_tag.verify',
      name: 'msgHash',
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
        curve: curve,
        groupPk: groupPk,
        msgHash: msgHash,
        signature: signature,
      ),
    );
  }

  @override
  BuBytes aggPublicKeys({
    required Dkls23Curve curve,
    required List<int> members,
    required int n,
    int? threshold,
  }) {
    if (n < 2) {
      throw CoreErrors.invalidOperationArguments(
        '$_tag.aggPublicKeys',
        name: 'n',
        reason: 'at least 2 members required',
      );
    }
    final t = threshold ?? n;
    if (t < 2 || t > n) {
      throw CoreErrors.invalidOperationArguments(
        '$_tag.aggPublicKeys',
        name: 'threshold',
        reason: 'need 2 <= threshold <= n',
      );
    }
    ApiValidate.length(
      members,
      n * 33,
      operation: '$_tag.aggPublicKeys',
      name: 'members',
    );
    return ApiValidate.call(
      '$_tag.aggPublicKeys',
      () => inner.aggPublicKeys(
        curve: curve,
        members: members,
        n: n,
        threshold: t,
      ),
    );
  }

  @override
  BuBytes xOnly({required Dkls23Curve curve, required List<int> groupPk}) {
    ApiValidate.length(
      groupPk,
      33,
      operation: '$_tag.xOnly',
      name: 'groupPk',
    );
    return ApiValidate.call(
      '$_tag.xOnly',
      () => inner.xOnly(curve: curve, groupPk: groupPk),
    );
  }

  @override
  BuBytes importSecrets({
    required Dkls23Curve curve,
    required List<int> secrets,
    required int n,
  }) {
    if (n < 2) {
      throw CoreErrors.invalidOperationArguments(
        '$_tag.importSecrets',
        name: 'n',
        reason: 'at least 2 secrets required',
      );
    }
    ApiValidate.length(
      secrets,
      n * 32,
      operation: '$_tag.importSecrets',
      name: 'secrets',
    );
    return ApiValidate.call(
      '$_tag.importSecrets',
      () => inner.importSecrets(curve: curve, secrets: secrets, n: n),
    );
  }
}
