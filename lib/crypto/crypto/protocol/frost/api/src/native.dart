import 'dart:typed_data' show Endian;
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/utils/numbers/utils/int_utils.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

import 'package:blockchain_utils/crypto/crypto/protocol/frost/api/src/api.dart';

/// [FrostApi] backed by a native (FFI/platform) implementation.
///
/// Every call maps onto the matching [BuFrostApi] endpoint via
/// `unwrapOrThrowCryptoError`, exactly like `NativeMuSig2Api` maps onto
/// `BuMusig2Api`. The `k1*` methods drive the secp256k1 suite (33-byte
/// points), the `ed*` methods the Ed25519 suite (32-byte points). Key
/// shares cross as `[id:u32 LE][share:32]` records and commitments as
/// `[id:u32 LE][hiding][binding]` records, mirroring `BuFrostShare` and
/// `BuFrostCommitment`.
class NativeFrostApi implements FrostApi {
  final BuFrostApi api;
  const NativeFrostApi(this.api);

  static Never _badArg(
    Object? value,
    String operation,
    String reason, [
    String? name,
  ]) {
    throw CoreErrors.invalidOperationArguments(
      operation,
      name: name,
      reason: reason,
      details: {"value": value.toString()},
    );
  }

  /// Fresh OS randomness for an omitted commit nonce scalar.
  static BuBytes _rand32() => QuickCrypto.generateRandom(length: 32);

  static BuBytes _sharesConcat(List<FrostKeyShare> shares) {
    final out = <int>[];
    for (final s in shares) {
      out.addAll(IntUtils.toBytes(s.id, length: 4, byteOrder: Endian.little));
      out.addAll(s.share);
    }
    return BuBytes(out);
  }

  static BuBytes _commitmentsConcat(List<FrostCommitment> commitments) {
    final out = <int>[];
    for (final c in commitments) {
      out.addAll(IntUtils.toBytes(c.id, length: 4, byteOrder: Endian.little));
      out.addAll(c.hiding);
      out.addAll(c.binding);
    }
    return BuBytes(out);
  }

  static List<FrostKeyShare> _parseShares(BuBytes concat) {
    if (concat.length % 36 != 0) {
      throw CoreErrors.cryptoFailed(
        'FrostApi.shard',
        reason:
            'Malformed share records from backend (length ${concat.length}, not a multiple of 36).',
      );
    }
    final shares = <FrostKeyShare>[];
    for (var at = 0; at < concat.length; at += 36) {
      final id = IntUtils.fromBytes(
        concat,
        offset: at,
        length: 4,
        byteOrder: Endian.little,
      );
      shares.add(FrostKeyShare(id: id, share: concat.sublist(at + 4, at + 36)));
    }
    return shares;
  }

  /// Pure-data encoding: `ids` as concatenated u32 LE (Rust reads u32s).
  static BuBytes _idsConcat(List<int> ids) {
    final out = <int>[];
    for (final id in ids) {
      out.addAll(
        IntUtils.toBytes(id, length: 4, byteOrder: Endian.little),
      );
    }
    return BuBytes(out);
  }

  @override
  FrostDealerShard k1Shard({
    required List<int> secret,
    required List<int> coefficients,
    required int maxParticipants,
  }) {
    if (coefficients.length % 32 != 0) {
      _badArg(
        coefficients.length,
        'Frost.k1Shard',
        'must hold whole 32-byte scalars.',
        'coefficients',
      );
    }
    final result = api.frostK1Shard(
      secret32: secret.asBytes,
      coeffsConcat: coefficients.asBytes,
      nCoeffs: coefficients.length ~/ 32,
      max: maxParticipants,
    );
    return result
        .map(
          (e) => FrostDealerShard(
            shares: _parseShares(e.sharesConcat),
            poly: e.polyConcat,
          ),
        )
        .unwrapOrThrowCryptoError();
  }

  @override
  BuBytes k1Combine(List<FrostKeyShare> shares) {
    final result = api.frostK1Combine(_sharesConcat(shares), shares.length);
    return result.unwrapOrThrowCryptoError();
  }

