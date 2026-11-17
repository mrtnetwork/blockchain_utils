// Suite-typed DKLs23 protocol engine (the FROST precedent:
// `FrostSecp256k1` / `FrostEd25519` behind `DartFrostApi`).
//
// `DklsK1Engine` / `DklsR1Engine` map the suite constructors; every flow
// below (DKG, sign, import, refresh, verify, aggregate) is written once
// against the shared [CryptoField]/[WeierstrassPoint] operator surface,
// so no `dynamic` values and no per-call curve dispatch appear anywhere.

import 'package:blockchain_utils/crypto/crypto/group/core/field.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/crypto/crypto/group/weierstrass/weierstrass.dart';
import 'package:blockchain_utils/crypto/crypto/prng/src/chacha20.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/utils/binary/src/utils.dart';
import 'package:blockchain_utils/utils/numbers/utils/int_utils.dart';

import 'package:blockchain_utils/crypto/crypto/protocol/dkls23/engine/dkls_codec.dart';
import 'package:blockchain_utils/crypto/crypto/protocol/dkls23/engine/dkls_curve.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// Typed DKLs23 suite engine.
///
/// `S` is the suite scalar field ([Secp256k1Fr]/[Secp256r1Fr]), `P` the
/// suite point ([Secp256k1Point]/[Secp256r1Point]). Participant ids are
/// plain [int] counters (1-based, `u32` wire range — the only range the
/// codec and the Rust `party_id` support); scalar values cross method
/// boundaries as field elements, never as `dynamic`, and no [BigInt]
/// appears anywhere on this path.
abstract class DklsEngine<
  S extends WeierstrassScalar<S>,
  B extends CryptoField<B>,
  P extends WeierstrassPoint<S, B, P>
