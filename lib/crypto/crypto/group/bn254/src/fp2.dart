// Fp2 = Fp[u]/(u^2+1), same tower as BLS (beta = -1).
// G2 curve: y^2 = x^3 + B2 where B2 = 3/(9+u), stored as (c0, c1).
import 'package:blockchain_utils/crypto/crypto/group/bn254/src/fp.dart';
import 'package:blockchain_utils/utils/numbers/fixed/src/u64/u64.dart';
import 'package:blockchain_utils/utils/equatable/equatable.dart';

class BnFp2SqrtResult {
  final Bn254Fp2 result;
  final bool isSquare;
  const BnFp2SqrtResult(this.result, this.isSquare);
}

class Bn254Fp2 with Equality {
  final Bn254Fp c0;
  final Bn254Fp c1;
  const Bn254Fp2({required this.c0, required this.c1});

  factory Bn254Fp2.conditionalSelect(Bn254Fp2 a, Bn254Fp2 b, bool choice) {
    return Bn254Fp2(
      c0: Bn254Fp.conditionalSelect(a.c0, b.c0, choice),
      c1: Bn254Fp.conditionalSelect(a.c1, b.c1, choice),
    );
  }

  factory Bn254Fp2.conditionalSelectMask(Bn254Fp2 a, Bn254Fp2 b, Uint64 bit) {
    return Bn254Fp2(
      c0: Bn254Fp.conditionalSelectMask(a.c0, b.c0, bit),
      c1: Bn254Fp.conditionalSelectMask(a.c1, b.c1, bit),
    );
  }

  // split const to satisfy Dart const rules (nested unsafe is const)
  static const c1b = Bn254Fp.unsafe([
    Uint64.unsafe(954723532, 3520921447),
    Uint64.unsafe(1710273405, 2479754558),
    Uint64.unsafe(3611939037, 581697706),
    Uint64.unsafe(21084622, 1248365901),
  ]);

  // B2 = 3/(u+9): c0 = 0x2b149d..., c1 = 0x9713b... (Montgomery below)
  static const b = Bn254Fp2(
    c0: Bn254Fp.unsafe([
      Uint64.unsafe(1006188771, 2008548008),
      Uint64.unsafe(34282279, 909333341),
      Uint64.unsafe(649588208, 1232425568),
      Uint64.unsafe(622118450, 1132767341),
    ]),
    c1: c1b,
  );

  static const zero = Bn254Fp2(c0: Bn254Fp.zero, c1: Bn254Fp.zero);
  static const one = Bn254Fp2(c0: Bn254Fp.one, c1: Bn254Fp.zero);

  // 9 in Montgomery form, for xi = 9+u tower arithmetic.
  static const nine = Bn254Fp.unsafe([
    Uint64.unsafe(4127606734, 1091403767),
    Uint64.unsafe(792555341, 3541815313),
    Uint64.unsafe(692269950, 960546513),
    Uint64.unsafe(496343272, 2816710743),
  ]);

  // 1/2 in Montgomery form.
  static const inv2 = Bn254Fp.unsafe([
    Uint64.unsafe(2277435346, 1325794674),
    Uint64.unsafe(3506252509, 790391525),
    Uint64.unsafe(2405397650, 4244459332),
    Uint64.unsafe(523723546, 1033682860),
  ]);

  factory Bn254Fp2.b3() {
    final b = Bn254Fp2.b;
    return b + b + b;
  }

  Bn254Fp2 conjugate() => Bn254Fp2(c0: c0, c1: -c1);
  Bn254Fp2 operator -() => Bn254Fp2(c0: -c0, c1: -c1);
  Bn254Fp2 operator +(Bn254Fp2 rhs) =>
      Bn254Fp2(c0: c0 + rhs.c0, c1: c1 + rhs.c1);
  Bn254Fp2 operator -(Bn254Fp2 rhs) =>
      Bn254Fp2(c0: c0 - rhs.c0, c1: c1 - rhs.c1);

  Bn254Fp2 operator *(Bn254Fp2 rhs) {
    final t0 = c0 * rhs.c0;
    final t1 = c1 * rhs.c1;
    final c0Res = t0 - t1;
    final c1Res = (c0 + c1) * (rhs.c0 + rhs.c1) - t0 - t1;
    return Bn254Fp2(c0: c0Res, c1: c1Res);
  }

