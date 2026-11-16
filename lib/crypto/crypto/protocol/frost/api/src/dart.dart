import 'package:blockchain_utils/crypto/crypto/group/edwards_limb/fields.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/crypto/crypto/group/edwards_limb/ops.dart';
import 'package:blockchain_utils/crypto/crypto/group/edwards_limb/points.dart';
import 'package:blockchain_utils/crypto/crypto/group/weierstrass/weierstrass.dart';
import 'package:blockchain_utils/crypto/crypto/protocol/frost/engine/frost_ed25519.dart';
import 'package:blockchain_utils/crypto/crypto/protocol/frost/engine/frost_k1.dart';
import 'package:blockchain_utils/crypto/crypto/protocol/frost/engine/types.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/utils/numbers/utils/int_utils.dart';

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

import 'package:blockchain_utils/crypto/crypto/protocol/frost/api/src/api.dart';

Never _badArg(Object? value, String operation, String reason, [String? name]) {
  throw CoreErrors.invalidOperationArguments(
    operation,
    name: name,
    reason: reason,
    details: {"value": value.toString()},
  );
}

/// [FrostApi] backed by this package's pure-Dart engines
/// ([FrostSecp256k1] / [FrostEd25519]) — the MuSig2 precedent
/// ([DartMuSig2Api] delegates to [MuSig2]).
class DartFrostApi implements FrostApi {
  final FrostSecp256k1 k1;
  final FrostEd25519 ed;
  const DartFrostApi({
    this.k1 = const FrostSecp256k1(),
    this.ed = const FrostEd25519(),
  });

  // -- secp256k1 helpers -------------------------------------------------

  FrostEngineCommitment<Secp256k1Point> _k1Commitment(FrostCommitment c) {
    return FrostEngineCommitment<Secp256k1Point>(
      id: c.id,
      hidingCommitment: k1.deserializeElement(c.hiding),
      bindingCommitment: k1.deserializeElement(c.binding),
    );
  }

  FrostEngineNonces<Secp256k1Point, Secp256k1Fr> _k1Nonces(
    FrostNoncePair n,
  ) {
    return FrostEngineNonces<Secp256k1Point, Secp256k1Fr>(
      hidingNonce: k1.deserializeScalar(n.hiding),
      bindingNonce: k1.deserializeScalar(n.binding),
      hidingCommitment: k1.deserializeElement(n.hidingCommitment),
      bindingCommitment: k1.deserializeElement(n.bindingCommitment),
    );
  }

  FrostNoncePair _k1NoncePair(
    FrostEngineNonces<Secp256k1Point, Secp256k1Fr> n,
  ) {
    return FrostNoncePair(
      hiding: k1.serializeScalar(n.hidingNonce),
      binding: k1.serializeScalar(n.bindingNonce),
      hidingCommitment: k1.serializeElement(n.hidingCommitment),
      bindingCommitment: k1.serializeElement(n.bindingCommitment),
    );
  }

  // -- ed25519 helpers ---------------------------------------------------

  FrostEngineCommitment<EdwardsLimbPoint> _edCommitment(FrostCommitment c) {
    return FrostEngineCommitment<EdwardsLimbPoint>(
      id: c.id,
      hidingCommitment: ed.deserializeElement(c.hiding),
      bindingCommitment: ed.deserializeElement(c.binding),
    );
  }

  FrostEngineNonces<EdwardsLimbPoint, Ed25519Fr> _edNonces(FrostNoncePair n) {
    return FrostEngineNonces<EdwardsLimbPoint, Ed25519Fr>(
      hidingNonce: ed.deserializeScalar(n.hiding),
      bindingNonce: ed.deserializeScalar(n.binding),
      hidingCommitment: ed.deserializeElement(n.hidingCommitment),
      bindingCommitment: ed.deserializeElement(n.bindingCommitment),
    );
  }

  FrostNoncePair _edNoncePair(
    FrostEngineNonces<EdwardsLimbPoint, Ed25519Fr> n,
  ) {
    return FrostNoncePair(
      hiding: ed.serializeScalar(n.hidingNonce),
      binding: ed.serializeScalar(n.bindingNonce),
      hidingCommitment: ed.serializeElement(n.hidingCommitment),
      bindingCommitment: ed.serializeElement(n.bindingCommitment),
    );
  }

