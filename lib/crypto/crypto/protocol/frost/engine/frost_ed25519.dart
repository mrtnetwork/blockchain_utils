// Pure-Dart RFC 9591 FROST(Ed25519, SHA-512) engine.
//
// It exercises the two-round signing protocol from Sections 4-5 plus
// trusted-dealer key generation (Appendix C) using only existing
// blockchain_utils primitives (limb points, SHA-512).
//
// All scalar arithmetic runs in [Ed25519Fr]; participant ids are plain
// 1-based `int` counters (`u32` wire range). [BigInt] remains only for
// the single order-derived bit ladder inside [deserializeElement]
// (prime-subgroup check needs integer-order multiplication, which
// reduced scalars cannot express).
//
// References: RFC 9591 Sections 6.1 (ciphersuite), 4.x (helpers),
// 5.1-5.3 (signing), Appendix C (dealer), Appendix E.1 (vectors).

import 'dart:typed_data' show Endian;

import 'package:blockchain_utils/crypto/crypto/group/edwards_limb/fields.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/utils/binary/src/utils.dart';
import 'package:blockchain_utils/crypto/crypto/group/edwards_limb/points.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/utils/numbers/fixed/src/u64/u64.dart';
import 'package:blockchain_utils/utils/numbers/utils/bigint_utils.dart';
import 'package:blockchain_utils/crypto/crypto/protocol/frost/engine/engine.dart';
import 'package:blockchain_utils/crypto/crypto/protocol/frost/engine/types.dart';
import 'package:blockchain_utils/utils/string/string.dart';

/// FROST(Ed25519, SHA-512) — RFC 9591 Section 6.1.
class FrostEd25519 implements FrostEngine<EdwardsLimbPoint, Ed25519Fr> {
  const FrostEd25519();
  @override
  String get contextString => 'FROST-ED25519-SHA512-v1';

  @override
  int get scalarLen => 32;
  @override
  int get elementLen => 32;

  /// Group order as an integer, derived from the field (no literals):
  /// `L = (L - 1) + 1`. Needed only for the prime-subgroup bit ladder,
  /// which must multiply by the integer order (reduced scalars lose the
  /// 8-torsion information the check relies on).
  static final BigInt _orderBi =
      BigintUtils.fromBytes(
        (Ed25519Fr.zero - Ed25519Fr.one).toBytes(),
        byteOrder: Endian.little,
      ) +
      BigInt.one;

  /// Small participant id (1-based, `u32` wire range) as a canonical
  /// scalar. Fails closed outside the range or above `L` (ids are tiny).
  static Ed25519Fr _frFromId(int v) {
    if (v <= 0 || v > 0xFFFFFFFF) {
      throw CoreErrors.invalidOperationArguments(
        'FrostEd25519._frFromId',
        reason: 'Identifier out of u32 range.',
      );
    }
    final b = List<int>.filled(32, 0);
    b[0] = v & 0xFF;
    b[1] = (v >> 8) & 0xFF;
    b[2] = (v >> 16) & 0xFF;
    b[3] = (v >> 24) & 0xFF;
    return Ed25519Fr.fromBytes(b);
  }

  // ------------------------------------------------------------------
  // Scalar / element codecs (Section 3.1 + Section 6.1).
  // ------------------------------------------------------------------

  /// SerializeScalar: 32-byte little-endian, always canonical.
  @override
  List<int> serializeScalar(Ed25519Fr s) => s.toBytes().toList();

  /// DeserializeScalar: 32-byte little-endian integer in [0, order).
  /// Fails closed on bad length or non-canonical encoding.
  @override
  Ed25519Fr deserializeScalar(List<int> buf) {
    try {
      return Ed25519Fr.fromBytes(buf);
    } catch (_) {
      throw CoreErrors.cryptoFailed(
        'deserializeScalar',
        reason: 'Invalid scalar encoding.',
      );
    }
  }

  @override
  List<int> serializeElement(EdwardsLimbPoint p) {
    if (p.isIdentity()) {
      throw CoreErrors.cryptoFailed(
        'serializeElement',
        reason: 'Identity element.',
      );
    }
    return p.toBytes().toList();
  }

