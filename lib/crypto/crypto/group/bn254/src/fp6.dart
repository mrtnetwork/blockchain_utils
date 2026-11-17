// BN254 Fp6 = Fp2[v]/(v^3 - xi), xi = 9+u.
// Naive noble-tower formulas (straight-line, no secret branches).
import 'package:blockchain_utils/utils/numbers/fixed/src/u64/u64.dart';
import 'package:blockchain_utils/utils/equatable/equatable.dart';

import 'package:blockchain_utils/crypto/crypto/group/bn254/src/fp.dart';
import 'package:blockchain_utils/crypto/crypto/group/bn254/src/fp2.dart';

class Bn254Fp6 with Equality {
  final Bn254Fp2 c0;
  final Bn254Fp2 c1;
  final Bn254Fp2 c2;
  const Bn254Fp6({required this.c0, required this.c1, required this.c2});

  factory Bn254Fp6.conditionalSelect(Bn254Fp6 a, Bn254Fp6 b, bool choice) {
    return Bn254Fp6(
      c0: Bn254Fp2.conditionalSelect(a.c0, b.c0, choice),
      c1: Bn254Fp2.conditionalSelect(a.c1, b.c1, choice),
      c2: Bn254Fp2.conditionalSelect(a.c2, b.c2, choice),
    );
  }

  static const zero = Bn254Fp6(
    c0: Bn254Fp2.zero,
    c1: Bn254Fp2.zero,
    c2: Bn254Fp2.zero,
  );
  static const one = Bn254Fp6(
    c0: Bn254Fp2.one,
    c1: Bn254Fp2.zero,
    c2: Bn254Fp2.zero,
  );

  factory Bn254Fp6.fromFp2(Bn254Fp2 f) =>
      Bn254Fp6(c0: f, c1: Bn254Fp2.zero, c2: Bn254Fp2.zero);

  bool isZero() => c0.isZero() && c1.isZero() && c2.isZero();

  Bn254Fp6 operator +(Bn254Fp6 rhs) =>
      Bn254Fp6(c0: c0 + rhs.c0, c1: c1 + rhs.c1, c2: c2 + rhs.c2);
  Bn254Fp6 operator -(Bn254Fp6 rhs) =>
      Bn254Fp6(c0: c0 - rhs.c0, c1: c1 - rhs.c1, c2: c2 - rhs.c2);
  Bn254Fp6 operator -() => Bn254Fp6(c0: -c0, c1: -c1, c2: -c2);
  Bn254Fp6 operator *(Bn254Fp6 rhs) {
    final t0 = c0 * rhs.c0;
    final t1 = c1 * rhs.c1;
    final t2 = c2 * rhs.c2;
    return Bn254Fp6(
      c0: t0 + ((c1 + c2) * (rhs.c1 + rhs.c2) - t1 - t2).mulByNonresidue(),
      c1: (c0 + c1) * (rhs.c0 + rhs.c1) - t0 - t1 + t2.mulByNonresidue(),
      c2: t1 + (c0 + c2) * (rhs.c0 + rhs.c2) - t0 - t2,
    );
  }

  Bn254Fp6 square() {
    final t0 = c0.square();
    final t1 = (c0 * c1) + (c0 * c1);
    final t3 = (c1 * c2) + (c1 * c2);
    final t4 = c2.square();
    return Bn254Fp6(
      c0: t3.mulByNonresidue() + t0,
      c1: t4.mulByNonresidue() + t1,
      c2: t1 + (c0 - c1 + c2).square() + t3 - t0 - t4,
    );
  }

  Bn254Fp6? invert() {
    final t0 = c0.square() - (c2 * c1).mulByNonresidue();
    final t1 = c2.square().mulByNonresidue() - c0 * c1;
    final t2 = c1.square() - c0 * c2;
    final tmp = ((c1 * t2) + (c2 * t1)).mulByNonresidue() + (c0 * t0);
    final t = tmp.invert();
    if (t == null) return null;
    return Bn254Fp6(c0: t * t0, c1: t * t1, c2: t * t2);
  }

  /// Mul by v (the Fp12 non-residue): (c2·xi, c0, c1).
  Bn254Fp6 mulByNonresidue() =>
      Bn254Fp6(c0: c2.mulByNonresidue(), c1: c0, c2: c1);

  Bn254Fp6 mulByFp2(Bn254Fp2 rhs) =>
      Bn254Fp6(c0: c0 * rhs, c1: c1 * rhs, c2: c2 * rhs);