> {
  const DklsEngine();

  // ------------------------------------------------------------------
  // Suite primitives (one tiny mapping per curve).
  // ------------------------------------------------------------------

  /// Strict 32-byte parse into the suite field, or null when out of range
  /// (Rust `from_bytes_be` rejection).
  S? scalarFromBe(List<int> bytes);

  /// Reducing 32-byte parse (never rejects, Rust `from_bytes_mod_order`).
  S scalarMod(List<int> bytes);

  /// Canonical 32-byte big-endian encoding.
  List<int> scalarToBytes(S f) => List<int>.from(f.toBytes());

  S scalarZero();

  S scalarOne();

  /// Strict parse of a participant id (1-based, `u32` wire range).
  S scalarFromInt(int v) {
    if (v <= 0 || v > 0xFFFFFFFF) {
      throw CoreErrors.invalidOperationArguments(
        'DklsEngine.scalarFromInt',
        name: 'v',
        reason: 'identifier out of u32 range.',
      );
    }
    final f = scalarFromBe(IntUtils.toBytes(v, length: 32));
    if (f == null) {
      throw CoreErrors.invalidOperationArguments(
        'DklsEngine.scalarFromInt',
        name: 'v',
        reason: 'scalar out of range.',
      );
    }
    return f;
  }

  S scalarInv(S a, String op) {
    final inv = a.invert();
    if (inv == null) {
      throw CoreErrors.invalidOperationArguments(
        op,
        name: 'scalar',
        reason: 'Zero scalar has no inverse.',
      );
    }
    return inv;
  }

  P identity();

  P baseMult(S s);

  P pointFromBytes(List<int> bytes);

  List<int> pointToCompressed(P p);

  /// x-coordinate bytes (32 BE) of a non-identity point.
  List<int> pointXBytes(P p);

  // ------------------------------------------------------------------
  // Shared flows (written once, fully typed).
  // ------------------------------------------------------------------

  /// Lagrange coefficient at zero over `ids` for `xi` (Rust
  /// `lagrange_at_zero` + `check_ids` effect: non-empty set, ids in
  /// 1..=u32max, no duplicates, `xi` a member).
  S lagrangeAtZero(List<int> ids, int xi) {
    const op = 'DklsUtils.lagrangeAtZero';
    if (ids.isEmpty || !ids.contains(xi)) {
      throw CoreErrors.invalidOperationArguments(
        op,
        name: 'xi',
        reason: 'identifier not in id set.',
      );
    }
    final seen = <int>{};
    for (final v in ids) {
      if (v <= 0 || v > 0xFFFFFFFF || !seen.add(v)) {
        throw CoreErrors.invalidOperationArguments(
          op,
          name: 'ids',
          reason: 'duplicate, zero, or out-of-range identifier.',
        );
      }
    }
    try {
      var num = scalarOne();
      var den = scalarOne();
      final xiF = scalarFromInt(xi);
      for (final xj in ids) {
        if (xj == xi) continue;
        final xjF = scalarFromInt(xj);
        num = num * xjF;
        den = den * (xjF - xiF);
      }
      return num * scalarInv(den, op);
    } catch (e) {
      if (e is BuError) rethrow;
      throw CoreErrors.invalidOperationArguments(
        op,
        name: 'ids',
        reason: 'invalid identifier set.',
      );
    }
  }

  /// Horner polynomial evaluation (Rust `eval_poly`).
  S evalPoly(List<S> coeffs, S x) {
    var v = scalarZero();
    for (var i = coeffs.length - 1; i >= 0; i--) {
      v = v * x + coeffs[i];
    }
    return v;
  }

  List<int> _sessionSeed(List<int> seed32, List<int> sid) {
    return QuickCrypto.sha256Hash([...seed32, ...QuickCrypto.sha256Hash(sid)]);
  }

  ChaCha20Rng _sessionRng(List<int> seed32, List<int> sid) {
    return ChaCha20Rng(_sessionSeed(seed32, sid));
  }

  List<int> _fill(ChaCha20Rng rng, int n) => rng.nextBytes(n).toList();

  /// Canonical nonzero scalar draw (Rust `from_bytes_be` + nonzero loop).
  S _sampleScalar(ChaCha20Rng rng) {
    while (true) {
      final v = scalarFromBe(_fill(rng, 32));
      if (v != null && !v.isZero()) return v;
    }
  }

  void _checkSid(List<int> sid, String op) {
    if (sid.isEmpty) {
      throw CoreErrors.invalidOperationArguments(
        op,
        name: 'sid',
        reason: 'session id must not be empty.',
      );
    }
  }

  void _checkSeeds(List<List<int>> seeds, int n, String op) {
    if (seeds.length != n) {
      throw CoreErrors.invalidOperationArguments(
        op,
        name: 'seeds',
        reason: 'need one 32-byte seed per party.',
      );
    }
    for (final s in seeds) {
      if (s.length != 32) {
        throw CoreErrors.invalidOperationArguments(
          op,
          name: 'seeds',
          reason: 'each seed must hold 32 bytes.',
        );
      }
    }
  }

  /// Full DKG: `n` parties, threshold `t`, under `sid` — returns key shares
  /// in party order (Rust `dkg_oneshot` honest path).
  List<DklsProtocolShare> dkg({
    required DklsProtocolCurve curve,
    required List<int> sid,
    required int n,
    required int t,
    required List<List<int>> seeds,
  }) {
    const op = 'DklsUtils.dkg';
    if (n < 2 || t < 2 || t > n) {
      throw CoreErrors.invalidOperationArguments(
        op,
        name: 'quorum',
        reason: 'need 2 <= t <= n (got t=$t, n=$n).',
      );
    }
    _checkSid(sid, op);
    _checkSeeds(seeds, n, op);
    // One Feldman polynomial per dealer (degree t-1, all coeffs nonzero
    // like Rust).
    final polys = <List<S>>[];
    for (var j = 0; j < n; j++) {
      final rng = _sessionRng(seeds[j], sid);
      final coeffs = <S>[];
      for (var k = 0; k < t; k++) {
        coeffs.add(_sampleScalar(rng));
      }
      _sampleScalar(rng); // Schnorr nonce slot (honest path discards proof)
      _fill(rng, 32); // rid contribution slot
      _fill(rng, 64); // commitment salt slot (keeps stream shape near Rust)
      polys.add(coeffs);
    }
    // Column shares x_i = Σ_j f_j(id_i); member keys y_i = G·x_i.
    final xs = <S>[];
    final zero = scalarZero();
    for (var i = 0; i < n; i++) {
      var acc = zero;
      final id = scalarFromInt(i + 1);
      for (final poly in polys) {
        var v = zero;
        for (var k = poly.length - 1; k >= 0; k--) {
          v = v * id + poly[k];
        }
        acc = acc + v;
      }
      if (acc.isZero()) {
        throw CoreErrors.cryptoFailed(op, reason: 'zero column share.');
      }
      xs.add(acc);
    }
    P pkPt = identity();
    for (final poly in polys) {
      pkPt = pkPt + baseMult(poly[0]);
    }
    if (pkPt.isZero()) {
      throw CoreErrors.cryptoFailed(op, reason: 'identity group key.');
    }
    final pk = pointToCompressed(pkPt);
    final members = [for (final x in xs) pointToCompressed(baseMult(x))];
    return [
      for (var i = 0; i < n; i++)
        DklsProtocolShare(
          party: i,
          n: n,
          t: t,
          curve: curve,
          x: scalarToBytes(xs[i]),
          pk: pk,
          shares: members,
        ),
    ];
  }

  /// Threshold sign over a 32-byte hash (Rust `sign_oneshot` honest path):
  /// Lagrange-rescales the subset key shares to additive (`x = Σ λ·σ`)
  /// while fresh nonces stay purely additive; `s = k^-1(e + r·x)`, low-S.
  List<int> sign({
    required List<DklsProtocolShare> shares,
    required List<int> sid,
    required List<int> msgHash,
    required List<List<int>> seeds,
  }) {
    const op = 'DklsUtils.sign';
    final n = shares.length;
    _checkSid(sid, op);
    if (n < 2) {
      throw CoreErrors.invalidOperationArguments(
        op,
        name: 'shares',
        reason: 'at least 2 signing shares required.',
      );
    }
    if (msgHash.length != 32) {
      throw CoreErrors.invalidOperationArguments(
        op,
        name: 'msgHash',
        reason: 'message hash must hold 32 bytes.',
      );
    }
    _checkSeeds(seeds, n, op);
    final ids = [for (final sh in shares) sh.party + 1];
    // Rescaled additive key shares.
    final xs = <S>[];
    for (final sh in shares) {
      final sigma = scalarFromBe(sh.x);
      if (sigma == null || sigma.isZero()) {
        throw CoreErrors.invalidOperationArguments(
          op,
          name: 'shares',
          reason: 'corrupt share scalar.',
        );
      }
      xs.add(lagrangeAtZero(ids, sh.party + 1) * sigma);
    }
    // Joint nonce.
    final ks = <S>[];
    for (var pos = 0; pos < n; pos++) {
      final rng = _sessionRng(seeds[pos], sid);
      ks.add(_sampleScalar(rng));
      _fill(rng, 64); // rebind salt slot (stream shape near Rust)
    }
    P rPt = identity();
    for (final k in ks) {
      rPt = rPt + baseMult(k);
    }
    if (rPt.isZero()) {
      throw CoreErrors.cryptoFailed(op, reason: 'identity nonce.');
    }
    final r = scalarMod(pointXBytes(rPt));
    if (r.isZero()) {
      throw CoreErrors.cryptoFailed(op, reason: 'zero r.');
    }
    var k = scalarZero();
    for (final v in ks) {
      k = k + v;
    }
    final kInv = scalarInv(k, op);
    final nInv = scalarInv(scalarFromInt(n), op);
    final kPart = kInv * nInv;
    final kr = kInv * r;
    final e = scalarMod(msgHash);
    var s = scalarZero();
    for (final x in xs) {
      s = s + (kPart * e + kr * x);
    }
    if (s.isZero()) {
      throw CoreErrors.cryptoFailed(op, reason: 'zero s.');
    }
    final negS = -s;
    if (BytesUtils.compareBytes(negS.toBytes(), s.toBytes()) < 0) {
      s = negS;
    }
    return [...r.toBytes(), ...s.toBytes()];
  }

  /// Additive import (Rust `import_secrets`): each secret becomes party
  /// `i`'s share pre-divided by its full-set Lagrange weight, group key =
  /// Σ G·s_i.
  List<DklsProtocolShare> importSecrets({
    required DklsProtocolCurve curve,
    required List<List<int>> secrets,
  }) {
    const op = 'DklsUtils.importSecrets';
    final n = secrets.length;
    if (n < 2) {
      throw CoreErrors.invalidOperationArguments(
        op,
        name: 'secrets',
        reason: 'at least 2 secrets required.',
      );
    }
    final xs = <S>[];
    for (final s in secrets) {
      final v = scalarFromBe(s);
      if (v == null || v.isZero()) {
        throw CoreErrors.invalidOperationArguments(
          op,
          name: 'secrets',
          reason: 'bad secret scalar.',
        );
      }
      xs.add(v);
    }
    final members = [for (final x in xs) pointToCompressed(baseMult(x))];
    P pkPt = identity();
    for (final m in members) {
      pkPt = pkPt + pointFromBytes(m);
    }
    if (pkPt.isZero()) {
      throw CoreErrors.cryptoFailed(op, reason: 'identity group key.');
    }
    final pk = pointToCompressed(pkPt);
    final ids = [for (var i = 0; i < n; i++) i + 1];
    return [
      for (var i = 0; i < n; i++)
        DklsProtocolShare(
          party: i,
          n: n,
          t: n,
          curve: curve,
          x: scalarToBytes(
            xs[i] *
                scalarInv(
                  lagrangeAtZero(ids, ids[i]),
                  'DklsUtils.importSecrets',
                ),
          ),
          pk: pk,
          shares: members,
        ),
    ];
  }

  /// Key refresh (Rust `refresh_oneshot` honest path): zero-constant-term
  /// delta rows, column sums applied; group key unchanged.
  List<DklsProtocolShare> refresh({
    required List<DklsProtocolShare> olds,
    required List<int> sid,
    required List<List<int>> seeds,
  }) {
    const op = 'DklsUtils.refresh';
    final n = olds.length;
    _checkSid(sid, op);
    if (n == 0) {
      throw CoreErrors.invalidOperationArguments(
        op,
        name: 'shares',
        reason: 'empty quorum.',
      );
    }
    _checkSeeds(seeds, n, op);
    final t = olds.first.t ?? n;
    // Delta rows.
    final rows = <List<S>>[];
    for (var j = 0; j < n; j++) {
      final rng = _sessionRng(seeds[j], sid);
      final coeffs = <S>[scalarZero()];
      for (var k = 1; k < t; k++) {
        coeffs.add(_sampleScalar(rng));
      }
      rows.add([
        for (var l = 0; l < n; l++) evalPoly(coeffs, scalarFromInt(l + 1)),
      ]);
    }
    return [
      for (var i = 0; i < n; i++)
        () {
          var add = scalarZero();
          for (final row in rows) {
            add = add + row[i];
          }
          final oldX = scalarFromBe(olds[i].x)!;
          final newX = oldX + add;
          if (newX.isZero()) {
            throw CoreErrors.cryptoFailed(op, reason: 'zero refreshed share.');
          }
          // Shift every member key by its column delta.
          final newMembers = <List<int>>[];
          for (var l = 0; l < n; l++) {
            var colAdd = scalarZero();
            for (final row in rows) {
              colAdd = colAdd + row[l];
            }
            final cur = pointFromBytes(olds[i].shares[l]);
            newMembers.add(pointToCompressed(cur + baseMult(colAdd)));
          }
          return DklsProtocolShare(
            party: olds[i].party,
            n: olds[i].n,
            t: olds[i].t,
            curve: olds[i].curve,
            x: scalarToBytes(newX),
            pk: olds[i].pk,
            shares: newMembers,
          );
        }(),
    ];
  }

  /// Standard ECDSA verify over a 32-byte hash (Rust `verify_hash` effect).
  bool verify({
    required List<int> groupPk,
    required List<int> msgHash,
    required List<int> signature,
  }) {
    if (groupPk.length != 33 ||
        msgHash.length != 32 ||
        signature.length != 64) {
      throw CoreErrors.invalidOperationArguments(
        'DklsUtils.verify',
        name: 'inputs',
        reason: 'need 33-byte group key, 32-byte hash, 64-byte signature.',
      );
    }
    final r = scalarFromBe(signature.sublist(0, 32));
    final s = scalarFromBe(signature.sublist(32));
    if (r == null || s == null || r.isZero() || s.isZero()) {
      return false;
    }
    final pkPt = pointFromBytes(groupPk);
    if (pkPt.isZero()) return false;
    final e = scalarMod(msgHash);
    final sInv = scalarInv(s, 'DklsUtils.verify');
    final u1 = e * sInv;
    final u2 = r * sInv;
    final P p = baseMult(u1) + (pkPt * u2);
    if (p.isZero()) return false;
    return scalarMod(pointXBytes(p)) == r;
  }

  /// Aggregate member keys by point addition (Rust `agg_public_keys`
  /// effect).
  List<int> agg({required List<List<int>> members}) {
    const op = 'DklsUtils.agg';
    if (members.length < 2) {
      throw CoreErrors.invalidOperationArguments(
        op,
        name: 'members',
        reason: 'at least 2 member keys required.',
      );
    }
    P acc = identity();
    for (final m in members) {
      final pt = pointFromBytes(m);
      if (pt.isZero()) {
        throw CoreErrors.invalidOperationArguments(
          op,
          name: 'members',
          reason: 'identity member key.',
        );
      }
      acc = acc + pt;
    }
    if (acc.isZero()) {
      throw CoreErrors.cryptoFailed(op, reason: 'identity aggregate.');
    }
    return pointToCompressed(acc);
  }

  /// x-only form (Rust `group_x_only` effect).
  List<int> xOnly({required List<int> groupPk}) {
    final pt = pointFromBytes(groupPk);
    if (pt.isZero()) {
      throw CoreErrors.invalidOperationArguments(
        'DklsUtils.xOnly',
        name: 'groupPk',
        reason: 'identity group key.',
      );
    }
    return pointXBytes(pt);
  }
}
