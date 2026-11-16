// Pure-Dart DKLs23 protocol core: digest oracles, wire codec, and the
// honest in-process session driver entry points.
//
// Mirrors `blockchain-utils/src/dkls23/` (`digest.rs` + `oracle.rs` tags,
// `shares.rs`, `sign.rs` round-3 equation, `refresh.rs`, `keys.rs`
// import/agg/verify, `codec.rs`, `session.rs` oneshots) using only library
// primitives (`ProjectiveECCPoint`, `ChaCha20Rng`, backend SHA-256 via
// [QuickCrypto]). Zero extra dependencies.
//
// Curve math lives in the suite engines ([DklsK1Engine]/[DklsR1Engine]
// behind [DklsEngine], the FROST precedent): each public flow below
// dispatches once on the curve and runs fully typed, with no `dynamic`
// values and no per-call curve branches.
//
// Honest-path scope (same as the Rust FFI drivers): all parties run
// in-process, so commit openings / Schnorr proofs / OT+mul chi always pass
// and are not re-verified here — the secret math (Feldman shares, Lagrange
// rescale, joint nonce, `s = k^-1(e + r·x)`, zero-sharing refresh) is exact.
// Deterministic under `(seeds, sid)` via the session RNG, matching the Rust
// mixing (`sha256(seed || sha256(sid))`); raw KAT bytes intentionally diverge
// (Rust draws extra commitment salts/proof nonces on the same streams),
// but every output is protocol-valid: framed blobs parse with the native
// codec, signatures verify under the native ECDSA verifiers and vice versa.
import 'dart:typed_data' show Endian;

import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/utils/numbers/utils/int_utils.dart';

import 'package:blockchain_utils/crypto/crypto/protocol/dkls23/engine/dkls_codec.dart';
import 'package:blockchain_utils/crypto/crypto/protocol/dkls23/engine/dkls_curve.dart';
import 'package:blockchain_utils/crypto/crypto/protocol/dkls23/engine/dkls_k1.dart';
import 'package:blockchain_utils/crypto/crypto/protocol/dkls23/engine/dkls_r1.dart';

/// Static entry point of the pure-Dart DKLs23 engine (the FROST precedent:
/// `FrostSecp256k1` / `FrostEd25519` behind `DartFrostApi`).
class DklsUtils {
  // ------------------------------------------------------------------
  // Digest oracles (`digest.rs` effect).
  // ------------------------------------------------------------------

  /// `tagged_hash(tag, components)` — byte-identical to the Rust oracle:
  /// `len(tag)||tag||len(c0)||c0||...`, each length a u64 BE.
  static List<int> taggedHash(List<int> tag, List<List<int>> components) {
    final h = QuickCrypto.sha256Instance();
    try {
      h.update(IntUtils.toBytes(tag.length, length: 8));
      h.update(tag);
      for (final c in components) {
        h.update(IntUtils.toBytes(c.length, length: 8));
        h.update(c);
      }
      return h.digest();
    } finally {
      h.clean();
    }
  }

  /// MGF-style expansion:
  /// `SHA256(len||tag||len||seed||len||ctx||counter)` (counter u32 BE).
  /// Matches Rust `tagged_expand`.
  static List<int> taggedExpand(
    List<int> tag,
    List<int> seed,
    List<int> context,
    int outLen,
  ) {
    final out = <int>[];
    var counter = 0;
    while (out.length < outLen) {
      final h = QuickCrypto.sha256Instance();
      try {
        h.update(IntUtils.toBytes(tag.length, length: 8));
        h.update(tag);
        h.update(IntUtils.toBytes(seed.length, length: 8));
        h.update(seed);
        h.update(IntUtils.toBytes(context.length, length: 8));
        h.update(context);
        h.update(IntUtils.toBytes(counter, length: 4));
        out.addAll(h.digest());
      } finally {
        h.clean();
      }
      counter = (counter + 1) & 0xFFFFFFFF;
    }
    return out.sublist(0, outLen);
  }

  static List<int> sha256(List<int> data) {
    return QuickCrypto.sha256Hash(data).toList();
  }

  // ------------------------------------------------------------------
  // Wire codec (`codec.rs` effect).
  // ------------------------------------------------------------------