  /// DeserializeElement: strict decode + identity + subgroup check.
  @override
  EdwardsLimbPoint deserializeElement(List<int> buf) {
    if (buf.length != elementLen) {
      throw CoreErrors.cryptoFailed(
        'deserializeElement',
        reason: 'Invalid element length.',
      );
    }
    late final EdwardsLimbPoint p;
    try {
      p = EdwardsLimbPoint.fromBytes(buf);
    } catch (_) {
      throw CoreErrors.cryptoFailed(
        'deserializeElement',
        reason: 'Invalid element encoding.',
      );
    }
    if (p.isIdentity()) {
      throw CoreErrors.cryptoFailed(
        'deserializeElement',
        reason: 'Identity element.',
      );
    }
    // Subgroup check: [order]P == identity. Integer-order ladder
    // (vartime on the public encoding): reduced scalars cannot express
    // this check, since (L)P via reduced arithmetic is trivially zero.
    if (!_isPrimeSubgroup(p)) {
      throw CoreErrors.cryptoFailed(
        'deserializeElement',
        reason: 'Not in prime-order subgroup.',
      );
    }
    return p;
  }

  /// Vartime integer-order multiply for the subgroup check above.
  static bool _isPrimeSubgroup(EdwardsLimbPoint p) {
    var acc = EdwardsLimbPoint.identity_;
    var base = p;
    var l = _orderBi;
    while (l > BigInt.zero) {
      if ((l & BigInt.one) == BigInt.one) acc = acc + base;
      base = base.double();
      l >>= 1;
    }
    return acc.isIdentity();
  }

  @override
  EdwardsLimbPoint scalarBaseMult(Ed25519Fr s) {
    return EdwardsLimbPoint.generator_ * s;
  }

  @override
  EdwardsLimbPoint scalarMult(EdwardsLimbPoint p, Ed25519Fr s) {
    return p * s;
  }

  // ------------------------------------------------------------------
  // Hashes H, H1..H5 (Section 6.1).
  // ------------------------------------------------------------------

  List<int> _sha512(List<int> data) {
    return QuickCrypto.sha512Hash(data);
  }

  Ed25519Fr _hashToScalar(List<int> digest) {
    return Ed25519Fr.fromBytes64(digest);
  }

  List<int> _ctx(String label) {
    return [...StringUtils.encode(contextString), ...StringUtils.encode(label)];
  }

  /// H1(m) = H(ctx || "rho" || m) -> scalar.
  Ed25519Fr h1(List<int> m) {
    return _hashToScalar(_sha512([..._ctx('rho'), ...m]));
  }

  /// H2(m) = H(m) -> scalar (no domain separation, Ed25519 compat).
  Ed25519Fr h2(List<int> m) {
    return _hashToScalar(_sha512(m));
  }

  /// H3(m) = H(ctx || "nonce" || m) -> scalar.
  Ed25519Fr h3(List<int> m) {
    return _hashToScalar(_sha512([..._ctx('nonce'), ...m]));
  }

  /// H4(m) = H(ctx || "msg" || m), raw 64 bytes.
  List<int> h4(List<int> m) {
    return _sha512([..._ctx('msg'), ...m]);
  }

  /// H5(m) = H(ctx || "com" || m), raw 64 bytes.
  List<int> h5(List<int> m) {
    return _sha512([..._ctx('com'), ...m]);
  }

  // ------------------------------------------------------------------
  // Polynomials (Sections 4.2, C.1.1).
  // ------------------------------------------------------------------

  @override
  Ed25519Fr deriveInterpolatingValue(List<int> ids, int xi) {
    if (!ids.contains(xi)) {
      throw CoreErrors.invalidOperationArguments(
        'deriveInterpolatingValue',
        reason: 'invalid parameters.',
      );
    }
    final seen = <int>{};
    for (final v in ids) {
      if (v <= 0 || v > 0xFFFFFFFF || !seen.add(v)) {
        throw CoreErrors.invalidOperationArguments(
          'deriveInterpolatingValue',
          reason: 'invalid parameters.',
        );
      }
    }
    final x = _frFromId(xi);
    var num = Ed25519Fr.one;
    var den = Ed25519Fr.one;
    for (final xj in ids) {
      if (xj == xi) continue;
      final fj = _frFromId(xj);
      num = num * fj;
      den = den * (fj - x);
    }
    final inv = den.invert();
    if (inv == null) {
      throw CoreErrors.cryptoFailed(
        'deriveInterpolatingValue',
        reason: 'Zero denominator.',
      );
    }
    return num * inv;
  }

  @override
  Ed25519Fr polynomialEvaluate(Ed25519Fr x, List<Ed25519Fr> coeffs) {
    var value = Ed25519Fr.zero;
    for (var i = coeffs.length - 1; i >= 0; i--) {
      value = value * x + coeffs[i];
    }
    return value;
  }