  @override
  FrostNoncePair k1Commit({
    required List<int> secretShare,
    List<int>? hidingRandomness,
    List<int>? bindingRandomness,
  }) {
    final result = api.frostK1Commit(
      secretShare32: secretShare.asBytes,
      hidingRand32: hidingRandomness?.asBytes ?? _rand32(),
      bindingRand32: bindingRandomness?.asBytes ?? _rand32(),
    );
    return result
        .map(
          (e) => FrostNoncePair(
            hiding: e.hiding,
            binding: e.binding,
            hidingCommitment: e.hidingCommitment,
            bindingCommitment: e.bindingCommitment,
          ),
        )
        .unwrapOrThrowCryptoError();
  }

  @override
  BuBytes k1Sign({
    required int identifier,
    required List<int> secretShare,
    required List<int> groupPublicKey,
    required FrostNoncePair nonces,
    required List<FrostCommitment> commitments,
    required List<int> message,
  }) {
    final result = api.frostK1Sign(
      id: identifier,
      secretShare32: secretShare.asBytes,
      groupPk33: groupPublicKey.asBytes,
      nonces: BuFrostNonces(
        hiding: nonces.hiding,
        binding: nonces.binding,
        hidingCommitment: nonces.hidingCommitment,
        bindingCommitment: nonces.bindingCommitment,
      ),
      commitmentsConcat: _commitmentsConcat(commitments),
      n: commitments.length,
      msg: message.asBytes,
    );
    return result.unwrapOrThrowCryptoError();
  }

  @override
  FrostThresholdSignature k1Aggregate({
    required List<FrostCommitment> commitments,
    required List<int> message,
    required List<int> groupPublicKey,
    required List<List<int>> shares,
  }) {
    final result = api.frostK1Aggregate(
      commitmentsConcat: _commitmentsConcat(commitments),
      n: commitments.length,
      msg: message.asBytes,
      groupPk33: groupPublicKey.asBytes,
      sharesConcat: BuBytes([for (final s in shares) ...s]),
      nShares: shares.length,
    );
    return result
        .map((e) => FrostThresholdSignature(r: e.r, z: e.z))
        .unwrapOrThrowCryptoError();
  }

  @override
  bool k1VerifyShare({
    required int identifier,
    required List<int> participantPublicKey,
    required FrostCommitment commitment,
    required List<int> share,
    required List<FrostCommitment> commitments,
    required List<int> groupPublicKey,
    required List<int> message,
  }) {
    final result = api.frostK1VerifyShare(
      id: identifier,
      pkShare33: participantPublicKey.asBytes,
      comm: BuFrostCommitment(
        id: commitment.id,
        hiding: commitment.hiding.asBytes,
        binding: commitment.binding.asBytes,
      ),
      share32: share.asBytes,
      commitmentsConcat: _commitmentsConcat(commitments),
      n: commitments.length,
      groupPk33: groupPublicKey.asBytes,
      msg: message.asBytes,
    );
    return result.unwrapOrThrowCryptoError();
  }

  @override
  bool k1Verify({
    required List<int> commitment,
    required List<int> z,
    required List<int> groupPublicKey,
    required List<int> message,
  }) {
    final result = api.frostK1Verify(
      r33: commitment.asBytes,
      z32: z.asBytes,
      groupPk33: groupPublicKey.asBytes,
      msg: message.asBytes,
    );
    return result.unwrapOrThrowCryptoError();
  }

  @override
  BuBytes k1PrepareShares({
    required List<FrostKeyShare> shares,
    required int threshold,
  }) {
    final result = api.frostK1PrepareShares(
      sharesConcat: _sharesConcat(shares),
      n: shares.length,
      threshold: threshold,
    );
    return result.unwrapOrThrowCryptoError();
  }

  @override
  BuBytes k1GroupFromMembers({
    required List<int> ids,
    required List<int> pubsConcat,
    required int threshold,
  }) {
    final result = api.frostK1GroupFromMembers(
      idsConcat: _idsConcat(ids),
      pubsConcat: pubsConcat.asBytes,
      n: ids.length,
      threshold: threshold,
    );
    return result.unwrapOrThrowCryptoError();
  }

  @override
  BuBytes k1VssCommit({required List<int> coeffsConcat, required int nCoeffs}) {
    final result = api.frostK1VssCommit(
      coeffsConcat: coeffsConcat.asBytes,
      nCoeffs: nCoeffs,
    );
    return result.unwrapOrThrowCryptoError();
  }

