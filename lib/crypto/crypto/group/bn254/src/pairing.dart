// BN254 optimal Ate pairing: Miller loop (6x+2, x = 4965661367192848881)
// + noble-style final exponentiation. Divisive twist => mul034 lines.
import 'package:blockchain_utils/utils/numbers/fixed/src/u64/u64.dart';

import 'package:blockchain_utils/crypto/crypto/group/bn254/src/fp.dart';
import 'package:blockchain_utils/crypto/crypto/group/bn254/src/fp2.dart';
import 'package:blockchain_utils/crypto/crypto/group/bn254/src/fp6.dart';
import 'package:blockchain_utils/crypto/crypto/group/bn254/src/fp12.dart';
import 'package:blockchain_utils/crypto/crypto/group/bn254/src/g1.dart';
import 'package:blockchain_utils/crypto/crypto/group/bn254/src/g2.dart';

class Bn254Pairing {
  static const int bnXLen = 63;
  static final BigInt bnX = BigInt.parse('4965661367192848881');
  static final BigInt ateLoop = bnX * BigInt.from(6) + BigInt.two;

  // psi coeffs: PSI_X = g1[1], PSI_Y = xi^((p-1)/2), PSI2_X = g1[2].
  static const psiX = Bn254Fp6.g11;
  static const psiY = Bn254Fp2(
    c0: Bn254Fp.unsafe([
      Uint64.unsafe(3837517068, 691451433),
      Uint64.unsafe(3140546914, 3778263755),
      Uint64.unsafe(833212854, 4184101734),
      Uint64.unsafe(624259262, 2768304349),
    ]),
    c1: Bn254Fp.unsafe([
      Uint64.unsafe(2715253988, 1610512327),
      Uint64.unsafe(128974097, 2015810011),
      Uint64.unsafe(1830206759, 3145653355),
      Uint64.unsafe(747053058, 2245983948),
    ]),
  );
  static const psi2X = Bn254Fp6.g12;

  static (Bn254Fp2, Bn254Fp2) psi(Bn254Fp2 x, Bn254Fp2 y) => (
    x.frobeniusMap() * psiX,
    y.frobeniusMap() * psiY,
  );

  static (Bn254Fp2, Bn254Fp2) psi2(Bn254Fp2 x, Bn254Fp2 y) => (x * psi2X, -y);

  static Bn254Fp2 _mulSmall(Bn254Fp2 a, int n) {
    var r = Bn254Fp2.zero;
    for (var i = 0; i < n; i++) {
      r = r + a;
    }
    return r;
  }

  /// Doubling step: returns (Rx,Ry,Rz) + line [c0,c1,c2].
  static ({Bn254Fp2 rx, Bn254Fp2 ry, Bn254Fp2 rz, List<Bn254Fp2> line})
  doublingStep(Bn254Fp2 rx, Bn254Fp2 ry, Bn254Fp2 rz) {
    final t0 = ry.square();
    final t1 = rz.square();
    final t2 = _mulSmall(t1.mulByB(), 3);
    final t3 = _mulSmall(t2, 3);
    final t4 = (ry + rz).square() - t1 - t0;
    final c0 = t2 - t0;
    final c1 = _mulSmall(rx.square(), 3);
    final c2 = -t4;
    final rx2 = ((t0 - t3) * rx * ry);
    final rx2h = Bn254Fp2(
      c0: rx2.c0 * Bn254Fp2.inv2,
      c1: rx2.c1 * Bn254Fp2.inv2,
    );
    final half = Bn254Fp2(
      c0: (t0 + t3).c0 * Bn254Fp2.inv2,
      c1: (t0 + t3).c1 * Bn254Fp2.inv2,
    );
    final ry2 = half.square() - _mulSmall(t2.square(), 3);
    final rz2 = t0 * t4;
    return (rx: rx2h, ry: ry2, rz: rz2, line: [c0, c1, c2]);
  }

  static ({Bn254Fp2 rx, Bn254Fp2 ry, Bn254Fp2 rz, List<Bn254Fp2> line})
  additionStep(
    Bn254Fp2 rx,
    Bn254Fp2 ry,
    Bn254Fp2 rz,
    Bn254Fp2 qx,
    Bn254Fp2 qy,
  ) {
    final t0 = ry - qy * rz;
    final t1 = rx - qx * rz;
    final c0 = t0 * qx - t1 * qy;
    final c1 = -t0;
    final c2 = t1;
    final t2 = t1.square();
    final t3 = t2 * t1;
    final t4 = t2 * rx;
    final t5 = t3 - (t4 + t4) + t0.square() * rz;
    final rx2 = t1 * t5;
    final ry2 = (t4 - t5) * t0 - t3 * ry;
    final rz2 = rz * t3;
    return (rx: rx2, ry: ry2, rz: rz2, line: [c0, c1, c2]);
  }

  /// NAF decomposition of the ate loop size (noble NAfDecomposition port).
  /// Top bit is a length marker and is dropped.
  static List<int> _naf(BigInt a) {
    final res = <int>[];
    while (a > BigInt.one) {
      if ((a & BigInt.one) == BigInt.zero) {
        res.insert(0, 0);
      } else if ((a & BigInt.from(3)) == BigInt.from(3)) {
        res.insert(0, -1);
        a += BigInt.one;
      } else {
        res.insert(0, 1);
      }
      a >>= 1;
    }
    return res;
  }