  static void _writeU32(List<int> out, int v) {
    out.addAll(IntUtils.toBytes(v, length: 4, byteOrder: Endian.little));
  }

  static int _readU32(List<int> b, int off) {
    return IntUtils.fromBytes(
      b,
      offset: off,
      length: 4,
      byteOrder: Endian.little,
    );
  }

  static List<int> keyshareBytes(DklsProtocolShare sh) {
    final out = <int>[];
    _writeU32(out, sh.party);
    _writeU32(out, sh.n);
    _writeU32(out, sh.t ?? 0);
    _writeU32(out, sh.curve.id);
    out.addAll(sh.x);
    out.addAll(sh.pk);
    for (final s in sh.shares) {
      out.addAll(s);
    }
    return out;
  }

  static DklsProtocolShare parseKeyshare(List<int> raw) {
    const op = 'DklsUtils.parseKeyshare';
    if (raw.length < 16 + 32 + 33) {
      throw CoreErrors.invalidOperationArguments(
        op,
        name: 'share',
        reason: 'short share record.',
      );
    }
    final party = _readU32(raw, 0);
    final n = _readU32(raw, 4);
    final t = _readU32(raw, 8);
    final curve = DklsProtocolCurveX.fromId(_readU32(raw, 12));
    if (raw.length != 16 + 32 + 33 + n * 33) {
      throw CoreErrors.invalidOperationArguments(
        op,
        name: 'share',
        reason: 'share record length mismatch.',
      );
    }
    var at = 16;
    final x = raw.sublist(at, at + 32);
    at += 32;
    final pk = raw.sublist(at, at + 33);
    at += 33;
    final shares = <List<int>>[];
    for (var i = 0; i < n; i++) {
      shares.add(raw.sublist(at, at + 33));
      at += 33;
    }
    return DklsProtocolShare(
      party: party,
      n: n,
      t: t == 0 ? null : t,
      curve: curve,
      x: x,
      pk: pk,
      shares: shares,
    );
  }

  /// Frame items as `[len:u32 LE] ++ bytes` concatenations.
  static List<int> frame(List<List<int>> items) {
    final out = <int>[];
    for (final it in items) {
      _writeU32(out, it.length);
      out.addAll(it);
    }
    return out;
  }

  static List<List<int>> unframe(List<int> blob) {
    const op = 'DklsUtils.unframe';
    final out = <List<int>>[];
    var at = 0;
    while (at < blob.length) {
      if (at + 4 > blob.length) {
        throw CoreErrors.invalidOperationArguments(
          op,
          name: 'blob',
          reason: 'truncated frame header.',
        );
      }
      final len = _readU32(blob, at);
      at += 4;
      if (at + len > blob.length) {
        throw CoreErrors.invalidOperationArguments(
          op,
          name: 'blob',
          reason: 'truncated frame body.',
        );
      }
      out.add(blob.sublist(at, at + len));
      at += len;
    }
    return out;
  }

  // ------------------------------------------------------------------
  // Session flows: one curve dispatch per entry, then fully typed
  // engine math (`session.rs` oneshots effect).
  // ------------------------------------------------------------------

  static void _checkQuorumCurve(
    List<DklsProtocolShare> shares,
    DklsProtocolCurve curve,
    String op,
  ) {
    for (final sh in shares) {
      if (sh.curve != curve) {
        throw CoreErrors.invalidOperationArguments(
          op,
          name: 'shares',
          reason: 'mixed quorum records.',
        );
      }
    }
  }

  /// Full DKG: `n` parties, threshold `t`, under `sid` — returns key shares
  /// in party order (Rust `dkg_oneshot` honest path).
  static List<DklsProtocolShare> dkg({
    required DklsProtocolCurve curve,
    required List<int> sid,
    required int n,
    required int t,
    required List<List<int>> seeds,
  }) {
    return switch (curve) {
      DklsProtocolCurve.k1 => const DklsK1Engine().dkg(
        curve: curve,
        sid: sid,
        n: n,
        t: t,
        seeds: seeds,
      ),
      DklsProtocolCurve.r1 => const DklsR1Engine().dkg(
        curve: curve,
        sid: sid,
        n: n,
        t: t,
        seeds: seeds,
      ),
    };
  }