  Bn254Fp2 square() {
    final a = c0 + c1;
    final b = c0 - c1;
    final c = c0 + c0;
    return Bn254Fp2(c0: a * b, c1: c * c1);
  }

  /// Tower non-residue xi = 9+u (BN sextic tower seed, NOT u+1).
  /// Matches noble `Fp2.NONRESIDUE = (9,1)`; this is what Fp6.mulByNonresidue needs.
  Bn254Fp2 mulByNonresidue() {
    // (c0 + c1*u)(9+u) = (9*c0 - c1) + (c0 + 9*c1)*u
    final n1 = c1 * nine;
    return Bn254Fp2(c0: c0 * nine - c1, c1: c0 + n1);
  }

  /// Mul by (u+1) — kept for completeness, unused by the BN tower.
  Bn254Fp2 mulByUplus1() => Bn254Fp2(c0: c0 - c1, c1: c0 + c1);

  /// Mul by G2 curve constant B2.
  Bn254Fp2 mulByB() => this * Bn254Fp2.b;

  /// Helper for Fp12 cyclotomic squaring: (a²·xi + b², (a+b)² - a² - b²).
  static (Bn254Fp2, Bn254Fp2) fp4Square(Bn254Fp2 a, Bn254Fp2 b) {
    final a2 = a.square();
    final b2 = b.square();
    return (b2.mulByNonresidue() + a2, (a + b).square() - a2 - b2);
  }

  bool isZero() => c0.isZero() && c1.isZero();

  bool lexicographicallyLargest() =>
      c1.lexicographicallyLargest() ||
      (c1.isZero() && c0.lexicographicallyLargest());

  Bn254Fp2? invert() {
    final t = (c0 * c0 + c1 * c1).invert();
    if (t == null) return null;
    return Bn254Fp2(c0: c0 * t, c1: -c1 * t);
  }

  Bn254Fp2 frobeniusMap([int power = 1]) => power % 2 == 0 ? this : conjugate();

  Bn254Fp2 powVarTime(List<Uint64> exponent) {
    var res = Bn254Fp2.one;
    for (var limb in exponent.reversed) {
      for (var i = 63; i >= 0; i--) {
        res = res.square();
        if ((limb >> i) & Uint64.one == Uint64.one) {
          res = res * this;
        }
      }
    }
    return res;
  }

  BnFp2SqrtResult sqrt() {
    if (isZero()) return BnFp2SqrtResult(Bn254Fp2.zero, true);
    // Same u^((p-3)/4)-style chain as Bls12Fp2, but with BN254 exponents.
    // m = (p-3)/4 for Fp arithmetic on the norm path below.
    // We reuse the generic Fp2 sqrt shape: a1 = self^((p-3)/4) over Fp2
    // where the exponent below equals Bls12's m with BN limbs.
    const m = [
      Uint64.unsafe(1325933317, 3055501137),
      Uint64.unsafe(1709202084, 1511813795),
      Uint64.unsafe(1846808941, 2690668055),
      Uint64.unsafe(202970012, 3092015114),
    ];
    final a1 = powVarTime(m);
    final alpha = a1.square() * this;
    final x0 = a1 * this;
    if (alpha == -Bn254Fp2.one) {
      final sqrt = Bn254Fp2(c0: -x0.c1, c1: x0.c0);
      return BnFp2SqrtResult(sqrt, sqrt.square() == this);
    }
    const m2 = [
      Uint64.unsafe(2651866635, 1816034979),
      Uint64.unsafe(3418404168, 3023627590),
      Uint64.unsafe(3693617883, 1086368814),
      Uint64.unsafe(405940025, 1889062932),
    ];
    final sqrt = (alpha + Bn254Fp2.one).powVarTime(m2) * x0;
    return BnFp2SqrtResult(sqrt, sqrt.square() == this);
  }

  bool sgn0() {
    final sign0 = c0.sgn0();
    final zero0 = c0.isZero();
    final sign1 = c1.sgn0();
    return sign0 || (zero0 && sign1);
  }

  Bn254Fp2 double() => this + this;

  @override
  List<dynamic> get variables => [c0, c1];
}