  // -- secp256k1 suite ---------------------------------------------------

  /// Wire participant id as a strict big-endian scalar (`u32` wire range).
  Secp256k1Fr _k1Id(int id) {
    if (id <= 0 || id > 0xFFFFFFFF) {
      _badArg(id, 'Frost._k1Id', 'identifier out of u32 range.', 'id');
    }
    return k1.deserializeScalar(IntUtils.toBytes(id, length: 32).toList());
  }

  /// Small scalar back to its participant id (ids are tiny by construction).
  int _k1FrToInt(Secp256k1Fr f) {
    var v = 0;
    for (final b in f.toBytes()) {
      v = (v << 8) + b;
    }
    return v;
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
        'must hold 32 bytes per coefficient.',
        'coefficients',
      );
    }
    final coeffs = <Secp256k1Fr>[];
    for (var i = 0; i < coefficients.length; i += 32) {
      coeffs.add(k1.deserializeScalar(coefficients.sublist(i, i + 32)));
    }
    final out = k1.secretShareShard(
      k1.deserializeScalar(secret),
      coeffs,
      maxParticipants,
    );
    return FrostDealerShard(
      shares:
          out.shares
              .map(
                (s) => FrostKeyShare(
                  id: _k1FrToInt(s.identifier),
                  share: k1.serializeScalar(s.secretShare),
                ),
              )
              .toList(),
      poly: out.coeffs.expand(k1.serializeScalar).toList(),
    );
  }

  @override
  BuBytes k1Combine(List<FrostKeyShare> shares) {
    final s = k1.secretShareCombine(
      shares
          .map(
            (e) => FrostEngineShare(
              identifier: _k1Id(e.id),
              secretShare: k1.deserializeScalar(e.share),
            ),
          )
          .toList(),
    );
    return BuBytes(k1.serializeScalar(s));
  }

  @override
  FrostNoncePair k1Commit({
    required List<int> secretShare,
    List<int>? hidingRandomness,
    List<int>? bindingRandomness,
  }) {
    final share = k1.deserializeScalar(secretShare);
    if (hidingRandomness == null && bindingRandomness == null) {
      return _k1NoncePair(k1.commit(share));
    }
    return _k1NoncePair(
      k1.commitWithRandomness(
        share,
        hidingRandomness ?? QuickCrypto.generateRandom(length: 32).toList(),
        bindingRandomness ?? QuickCrypto.generateRandom(length: 32).toList(),
      ),
    );
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
    final z = k1.sign(
      identifier,
      k1.deserializeScalar(secretShare),
      Secp256k1Point.fromBytes(groupPublicKey),
      _k1Nonces(nonces),
      message,
      commitments.map(_k1Commitment).toList(),
    );
    return BuBytes(k1.serializeScalar(z));
  }

  @override
  FrostThresholdSignature k1Aggregate({
    required List<FrostCommitment> commitments,
    required List<int> message,
    required List<int> groupPublicKey,
    required List<List<int>> shares,
  }) {
    final (r, z) = k1.aggregate(
      commitments.map(_k1Commitment).toList(),
      message,
      Secp256k1Point.fromBytes(groupPublicKey),
      shares.map((e) => k1.deserializeScalar(e)).toList(),
    );
    return FrostThresholdSignature(
      r: k1.serializeElement(r),
      z: k1.serializeScalar(z),
    );
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
    return k1.verifyShare(
      identifier,
      Secp256k1Point.fromBytes(participantPublicKey),
      _k1Commitment(commitment),
      k1.deserializeScalar(share),
      commitments.map(_k1Commitment).toList(),
      Secp256k1Point.fromBytes(groupPublicKey),
      message,
    );
  }

  @override
  bool k1Verify({
    required List<int> commitment,
    required List<int> z,
    required List<int> groupPublicKey,
    required List<int> message,
  }) {
    return k1.verifySignature(
      Secp256k1Point.fromBytes(commitment),
      k1.deserializeScalar(z),
      Secp256k1Point.fromBytes(groupPublicKey),
      message,
    );
  }

  static void _checkQuorum(int n, int threshold, String op) {
    if (n < 2) {
      _badArg(n, op, 'at least 2 shares required.');
    }
    if (threshold != 0 && (threshold < 2 || threshold > n)) {
      _badArg(threshold, op, 'need threshold 0 (additive) or 2 <= t <= n.');
    }
  }

  @override
  BuBytes k1PrepareShares({
    required List<FrostKeyShare> shares,
    required int threshold,
  }) {
    const op = 'Frost.k1PrepareShares';
    _checkQuorum(shares.length, threshold, op);
    final ids = shares.map((e) => e.id).toList();
    final secs = <Secp256k1Fr>[];
    for (final s in shares) {
      final v = k1.deserializeScalar(s.share);
      if (v.isZero()) {
        _badArg(s.share, op, 'zero share.');
      }
      secs.add(v);
    }
    if (threshold != 0) {
      return BuBytes(secs.expand(k1.serializeScalar).toList());
    }
    final out = <int>[];
    for (var i = 0; i < ids.length; i++) {
      final lambda = k1.deriveInterpolatingValue(ids, ids[i]);
      final inv = lambda.invert();
      if (inv == null) {
        _badArg(ids[i], op, 'invalid identifier.');
      }
      final w = secs[i] * inv;
      out.addAll(k1.serializeScalar(w));
    }
    return BuBytes(out);
  }

  @override
  BuBytes k1GroupFromMembers({
    required List<int> ids,
    required List<int> pubsConcat,
    required int threshold,
  }) {
    const op = 'Frost.k1GroupFromMembers';
    const elen = 33;
    if (pubsConcat.length % elen != 0) {
      _badArg(pubsConcat.length, op, 'must hold whole 33-byte points.');
    }
    final n = pubsConcat.length ~/ elen;
    _checkQuorum(n, threshold, op);
    if (ids.length != n) {
      _badArg(ids.length, op, 'ids/pubs length mismatch.');
    }
    final points = <Secp256k1Point>[];
    for (var i = 0; i < n; i++) {
      points.add(
        k1.deserializeElement(pubsConcat.sublist(i * elen, (i + 1) * elen)),
      );
    }
    var acc = Secp256k1Point.identity_;
    if (threshold == 0) {
      for (final p in points) {
        acc = (acc + p);
      }
    } else {
      for (var i = 0; i < n; i++) {
        final lambda = k1.deriveInterpolatingValue(ids, ids[i]);
        acc = (acc + k1.scalarMult(points[i], lambda));
      }
    }
    if (acc.isZero()) {
      _badArg(acc, op, 'identity group key.');
    }
    return BuBytes(k1.serializeElement(acc));
  }

  @override
  BuBytes k1VssCommit({required List<int> coeffsConcat, required int nCoeffs}) {
    const op = 'Frost.k1VssCommit';
    if (coeffsConcat.length != nCoeffs * 32 || nCoeffs == 0) {
      _badArg(coeffsConcat.length, op, 'bad coeffs.');
    }
    final coeffs = <Secp256k1Fr>[];
    for (var i = 0; i < nCoeffs; i++) {
      coeffs.add(
        k1.deserializeScalar(coeffsConcat.sublist(i * 32, (i + 1) * 32)),
      );
    }
    return BuBytes(k1.vssCommit(coeffs).expand(k1.serializeElement).toList());
  }

  @override
  FrostGroupInfo k1GroupInfo({
    required List<int> vssConcat,
    required int nComms,
    required int max,
  }) {
    const op = 'Frost.k1GroupInfo';
    const elen = 33;
    if (vssConcat.length != nComms * elen || nComms == 0 || max <= 0) {
      _badArg(vssConcat.length, op, 'bad VSS length.');
    }
    final vss = <Secp256k1Point>[];
    for (var i = 0; i < nComms; i++) {
      vss.add(
        k1.deserializeElement(vssConcat.sublist(i * elen, (i + 1) * elen)),
      );
    }
    final pks = <List<int>>[];
    for (var i = 1; i <= max; i++) {
      final x = _k1Id(i);
      var power = Secp256k1Fr.one;
      var acc = Secp256k1Point.identity_;
      for (final c in vss) {
        acc = acc + (c * power);
        power = power * x;
      }
      pks.add(k1.serializeElement(acc));
    }
    return FrostGroupInfo(group: vssConcat.sublist(0, elen), memberKeys: pks);
  }

  @override
  FrostReshare k1Reshare({
    required List<int> ids,
    required List<int> secretsConcat,
    required List<int> coeffsConcat,
    required int threshold,
  }) {
    const op = 'Frost.k1Reshare';
    final n = ids.length;
    _checkQuorum(n, threshold, op);
    if (secretsConcat.length != n * 32) {
      _badArg(secretsConcat.length, op, 'secrets must hold n 32-byte scalars.');
    }
    if (coeffsConcat.length != n * (threshold - 1) * 32) {
      _badArg(
        coeffsConcat.length,
        op,
        'coeffs must hold n * (threshold - 1) 32-byte scalars.',
      );
    }
    final secrets = <Secp256k1Fr>[];
    for (var i = 0; i < n; i++) {
      secrets.add(
        k1.deserializeScalar(secretsConcat.sublist(i * 32, (i + 1) * 32)),
      );
    }
    final coeffs = <Secp256k1Fr>[];
    final nCoeffs = n * (threshold - 1);
    for (var i = 0; i < nCoeffs; i++) {
      coeffs.add(
        k1.deserializeScalar(coeffsConcat.sublist(i * 32, (i + 1) * 32)),
      );
    }
    final r = k1.reshareAdditive(secrets, coeffs, ids, threshold);
    return FrostReshare(
      sharesConcat: r.shares.expand(k1.serializeScalar).toList(),
      pubs: r.pubs.map(k1.serializeElement).toList(),
      group: k1.serializeElement(r.group),
    );
  }

  // -- ed25519 suite -----------------------------------------------------

  /// Shared secret-input decoding: canonical scalar bytes as-is, or an
  /// RFC 8032 seed expanded like `ED25519KeyUtils.derivePublicKey`
  /// (`clamp(SHA-512(seed)[0:32])`, limb-reduced mod `L`).
  Ed25519Fr _edSecretScalar(List<int> input, bool isScalar) {
    if (isScalar) return ed.deserializeScalar(input);
    final digest = QuickCrypto.sha512Hash(input);
    final a = digest.sublist(0, 32).toList();
    a[0] &= 248;
    a[31] &= 127;
    a[31] |= 64;
    return ed.deserializeScalar(EdwardsLimbOps.scReduce32(a));
  }

  /// Wire participant id as a canonical little-endian scalar (`u32` wire
  /// range, always `< L`).
  Ed25519Fr _edId(int id) {
    if (id <= 0 || id > 0xFFFFFFFF) {
      _badArg(id, 'Frost._edId', 'identifier out of u32 range.', 'id');
    }
    final b = List<int>.filled(32, 0);
    b[0] = id & 0xFF;
    b[1] = (id >> 8) & 0xFF;
    b[2] = (id >> 16) & 0xFF;
    b[3] = (id >> 24) & 0xFF;
    return ed.deserializeScalar(b);
  }

  /// Small scalar back to its participant id (little-endian, ids are tiny
  /// by construction).
  int _edFrToInt(Ed25519Fr f) {
    final b = f.toBytes();
    var v = 0;
    for (var i = 3; i >= 0; i--) {
      v = (v << 8) + b[i];
    }
    return v;
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
        'must hold 32 bytes per coefficient.',
        'coefficients',
      );
    }
    final coeffs = <Ed25519Fr>[];
    for (var i = 0; i < coefficients.length; i += 32) {
      coeffs.add(_edSecretScalar(coefficients.sublist(i, i + 32), isScalar));
    }
    final out = ed.secretShareShard(
      _edSecretScalar(secret, isScalar),
      coeffs,
      maxParticipants,
    );
    return FrostDealerShard(
      shares:
          out.shares
              .map(
                (s) => FrostKeyShare(
                  id: _edFrToInt(s.identifier),
                  share: ed.serializeScalar(s.secretShare),
                ),
              )
              .toList(),
      poly: out.coeffs.expand(ed.serializeScalar).toList(),
    );
  }

  @override
  BuBytes edCombine(List<FrostKeyShare> shares, {bool isScalar = true}) {
    final s = ed.secretShareCombine(
      shares
          .map(
            (e) => FrostEngineShare(
              identifier: _edId(e.id),
              secretShare: _edSecretScalar(e.share, isScalar),
            ),
          )
          .toList(),
    );
    return BuBytes(ed.serializeScalar(s));
  }

  @override
  BuBytes edPrepareShares({
    required List<FrostKeyShare> shares,
    required int threshold,
    bool isScalar = true,
  }) {
    const op = 'Frost.edPrepareShares';
    _checkQuorum(shares.length, threshold, op);
    final ids = shares.map((e) => e.id).toList();
    final secs = <Ed25519Fr>[];
    for (final s in shares) {
      final v = _edSecretScalar(s.share, isScalar);
      if (v == Ed25519Fr.zero) {
        _badArg(s.share, op, 'zero share.');
      }
      secs.add(v);
    }
    if (threshold != 0) {
      return BuBytes(secs.expand(ed.serializeScalar).toList());
    }
    final out = <int>[];
    for (var i = 0; i < ids.length; i++) {
      final lambda = ed.deriveInterpolatingValue(ids, ids[i]);
      final inv = lambda.invert();
      if (inv == null) {
        _badArg(ids[i], op, 'zero lagrange weight.');
      }
      out.addAll(ed.serializeScalar(secs[i] * inv));
    }
    return BuBytes(out);
  }

  @override
  BuBytes edGroupFromMembers({
    required List<int> ids,
    required List<int> pubsConcat,
    required int threshold,
  }) {
    const op = 'Frost.edGroupFromMembers';
    const elen = 32;
    if (pubsConcat.length % elen != 0) {
      _badArg(pubsConcat.length, op, 'must hold whole 32-byte points.');
    }
    final n = pubsConcat.length ~/ elen;
    _checkQuorum(n, threshold, op);
    if (ids.length != n) {
      _badArg(ids.length, op, 'ids/pubs length mismatch.');
    }
    final points = <EdwardsLimbPoint>[];
    for (var i = 0; i < n; i++) {
      points.add(
        ed.deserializeElement(pubsConcat.sublist(i * elen, (i + 1) * elen)),
      );
    }
    var acc = EdwardsLimbPoint.identity_;
    if (threshold == 0) {
      for (final p in points) {
        acc = acc + p;
      }
    } else {
      for (var i = 0; i < n; i++) {
        final lambda = ed.deriveInterpolatingValue(ids, ids[i]);
        acc = acc + ed.scalarMult(points[i], lambda);
      }
    }
    if (acc.isIdentity()) {
      _badArg(acc, op, 'identity group key.');
    }
    return BuBytes(ed.serializeElement(acc));
  }

  @override
  BuBytes edVssCommit({required List<int> coeffsConcat, required int nCoeffs}) {
    const op = 'Frost.edVssCommit';
    if (coeffsConcat.length != nCoeffs * 32 || nCoeffs == 0) {
      _badArg(coeffsConcat.length, op, 'bad coeffs.');
    }
    final coeffs = <Ed25519Fr>[];
    for (var i = 0; i < nCoeffs; i++) {
      coeffs.add(
        ed.deserializeScalar(coeffsConcat.sublist(i * 32, (i + 1) * 32)),
      );
    }
    return BuBytes(ed.vssCommit(coeffs).expand(ed.serializeElement).toList());
  }

  @override
  FrostGroupInfo edGroupInfo({
    required List<int> vssConcat,
    required int nComms,
    required int max,
  }) {
    const op = 'Frost.edGroupInfo';
    const elen = 32;
    if (vssConcat.length != nComms * elen || nComms == 0 || max <= 0) {
      _badArg(vssConcat.length, op, 'bad VSS length.');
    }
    final vss = <EdwardsLimbPoint>[];
    for (var i = 0; i < nComms; i++) {
      vss.add(
        ed.deserializeElement(vssConcat.sublist(i * elen, (i + 1) * elen)),
      );
    }
    final (_, memberKeys) = ed.deriveGroupInfo(max, vss);
    return FrostGroupInfo(
      group: vssConcat.sublist(0, elen),
      memberKeys: memberKeys.map(ed.serializeElement).toList(),
    );
  }

  @override
  FrostReshare edReshare({
    required List<int> ids,
    required List<int> seedsConcat,
    required List<int> coeffSeedsConcat,
    required int threshold,
  }) {
    const op = 'Frost.edReshare';
    final n = ids.length;
    _checkQuorum(n, threshold, op);
    if (seedsConcat.length != n * 32) {
      _badArg(seedsConcat.length, op, 'seeds must hold n 32-byte seeds.');
    }
    if (coeffSeedsConcat.length != n * (threshold - 1) * 32) {
      _badArg(
        coeffSeedsConcat.length,
        op,
        'coeff seeds must hold n * (threshold - 1) 32-byte seeds.',
      );
    }
    final secrets = <Ed25519Fr>[];
    for (var i = 0; i < n; i++) {
      secrets.add(
        _edSecretScalar(seedsConcat.sublist(i * 32, (i + 1) * 32), false),
      );
    }
    final coeffs = <Ed25519Fr>[];
    final nCoeffs = n * (threshold - 1);
    for (var i = 0; i < nCoeffs; i++) {
      coeffs.add(
        _edSecretScalar(coeffSeedsConcat.sublist(i * 32, (i + 1) * 32), false),
      );
    }
    final r = ed.reshareAdditive(secrets, coeffs, ids, threshold);
    return FrostReshare(
      sharesConcat: r.shares.expand(ed.serializeScalar).toList(),
      pubs: r.pubs.map(ed.serializeElement).toList(),
      group: ed.serializeElement(r.group),
    );
  }

  @override
  FrostNoncePair edCommit({
    required List<int> secretShare,
    List<int>? hidingRandomness,
    List<int>? bindingRandomness,
    bool isScalar = true,
  }) {
    final share = _edSecretScalar(secretShare, isScalar);
    if (hidingRandomness == null && bindingRandomness == null) {
      return _edNoncePair(ed.commit(share));
    }
    return _edNoncePair(
      ed.commitWithRandomness(
        share,
        hidingRandomness ?? QuickCrypto.generateRandom(length: 32).toList(),
        bindingRandomness ?? QuickCrypto.generateRandom(length: 32).toList(),
      ),
    );
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
    final z = ed.sign(
      identifier,
      _edSecretScalar(secretShare, isScalar),
      EdwardsLimbPoint.fromBytes(groupPublicKey),
      _edNonces(nonces),
      message,
      commitments.map(_edCommitment).toList(),
    );
    return BuBytes(ed.serializeScalar(z));
  }

  @override
  FrostThresholdSignature edAggregate({
    required List<FrostCommitment> commitments,
    required List<int> message,
    required List<int> groupPublicKey,
    required List<List<int>> shares,
  }) {
    final (r, z) = ed.aggregate(
      commitments.map(_edCommitment).toList(),
      message,
      EdwardsLimbPoint.fromBytes(groupPublicKey),
      shares.map((e) => ed.deserializeScalar(e)).toList(),
    );
    return FrostThresholdSignature(
      r: ed.serializeElement(r),
      z: ed.serializeScalar(z),
    );
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
    return ed.verifyShare(
      identifier,
      EdwardsLimbPoint.fromBytes(participantPublicKey),
      _edCommitment(commitment),
      ed.deserializeScalar(share),
      commitments.map(_edCommitment).toList(),
      EdwardsLimbPoint.fromBytes(groupPublicKey),
      message,
    );
  }

  @override
  bool edVerify({
    required List<int> commitment,
    required List<int> z,
    required List<int> groupPublicKey,
    required List<int> message,
  }) {
    return ed.verifySignature(
      EdwardsLimbPoint.fromBytes(commitment),
      ed.deserializeScalar(z),
      EdwardsLimbPoint.fromBytes(groupPublicKey),
      message,
    );
  }
}
