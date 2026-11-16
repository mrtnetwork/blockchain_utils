import 'package:blockchain_utils/crypto/crypto/group/bls12_381/src/fp.dart';
import 'package:blockchain_utils/crypto/crypto/group/bls12_381/src/fp2.dart';
import 'package:blockchain_utils/utils/numbers/fixed/src/u64/u64.dart';
import 'package:blockchain_utils/utils/equatable/equatable.dart';

/// Cubic extension field GF(p⁶) over GF(p²), represented as c0 + c1·v + c2·v² with v³ = u + 1.
class Bls12Fp6 with Equality {
  final Bls12Fp2 c0;
  final Bls12Fp2 c1;
  final Bls12Fp2 c2;

  const Bls12Fp6({required this.c0, required this.c1, required this.c2});
  factory Bls12Fp6.conditionalSelect(Bls12Fp6 a, Bls12Fp6 b, bool choice) {
    return Bls12Fp6(
      c0: Bls12Fp2.conditionalSelect(a.c0, b.c0, choice),
      c1: Bls12Fp2.conditionalSelect(a.c1, b.c1, choice),
      c2: Bls12Fp2.conditionalSelect(a.c2, b.c2, choice),
    );
  }
  static const zero = Bls12Fp6(
    c0: Bls12Fp2.zero,
    c1: Bls12Fp2.zero,
    c2: Bls12Fp2.zero,
  );
  static const one = Bls12Fp6(
    c0: Bls12Fp2.one,
    c1: Bls12Fp2.zero,
    c2: Bls12Fp2.zero,
  );

  factory Bls12Fp6.fromFp(Bls12Fp f) =>
      Bls12Fp6(c0: Bls12Fp2.from(f), c1: Bls12Fp2.zero, c2: Bls12Fp2.zero);
  factory Bls12Fp6.fromBls12Fp2(Bls12Fp2 f) =>
      Bls12Fp6(c0: f, c1: Bls12Fp2.zero, c2: Bls12Fp2.zero);

  bool isZero() => c0.isZero() && c1.isZero() && c2.isZero();

  /// Operator overrides
  Bls12Fp6 operator +(Bls12Fp6 rhs) =>
      Bls12Fp6(c0: c0 + rhs.c0, c1: c1 + rhs.c1, c2: c2 + rhs.c2);

  Bls12Fp6 operator -(Bls12Fp6 rhs) =>
      Bls12Fp6(c0: c0 - rhs.c0, c1: c1 - rhs.c1, c2: c2 - rhs.c2);

  Bls12Fp6 operator -() => Bls12Fp6(c0: -c0, c1: -c1, c2: -c2);

  Bls12Fp6 operator *(Bls12Fp6 rhs) => mulInterleaved(rhs);

  /// Multiply by quadratic nonresidue v
  Bls12Fp6 mulByNonresidue() =>
      Bls12Fp6(c0: c2.mulByNonresidue(), c1: c0, c2: c1);

  /// Multiply by Bls12Fp2 element only in position c1
  Bls12Fp6 mulBy1(Bls12Fp2 rhsC1) => Bls12Fp6(
    c0: (c2 * rhsC1).mulByNonresidue(),
    c1: c0 * rhsC1,
    c2: c1 * rhsC1,
  );

  /// Multiply by Bls12Fp2 elements in positions c0 and c1
  Bls12Fp6 mulBy01(Bls12Fp2 rhsC0, Bls12Fp2 rhsC1) {
    final aA = c0 * rhsC0;
    final bB = c1 * rhsC1;

    final t1 = (c2 * rhsC1).mulByNonresidue() + aA;
    final t2 = (c0 + c1) * (rhsC0 + rhsC1) - aA - bB;
    final t3 = c2 * rhsC0 + bB;

    return Bls12Fp6(c0: t1, c1: t2, c2: t3);
  }