  @override
  Ed25519Fr polynomialInterpolateConstant(List<(Ed25519Fr, Ed25519Fr)> points) {
    final xs = points.map((e) => e.$1).toList();
    var acc = Ed25519Fr.zero;
    for (final (x, y) in points) {
      acc = acc + y * _lagrangeAtZero(xs, x);
    }
    return acc;
  }

  /// Lagrange weight without the membership preconditions (inputs
  /// already validated by the caller).
  static Ed25519Fr _lagrangeAtZero(List<Ed25519Fr> ids, Ed25519Fr xi) {
    var num = Ed25519Fr.one;
    var den = Ed25519Fr.one;
    for (final xj in ids) {
      if (xj == xi) continue;
      num = num * xj;
      den = den * (xj - xi);
    }
    // Distinct identifiers keep the denominator non-zero.
    return num * den.invert()!;
  }

  // ------------------------------------------------------------------
  // Binding factors / commitments / challenge (Sections 4.3-4.6).
  // ------------------------------------------------------------------

  /// commitment-list entries; identifiers are scalars in [1, ...].
  @override
  List<int> encodeGroupCommitmentList(
    List<FrostEngineCommitment<EdwardsLimbPoint>> commitments,
  ) {
    final sorted = [...commitments]..sort((a, b) => a.id.compareTo(b.id));
    final out = <int>[];
    for (final c in sorted) {
      out.addAll(serializeScalar(_frFromId(c.id)));
      out.addAll(serializeElement(c.hidingCommitment));
      out.addAll(serializeElement(c.bindingCommitment));
    }
    return out;
  }

  @override
  List<int> participantsFromCommitmentList(
    List<FrostEngineCommitment<EdwardsLimbPoint>> commitments,
  ) {
    return commitments.map((c) => c.id).toList();
  }

  @override
  Map<int, Ed25519Fr> computeBindingFactors(
    EdwardsLimbPoint groupPublicKey,
    List<FrostEngineCommitment<EdwardsLimbPoint>> commitments,
    List<int> msg,
  ) {
    final sorted = [...commitments]..sort((a, b) => a.id.compareTo(b.id));
    // Duplicate / zero / out-of-range identifiers are invalid.
    final seen = <int>{};
    for (final c in sorted) {
      if (c.id <= 0 || c.id > 0xFFFFFFFF || !seen.add(c.id)) {
        throw CoreErrors.invalidOperationArguments(
          'computeBindingFactors',
          reason: 'invalid parameters.',
        );
      }
    }
    final prefix = [
      ...serializeElement(groupPublicKey),
      ...h4(msg),
      ...h5(encodeGroupCommitmentList(sorted)),
    ];
    final out = <int, Ed25519Fr>{};
    for (final c in sorted) {
      out[c.id] = h1([...prefix, ...serializeScalar(_frFromId(c.id))]);
    }
    return out;
  }

  @override
  Ed25519Fr bindingFactorFor(Map<int, Ed25519Fr> factors, int identifier) {
    final v = factors[identifier];
    if (v == null) {
      throw CoreErrors.invalidOperationArguments(
        'bindingFactorFor',
        reason: 'invalid participant.',
      );
    }
    return v;
  }

  @override
  EdwardsLimbPoint computeGroupCommitment(
    List<FrostEngineCommitment<EdwardsLimbPoint>> commitments,
    Map<int, Ed25519Fr> factors,
  ) {
    var acc = EdwardsLimbPoint.identity_;
    for (final c in commitments) {
      final rho = bindingFactorFor(factors, c.id);
      acc = acc + c.hidingCommitment + scalarMult(c.bindingCommitment, rho);
    }
    if (acc.isIdentity()) {
      throw CoreErrors.cryptoFailed(
        'computeGroupCommitment',
        reason: 'Identity group commitment.',
      );
    }
    return acc;
  }

  @override
  Ed25519Fr computeChallenge(
    EdwardsLimbPoint groupCommitment,
    EdwardsLimbPoint groupPublicKey,
    List<int> msg,
  ) {
    return h2([
      ...serializeElement(groupCommitment),
      ...serializeElement(groupPublicKey),
      ...msg,
    ]);
  }

  // ------------------------------------------------------------------
  // Round 1: commit (Section 5.1).
  // ------------------------------------------------------------------