  /// Precomputes for one G2 affine point: list per loop-digit of 1-2 lines.
  /// Digit chain is NAF (matches noble); the two BN extra adds are folded
  /// into the LAST group (no extra squaring), like noble postPrecompute.
  static List<List<List<Bn254Fp2>>> calcPrecomputes(Bn254G2AffinePoint q) {
    var rx = q.x;
    var ry = q.y;
    var rz = Bn254Fp2.one;
    final ell = <List<List<Bn254Fp2>>>[];
    final negQy = -q.y;
    for (final bit in _naf(ateLoop)) {
      final cur = <List<Bn254Fp2>>[];
      final d = doublingStep(rx, ry, rz);
      rx = d.rx;
      ry = d.ry;
      rz = d.rz;
      cur.add(d.line);
      if (bit != 0) {
        final a = additionStep(rx, ry, rz, q.x, bit == -1 ? negQy : q.y);
        rx = a.rx;
        ry = a.ry;
        rz = a.rz;
        cur.add(a.line);
      }
      ell.add(cur);
    }
    // BN extra: R += Q1 then R += -Q2, appended to the last group.
    final last = ell[ell.length - 1];
    final q1 = psi(q.x, q.y);
    var a1 = additionStep(rx, ry, rz, q1.$1, q1.$2);
    rx = a1.rx;
    ry = a1.ry;
    rz = a1.rz;
    last.add(a1.line);
    // q2 = psi(Q1) = psi^2(Q); add (q2.x, -q2.y). (psi2(Q) would give the
    // same point; we apply single psi to Q1 like the reference.)
    final q2 = psi(q1.$1, q1.$2);
    final a2 = additionStep(rx, ry, rz, q2.$1, -q2.$2);
    last.add(a2.line);
    return ell;
  }

  static Bn254Fp12 lineEval(
    Bn254Fp12 f,
    List<Bn254Fp2> line,
    Bn254Fp px,
    Bn254Fp py,
  ) {
    // divisive: mul034(f, l0=c2, l3=c1, l4=c0)
    return f.mulBy034(line[2], line[1], line[0], px, py);
  }

  static Bn254Fp12 millerLoop(
    List<(List<List<List<Bn254Fp2>>>, Bn254Fp, Bn254Fp)> pairs, {
    bool withFinalExp = true,
  }) {
    var f = Bn254Fp12.one;
    if (pairs.isNotEmpty) {
      final ellLen = pairs[0].$1.length;
      for (var i = 0; i < ellLen; i++) {
        if (i != 0) f = f.square();
        for (final (ell, px, py) in pairs) {
          for (final line in ell[i]) {
            f = lineEval(f, line, px, py);
          }
        }
      }
    }
    return withFinalExp ? finalExponentiate(f) : f;
  }

  static Bn254Fp12 _cyclotomicExpX(Bn254Fp12 num) {
    Bn254Fp12 cyclSqrN(Bn254Fp12 n, int count) {
      for (var i = 0; i < count; i++) {
        n = n.cyclotomicSquare();
      }
      return n;
    }

    final x10 = num.cyclotomicSquare();
    final x100 = x10.cyclotomicSquare();
    final x1000 = x100.cyclotomicSquare();
    final x10000 = x1000.cyclotomicSquare();
    final x10001 = x10000 * num;
    final x10011 = x10001 * x10;
    final x10100 = x10011 * num;
    final x11001 = x1000 * x10001;
    final x100010 = x10001.cyclotomicSquare();
    final x100111 = x10011 * x10100;
    final x101001 = x10 * x100111;
    var r = cyclSqrN(x100010, 6);
    r = r * x100 * x11001;
    r = cyclSqrN(r, 7) * x11001;
    r = cyclSqrN(r, 8);
    r = r * x101001 * x10;
    r = cyclSqrN(r, 6) * x10001;
    r = cyclSqrN(r, 8) * x101001;
    r = cyclSqrN(r, 6) * x101001;
    r = cyclSqrN(r, 10) * x100111;
    r = cyclSqrN(r, 6) * x101001 * x1000;
    return r;
  }

  static Bn254Fp12 finalExponentiate(Bn254Fp12 num) {
    Bn254Fp12 powMinusX(Bn254Fp12 n) => _cyclotomicExpX(n).conjugate();
    final r0 = num.conjugate() * num.invert()!;
    final r = r0.frobeniusMap(2) * r0;
    final y1 = powMinusX(r).cyclotomicSquare();
    final y2 = y1.cyclotomicSquare() * y1;
    final y4 = powMinusX(y2);
    final y6 = powMinusX(y4.cyclotomicSquare());
    final y8 = y6.conjugate() * y4 * y2.conjugate();
    final y9 = y8 * y1;
    return (r.conjugate() * y9).frobeniusMap(3) *
        y8.frobeniusMap(2) *
        y9.frobeniusMap(1) *
        y8 *
        y4 *
        r;
  }

  static Bn254Fp12 pairing(Bn254G1AffinePoint p, Bn254G2AffinePoint q) {
    if (p.isIdentity() || q.isIdentity()) return Bn254Fp12.one;
    return millerLoop([(calcPrecomputes(q), p.x, p.y)]);
  }

  static Bn254Fp12 pairingBatch(
    List<(Bn254G1AffinePoint, Bn254G2AffinePoint)> pairs,
  ) {
    final terms = <(List<List<List<Bn254Fp2>>>, Bn254Fp, Bn254Fp)>[];
    for (final (p, q) in pairs) {
      if (p.isIdentity() || q.isIdentity()) continue;
      terms.add((calcPrecomputes(q), p.x, p.y));
    }
    if (terms.isEmpty) return Bn254Fp12.one;
    return millerLoop(terms);
  }
}
