import 'package:blockchain_utils/crypto/crypto/group/edwards_limb/fields.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/crypto/crypto/group/edwards_limb/points.dart';
import 'package:blockchain_utils/crypto/crypto/group/extended/monero.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/utils/numbers/fixed/src/u64/u64.dart';

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// Byte-level Ed25519 group operations on the limb backend
/// ([EdwardsLimbPoint]/[Ed25519Fr]): the BigInt-free replacement for the
/// ref10 [CryptoOps]/`Ed25519Utils` combination.
///
/// Conventions (identical to the code being replaced):
/// * scalars are 32-byte little-endian; `sc*` CT entry points require
///   canonical scalars (`< L`) and throw otherwise (fail-closed);
/// * `scMulSub(a, b, c)` returns `c − a·b` and `scMulAdd(a, b, c)` returns
///   `a·b + c` (matching the old `CryptoOps` formulas);
/// * `*PrecompPointVar` / `*BasePointVar` multiscalar helpers are vartime
///   (public inputs: verify paths), ported 1:1 from the old slide-based
///   algorithms.
class EdwardsLimbOps {
  EdwardsLimbOps._();

  // ---------------------------------------------------------------- scalars

  static Ed25519Fr _fr(List<int> s, String op) {
    try {
      return Ed25519Fr.fromBytes(s);
    } on BuError {
      throw CoreErrors.invalidOperationArguments(
        op,
        name: 'scalar',
        reason: 'Invalid canonical scalar bytes.',
      );
    }
  }