  /// Nonce pair derivation with caller-supplied 32-byte randomness
  /// (test vectors) or fresh randomness (production, Section 4.1).
  @override
  FrostEngineNonces<EdwardsLimbPoint, Ed25519Fr> commitWithRandomness(
    Ed25519Fr secretShare,
    List<int> hidingRandomness,
    List<int> bindingRandomness,
  ) {
    if (hidingRandomness.length != 32 || bindingRandomness.length != 32) {
      throw CoreErrors.invalidOperationArguments(
        'commit',
        reason: 'Randomness must be 32 bytes.',
      );
    }
    if (secretShare == Ed25519Fr.zero) {
      throw CoreErrors.invalidOperationArguments(
        'commit',
        reason: 'Invalid secret share.',
      );
    }
    final enc = serializeScalar(secretShare);
    final hiding = h3([...hidingRandomness, ...enc]);
    final binding = h3([...bindingRandomness, ...enc]);
    if (hiding == Ed25519Fr.zero || binding == Ed25519Fr.zero) {
      throw CoreErrors.cryptoFailed('commit', reason: 'Zero nonce.');
    }
    return FrostEngineNonces<EdwardsLimbPoint, Ed25519Fr>(
      hidingNonce: hiding,
      bindingNonce: binding,
      hidingCommitment: scalarBaseMult(hiding),
      bindingCommitment: scalarBaseMult(binding),
    );
  }

  @override
  FrostEngineNonces<EdwardsLimbPoint, Ed25519Fr> commit(Ed25519Fr secretShare) {
    final r1 = QuickCrypto.generateRandom(length: 32);
    final r2 = QuickCrypto.generateRandom(length: 32);
    return commitWithRandomness(secretShare, r1, r2);
  }

  // ------------------------------------------------------------------
  // Round 2: sign (Section 5.2).
  // ------------------------------------------------------------------

  @override
  Ed25519Fr sign(
    int identifier,
    Ed25519Fr secretShare,
    EdwardsLimbPoint groupPublicKey,
    FrostEngineNonces<EdwardsLimbPoint, Ed25519Fr> nonces,
    List<int> msg,
    List<FrostEngineCommitment<EdwardsLimbPoint>> commitments,
  ) {
    final factors = computeBindingFactors(groupPublicKey, commitments, msg);
    final rho = bindingFactorFor(factors, identifier);
    final groupCommitment = computeGroupCommitment(commitments, factors);
    final lambda = deriveInterpolatingValue(
      participantsFromCommitmentList(commitments),
      identifier,
    );
    final challenge = computeChallenge(groupCommitment, groupPublicKey, msg);
    return nonces.hidingNonce +
        nonces.bindingNonce * rho +
        lambda * secretShare * challenge;
  }

  // ------------------------------------------------------------------
  // Aggregation + share verification (Section 5.3).
  // ------------------------------------------------------------------

  @override
  (EdwardsLimbPoint, Ed25519Fr) aggregate(
    List<FrostEngineCommitment<EdwardsLimbPoint>> commitments,
    List<int> msg,
    EdwardsLimbPoint groupPublicKey,
    List<Ed25519Fr> shares,
  ) {
    if (shares.length < 2) {
      throw CoreErrors.invalidOperationArguments(
        'aggregate',
        reason: 'At least 2 shares required.',
      );
    }
    if (shares.length != commitments.length) {
      throw CoreErrors.invalidOperationArguments(
        'aggregate',
        reason: 'Shares/commitments length mismatch.',
      );
    }
    final factors = computeBindingFactors(groupPublicKey, commitments, msg);
    final groupCommitment = computeGroupCommitment(commitments, factors);
    var z = Ed25519Fr.zero;
    for (final s in shares) {
      z = z + s;
    }
    return (groupCommitment, z);
  }

