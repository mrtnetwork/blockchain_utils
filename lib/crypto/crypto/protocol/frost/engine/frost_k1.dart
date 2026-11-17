// Pure-Dart RFC 9591 FROST(secp256k1, SHA-256) engine.
//
// It exercises the two-round signing protocol from Sections 4-5 plus
// trusted-dealer key generation (Appendix C) using only existing
// blockchain_utils primitives (secp256k1 group ops, SHA-256).
//
// References: RFC 9591 Sections 6.5 (ciphersuite), 4.x (helpers),
// 5.1-5.3 (signing), Appendix C (dealer), Appendix E.5 (vectors),
// RFC 9380 Section 5.2-5.3 (hash_to_field / expand_message_xmd).

import 'package:blockchain_utils/crypto/crypto/group/weierstrass/weierstrass.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/utils/binary/src/utils.dart';
import 'package:blockchain_utils/utils/numbers/fixed/src/u64/u64.dart';
import 'package:blockchain_utils/utils/numbers/utils/int_utils.dart';
import 'package:blockchain_utils/crypto/crypto/protocol/frost/engine/engine.dart';
import 'package:blockchain_utils/crypto/crypto/protocol/frost/engine/types.dart';
import 'package:blockchain_utils/utils/string/string.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// FROST(secp256k1, SHA-256) — RFC 9591 Section 6.5.
///
/// All scalar arithmetic runs in [Secp256k1Fr]; participant ids are plain
/// 1-based `int` counters (`u32` wire range). No [BigInt] appears anywhere
/// on this path.
class FrostSecp256k1 implements FrostEngine<Secp256k1Point, Secp256k1Fr> {
  const FrostSecp256k1();
  @override
  String get contextString => 'FROST-secp256k1-SHA256-v1';

  static final Secp256k1Fr _b256 = Secp256k1Fr.from(Uint64(256));

  static Secp256k1Fr _frUnchecked(List<int> bytes) =>
      Secp256k1Fr.fromBytesUnchecked(bytes);

  /// Small participant id (1-based, `u32` wire range) as a scalar.
  /// Fails closed outside the range or above `n` (ids are tiny).
  static Secp256k1Fr _idFr(int v) {
    if (v <= 0 || v > 0xFFFFFFFF) {
      throw CoreErrors.invalidOperationArguments(
        'FrostSecp256k1._idFr',
        reason: 'Identifier out of u32 range.',
      );
    }
    return Secp256k1Fr.fromBytes(IntUtils.toBytes(v, length: 32));
  }

  @override
  int get scalarLen => 32;
  @override
  int get elementLen => 33;

  // ------------------------------------------------------------------
  // Scalar / element codecs (Section 3.1 + Section 6.5).
  // ------------------------------------------------------------------

  /// SerializeScalar: Field-Element-to-Octet-String (big-endian 32B).
  @override
  List<int> serializeScalar(Secp256k1Fr s) => s.toBytes();

  /// DeserializeScalar: 32-byte big-endian integer in [0, order).
  /// Fails closed on bad length or non-canonical encoding.
  @override
  Secp256k1Fr deserializeScalar(List<int> buf) {
    if (buf.length != scalarLen) {
      throw CoreErrors.cryptoFailed(
        'deserializeScalar',
        reason: 'Invalid scalar length.',
      );
    }
    try {
      return Secp256k1Fr.fromBytes(buf);
    } catch (_) {
      throw CoreErrors.cryptoFailed(
        'deserializeScalar',
        reason: 'Scalar out of range.',
      );
    }
  }

  /// SerializeElement: compressed SEC1 (33B), rejects identity.
  @override
  List<int> serializeElement(Secp256k1Point p) {
    if (p.isZero()) {
      throw CoreErrors.cryptoFailed(
        'serializeElement',
        reason: 'Identity element.',
      );
    }
    return p.toBytes();
  }