  /// True iff [s] is a canonical (< L) 32-byte scalar, else false.
  static bool scCheck(List<int> s) {
    if (s.length != 32) return false;
    try {
      Ed25519Fr.fromBytes(s);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// True iff any of the 32 bytes is non-zero (length-checked).
  /// Same semantics as the old byte-OR check: non-canonical inputs with a
  /// non-zero byte still report true.
  static bool scIsNonZero(List<int> s) {
    if (s.length != 32) return false;
    var acc = 0;
    for (var i = 0; i < 32; i++) {
      acc |= s[i];
    }
    return acc != 0;
  }

  /// Reduces an arbitrary 32-byte LE integer mod L.
  static BuBytes scReduce32(List<int> s) {
    if (s.length != 32) {
      throw CoreErrors.invalidOperationArguments(
        'scReduce32',
        name: 'scalar',
        reason: 'Invalid length.',
      );
    }
    return Ed25519Fr.fromBytes64([...s, ...List.filled(32, 0)]).toBytes();
  }

  /// Reduces a 64-byte LE integer mod L.
  static BuBytes scReduce64(List<int> s) {
    if (s.length != 64) {
      throw CoreErrors.invalidOperationArguments(
        'scReduce64',
        name: 'scalar',
        reason: 'Invalid length.',
      );
    }
    return Ed25519Fr.fromBytes64(s).toBytes();
  }

  /// Reduces an arbitrary-length little-endian integer mod L (Horner,
  /// base-256 field fold). Exact for any input length.
  static BuBytes scReduceLong(List<int> s) {
    if (s.isEmpty) {
      throw CoreErrors.invalidOperationArguments(
        'scReduceLong',
        name: 'scalar',
        reason: 'Invalid length.',
      );
    }
    var acc = Ed25519Fr.zero;
    var pow256 = Ed25519Fr.one;
    final base = Ed25519Fr.from(Uint64(256));
    for (final byte in s) {
      acc = acc + Ed25519Fr.from(Uint64(byte & 0xFF)) * pow256;
      pow256 = pow256 * base;
    }
    return acc.toBytes();
  }

  /// Fr-level scalar cores: live-object arithmetic, no bytes cross here.
  /// The bytes `sc*` entry points decode via [_fr], run these, and encode
  /// on the way out (API boundary only).
  static Ed25519Fr scAddField(Ed25519Fr a, Ed25519Fr b) => a + b;

  static Ed25519Fr scSubField(Ed25519Fr a, Ed25519Fr b) => a - b;

  static Ed25519Fr scMulField(Ed25519Fr a, Ed25519Fr b) => a * b;

  static Ed25519Fr scNegField(Ed25519Fr s) => -s;

  /// Returns `a·b + c`.
  static Ed25519Fr scMulAddField(Ed25519Fr a, Ed25519Fr b, Ed25519Fr c) =>
      a * b + c;

  /// Returns `c − a·b` (matches the legacy formula).
  static Ed25519Fr scMulSubField(Ed25519Fr a, Ed25519Fr b, Ed25519Fr c) =>
      c - a * b;

  static BuBytes scAdd(List<int> a, List<int> b) =>
      scAddField(_fr(a, 'scAdd'), _fr(b, 'scAdd')).toBytes();

  static BuBytes scSub(List<int> a, List<int> b) =>
      scSubField(_fr(a, 'scSub'), _fr(b, 'scSub')).toBytes();

  static BuBytes scMul(List<int> a, List<int> b) =>
      scMulField(_fr(a, 'scMul'), _fr(b, 'scMul')).toBytes();

  static BuBytes scNeg(List<int> s) => scNegField(_fr(s, 'scNeg')).toBytes();

  /// Returns `a·b + c`.
  static BuBytes scMulAdd(List<int> a, List<int> b, List<int> c) =>
      scMulAddField(
        _fr(a, 'scMulAdd'),
        _fr(b, 'scMulAdd'),
        _fr(c, 'scMulAdd'),
      ).toBytes();

  /// Returns `c − a·b` (matches the legacy formula).
  static BuBytes scMulSub(List<int> a, List<int> b, List<int> c) =>
      scMulSubField(
        _fr(a, 'scMulSub'),
        _fr(b, 'scMulSub'),
        _fr(c, 'scMulSub'),
      ).toBytes();

  // ------------------------------------------------------------------ points

  static EdwardsLimbPoint _dec(List<int> p, String op) {
    try {
      return EdwardsLimbPoint.fromBytes(p);
    } catch (_) {
      throw CoreErrors.invalidOperationArguments(
        op,
        name: 'point',
        reason: 'Invalid point bytes.',
      );
    }
  }

  /// Decodes a point, or null on invalid bytes.
  static EdwardsLimbPoint? maybeAsPoint(List<int> point) {
    try {
      return EdwardsLimbPoint.fromBytes(point);
    } catch (_) {
      return null;
    }
  }

  static EdwardsLimbPoint asPoint(List<int> point) => _dec(point, 'asPoint');

  /// Point-level core: scalar (bytes) times generator.
  static EdwardsLimbPoint multBasePoint(List<int> scalar) =>
      EdwardsLimbPoint.generator_ * _fr(scalar, 'multBase');

  static BuBytes multBase(List<int> scalar) => multBasePoint(scalar).toBytes();

  /// Point-level core: reduced scalar (bytes) times generator.
  static EdwardsLimbPoint reduceMultBasePoint(List<int> scalar) =>
      EdwardsLimbPoint.generator_ * Ed25519Fr.fromBytes(scReduce32(scalar));

  static BuBytes reduceMultBase(List<int> scalar) =>
      reduceMultBasePoint(scalar).toBytes();

  /// Point-level core: scalar (bytes) times live point.
  static EdwardsLimbPoint multPoint(List<int> scalar, EdwardsLimbPoint point) =>
      point * _fr(scalar, 'mult');

  static BuBytes mult(List<int> scalar, List<int> point) =>
      multPoint(scalar, _dec(point, 'mult')).toBytes();

  /// Point-level core: live point addition.
  static EdwardsLimbPoint addPoints(EdwardsLimbPoint a, EdwardsLimbPoint b) =>
      a + b;

  static BuBytes add(List<int> a, List<int> b) =>
      addPoints(_dec(a, 'add'), _dec(b, 'add')).toBytes();

  /// Point-level core: live point subtraction.
  static EdwardsLimbPoint subPoints(EdwardsLimbPoint a, EdwardsLimbPoint b) =>
      a + (-b);

  static BuBytes sub(List<int> a, List<int> b) =>
      subPoints(_dec(a, 'sub'), _dec(b, 'sub')).toBytes();

  static BuBytes neg(List<int> point) {
    // Edwards compressed: (x, y) -> (-x, y) — flip sign bit.
    // Validate first: negating an invalid encoding must throw.
    _dec(point, 'neg');
    final out = BuBytes.fill(32, 0);
    for (var i = 0; i < 32 && i < point.length; i++) {
      out[i] = point[i];
    }
    out[31] ^= 0x80;
    return out;
  }

  static BuBytes generator() => EdwardsLimbPoint.generator_.toBytes();

  static BuBytes identity() => EdwardsLimbPoint.identity_.toBytes();

  /// Point-level core: cofactor clearing on a live point.
  static EdwardsLimbPoint mul8Point(EdwardsLimbPoint point) =>
      point.double().double().double();

  static BuBytes mul8(List<int> point) {
    return mul8Point(_dec(point, 'mul8')).toBytes();
  }

  /// Point-level core: 8 * (s * P) on live points, no intermediate encoding.
  /// Fused `mult` + `mul8`: avoids the `toBytes` -> `fromBytes` round-trip
  /// (invert + sqrt decode) of `mul8(mult(s, P))`.
  static EdwardsLimbPoint mul8MultPoint(
    List<int> scalar,
    EdwardsLimbPoint point,
  ) => mul8Point(multPoint(scalar, point));

  static BuBytes mul8Mult(List<int> scalar, List<int> point) =>
      mul8MultPoint(scalar, _dec(point, 'mul8Mult')).toBytes();

  /// Point-level core: `s1·p1 + s2·p2` on live points (straight-line mults).
  static EdwardsLimbPoint doubleScalarMultPoints(
    List<int> s1,
    EdwardsLimbPoint p1,
    List<int> s2,
    EdwardsLimbPoint p2,
  ) {
    final a = p1 * _fr(s1, 'doubleScalarMult');
    final b = p2 * _fr(s2, 'doubleScalarMult');
    return a + b;
  }

  /// `s1·p1 + s2·p2` (straight-line ladder mults).
  static BuBytes doubleScalarMult(
    List<int> s1,
    List<int> p1,
    List<int> s2,
    List<int> p2,
  ) {
    return doubleScalarMultPoints(
      s1,
      _dec(p1, 'doubleScalarMult'),
      s2,
      _dec(p2, 'doubleScalarMult'),
    ).toBytes();
  }

  static BuBytes secretKeyToPubKey(List<int> secretKey) => multBase(secretKey);

  /// Point-level core: Monero Elligator map from hashed bytes to live point.
  /// Vartime on the public hashed input.
  static EdwardsLimbPoint hashToPointPoint(List<int> data) =>
      MoneroH2C.geFromFeFromBytesVartime(data);

  /// Maps 32 hashed bytes to a compressed point (Monero Elligator map).
  /// Vartime on the public hashed input.
  static BuBytes hashToPoint(List<int> data) =>
      hashToPointPoint(data).toBytes();

  // ------------------------------------------------- vartime multiscalar --

  /// Reference slide (ref10): rewrites scalar bytes into signed digits.
  static void slide(List<int> r, List<int> a) {
    int i, b, k;
    for (i = 0; i < 256; ++i) {
      r[i] = 1 & (a[i >> 3] >> (i & 7));
    }
    for (i = 0; i < 256; ++i) {
      if (r[i] != 0) {
        for (b = 1; b <= 6 && i + b < 256; ++b) {
          if (r[i + b] != 0) {
            if (r[i] + (r[i + b] << b) <= 15) {
              r[i] += r[i + b] << b;
              r[i + b] = 0;
            } else if (r[i] - (r[i + b] << b) >= -15) {
              r[i] -= r[i + b] << b;
              for (k = i + b; k < 256; ++k) {
                if (r[k] == 0) {
                  r[k] = 1;
                  break;
                }
                r[k] = 0;
              }
            } else {
              break;
            }
          }
        }
      }
    }
  }

  /// Odd multiples [1P, 3P, .., 15P] as compressed bytes (vartime).
  static List<List<int>> dsmPrecompVar(List<int> pointBytes) {
    return dsmPrecomp(_dec(pointBytes, 'dsmPrecompVar'));
  }

  /// Odd multiples [1P, 3P, .., 15P] as live points (vartime).
  ///
  /// Point-level core: no bytes cross this boundary. The bytes-table
  /// [dsmPrecomp] encodes on the way out (API boundary only).
  static List<EdwardsLimbPoint> dsmPrecompPoints(EdwardsLimbPoint point) {
    final twoP = point.double();
    var current = point;
    final out = <EdwardsLimbPoint>[];
    for (var i = 0; i < 8; i++) {
      out.add(current);
      current = current + twoP;
    }
    return out;
  }

  /// Odd multiples [1P, 3P, .., 15P] as compressed bytes (vartime).
  static List<List<int>> dsmPrecomp(EdwardsLimbPoint point) {
    return dsmPrecompPoints(
      point,
    ).map((p) => p.toBytes().toList()).toList(growable: false);
  }

  static List<EdwardsLimbPoint> _table(List<List<int>> t, String op) =>
      t.map((e) => _dec(e, op)).toList(growable: false);

  static List<EdwardsLimbPoint> _negated(List<EdwardsLimbPoint> points) =>
      points.map((p) => -p).toList(growable: false);

  /// `a·A + b·B` from odd-multiple point tables (vartime).
  ///
  /// Point-level core: tables and result stay live points, no bytes cross
  /// this boundary. The bytes-table [doubleScalarMultPrecompPointVar]
  /// decodes on the way in and encodes on the way out (API boundary only).
  static EdwardsLimbPoint doubleScalarMultPrecompPoints(
    List<int> a,
    List<EdwardsLimbPoint> aI,
    List<int> b,
    List<EdwardsLimbPoint> bI,
  ) {
    const op = 'doubleScalarMultPrecompPoints';
    final aINeg = _negated(aI);
    final bINeg = _negated(bI);
    final aslide = List<int>.filled(256, 0);
    final bslide = List<int>.filled(256, 0);
    slide(aslide, a);
    slide(bslide, b);
    EdwardsLimbPoint? r;
    for (var i = 255; i >= 0; i--) {
      final aVal = aslide[i];
      final bVal = bslide[i];
      if (r == null) {
        if (aVal != 0) {
          final idx = (aVal.abs() - 1) ~/ 2;
          r = aVal > 0 ? aI[idx] : aINeg[idx];
        }
        if (bVal != 0) {
          final idx = (bVal.abs() - 1) ~/ 2;
          final bi = bVal > 0 ? bI[idx] : bINeg[idx];
          r = (r == null) ? bi : (r + bi);
        }
        if (r == null) continue;
      } else {
        r = r + r;
        if (aVal != 0) {
          final idx = (aVal.abs() - 1) ~/ 2;
          r += aVal > 0 ? aI[idx] : aINeg[idx];
        }
        if (bVal != 0) {
          final idx = (bVal.abs() - 1) ~/ 2;
          r += bVal > 0 ? bI[idx] : bINeg[idx];
        }
      }
    }
    if (r == null) {
      throw CoreErrors.cryptoFailed(
        op,
        reason:
            'Both scalars are zero; result undefined without identity support.',
      );
    }
    return r;
  }

  /// `a·A + b·B` from odd-multiple tables (vartime).
  static BuBytes doubleScalarMultPrecompPointVar(
    List<int> a,
    List<List<int>> aIBytes,
    List<int> b,
    List<List<int>> bIBytes,
  ) {
    const op = 'doubleScalarMultPrecompPointVar';
    final aI = _table(aIBytes, op);
    final bI = _table(bIBytes, op);
    return doubleScalarMultPrecompPoints(a, aI, b, bI).toBytes();
  }

  /// `a·B + b·P + c·Q` with base-table B (vartime).
  static BuBytes tripleScalarMultBasePointVar({
    required List<int> a,
    required List<int> b,
    required List<List<int>> bIBytes,
    required List<int> c,
    required List<List<int>> cIBytes,
  }) {
    const op = 'tripleScalarMultBasePointVar';
    final geBi = _geBi;
    final bI = _table(bIBytes, op);
    final cI = _table(cIBytes, op);
    final bINeg = _negated(bI);
    final cINeg = _negated(cI);
    final aslide = List<int>.filled(256, 0);
    final bslide = List<int>.filled(256, 0);
    final cslide = List<int>.filled(256, 0);
    slide(aslide, a);
    slide(bslide, b);
    slide(cslide, c);
    EdwardsLimbPoint? r;
    for (var i = 255; i >= 0; i--) {
      final aVal = aslide[i];
      final bVal = bslide[i];
      final cVal = cslide[i];
      if (r == null) {
        if (aVal != 0) {
          final idx = (aVal.abs() - 1) ~/ 2;
          r = aVal > 0 ? geBi[idx] : -geBi[idx];
        }
        if (bVal != 0) {
          final idx = (bVal.abs() - 1) ~/ 2;
          final bi = bVal > 0 ? bI[idx] : bINeg[idx];
          r = (r == null) ? bi : (r + bi);
        }
        if (cVal != 0) {
          final idx = (cVal.abs() - 1) ~/ 2;
          final ci = cVal > 0 ? cI[idx] : cINeg[idx];
          r = (r == null) ? ci : (r + ci);
        }
        if (r == null) continue;
      } else {
        r = r + r;
        if (aVal != 0) {
          final idx = (aVal.abs() - 1) ~/ 2;
          r += aVal > 0 ? geBi[idx] : -geBi[idx];
        }
        if (bVal != 0) {
          final idx = (bVal.abs() - 1) ~/ 2;
          r += bVal > 0 ? bI[idx] : bINeg[idx];
        }
        if (cVal != 0) {
          final idx = (cVal.abs() - 1) ~/ 2;
          r += cVal > 0 ? cI[idx] : cINeg[idx];
        }
      }
    }
    if (r == null) {
      throw CoreErrors.cryptoFailed(
        op,
        reason:
            'All scalars are zero; result undefined without identity support.',
      );
    }
    return r.toBytes();
  }

  /// `a·A + b·B + c·C` from odd-multiple tables (vartime).
  static BuBytes tripleScalarMultPrecompPointVar(
    List<int> a,
    List<List<int>> aIBytes,
    List<int> b,
    List<List<int>> bIBytes,
    List<int> c,
    List<List<int>> cIBytes,
  ) {
    const op = 'tripleScalarMultPrecompPointVar';
    final aI = _table(aIBytes, op);
    final bI = _table(bIBytes, op);
    final cI = _table(cIBytes, op);
    final aINeg = _negated(aI);
    final bINeg = _negated(bI);
    final cINeg = _negated(cI);
    final aslide = List<int>.filled(256, 0);
    final bslide = List<int>.filled(256, 0);
    final cslide = List<int>.filled(256, 0);
    slide(aslide, a);
    slide(bslide, b);
    slide(cslide, c);
    EdwardsLimbPoint? r;
    for (var i = 255; i >= 0; i--) {
      final aVal = aslide[i];
      final bVal = bslide[i];
      final cVal = cslide[i];
      if (r == null) {
        if (aVal != 0) {
          final idx = (aVal.abs() - 1) ~/ 2;
          r = aVal > 0 ? aI[idx] : aINeg[idx];
        }
        if (bVal != 0) {
          final idx = (bVal.abs() - 1) ~/ 2;
          final bi = bVal > 0 ? bI[idx] : bINeg[idx];
          r = (r == null) ? bi : (r + bi);
        }
        if (cVal != 0) {
          final idx = (cVal.abs() - 1) ~/ 2;
          final ci = cVal > 0 ? cI[idx] : cINeg[idx];
          r = (r == null) ? ci : (r + ci);
        }
        if (r == null) continue;
      } else {
        r = r + r;
        if (aVal != 0) {
          final idx = (aVal.abs() - 1) ~/ 2;
          r += aVal > 0 ? aI[idx] : aINeg[idx];
        }
        if (bVal != 0) {
          final idx = (bVal.abs() - 1) ~/ 2;
          r += bVal > 0 ? bI[idx] : bINeg[idx];
        }
        if (cVal != 0) {
          final idx = (cVal.abs() - 1) ~/ 2;
          r += cVal > 0 ? cI[idx] : cINeg[idx];
        }
      }
    }
    if (r == null) {
      throw CoreErrors.cryptoFailed(
        op,
        reason:
            'All scalars are zero; result undefined without identity support.',
      );
    }
    return r.toBytes();
  }

  /// `a·gA + b·B` (B = base point), vartime.
  static BuBytes doubleScalarMultBasePointVar({
    required List<int> a,
    required List<int> gABytes,
    required List<int> b,
  }) {
    const op = 'doubleScalarMultBasePointVar';
    final gA = _dec(gABytes, op);
    final aI = _dsm(gA);
    final aslide = List<int>.filled(256, 0);
    final bslide = List<int>.filled(256, 0);
    slide(aslide, a);
    slide(bslide, b);
    EdwardsLimbPoint? r;
    for (var i = 255; i >= 0; i--) {
      final aVal = aslide[i];
      final bVal = bslide[i];
      if (r == null) {
        if (aVal != 0) {
          final idx = (aVal.abs() - 1) ~/ 2;
          final ai = aI[idx];
          r = aVal > 0 ? ai : -ai;
        }
        if (bVal != 0) {
          final idx = (bVal.abs() - 1) ~/ 2;
          final bi = _geBi[idx];
          final term = bVal > 0 ? bi : -bi;
          r = (r == null) ? term : (r + term);
        }
      } else {
        r = r + r;
        if (aVal != 0) {
          final idx = (aVal.abs() - 1) ~/ 2;
          final ai = aI[idx];
          r += aVal > 0 ? ai : -ai;
        }
        if (bVal != 0) {
          final idx = (bVal.abs() - 1) ~/ 2;
          final bi = _geBi[idx];
          r += bVal > 0 ? bi : -bi;
        }
      }
    }
    if (r == null) {
      throw CoreErrors.cryptoFailed(
        op,
        reason:
            'All scalars are zero; result undefined without identity support.',
      );
    }
    return r.toBytes();
  }

  static List<EdwardsLimbPoint> _dsm(EdwardsLimbPoint point) {
    final twoP = point.double();
    var current = point;
    final out = <EdwardsLimbPoint>[];
    for (var i = 0; i < 8; i++) {
      out.add(current);
      current = current + twoP;
    }
    return out;
  }

  // Odd multiples [1B, 3B, .., 15B] of the base point as fixed Montgomery
  // (`unsafe`) constants — same encodings as the legacy base table, no
  // runtime decode/sqrt.
  static const List<EdwardsLimbPoint> _geBi = [
    EdwardsLimbPoint(
      x: Ed25519Fp.unsafe([
        Uint64.unsafe(3804937301, 1067295367),
        Uint64.unsafe(2628098134, 597091465),
        Uint64.unsafe(2558104427, 2917447095),
        Uint64.unsafe(1973298032, 2120251344),
      ]),
      y: Ed25519Fp.unsafe([
        Uint64.unsafe(858993459, 858993482),
        Uint64.unsafe(858993459, 858993459),
        Uint64.unsafe(858993459, 858993459),
        Uint64.unsafe(858993459, 858993459),
      ]),
      z: Ed25519Fp.unsafe([
        Uint64.unsafe(0, 38),
        Uint64.unsafe(0, 0),
        Uint64.unsafe(0, 0),
        Uint64.unsafe(0, 0),
      ]),
      t: Ed25519Fp.unsafe([
        Uint64.unsafe(1325962922, 2571823212),
        Uint64.unsafe(3820465425, 3054653550),
        Uint64.unsafe(1187490082, 4051944594),
        Uint64.unsafe(1578638425, 4273181453),
      ]),
    ),
    EdwardsLimbPoint(
      x: Ed25519Fp.unsafe([
        Uint64.unsafe(2526461497, 1995545570),
        Uint64.unsafe(3154678729, 882295805),
        Uint64.unsafe(3193038145, 1417263274),
        Uint64.unsafe(1676358401, 566314202),
      ]),
      y: Ed25519Fp.unsafe([
        Uint64.unsafe(1761704641, 4101560279),
        Uint64.unsafe(2640776057, 1331196568),
        Uint64.unsafe(3954965282, 1169922241),
        Uint64.unsafe(996435223, 3445862265),
      ]),
      z: Ed25519Fp.unsafe([
        Uint64.unsafe(0, 38),
        Uint64.unsafe(0, 0),
        Uint64.unsafe(0, 0),
        Uint64.unsafe(0, 0),
      ]),
      t: Ed25519Fp.unsafe([
        Uint64.unsafe(2465682733, 3937033408),
        Uint64.unsafe(2916217543, 1164538650),
        Uint64.unsafe(92421515, 3380159447),
        Uint64.unsafe(1198414274, 1726226563),
      ]),
    ),
    EdwardsLimbPoint(
      x: Ed25519Fp.unsafe([
        Uint64.unsafe(2409055367, 1928852769),
        Uint64.unsafe(2918439679, 941850259),
        Uint64.unsafe(2341244105, 214343425),
        Uint64.unsafe(2074530637, 3485409895),
      ]),
      y: Ed25519Fp.unsafe([
        Uint64.unsafe(2133896593, 3584152898),
        Uint64.unsafe(1274475024, 1609805776),
        Uint64.unsafe(1184388876, 1807119147),
        Uint64.unsafe(615880834, 3050169499),
      ]),
      z: Ed25519Fp.unsafe([
        Uint64.unsafe(0, 38),
        Uint64.unsafe(0, 0),
        Uint64.unsafe(0, 0),
        Uint64.unsafe(0, 0),
      ]),
      t: Ed25519Fp.unsafe([
        Uint64.unsafe(3686923276, 879773542),
        Uint64.unsafe(360818622, 22790248),
        Uint64.unsafe(1415759860, 304197392),
        Uint64.unsafe(1169476255, 893327695),
      ]),
    ),
    EdwardsLimbPoint(
      x: Ed25519Fp.unsafe([
        Uint64.unsafe(481596416, 1612556156),
        Uint64.unsafe(2490464813, 3856968235),
        Uint64.unsafe(3084212161, 643901213),
        Uint64.unsafe(81262563, 2354321846),
      ]),
      y: Ed25519Fp.unsafe([
        Uint64.unsafe(3375706869, 2744035418),
        Uint64.unsafe(3023465608, 3280336144),
        Uint64.unsafe(681764752, 3592271817),
        Uint64.unsafe(1665979320, 1823057166),
      ]),
      z: Ed25519Fp.unsafe([
        Uint64.unsafe(0, 38),
        Uint64.unsafe(0, 0),
        Uint64.unsafe(0, 0),
        Uint64.unsafe(0, 0),
      ]),
      t: Ed25519Fp.unsafe([
        Uint64.unsafe(2081966800, 2989306465),
        Uint64.unsafe(1107736640, 2331277786),
        Uint64.unsafe(611765074, 1975105220),
        Uint64.unsafe(495305802, 1364326425),
      ]),
    ),
    EdwardsLimbPoint(
      x: Ed25519Fp.unsafe([
        Uint64.unsafe(1933914864, 432985285),
        Uint64.unsafe(68297134, 3751043607),
        Uint64.unsafe(639247696, 2415732580),
        Uint64.unsafe(1887823549, 2953893122),
      ]),
      y: Ed25519Fp.unsafe([
        Uint64.unsafe(2510171044, 2737825087),
        Uint64.unsafe(2883936983, 1113464637),
        Uint64.unsafe(2287569570, 3893055890),
        Uint64.unsafe(1662209768, 3973059154),
      ]),
      z: Ed25519Fp.unsafe([
        Uint64.unsafe(0, 38),
        Uint64.unsafe(0, 0),
        Uint64.unsafe(0, 0),
        Uint64.unsafe(0, 0),
      ]),
      t: Ed25519Fp.unsafe([
        Uint64.unsafe(2966053006, 1250969855),
        Uint64.unsafe(2226229220, 3131539137),
        Uint64.unsafe(2436210130, 3030941499),
        Uint64.unsafe(952464082, 3492300566),
      ]),
    ),
    EdwardsLimbPoint(
      x: Ed25519Fp.unsafe([
        Uint64.unsafe(3776530602, 3532402836),
        Uint64.unsafe(1698601097, 1408346705),
        Uint64.unsafe(582688525, 3570098287),
        Uint64.unsafe(436472393, 692312965),
      ]),
      y: Ed25519Fp.unsafe([
        Uint64.unsafe(893438721, 3162123721),
        Uint64.unsafe(3105700400, 4281675647),
        Uint64.unsafe(1821149627, 2782681238),
        Uint64.unsafe(1131631439, 1593800823),
      ]),
      z: Ed25519Fp.unsafe([
        Uint64.unsafe(0, 38),
        Uint64.unsafe(0, 0),
        Uint64.unsafe(0, 0),
        Uint64.unsafe(0, 0),
      ]),
      t: Ed25519Fp.unsafe([
        Uint64.unsafe(4124885236, 2409985382),
        Uint64.unsafe(905987823, 2069346380),
        Uint64.unsafe(2484387927, 4015901287),
        Uint64.unsafe(2117897489, 37750804),
      ]),
    ),
    EdwardsLimbPoint(
      x: Ed25519Fp.unsafe([
        Uint64.unsafe(1025593645, 1183726970),
        Uint64.unsafe(974378116, 4079437144),
        Uint64.unsafe(2309738917, 4139068366),
        Uint64.unsafe(1899883359, 3256959592),
      ]),
      y: Ed25519Fp.unsafe([
        Uint64.unsafe(765165558, 3313806687),
        Uint64.unsafe(866047090, 115461958),
        Uint64.unsafe(3664921899, 1282437464),
        Uint64.unsafe(1285300753, 979809097),
      ]),
      z: Ed25519Fp.unsafe([
        Uint64.unsafe(0, 38),
        Uint64.unsafe(0, 0),
        Uint64.unsafe(0, 0),
        Uint64.unsafe(0, 0),
      ]),
      t: Ed25519Fp.unsafe([
        Uint64.unsafe(849921680, 2432370619),
        Uint64.unsafe(2232502312, 3907598708),
        Uint64.unsafe(1520491652, 2060008029),
        Uint64.unsafe(737214329, 2252531293),
      ]),
    ),
    EdwardsLimbPoint(
      x: Ed25519Fp.unsafe([
        Uint64.unsafe(1853416259, 1006308443),
        Uint64.unsafe(1152705353, 2855957559),
        Uint64.unsafe(3044641027, 3536436628),
        Uint64.unsafe(1028313311, 250683390),
      ]),
      y: Ed25519Fp.unsafe([
        Uint64.unsafe(137979185, 3034696057),
        Uint64.unsafe(2853698983, 4243780604),
        Uint64.unsafe(347122228, 4148287839),
        Uint64.unsafe(1246185646, 3185520746),
      ]),
      z: Ed25519Fp.unsafe([
        Uint64.unsafe(0, 38),
        Uint64.unsafe(0, 0),
        Uint64.unsafe(0, 0),
        Uint64.unsafe(0, 0),
      ]),
      t: Ed25519Fp.unsafe([
        Uint64.unsafe(4194361759, 3184026135),
        Uint64.unsafe(718084443, 3651019360),
        Uint64.unsafe(1736282901, 3079016369),
        Uint64.unsafe(2075501084, 523980191),
      ]),
    ),
  ];
}