  /// Sparse mul by (0, b1).
  Bn254Fp6 mul1(Bn254Fp2 b1) =>
      Bn254Fp6(c0: (c2 * b1).mulByNonresidue(), c1: c0 * b1, c2: c1 * b1);

  /// Sparse mul by (b0, b1).
  Bn254Fp6 mul01(Bn254Fp2 b0, Bn254Fp2 b1) {
    final t0 = c0 * b0;
    final t1 = c1 * b1;
    return Bn254Fp6(
      c0: ((c1 + c2) * b1 - t1).mulByNonresidue() + t0,
      c1: (b0 + b1) * (c0 + c1) - t0 - t1,
      c2: (c0 + c2) * b0 - t0 + t1,
    );
  }

  // Frobenius coefficient tables: g1[j] = xi^((p^j-1)/3), g2 = g1².
  // j=0 is one (unused branches below skip index 0).
  static const g10 = Bn254Fp2(c0: Bn254Fp.one, c1: Bn254Fp.zero);
  static const g11 = Bn254Fp2(
    c0: Bn254Fp.unsafe([
      Uint64.unsafe(3044490000, 1164159792),
      Uint64.unsafe(880775624, 2846516308),
      Uint64.unsafe(2046849319, 606996881),
      Uint64.unsafe(425114840, 293737708),
    ]),
    c1: Bn254Fp.unsafe([
      Uint64.unsafe(1854185246, 2695513943),
      Uint64.unsafe(2853993325, 2314768705),
      Uint64.unsafe(3068597197, 4209035834),
      Uint64.unsafe(644435899, 1317202883),
    ]),
  );
  static const g12 = Bn254Fp2(
    c0: Bn254Fp.unsafe([
      Uint64.unsafe(860932238, 333974428),
      Uint64.unsafe(2110674300, 3680392889),
      Uint64.unsafe(1610724536, 3054851658),
      Uint64.unsafe(646112791, 33691616),
    ]),
    c1: Bn254Fp.zero,
  );
  static const g13 = Bn254Fp2(
    c0: Bn254Fp.unsafe([
      Uint64.unsafe(3383698167, 380464045),
      Uint64.unsafe(3004266538, 1252418226),
      Uint64.unsafe(435072868, 3796420596),
      Uint64.unsafe(539442807, 3812859778),
    ]),
    c1: Bn254Fp.unsafe([
      Uint64.unsafe(2898274400, 4157510572),
      Uint64.unsafe(959698305, 2074569548),
      Uint64.unsafe(1776687243, 1147962471),
      Uint64.unsafe(172360557, 1142410325),
    ]),
  );
  static const g14 = Bn254Fp2(
    c0: Bn254Fp.unsafe([
      Uint64.unsafe(1905462289, 3615678805),
      Uint64.unsafe(2797311100, 4290655011),
      Uint64.unsafe(2855285572, 3564377156),
      Uint64.unsafe(742080269, 643385667),
    ]),
    c1: Bn254Fp.zero,
  );
  static const g15 = Bn254Fp2(
    c0: Bn254Fp.unsafe([
      Uint64.unsafe(4179278374, 1424548785),
      Uint64.unsafe(1198639919, 3700608530),
      Uint64.unsafe(3702614752, 4237025077),
      Uint64.unsafe(659202453, 3449654244),
    ]),
    c1: Bn254Fp.unsafe([
      Uint64.unsafe(1560039598, 411115403),
      Uint64.unsafe(1269990451, 3410204812),
      Uint64.unsafe(1339252499, 3283444249),
      Uint64.unsafe(806963645, 801671226),
    ]),
  );

  static Bn254Fp2 _g1(int j) => switch (j) {
    1 => g11,
    2 => g12,
    3 => g13,
    4 => g14,
    5 => g15,
    _ => g10,
  };

  Bn254Fp6 frobeniusMap([int power = 1]) {
    final p = power % 6;
    if (p == 0) return this;
    final g1 = _g1(p);
    final g2 = g1.square();
    return Bn254Fp6(
      c0: c0.frobeniusMap(p),
      c1: c1.frobeniusMap(p) * g1,
      c2: c2.frobeniusMap(p) * g2,
    );
  }

  Bn254Fp6 double() => this + this;

  @override
  List<dynamic> get variables => [c0, c1, c2];
}