  /// DeserializeElement: SEC1 compressed decode + on-curve + identity
  /// checks (no subgroup check needed: cofactor is 1).
  @override
  Secp256k1Point deserializeElement(List<int> buf) {
    if (buf.length != elementLen) {
      throw CoreErrors.cryptoFailed(
        'deserializeElement',
        reason: 'Invalid element length.',
      );
    }
    try {
      final p = Secp256k1Point.fromBytes(buf);
      if (p.isZero()) {
        throw const FormatException('identity');
      }
      return p;
    } catch (_) {
      throw CoreErrors.cryptoFailed(
        'deserializeElement',
        reason: 'Invalid element encoding.',
      );
    }
  }

  @override
  Secp256k1Point scalarBaseMult(Secp256k1Fr s) {
    return Secp256k1Point.generator_ * s;
  }

  @override
  Secp256k1Point scalarMult(Secp256k1Point p, Secp256k1Fr s) {
    return p * s;
  }

  // ------------------------------------------------------------------
  // Hashes H, H1..H5 (Section 6.5 + RFC 9380 Section 5.2-5.3).
  // ------------------------------------------------------------------

  List<int> _sha256(List<int> data) {
    return QuickCrypto.sha256Hash(data);
  }

  List<int> _i2osp(int v, int len) {
    final out = List<int>.filled(len, 0);
    for (var i = len - 1; i >= 0; i--) {
      out[i] = v & 0xff;
      v >>= 8;
    }
    return out;
  }

  List<int> _strxor(List<int> a, List<int> b) {
    return List<int>.generate(a.length, (i) => a[i] ^ b[i]);
  }

  /// expand_message_xmd(msg, DST, len_in_bytes) with SHA-256 (RFC 9380).
  List<int> expandMessageXmd(List<int> msg, List<int> dst, int lenInBytes) {
    const bInBytes = 32;
    const sBytes = 64;
    final dstPrime = [...dst, dst.length];
    final zPad = List<int>.filled(sBytes, 0);
    final lIBStr = _i2osp(lenInBytes, 2);
    final msgPrime = [...zPad, ...msg, ...lIBStr, 0, ...dstPrime];
    final b0 = _sha256(msgPrime);
    final b1 = _sha256([...b0, 1, ...dstPrime]);
    final out = [...b1];
    var bPrev = b1;
    var i = 2;
    while (out.length < lenInBytes) {
      final bi = _sha256([..._strxor(b0, bPrev), i, ...dstPrime]);
      out.addAll(bi);
      bPrev = bi;
      i++;
    }
    const ell = (255 * bInBytes) ~/ 8;
    if (lenInBytes > ell) {
      throw CoreErrors.cryptoFailed(
        'expandMessageXmd',
        reason: 'Length too large.',
      );
    }
    return out.sublist(0, lenInBytes);
  }

  /// hash_to_field(m, 1) with L=48: OS2IP-BE reduced mod n via a
  /// Horner base-256 fold (pure field arithmetic, no BigInt order).
  Secp256k1Fr _hashToScalarFr(List<int> m, List<int> dst) {
    final uniform = expandMessageXmd(m, dst, 48);
    var acc = Secp256k1Fr.zero;
    for (final byte in uniform) {
      acc = acc * _b256 + Secp256k1Fr.from(Uint64(byte));
    }
    return acc;
  }

  Secp256k1Fr _hashToScalar(List<int> m, List<int> dst) =>
      _hashToScalarFr(m, dst);

  List<int> _ctx(String label) {
    return [...StringUtils.encode(contextString), ...StringUtils.encode(label)];
  }

  /// H1(m) = hash_to_field DST=context||"rho".
  Secp256k1Fr h1(List<int> m) {
    return _hashToScalar(m, _ctx('rho'));
  }

  /// H2(m) = hash_to_field DST=context||"chal".
  Secp256k1Fr h2(List<int> m) {
    return _hashToScalar(m, _ctx('chal'));
  }

  /// H3(m) = hash_to_field DST=context||"nonce".
  Secp256k1Fr h3(List<int> m) {
    return _hashToScalar(m, _ctx('nonce'));
  }

  /// H4(m) = H(context || "msg" || m), raw 32 bytes.
  List<int> h4(List<int> m) {
    return _sha256([..._ctx('msg'), ...m]);
  }

  /// H5(m) = H(context || "com" || m), raw 32 bytes.
  List<int> h5(List<int> m) {
    return _sha256([..._ctx('com'), ...m]);
  }

