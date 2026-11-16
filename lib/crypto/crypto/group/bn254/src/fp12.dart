// BN254 Fp12 = Fp6[w]/(w^2 - v).
import 'package:blockchain_utils/utils/numbers/fixed/src/u64/u64.dart';
import 'package:blockchain_utils/utils/equatable/equatable.dart';

import 'package:blockchain_utils/crypto/crypto/group/bn254/src/fp.dart';
import 'package:blockchain_utils/crypto/crypto/group/bn254/src/fp2.dart';
import 'package:blockchain_utils/crypto/crypto/group/bn254/src/fp6.dart';

class Bn254Fp12 with Equality {
  final Bn254Fp6 c0;
  final Bn254Fp6 c1;
  const Bn254Fp12({required this.c0, required this.c1});

  factory Bn254Fp12.conditionalSelect(
    Bn254Fp12 a,
    Bn254Fp12 b,
    bool choice,
  ) {
    return Bn254Fp12(
      c0: Bn254Fp6.conditionalSelect(a.c0, b.c0, choice),
      c1: Bn254Fp6.conditionalSelect(a.c1, b.c1, choice),
    );
  }

  static const zero = Bn254Fp12(c0: Bn254Fp6.zero, c1: Bn254Fp6.zero);
  static const one = Bn254Fp12(c0: Bn254Fp6.one, c1: Bn254Fp6.zero);

  bool isZero() => c0.isZero() && c1.isZero();
  Bn254Fp12 conjugate() => Bn254Fp12(c0: c0, c1: -c1);

  Bn254Fp12 operator +(Bn254Fp12 rhs) =>
      Bn254Fp12(c0: c0 + rhs.c0, c1: c1 + rhs.c1);
  Bn254Fp12 operator -(Bn254Fp12 rhs) =>
      Bn254Fp12(c0: c0 - rhs.c0, c1: c1 - rhs.c1);
  Bn254Fp12 operator -() => Bn254Fp12(c0: -c0, c1: -c1);

  Bn254Fp12 operator *(Bn254Fp12 rhs) {
    final t1 = c0 * rhs.c0;
    final t2 = c1 * rhs.c1;
    return Bn254Fp12(
      c0: t1 + t2.mulByNonresidue(),
      c1: (c0 + c1) * (rhs.c0 + rhs.c1) - t1 - t2,
    );
  }

  Bn254Fp12 square() {
    final ab = c0 * c1;
    return Bn254Fp12(
      c0:
          (c1.mulByNonresidue() + c0) * (c0 + c1) -
          ab -
          ab.mulByNonresidue(),
      c1: ab + ab,
    );
  }

  Bn254Fp12? invert() {
    final tmp = (c0.square() - c1.square().mulByNonresidue()).invert();
    if (tmp == null) return null;
    return Bn254Fp12(c0: c0 * tmp, c1: c1 * -tmp);
  }

  /// Sparse mul for divisive-twist line: coeffs already hold
  /// (l0 = lineC2, l3 = lineC1, l4 = lineC0); px/py scale l0/l3.
  Bn254Fp12 mulBy034(
    Bn254Fp2 l0,
    Bn254Fp2 l3,
    Bn254Fp2 l4,
    Bn254Fp px,
    Bn254Fp py,
  ) {
    final o0 = Bn254Fp2(c0: l0.c0 * py, c1: l0.c1 * py);
    final o3 = Bn254Fp2(c0: l3.c0 * px, c1: l3.c1 * px);
    final o4 = l4;
    final f0 = c0;
    final f1 = c1;
    // a = f0 * o0
    final aC0 = f0.c0 * o0;
    final aC1 = f0.c1 * o0;
    final aC2 = f0.c2 * o0;
    // b = f1.mul01(o3, o4)
    final b0m = f1.c0 * o3;
    final b1m = f1.c1 * o4;
    final bC0 =
        ((f1.c1 + f1.c2) * o4 - b1m).mulByNonresidue() + b0m;
    final bC1 = (o3 + o4) * (f1.c0 + f1.c1) - b0m - b1m;
    final bC2 = (f1.c0 + f1.c2) * o3 - b0m + b1m;
    // e = (f0+f1).mul01(o0+o3, o4)
    final s0 = f0.c0 + f1.c0;
    final s1 = f0.c1 + f1.c1;
    final s2 = f0.c2 + f1.c2;
    final o03 = o0 + o3;
    final e0m = s0 * o03;
    final e1m = s1 * o4;
    final eC0 = ((s1 + s2) * o4 - e1m).mulByNonresidue() + e0m;
    final eC1 = (o03 + o4) * (s0 + s1) - e0m - e1m;
    final eC2 = (s0 + s2) * o03 - e0m + e1m;
    return Bn254Fp12(
      c0: Bn254Fp6(
        c0: bC2.mulByNonresidue() + aC0,
        c1: bC0 + aC1,
        c2: bC1 + aC2,
      ),
      c1: Bn254Fp6(
        c0: eC0 - aC0 - bC0,
        c1: eC1 - aC1 - bC1,
        c2: eC2 - aC2 - bC2,
      ),
    );
  }