  /// Threshold sign over a 32-byte hash (Rust `sign_oneshot` honest path):
  /// Lagrange-rescales the subset key shares to additive (`x = Σ λ·σ`)
  /// while fresh nonces stay purely additive; `s = k^-1(e + r·x)`, low-S.
  static List<int> sign({
    required List<DklsProtocolShare> shares,
    required List<int> sid,
    required List<int> msgHash,
    required List<List<int>> seeds,
  }) {
    const op = 'DklsUtils.sign';
    if (shares.isEmpty) {
      throw CoreErrors.invalidOperationArguments(
        op,
        name: 'shares',
        reason: 'at least 2 signing shares required.',
      );
    }
    final curve = shares.first.curve;
    _checkQuorumCurve(shares, curve, op);
    return switch (curve) {
      DklsProtocolCurve.k1 => const DklsK1Engine().sign(
        shares: shares,
        sid: sid,
        msgHash: msgHash,
        seeds: seeds,
      ),
      DklsProtocolCurve.r1 => const DklsR1Engine().sign(
        shares: shares,
        sid: sid,
        msgHash: msgHash,
        seeds: seeds,
      ),
    };
  }

  /// Additive import (Rust `import_secrets`): each secret becomes party
  /// `i`'s share pre-divided by its full-set Lagrange weight, group key =
  /// Σ G·s_i.
  static List<DklsProtocolShare> importSecrets({
    required DklsProtocolCurve curve,
    required List<List<int>> secrets,
  }) {
    return switch (curve) {
      DklsProtocolCurve.k1 => const DklsK1Engine().importSecrets(
        curve: curve,
        secrets: secrets,
      ),
      DklsProtocolCurve.r1 => const DklsR1Engine().importSecrets(
        curve: curve,
        secrets: secrets,
      ),
    };
  }

  /// Key refresh (Rust `refresh_oneshot` honest path): zero-constant-term
  /// delta rows, column sums applied; group key unchanged.
  static List<DklsProtocolShare> refresh({
    required List<DklsProtocolShare> olds,
    required List<int> sid,
    required List<List<int>> seeds,
  }) {
    const op = 'DklsUtils.refresh';
    if (olds.isEmpty) {
      throw CoreErrors.invalidOperationArguments(
        op,
        name: 'shares',
        reason: 'empty quorum.',
      );
    }
    final curve = olds.first.curve;
    _checkQuorumCurve(olds, curve, op);
    return switch (curve) {
      DklsProtocolCurve.k1 => const DklsK1Engine().refresh(
        olds: olds,
        sid: sid,
        seeds: seeds,
      ),
      DklsProtocolCurve.r1 => const DklsR1Engine().refresh(
        olds: olds,
        sid: sid,
        seeds: seeds,
      ),
    };
  }

  /// Standard ECDSA verify over a 32-byte hash (Rust `verify_hash` effect).
  static bool verify({
    required DklsProtocolCurve curve,
    required List<int> groupPk,
    required List<int> msgHash,
    required List<int> signature,
  }) {
    return switch (curve) {
      DklsProtocolCurve.k1 => const DklsK1Engine().verify(
        groupPk: groupPk,
        msgHash: msgHash,
        signature: signature,
      ),
      DklsProtocolCurve.r1 => const DklsR1Engine().verify(
        groupPk: groupPk,
        msgHash: msgHash,
        signature: signature,
      ),
    };
  }

  /// Aggregate member keys by point addition (Rust `agg_public_keys`
  /// effect).
  static List<int> agg({
    required DklsProtocolCurve curve,
    required List<List<int>> members,
  }) {
    return switch (curve) {
      DklsProtocolCurve.k1 => const DklsK1Engine().agg(members: members),
      DklsProtocolCurve.r1 => const DklsR1Engine().agg(members: members),
    };
  }

  /// x-only form (Rust `group_x_only` effect).
  static List<int> xOnly({
    required DklsProtocolCurve curve,
    required List<int> groupPk,
  }) {
    return switch (curve) {
      DklsProtocolCurve.k1 => const DklsK1Engine().xOnly(groupPk: groupPk),
      DklsProtocolCurve.r1 => const DklsR1Engine().xOnly(groupPk: groupPk),
    };
  }
}
