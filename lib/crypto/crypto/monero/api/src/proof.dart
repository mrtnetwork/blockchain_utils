import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// A Monero Bulletproofs+ proof (decoded form).
///
/// Wire blob layout (all integers little-endian):
/// ```text
/// m: u8 (1..=16) | V[m][32] | A A1 B R1 S1 D1 (6x32)
/// | n_lr: u8 (= 6 + log2(ceil_pow2(m))) | L[n_lr][32] | R[n_lr][32]
/// ```
class MoneroBpPlusProof {
  /// Commitments (1..16 points).
  final List<BuBytes> v;

  /// Commitment to bit vectors.
  final BuBytes a;

  /// Masked inner-product commitment.
  final BuBytes a1;

  /// Blinding commitment.
  final BuBytes b;

  /// Response scalars.
  final BuBytes r1;

  /// Response scalars.
  final BuBytes s1;

  /// Response scalars.
  final BuBytes d1;

  /// Fold points (left, `6 + logM` entries).
  final List<BuBytes> l;

  /// Fold points (right, `6 + logM` entries).
  final List<BuBytes> r;

  MoneroBpPlusProof({
    required List<List<int>> v,
    required List<int> a,
    required List<int> a1,
    required List<int> b,
    required List<int> r1,
    required List<int> s1,
    required List<int> d1,
    required List<List<int>> l,
    required List<List<int>> r,
  }) : v = v.map(BuBytes.from).toList().immutable,
       a = BuBytes.from(a),
       a1 = BuBytes.from(a1),
       b = BuBytes.from(b),
       r1 = BuBytes.from(r1),
       s1 = BuBytes.from(s1),
       d1 = BuBytes.from(d1),
       l = l.map(BuBytes.from).toList().immutable,
       r = r.map(BuBytes.from).toList().immutable {
    const op = 'MoneroBpPlusProof';
    if (v.isEmpty || v.length > 16) {
      throw CoreErrors.invalidOperationArguments(
        op,
        name: 'v',
        reason: 'need 1..16 commitments, got ${v.length}',
      );
    }
    var logM = 0;
    var mm = 1;
    while (mm < v.length) {
      mm <<= 1;
      logM++;
    }
    if (l.length != 6 + logM || r.length != 6 + logM) {
      throw CoreErrors.invalidOperationArguments(
        op,
        name: 'l/r',
        reason: 'need ${6 + logM} fold points for ${v.length} outputs',
      );
    }
  }

  /// Encode one proof blob.
  BuBytes toBlob() {
    final out = <int>[v.length];
    for (final x in v) {
      out.addAll(x);
    }
    out.addAll([...a, ...a1, ...b, ...r1, ...s1, ...d1]);
    out.add(l.length);
    for (final x in l) {
      out.addAll(x);
    }
    for (final x in r) {
      out.addAll(x);
    }
    return BuBytes(out);
  }

  /// Decode one proof blob (validates structure only).
  factory MoneroBpPlusProof.fromBlob(List<int> blob) {
    const op = 'MoneroBpPlusProof.fromBlob';
    var off = 0;
    List<int> take32() {
      if (off + 32 > blob.length) {
        throw CoreErrors.invalidOperationArguments(
          op,
          name: 'blob',
          reason: 'truncated at $off',
        );
      }
      final s = blob.sublist(off, off + 32);
      off += 32;
      return s;
    }

    if (blob.isEmpty) {
      throw CoreErrors.invalidOperationArguments(
        op,
        name: 'blob',
        reason: 'empty',
      );
    }
    final m = blob[off++];
    final v = [for (var i = 0; i < m; i++) take32()];
    final a = take32();
    final a1 = take32();
    final b = take32();
    final r1 = take32();
    final s1 = take32();
    final d1 = take32();
    if (off >= blob.length) {
      throw CoreErrors.invalidOperationArguments(
        op,
        name: 'blob',
        reason: 'truncated fold count',
      );
    }
    final nlr = blob[off++];
    final l = [for (var i = 0; i < nlr; i++) take32()];
    final r = [for (var i = 0; i < nlr; i++) take32()];
    if (off != blob.length) {
      throw CoreErrors.invalidOperationArguments(
        op,
        name: 'blob',
        reason: 'trailing bytes',
      );
    }
    return MoneroBpPlusProof(
      v: v,
      a: a,
      a1: a1,
      b: b,
      r1: r1,
      s1: s1,
      d1: d1,
      l: l,
      r: r,
    );
  }

  /// Encode a packed batch (`n: u32 LE | len: u32 LE | blob * n`).
  static BuBytes pack(List<MoneroBpPlusProof> proofs) {
    final out = <int>[];
    void u32(int v) {
      out.addAll([
        v & 0xff,
        (v >> 8) & 0xff,
        (v >> 16) & 0xff,
        (v >> 24) & 0xff,
      ]);
    }

    u32(proofs.length);
    for (final p in proofs) {
      final blob = p.toBlob();
      u32(blob.length);
      out.addAll(blob);
    }
    return BuBytes(out);
  }
}