  /// Frobenius map
  Bls12Fp6 frobeniusMap() => Bls12Fp6(
    c0: c0.frobeniusMap(),
    c1:
        c1.frobeniusMap() *
        const Bls12Fp2(
          c0: Bls12Fp.zero,
          c1: Bls12Fp.unsafe([
            Uint64.unsafe(3439577572, 2255614065),
            Uint64.unsafe(1571496518, 533571026),
            Uint64.unsafe(1483752111, 3548715925),
            Uint64.unsafe(2394295998, 29019038),
            Uint64.unsafe(66682222, 2211467474),
            Uint64.unsafe(418390117, 1415808833),
          ]),
        ),
    c2:
        c2.frobeniusMap() *
        const Bls12Fp2(
          c1: Bls12Fp.zero,
          c0: Bls12Fp.unsafe([
            Uint64.unsafe(2299382244, 2255832515),
            Uint64.unsafe(720577107, 847619541),
            Uint64.unsafe(1351092326, 815496748),
            Uint64.unsafe(2718768012, 2122846244),
            Uint64.unsafe(350548047, 3806040168),
            Uint64.unsafe(350580031, 358909242),
          ]),
        ),
  );

  /// Interleaved multiplication (schoolbook optimized)
  Bls12Fp6 mulInterleaved(Bls12Fp6 b) {
    final a = this;

    final b10p = b.c1.c0 + b.c1.c1;
    final b10m = b.c1.c0 - b.c1.c1;
    final b20p = b.c2.c0 + b.c2.c1;
    final b20m = b.c2.c0 - b.c2.c1;

    return Bls12Fp6(
      c0: Bls12Fp2(
        c0: Bls12Fp.sumOfProducts(
          [a.c0.c0, -a.c0.c1, a.c1.c0, -a.c1.c1, a.c2.c0, -a.c2.c1],
          [b.c0.c0, b.c0.c1, b20m, b20p, b10m, b10p],
        ),
        c1: Bls12Fp.sumOfProducts(
          [a.c0.c0, a.c0.c1, a.c1.c0, a.c1.c1, a.c2.c0, a.c2.c1],
          [b.c0.c1, b.c0.c0, b20p, b20m, b10p, b10m],
        ),
      ),
      c1: Bls12Fp2(
        c0: Bls12Fp.sumOfProducts(
          [a.c0.c0, -a.c0.c1, a.c1.c0, -a.c1.c1, a.c2.c0, -a.c2.c1],
          [b.c1.c0, b.c1.c1, b.c0.c0, b.c0.c1, b20m, b20p],
        ),
        c1: Bls12Fp.sumOfProducts(
          [a.c0.c0, a.c0.c1, a.c1.c0, a.c1.c1, a.c2.c0, a.c2.c1],
          [b.c1.c1, b.c1.c0, b.c0.c1, b.c0.c0, b20p, b20m],
        ),
      ),
      c2: Bls12Fp2(
        c0: Bls12Fp.sumOfProducts(
          [a.c0.c0, -a.c0.c1, a.c1.c0, -a.c1.c1, a.c2.c0, -a.c2.c1],
          [b.c2.c0, b.c2.c1, b.c1.c0, b.c1.c1, b.c0.c0, b.c0.c1],
        ),
        c1: Bls12Fp.sumOfProducts(
          [a.c0.c0, a.c0.c1, a.c1.c0, a.c1.c1, a.c2.c0, a.c2.c1],
          [b.c2.c1, b.c2.c0, b.c1.c1, b.c1.c0, b.c0.c1, b.c0.c0],
        ),
      ),
    );
  }

  /// Squaring
  Bls12Fp6 square() {
    final s0 = c0.square();
    final ab = c0 * c1;
    final s1 = ab + ab;
    final s2 = (c0 - c1 + c2).square();
    final bc = c1 * c2;
    final s3 = bc + bc;
    final s4 = c2.square();

    return Bls12Fp6(
      c0: s3.mulByNonresidue() + s0,
      c1: s4.mulByNonresidue() + s1,
      c2: s1 + s2 + s3 - s0 - s4,
    );
  }

  /// Inversion
  Bls12Fp6? invert() {
    Bls12Fp2 c0 = (this.c1 * this.c2).mulByNonresidue();
    c0 = this.c0.square() - c0;

    Bls12Fp2 c1 = this.c2.square().mulByNonresidue();
    c1 = c1 - (this.c0 * this.c1);

    Bls12Fp2 c2 = this.c1.square();
    c2 = c2 - (this.c0 * this.c2);

    Bls12Fp2 tmp = ((this.c1 * c2) + (this.c2 * c1)).mulByNonresidue();
    tmp = tmp + (this.c0 * c0);

    final t = tmp.invert();
    if (t == null) return null;
    return Bls12Fp6(c0: t * c0, c1: t * c1, c2: t * c2);
  }

  @override
  List<dynamic> get variables => [c0, c1, c2];
}