  @override
  FrostGroupInfo k1GroupInfo({
    required List<int> vssConcat,
    required int nComms,
    required int max,
  }) {
    final result = api.frostK1GroupInfo(
      vssConcat: vssConcat.asBytes,
      nComms: nComms,
      max: max,
    );
    return result
        .map(
          (e) => FrostGroupInfo(
            group: e.group,
            memberKeys: _splitEl(e.pksConcat, 33),
          ),
        )
        .unwrapOrThrowCryptoError();
  }

  @override
  FrostReshare k1Reshare({
    required List<int> ids,
    required List<int> secretsConcat,
    required List<int> coeffsConcat,
    required int threshold,
  }) {
    final result = api.frostK1Reshare(
      idsConcat: _idsConcat(ids),
      secretsConcat: secretsConcat.asBytes,
      n: ids.length,
      coeffsConcat: coeffsConcat.asBytes,
      nCoeffs: coeffsConcat.length ~/ 32,
      threshold: threshold,
    );
    final out = result.unwrapOrThrowCryptoError();
    return FrostReshare(
      sharesConcat: out.sharesConcat.toList(),
      pubs: _splitEl(out.pubsConcat, 33),
      group: out.group.toList(),
    );
  }

  static List<List<int>> _splitEl(BuBytes concat, int elen) {
    if (concat.length % elen != 0) {
      throw CoreErrors.cryptoFailed(
        'FrostApi.groupInfo',
        reason: 'Malformed member keys from backend.',
      );
    }
    return [
      for (var at = 0; at < concat.length; at += elen)
        concat.sublist(at, at + elen),
    ];
  }

  @override
  FrostDealerShard edShard({
    required List<int> secret,
    required List<int> coefficients,
    required int maxParticipants,
    bool isScalar = true,
  }) {
    if (coefficients.length % 32 != 0) {
      _badArg(
        coefficients.length,
        'Frost.edShard',
        'must hold whole 32-byte scalars.',
        'coefficients',
      );
    }
    final result = api.frostEdShard(
      secret32: secret.asBytes,
      coeffsConcat: coefficients.asBytes,
      nCoeffs: coefficients.length ~/ 32,
      max: maxParticipants,
      isScalar: isScalar,
    );
    return result
        .map(
          (e) => FrostDealerShard(
            shares: _parseShares(e.sharesConcat),
            poly: e.polyConcat,
          ),
        )
        .unwrapOrThrowCryptoError();
  }

  @override
  BuBytes edCombine(List<FrostKeyShare> shares, {bool isScalar = true}) {
    final result = api.frostEdCombine(
      _sharesConcat(shares),
      shares.length,
      isScalar: isScalar,
    );
    return result.unwrapOrThrowCryptoError();
  }

  @override
  FrostNoncePair edCommit({
    required List<int> secretShare,
    List<int>? hidingRandomness,
    List<int>? bindingRandomness,
    bool isScalar = true,
  }) {
    final result = api.frostEdCommit(
      secretShare32: secretShare.asBytes,
      hidingRand32: hidingRandomness?.asBytes ?? _rand32(),
      bindingRand32: bindingRandomness?.asBytes ?? _rand32(),
      isScalar: isScalar,
    );
    return result
        .map(
          (e) => FrostNoncePair(
            hiding: e.hiding,
            binding: e.binding,
            hidingCommitment: e.hidingCommitment,
            bindingCommitment: e.bindingCommitment,
          ),
        )
        .unwrapOrThrowCryptoError();
  }

  @override
  BuBytes edSign({
    required int identifier,
    required List<int> secretShare,
    required List<int> groupPublicKey,
    required FrostNoncePair nonces,
    required List<FrostCommitment> commitments,
    required List<int> message,
    bool isScalar = true,
  }) {
    final result = api.frostEdSign(
      id: identifier,
      secretShare32: secretShare.asBytes,
      groupPk32: groupPublicKey.asBytes,
      nonces: BuFrostNonces(
        hiding: nonces.hiding,
        binding: nonces.binding,
        hidingCommitment: nonces.hidingCommitment,
        bindingCommitment: nonces.bindingCommitment,
      ),
      commitmentsConcat: _commitmentsConcat(commitments),
      n: commitments.length,
      msg: message.asBytes,
      isScalar: isScalar,
    );
    return result.unwrapOrThrowCryptoError();
  }