  /// Sparse mul for completeness (multiplicative shape, unused by BN loop).
  Bn254Fp12 mulBy014(Bn254Fp2 c0, Bn254Fp2 c1, Bn254Fp2 c4) {
    final aa = this.c0.mul01(c0, c1);
    final bb = this.c1.mul1(c4);
    final o = c1 + c4;
    var c1_ = (this.c1 + this.c0).mul01(c0, o) - aa - bb;
    final c0_ = bb.mulByNonresidue() + aa;
    return Bn254Fp12(c0: c0_, c1: c1_);
  }

  // h[j] = xi^((p^j-1)/6), j = 0..11.
  static const h0 = Bn254Fp2(c0: Bn254Fp.one, c1: Bn254Fp.zero);
  static const h1 = Bn254Fp2(
    c0: Bn254Fp.unsafe([
      Uint64.unsafe(2946213526, 856967431),
      Uint64.unsafe(3396017523, 2276439946),
      Uint64.unsafe(297659742, 4035584135),
      Uint64.unsafe(49499509, 438254204),
    ]),
    c1: Bn254Fp.unsafe([
      Uint64.unsafe(2720181795, 1279864178),
      Uint64.unsafe(3490644644, 1448993115),
      Uint64.unsafe(3694130082, 1407174950),
      Uint64.unsafe(279402262, 3012138321),
    ]),
  );
  static const h2 = Bn254Fp2(
    c0: Bn254Fp.unsafe([
      Uint64.unsafe(3398270981, 16391154),
      Uint64.unsafe(4039497236, 1756600169),
      Uint64.unsafe(236982897, 2903327768),
      Uint64.unsafe(69799781, 3134740198),
    ]),
    c1: Bn254Fp.zero,
  );
  static const h3 = Bn254Fp2(
    c0: Bn254Fp.unsafe([
      Uint64.unsafe(911414808, 1313266045),
      Uint64.unsafe(183964318, 3569970591),
      Uint64.unsafe(1704830767, 3390048693),
      Uint64.unsafe(135359881, 2208435491),
    ]),
    c1: Bn254Fp.unsafe([
      Uint64.unsafe(2984200951, 3281787193),
      Uint64.unsafe(1033831047, 2322841471),
      Uint64.unsafe(2602705042, 2360281824),
      Uint64.unsafe(644367637, 4025504934),
    ]),
  );
  static const h4 = Bn254Fp6.g12;
  static const h5 = Bn254Fp2(
    c0: Bn254Fp.unsafe([
      Uint64.unsafe(2260168578, 456298614),
      Uint64.unsafe(1082914091, 1293530644),
      Uint64.unsafe(1407171024, 3649431853),
      Uint64.unsafe(85860372, 1770181287),
    ]),
    c1: Bn254Fp.unsafe([
      Uint64.unsafe(264019156, 2001923015),
      Uint64.unsafe(1838153699, 873848356),
      Uint64.unsafe(3203542256, 953106873),
      Uint64.unsafe(364965375, 1013366612),
    ]),
  );
  static const h6 = Bn254Fp2(
    c0: Bn254Fp.unsafe([
      Uint64.unsafe(1757628553, 317583274),
      Uint64.unsafe(2366144360, 1923792719),
      Uint64.unsafe(1373741639, 151523889),
      Uint64.unsafe(576313009, 1193918714),
    ]),
    c1: Bn254Fp.zero,
  );
  static const h7 = Bn254Fp2(
    c0: Bn254Fp.unsafe([
      Uint64.unsafe(2357519744, 2775102528),
      Uint64.unsafe(3440790813, 3770815234),
      Uint64.unsafe(2794608727, 2432120789),
      Uint64.unsafe(762380541, 3339871661),
    ]),
    c1: Bn254Fp.unsafe([
      Uint64.unsafe(2583551475, 2352205781),
      Uint64.unsafe(3346163693, 303294769),
      Uint64.unsafe(3693105684, 765562678),
      Uint64.unsafe(532477788, 765987543),
    ]),
  );
  static const h8 = Bn254Fp6.g14;
  static const h9 = Bn254Fp2(
    c0: Bn254Fp.unsafe([
      Uint64.unsafe(97351166, 2318803914),
      Uint64.unsafe(2357876722, 2477284590),
      Uint64.unsafe(1387437702, 3077656232),
      Uint64.unsafe(676520169, 1569690374),
    ]),
    c1: Bn254Fp.unsafe([
      Uint64.unsafe(2319532319, 350282766),
      Uint64.unsafe(1508009993, 3724413709),
      Uint64.unsafe(489563427, 4107423101),
      Uint64.unsafe(167512412, 4047588227),
    ]),
  );
  static const h10 = Bn254Fp2(
    c0: Bn254Fp.unsafe([
      Uint64.unsafe(147833736, 3298095531),
      Uint64.unsafe(431166740, 2366862292),
      Uint64.unsafe(1481543933, 3412853267),
      Uint64.unsafe(165767259, 3744434249),
    ]),
    c1: Bn254Fp.zero,
  );
  static const h11 = Bn254Fp2(
    c0: Bn254Fp.unsafe([
      Uint64.unsafe(3043564692, 3175771345),
      Uint64.unsafe(1458926950, 458757240),
      Uint64.unsafe(1685097445, 2818273072),
      Uint64.unsafe(726019678, 2007944578),
    ]),
    c1: Bn254Fp.unsafe([
      Uint64.unsafe(744746818, 1630146944),
      Uint64.unsafe(703687342, 878439529),
      Uint64.unsafe(4183693510, 1219630756),
      Uint64.unsafe(446914675, 2764759252),
    ]),
  );