  @override
  bool verifyShare(
    int identifier,
    EdwardsLimbPoint participantPublicKey,
    FrostEngineCommitment<EdwardsLimbPoint> commitment,
    Ed25519Fr share,
    List<FrostEngineCommitment<EdwardsLimbPoint>> commitments,
    EdwardsLimbPoint groupPublicKey,
    List<int> msg,
  ) {
    if (identifier <= 0 || commitment.id != identifier) {
      throw CoreErrors.invalidOperationArguments(
        'verifyShare',
        reason: 'invalid participant.',
      );
    }
    // The standalone commitment must match the list entry for
    // `identifier`: rho/R/c below derive from the list, so a divergent
    // commitment would verify unrelated DLOG inputs meaninglessly.
    FrostEngineCommitment<EdwardsLimbPoint>? listed;
    for (final c in commitments) {
      if (c.id == identifier) {
        listed = c;
        break;
      }
    }
    if (listed == null) {
      throw CoreErrors.invalidOperationArguments(
        'verifyShare',
        reason: 'Unknown participant.',
      );
    }
    if (!BytesUtils.bytesEqual(
          serializeElement(listed.hidingCommitment),
          serializeElement(commitment.hidingCommitment),
        ) ||
        !BytesUtils.bytesEqual(
          serializeElement(listed.bindingCommitment),
          serializeElement(commitment.bindingCommitment),
        )) {
      throw CoreErrors.cryptoFailed(
        'verifyShare',
        reason: 'Commitment mismatch.',
      );
    }
    final factors = computeBindingFactors(groupPublicKey, commitments, msg);
    final rho = bindingFactorFor(factors, identifier);
    final groupCommitment = computeGroupCommitment(commitments, factors);
    final commShare =
        commitment.hidingCommitment +
        scalarMult(commitment.bindingCommitment, rho);
    final challenge = computeChallenge(groupCommitment, groupPublicKey, msg);
    final lambda = deriveInterpolatingValue(
      participantsFromCommitmentList(commitments),
      identifier,
    );
    final lhs = scalarBaseMult(share);
    final rhs =
        commShare + scalarMult(participantPublicKey, challenge * lambda);
    return lhs == rhs;
  }

  /// Ed25519-compat verification: [8][z]B == [8]R + [8][c]PK (Sec 6.1).
  @override
  bool verifySignature(
    EdwardsLimbPoint groupCommitment,
    Ed25519Fr z,
    EdwardsLimbPoint groupPublicKey,
    List<int> msg,
  ) {
    if (groupCommitment.isIdentity() || groupPublicKey.isIdentity()) {
      return false;
    }
    final c = computeChallenge(groupCommitment, groupPublicKey, msg);
    final eight = Ed25519Fr.from(Uint64(8));
    final lhs = scalarBaseMult(z * eight);
    final rhs =
        scalarMult(groupCommitment, eight) +
        scalarMult(groupPublicKey, c * eight);
    return lhs == rhs;
  }

  @override
  List<int> encodeSignature(EdwardsLimbPoint r, Ed25519Fr z) {
    return [...serializeElement(r), ...serializeScalar(z)];
  }

  @override
  (EdwardsLimbPoint, Ed25519Fr) decodeSignature(List<int> sig) {
    if (sig.length != 64) {
      throw CoreErrors.cryptoFailed(
        'decodeSignature',
        reason: 'Invalid signature length.',
      );
    }
    return (
      deserializeElement(sig.sublist(0, 32)),
      deserializeScalar(sig.sublist(32)),
    );
  }

  // ------------------------------------------------------------------
  // Trusted dealer key generation (Appendix C).
  // ------------------------------------------------------------------

  @override
  ({List<FrostEngineShare<Ed25519Fr>> shares, List<Ed25519Fr> coeffs})
  secretShareShard(
    Ed25519Fr secret,
    List<Ed25519Fr> coefficients,
    int maxParticipants,
  ) {
    if (secret == Ed25519Fr.zero) {
      throw CoreErrors.invalidOperationArguments(
        'secretShareShard',
        reason: 'Invalid secret.',
      );
    }
    if (maxParticipants < 2) {
      throw CoreErrors.invalidOperationArguments(
        'secretShareShard',
        reason: 'Invalid MAX_PARTICIPANTS.',
      );
    }
    if (coefficients.length + 1 > maxParticipants) {
      throw CoreErrors.invalidOperationArguments(
        'secretShareShard',
        reason: 'Threshold exceeds MAX_PARTICIPANTS.',
      );
    }
    final full = [secret, ...coefficients];
    final shares = <FrostEngineShare<Ed25519Fr>>[];
    for (var i = 1; i <= maxParticipants; i++) {
      final id = _frFromId(i);
      shares.add(
        FrostEngineShare(
          identifier: id,
          secretShare: polynomialEvaluate(id, full),
        ),
      );
    }
    return (shares: shares, coeffs: full);
  }

  @override
  Ed25519Fr secretShareCombine(List<FrostEngineShare<Ed25519Fr>> shares) {
    if (shares.length < 2) {
      throw CoreErrors.invalidOperationArguments(
        'secretShareCombine',
        reason: 'At least 2 shares required.',
      );
    }
    return polynomialInterpolateConstant(
      shares.map((e) => (e.identifier, e.secretShare)).toList(),
    );
  }

  @override
  List<EdwardsLimbPoint> vssCommit(List<Ed25519Fr> coeffs) {
    return coeffs.map(scalarBaseMult).toList();
  }