  // ------------------------------------------------------------------
  // Polynomials (Sections 4.2, C.1.1).
  // ------------------------------------------------------------------

  static Secp256k1Fr _polyEvalFr(Secp256k1Fr x, List<Secp256k1Fr> coeffs) {
    var value = Secp256k1Fr.zero;
    for (var i = coeffs.length - 1; i >= 0; i--) {
      value = value * x + coeffs[i];
    }
    return value;
  }

  /// Lagrange weight without the membership preconditions (inputs
  /// already validated by the caller).
  static Secp256k1Fr _lagrangeFr(List<Secp256k1Fr> xs, Secp256k1Fr x) {
    var num = Secp256k1Fr.one;
    var den = Secp256k1Fr.one;
    for (final xj in xs) {
      if (xj == x) continue;
      num = num * xj;
      den = den * (xj - x);
    }
    // Distinct identifiers keep the denominator non-zero.
    final inv = den.invert();
    if (inv == null) throw const FormatException();
    return num * inv;
  }

  @override
  Secp256k1Fr deriveInterpolatingValue(List<int> ids, int xi) {
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
    try {
      return _lagrangeFr([for (final id in ids) _idFr(id)], _idFr(xi));
    } on BuError {
      rethrow;
    } catch (_) {
      throw CoreErrors.invalidOperationArguments(
        'deriveInterpolatingValue',
        reason: 'invalid parameters.',
      );
    }
  }

  @override
  Secp256k1Fr polynomialEvaluate(Secp256k1Fr x, List<Secp256k1Fr> coeffs) {
    return _polyEvalFr(x, coeffs);
  }

  @override
  Secp256k1Fr polynomialInterpolateConstant(
    List<(Secp256k1Fr, Secp256k1Fr)> points,
  ) {
    try {
      final xs = points.map((e) => e.$1).toList();
      var acc = Secp256k1Fr.zero;
      for (final (x, y) in points) {
        acc = acc + y * _lagrangeFr(xs, x);
      }
      return acc;
    } on BuError {
      rethrow;
    } catch (_) {
      throw CoreErrors.invalidOperationArguments(
        'polynomialInterpolateConstant',
        reason: 'invalid parameters.',
      );
    }
  }

  // ------------------------------------------------------------------
  // Binding factors / commitments / challenge (Sections 4.3-4.6).
  // ------------------------------------------------------------------

  @override
  List<int> encodeGroupCommitmentList(
    List<FrostEngineCommitment<Secp256k1Point>> commitments,
  ) {
    final sorted = [...commitments]..sort((a, b) => a.id.compareTo(b.id));
    final out = <int>[];
    for (final c in sorted) {
      out.addAll(serializeScalar(_idFr(c.id)));
      out.addAll(serializeElement(c.hidingCommitment));
      out.addAll(serializeElement(c.bindingCommitment));
    }
    return out;
  }

  @override
  List<int> participantsFromCommitmentList(
    List<FrostEngineCommitment<Secp256k1Point>> commitments,
  ) {
    return commitments.map((c) => c.id).toList();
  }

  @override
  Map<int, Secp256k1Fr> computeBindingFactors(
    Secp256k1Point groupPublicKey,
    List<FrostEngineCommitment<Secp256k1Point>> commitments,
    List<int> msg,
  ) {
    final sorted = [...commitments]..sort((a, b) => a.id.compareTo(b.id));
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
    final out = <int, Secp256k1Fr>{};
    for (final c in sorted) {
      out[c.id] = h1([...prefix, ...serializeScalar(_idFr(c.id))]);
    }
    return out;
  }