  static Bn254Fp2 _h(int j) => switch (j) {
    1 => h1,
    2 => h2,
    3 => h3,
    4 => h4,
    5 => h5,
    6 => h6,
    7 => h7,
    8 => h8,
    9 => h9,
    10 => h10,
    11 => h11,
    _ => h0,
  };

  Bn254Fp12 frobeniusMap([int power = 1]) {
    final p = power % 12;
    if (p == 0) return this;
    if (p == 6) return conjugate();
    final h = _h(p);
    final f1 = c1.frobeniusMap(p);
    return Bn254Fp12(
      c0: c0.frobeniusMap(p),
      c1: Bn254Fp6(
        c0: f1.c0 * h,
        c1: f1.c1 * h,
        c2: f1.c2 * h,
      ),
    );
  }

  /// Cyclotomic square (noble _cyclotomicSquare port).
  Bn254Fp12 cyclotomicSquare() {
    final c0c0 = c0.c0;
    final c0c1 = c0.c1;
    final c0c2 = c0.c2;
    final c1c0 = c1.c0;
    final c1c1 = c1.c1;
    final c1c2 = c1.c2;
    final t3t4 = Bn254Fp2.fp4Square(c0c0, c1c1);
    final t5t6 = Bn254Fp2.fp4Square(c1c0, c0c2);
    final t7t8 = Bn254Fp2.fp4Square(c0c1, c1c2);
    final t9 = t7t8.$2.mulByNonresidue();
    Bn254Fp2 twice(Bn254Fp2 a) => a + a;
    return Bn254Fp12(
      c0: Bn254Fp6(
        c0: twice(t3t4.$1 - c0c0) + t3t4.$1,
        c1: twice(t5t6.$1 - c0c1) + t5t6.$1,
        c2: twice(t7t8.$1 - c0c2) + t7t8.$1,
      ),
      c1: Bn254Fp6(
        c0: twice(t9 + c1c0) + t9,
        c1: twice(t3t4.$2 + c1c1) + t3t4.$2,
        c2: twice(t5t6.$2 + c1c2) + t5t6.$2,
      ),
    );
  }

  Bn254Fp12 powVarTime(BigInt e) {
    var res = Bn254Fp12.one;
    for (var i = e.bitLength - 1; i >= 0; i--) {
      res = res.square();
      if ((e >> i) & BigInt.one == BigInt.one) res = res * this;
    }
    return res;
  }

  @override
  List<dynamic> get variables => [c0, c1];
}