  @override
  bool vssVerify(
    FrostEngineShare<Ed25519Fr> share,
    List<EdwardsLimbPoint> commitment,
  ) {
    var acc = EdwardsLimbPoint.identity_;
    var power = Ed25519Fr.one;
    for (var j = 0; j < commitment.length; j++) {
      acc = acc + scalarMult(commitment[j], power);
      power = power * share.identifier;
    }
    return scalarBaseMult(share.secretShare) == acc;
  }

  @override
  (EdwardsLimbPoint, List<EdwardsLimbPoint>) deriveGroupInfo(
    int maxParticipants,
    List<EdwardsLimbPoint> vssCommitment,
  ) {
    final groupKey = vssCommitment[0];
    final pks = <EdwardsLimbPoint>[];
    for (var i = 1; i <= maxParticipants; i++) {
      var acc = EdwardsLimbPoint.identity_;
      var power = Ed25519Fr.one;
      final id = _frFromId(i);
      for (var j = 0; j < vssCommitment.length; j++) {
        acc = acc + scalarMult(vssCommitment[j], power);
        power = power * id;
      }
      pks.add(acc);
    }
    return (groupKey, pks);
  }

  /// Threshold reshare (additive, Rust core mirror).
  ///
  /// ```dart
  /// // n = 2, threshold = 2: poly0 = [a0, c0], poly1 = [a1, c1];
  /// // b_i = poly0(ids[i]) + poly1(ids[i]); pubs[i] == G * b_i;
  /// // group == G * a0 + G * a1; any threshold (id, b) pairs combine
  /// // to (a0 + a1) via deriveInterpolatingValue.
  /// final r = engine.reshareAdditive([a0, a1], [c0, c1], [id1, id2], 2);
  /// assert(r.shares.length == 2 && r.pubs.length == 2);
  /// ```
  @override
  ({
    List<Ed25519Fr> shares,
    List<EdwardsLimbPoint> pubs,
    EdwardsLimbPoint group,
  })
  reshareAdditive(
    List<Ed25519Fr> secrets,
    List<Ed25519Fr> coeffs,
    List<int> ids,
    int threshold,
  ) {
    final n = secrets.length;
    if (n < 2) {
      throw CoreErrors.invalidOperationArguments(
        'reshareAdditive',
        reason: 'invalid parameters.',
      );
    }
    if (threshold < 2 || threshold > n) {
      throw CoreErrors.invalidOperationArguments(
        'reshareAdditive',
        reason: 'invalid parameters.',
      );
    }
    if (ids.length != n) {
      throw CoreErrors.invalidOperationArguments(
        'reshareAdditive',
        reason: 'invalid parameters.',
      );
    }
    if (coeffs.length != n * (threshold - 1)) {
      throw CoreErrors.invalidOperationArguments(
        'reshareAdditive',
        reason: 'invalid parameters.',
      );
    }
    final seen = <int>{};
    for (final id in ids) {
      if (id <= 0 || id > 0xFFFFFFFF || !seen.add(id)) {
        throw CoreErrors.invalidOperationArguments(
          'reshareAdditive',
          reason: 'invalid parameters.',
        );
      }
    }
    for (final s in secrets) {
      if (s == Ed25519Fr.zero) {
        throw CoreErrors.invalidOperationArguments(
          'reshareAdditive',
          reason: 'Invalid secret.',
        );
      }
    }
    final frIds = ids.map(_frFromId).toList();
    final chunk = threshold - 1;
    final shares = <Ed25519Fr>[];
    for (var i = 0; i < n; i++) {
      var b = Ed25519Fr.zero;
      for (var j = 0; j < n; j++) {
        final poly = <Ed25519Fr>[
          secrets[j],
          ...coeffs.sublist(j * chunk, (j + 1) * chunk),
        ];
        b = b + polynomialEvaluate(frIds[i], poly);
      }
      if (b == Ed25519Fr.zero) {
        throw CoreErrors.cryptoFailed('reshareAdditive', reason: 'Zero share.');
      }
      shares.add(b);
    }
    final pubs = shares.map(scalarBaseMult).toList();
    var group = EdwardsLimbPoint.identity_;
    for (final s in secrets) {
      group = group + scalarBaseMult(s);
    }
    if (group.isIdentity()) {
      throw CoreErrors.cryptoFailed(
        'reshareAdditive',
        reason: 'Identity group key.',
      );
    }
    return (shares: shares, pubs: pubs, group: group);
  }
}