  @override
  Secp256k1Fr bindingFactorFor(Map<int, Secp256k1Fr> factors, int identifier) {
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
  Secp256k1Point computeGroupCommitment(
    List<FrostEngineCommitment<Secp256k1Point>> commitments,
    Map<int, Secp256k1Fr> factors,
  ) {
    var acc = Secp256k1Point.identity_;
    for (final c in commitments) {
      final rho = bindingFactorFor(factors, c.id);
      acc = acc + c.hidingCommitment + scalarMult(c.bindingCommitment, rho);
    }
    if (acc.isZero()) {
      throw CoreErrors.cryptoFailed(
        'computeGroupCommitment',
        reason: 'Identity group commitment.',
      );
    }
    return acc;
  }

  @override
  Secp256k1Fr computeChallenge(
    Secp256k1Point groupCommitment,
    Secp256k1Point groupPublicKey,
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
  FrostEngineNonces<Secp256k1Point, Secp256k1Fr> commitWithRandomness(
    Secp256k1Fr secretShare,
    List<int> hidingRandomness,
    List<int> bindingRandomness,
  ) {
    if (hidingRandomness.length != 32 || bindingRandomness.length != 32) {
      throw CoreErrors.invalidOperationArguments(
        'commit',
        reason: 'Randomness must be 32 bytes.',
      );
    }
    if (secretShare.isZero()) {
      throw CoreErrors.invalidOperationArguments(
        'commit',
        reason: 'Invalid secret share.',
      );
    }
    final enc = serializeScalar(secretShare);
    final hiding = h3([...hidingRandomness, ...enc]);
    final binding = h3([...bindingRandomness, ...enc]);
    if (hiding.isZero() || binding.isZero()) {
      throw CoreErrors.cryptoFailed('commit', reason: 'Zero nonce.');
    }
    return FrostEngineNonces<Secp256k1Point, Secp256k1Fr>(
      hidingNonce: hiding,
      bindingNonce: binding,
      hidingCommitment: scalarBaseMult(hiding),
      bindingCommitment: scalarBaseMult(binding),
    );
  }

  @override
  FrostEngineNonces<Secp256k1Point, Secp256k1Fr> commit(
    Secp256k1Fr secretShare,
  ) {
    final r1 = QuickCrypto.generateRandom(length: 32);
    final r2 = QuickCrypto.generateRandom(length: 32);
    return commitWithRandomness(secretShare, r1, r2);
  }

  // ------------------------------------------------------------------
  // Round 2: sign (Section 5.2).
  // ------------------------------------------------------------------

  @override
  Secp256k1Fr sign(
    int identifier,
    Secp256k1Fr secretShare,
    Secp256k1Point groupPublicKey,
    FrostEngineNonces<Secp256k1Point, Secp256k1Fr> nonces,
    List<int> msg,
    List<FrostEngineCommitment<Secp256k1Point>> commitments,
  ) {
    final factors = computeBindingFactors(groupPublicKey, commitments, msg);
    final rho = bindingFactorFor(factors, identifier);
    final groupCommitment = computeGroupCommitment(commitments, factors);
    final lambda = deriveInterpolatingValue(
      participantsFromCommitmentList(commitments),
      identifier,
    );
    final challenge = computeChallenge(groupCommitment, groupPublicKey, msg);
    final h = nonces.hidingNonce;
    final b = nonces.bindingNonce;
    final s = secretShare;
    return h + b * rho + lambda * s * challenge;
  }

  // ------------------------------------------------------------------
  // Aggregation + share verification (Section 5.3).
  // ------------------------------------------------------------------

  @override
  (Secp256k1Point, Secp256k1Fr) aggregate(
    List<FrostEngineCommitment<Secp256k1Point>> commitments,
    List<int> msg,
    Secp256k1Point groupPublicKey,
    List<Secp256k1Fr> shares,
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
    var z = Secp256k1Fr.zero;
    for (final s in shares) {
      z = z + s;
    }
    return (groupCommitment, z);
  }

  @override
  bool verifyShare(
    int identifier,
    Secp256k1Point participantPublicKey,
    FrostEngineCommitment<Secp256k1Point> commitment,
    Secp256k1Fr share,
    List<FrostEngineCommitment<Secp256k1Point>> commitments,
    Secp256k1Point groupPublicKey,
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
    FrostEngineCommitment<Secp256k1Point>? listed;
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
        commitment.hidingCommitment + (commitment.bindingCommitment * rho);
    final challenge = computeChallenge(groupCommitment, groupPublicKey, msg);
    final lambda = deriveInterpolatingValue(
      participantsFromCommitmentList(commitments),
      identifier,
    );
    final lhs = scalarBaseMult(share);
    final rhs = commShare + (participantPublicKey * (challenge * lambda));
    return lhs == rhs;
  }

  /// Schnorr verification (Appendix B): z*G == R + c*PK.
  @override
  bool verifySignature(
    Secp256k1Point groupCommitment,
    Secp256k1Fr z,
    Secp256k1Point groupPublicKey,
    List<int> msg,
  ) {
    final zFr = z;
    if (groupCommitment.isZero() || groupPublicKey.isZero()) return false;
    final c = computeChallenge(groupCommitment, groupPublicKey, msg);
    final lhs = Secp256k1Point.generator_ * zFr;
    final rhs = groupCommitment + groupPublicKey * c;
    return lhs == rhs;
  }

  /// Canonical encoding (Appendix A): R (33B) || z (32B).
  @override
  List<int> encodeSignature(Secp256k1Point r, Secp256k1Fr z) {
    return [...serializeElement(r), ...serializeScalar(z)];
  }

  @override
  (Secp256k1Point, Secp256k1Fr) decodeSignature(List<int> sig) {
    if (sig.length != 65) {
      throw CoreErrors.cryptoFailed(
        'decodeSignature',
        reason: 'Invalid signature length.',
      );
    }
    return (
      deserializeElement(sig.sublist(0, 33)),
      deserializeScalar(sig.sublist(33)),
    );
  }

  // ------------------------------------------------------------------
  // Trusted dealer key generation (Appendix C).
  // ------------------------------------------------------------------

  @override
  ({List<FrostEngineShare<Secp256k1Fr>> shares, List<Secp256k1Fr> coeffs})
  secretShareShard(
    Secp256k1Fr secret,
    List<Secp256k1Fr> coefficients,
    int maxParticipants,
  ) {
    if (secret.isZero()) {
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
    final shares = <FrostEngineShare<Secp256k1Fr>>[];
    for (var i = 1; i <= maxParticipants; i++) {
      shares.add(
        FrostEngineShare<Secp256k1Fr>(
          identifier: _idFr(i),
          secretShare: _polyEvalFr(_idFr(i), full),
        ),
      );
    }
    return (shares: shares, coeffs: full);
  }

  @override
  Secp256k1Fr secretShareCombine(List<FrostEngineShare<Secp256k1Fr>> shares) {
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
  List<Secp256k1Point> vssCommit(List<Secp256k1Fr> coeffs) {
    return coeffs.map(scalarBaseMult).toList();
  }

  @override
  bool vssVerify(
    FrostEngineShare<Secp256k1Fr> share,
    List<Secp256k1Point> commitment,
  ) {
    var acc = Secp256k1Point.identity_;
    var power = Secp256k1Fr.one;
    final id = share.identifier;
    for (var j = 0; j < commitment.length; j++) {
      acc = acc + (commitment[j] * power);
      power = power * id;
    }
    return Secp256k1Point.generator_ * share.secretShare == acc;
  }

  @override
  (Secp256k1Point, List<Secp256k1Point>) deriveGroupInfo(
    int maxParticipants,
    List<Secp256k1Point> vssCommitment,
  ) {
    final groupKey = vssCommitment[0];
    final pks = <Secp256k1Point>[];
    for (var i = 1; i <= maxParticipants; i++) {
      var acc = Secp256k1Point.identity_;
      var power = Secp256k1Fr.one;
      final id = _idFr(i);
      for (var j = 0; j < vssCommitment.length; j++) {
        acc = acc + (vssCommitment[j] * power);
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
  ({List<Secp256k1Fr> shares, List<Secp256k1Point> pubs, Secp256k1Point group})
  reshareAdditive(
    List<Secp256k1Fr> secrets,
    List<Secp256k1Fr> coeffs,
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
      if (s.isZero()) {
        throw CoreErrors.invalidOperationArguments(
          'reshareAdditive',
          reason: 'Invalid secret.',
        );
      }
    }
    final chunk = threshold - 1;
    final shares = <Secp256k1Fr>[];
    for (var i = 0; i < n; i++) {
      var b = Secp256k1Fr.zero;
      final idi = _idFr(ids[i]);
      for (var j = 0; j < n; j++) {
        final poly = <Secp256k1Fr>[
          secrets[j],
          ...coeffs.sublist(j * chunk, (j + 1) * chunk),
        ];
        b = b + _polyEvalFr(idi, poly);
      }
      if (b.isZero()) {
        throw CoreErrors.cryptoFailed('reshareAdditive', reason: 'Zero share.');
      }
      shares.add(b);
    }
    final pubs = shares.map((s) => Secp256k1Point.generator_ * s).toList();
    var group = Secp256k1Point.identity_;
    for (final s in secrets) {
      group = group + (Secp256k1Point.generator_ * s);
    }
    if (group.isZero()) {
      throw CoreErrors.cryptoFailed(
        'reshareAdditive',
        reason: 'Identity group key.',
      );
    }
    return (shares: shares, pubs: pubs, group: group);
  }

  // ------------------------------------------------------------------
  // BIP-340 single-signer helpers (for full-key local signing).
  // ------------------------------------------------------------------

  List<int> _taggedHash(String tag, List<int> msg) {
    final tagHash = QuickCrypto.sha256Hash(StringUtils.encode(tag));
    return QuickCrypto.sha256Hash([...tagHash, ...tagHash, ...msg]);
  }

  /// BIP-340 sign with a full secret (even-Y enforced).
  (List<int>, Secp256k1Fr) bip340Sign(
    Secp256k1Fr secret,
    List<int> msg, {
    List<int>? auxRand,
  }) {
    var d = secret;
    if (d.isZero()) {
      throw CoreErrors.invalidOperationArguments(
        'bip340Sign',
        reason: 'Invalid secret.',
      );
    }
    var p = Secp256k1Point.generator_ * d;
    if (p.isOdd) {
      d = -d;
      p = -p;
    }
    final aux = auxRand ?? QuickCrypto.generateRandom(length: 32);
    if (aux.length != 32) {
      throw CoreErrors.invalidOperationArguments(
        'bip340Sign',
        reason: 'aux must be 32 bytes.',
      );
    }
    final t = _taggedHash('BIP0340/aux', aux).xorWith(d.toBytes().toList());
    Secp256k1Fr k;
    List<int> rBytes;
    while (true) {
      final rand = QuickCrypto.generateRandom(length: 32);
      k = _frUnchecked(
        _taggedHash('BIP0340/nonce', [...t, ...p.toXOnly(), ...msg, ...rand]),
      );
      if (k.isZero()) continue;
      final r = Secp256k1Point.generator_ * k;
      if (r.isOdd) {
        k = -k;
      }
      rBytes = r.toXOnly();
      break;
    }
    final e = _frUnchecked(
      _taggedHash('BIP0340/challenge', [...rBytes, ...p.toXOnly(), ...msg]),
    );
    final s = k + e * d;
    return (rBytes, s);
  }

  /// BIP-340 verify (x-only key + message).
  bool bip340Verify(
    List<int> pubkeyX,
    List<int> msg,
    List<int> rBytes,
    Secp256k1Fr s,
  ) {
    if (pubkeyX.length != 32 || rBytes.length != 32) return false;
    final sFr = s;
    if (sFr.isZero()) return false;
    // Lift x-only key (even Y). fromBytes enforces x < p.
    late final Secp256k1Point p;
    try {
      Secp256k1Fp.fromBytes(pubkeyX);
      p = Secp256k1AffinePoint.liftX(pubkeyX).toCurve();
      Secp256k1Fp.fromBytes(rBytes);
    } catch (_) {
      return false;
    }
    final e = _frUnchecked(
      _taggedHash('BIP0340/challenge', [...rBytes, ...pubkeyX, ...msg]),
    );
    final rPt = Secp256k1Point.generator_ * sFr + p * (-e);
    if (rPt.isZero()) return false;
    if (rPt.isOdd) return false;
    return BytesUtils.bytesEqual(rPt.toXOnly(), rBytes);
  }
}

extension _XorBytes on List<int> {
  List<int> xorWith(List<int> other) {
    return List<int>.generate(length, (i) => this[i] ^ other[i]);
  }
}