  @override
  FrostThresholdSignature edAggregate({
    required List<FrostCommitment> commitments,
    required List<int> message,
    required List<int> groupPublicKey,
    required List<List<int>> shares,
  }) {
    final result = api.frostEdAggregate(
      commitmentsConcat: _commitmentsConcat(commitments),
      n: commitments.length,
      msg: message.asBytes,
      groupPk32: groupPublicKey.asBytes,
      sharesConcat: BuBytes([for (final s in shares) ...s]),
      nShares: shares.length,
    );
    return result
        .map((e) => FrostThresholdSignature(r: e.r, z: e.z))
        .unwrapOrThrowCryptoError();
  }

  @override
  bool edVerifyShare({
    required int identifier,
    required List<int> participantPublicKey,
    required FrostCommitment commitment,
    required List<int> share,
    required List<FrostCommitment> commitments,
    required List<int> groupPublicKey,
    required List<int> message,
  }) {
    final result = api.frostEdVerifyShare(
      id: identifier,
      pkShare32: participantPublicKey.asBytes,
      comm: BuFrostCommitment(
        id: commitment.id,
        hiding: commitment.hiding.asBytes,
        binding: commitment.binding.asBytes,
      ),
      share32: share.asBytes,
      commitmentsConcat: _commitmentsConcat(commitments),
      n: commitments.length,
      groupPk32: groupPublicKey.asBytes,
      msg: message.asBytes,
    );
    return result.unwrapOrThrowCryptoError();
  }

  @override
  bool edVerify({
    required List<int> commitment,
    required List<int> z,
    required List<int> groupPublicKey,
    required List<int> message,
  }) {
    final result = api.frostEdVerify(
      r32: commitment.asBytes,
      z32: z.asBytes,
      groupPk32: groupPublicKey.asBytes,
      msg: message.asBytes,
    );
    return result.unwrapOrThrowCryptoError();
  }

  @override
  BuBytes edPrepareShares({
    required List<FrostKeyShare> shares,
    required int threshold,
    bool isScalar = true,
  }) {
    final result = api.frostEdPrepareShares(
      sharesConcat: _sharesConcat(shares),
      n: shares.length,
      threshold: threshold,
      isScalar: isScalar,
    );
    return result.unwrapOrThrowCryptoError();
  }

  @override
  BuBytes edGroupFromMembers({
    required List<int> ids,
    required List<int> pubsConcat,
    required int threshold,
  }) {
    final result = api.frostEdGroupFromMembers(
      idsConcat: _idsConcat(ids),
      pubsConcat: pubsConcat.asBytes,
      n: ids.length,
      threshold: threshold,
    );
    return result.unwrapOrThrowCryptoError();
  }

  @override
  BuBytes edVssCommit({required List<int> coeffsConcat, required int nCoeffs}) {
    final result = api.frostEdVssCommit(
      coeffsConcat: coeffsConcat.asBytes,
      nCoeffs: nCoeffs,
    );
    return result.unwrapOrThrowCryptoError();
  }

  @override
  FrostGroupInfo edGroupInfo({
    required List<int> vssConcat,
    required int nComms,
    required int max,
  }) {
    final result = api.frostEdGroupInfo(
      vssConcat: vssConcat.asBytes,
      nComms: nComms,
      max: max,
    );
    return result
        .map(
          (e) => FrostGroupInfo(
            group: e.group,
            memberKeys: _splitEl(e.pksConcat, 32),
          ),
        )
        .unwrapOrThrowCryptoError();
  }

  @override
  FrostReshare edReshare({
    required List<int> ids,
    required List<int> seedsConcat,
    required List<int> coeffSeedsConcat,
    required int threshold,
  }) {
    final result = api.frostEdReshare(
      idsConcat: _idsConcat(ids),
      secretsConcat: seedsConcat.asBytes,
      n: ids.length,
      coeffsConcat: coeffSeedsConcat.asBytes,
      nCoeffs: coeffSeedsConcat.length ~/ 32,
      threshold: threshold,
    );
    final out = result.unwrapOrThrowCryptoError();
    return FrostReshare(
      sharesConcat: out.sharesConcat.toList(),
      pubs: _splitEl(out.pubsConcat, 32),
      group: out.group.toList(),
    );
  }
}
