import 'package:blockchain_utils/crypto/crypto/group/core/field.dart';
import 'package:blockchain_utils/crypto/crypto/group/bls12_381/src/fp.dart';
import 'package:blockchain_utils/crypto/crypto/group/pasta/utils/utils.dart';
import 'package:blockchain_utils/utils/numbers/fixed/src/u64/u64.dart';
import 'package:blockchain_utils/utils/equatable/equatable.dart';

/// Implements arithmetic over the quadratic extension field Fp2.
class Bls12Fp2 with Equality implements CryptoField<Bls12Fp2> {
  final Bls12Fp c0;
  final Bls12Fp c1;
  factory Bls12Fp2.conditionalSelect(Bls12Fp2 a, Bls12Fp2 b, bool choice) {
    return Bls12Fp2(
      c0: Bls12Fp.conditionalSelect(a.c0, b.c0, choice),
      c1: Bls12Fp.conditionalSelect(a.c1, b.c1, choice),
    );
  }

  /// Mask form of [conditionalSelect]: [bit] is a 0/1 [Uint64] (never a
  /// `bool`), so the whole select is straight-line limb arithmetic.
  factory Bls12Fp2.conditionalSelectMask(Bls12Fp2 a, Bls12Fp2 b, Uint64 bit) {
    return Bls12Fp2(
      c0: Bls12Fp.conditionalSelectMask(a.c0, b.c0, bit),
      c1: Bls12Fp.conditionalSelectMask(a.c1, b.c1, bit),
    );
  }

  const Bls12Fp2({required this.c0, required this.c1});
  Bls12Fp2 copyWith({Bls12Fp? c0, Bls12Fp? c1}) {
    return Bls12Fp2(c0: c0 ?? this.c0, c1: c1 ?? this.c1);
  }

  factory Bls12Fp2.from(Bls12Fp f) => Bls12Fp2(c0: f, c1: Bls12Fp.zero);

  static const b = Bls12Fp2(c0: Bls12Fp.b, c1: Bls12Fp.b);
  static const zero = Bls12Fp2(c0: Bls12Fp.zero, c1: Bls12Fp.zero);
  static const one = Bls12Fp2(c0: Bls12Fp.one, c1: Bls12Fp.zero);

  factory Bls12Fp2.b3() {
    final b = Bls12Fp2.b;
    return b + b + b;
  }

  /// Conjugate: a + bu -> a - bu
  Bls12Fp2 conjugate() => Bls12Fp2(c0: c0, c1: -c1);

  /// Negation: -(a + bu) = -a - bu
  @override
  Bls12Fp2 operator -() => Bls12Fp2(c0: -c0, c1: -c1);

  /// Add two Fp2 elements
  @override
  Bls12Fp2 operator +(Bls12Fp2 rhs) =>
      Bls12Fp2(c0: c0 + rhs.c0, c1: c1 + rhs.c1);

  /// Subtract two Fp2 elements
  @override
  Bls12Fp2 operator -(Bls12Fp2 rhs) =>
      Bls12Fp2(c0: c0 - rhs.c0, c1: c1 - rhs.c1);

  /// Multiply two Fp2 elements
  @override
  Bls12Fp2 operator *(Bls12Fp2 rhs) {
    // Karatsuba / schoolbook multiplication with beta = -1
    final t0 = c0 * rhs.c0;
    final t1 = c1 * rhs.c1;
    final c0Res = t0 - t1; // c0 = a0*b0 - a1*b1
    final c1Res = (c0 + c1) * (rhs.c0 + rhs.c1) - t0 - t1; // c1 = a0*b1 + a1*b0
    return Bls12Fp2(c0: c0Res, c1: c1Res);
  }

  /// Complex squaring
  @override
  Bls12Fp2 square() {
    final a = c0 + c1;
    final b = c0 - c1;
    final c = c0 + c0; // 2 * c0
    return Bls12Fp2(c0: a * b, c1: c * c1);
  }

  /// Multiply by non-residue (u + 1, beta = -1)
  Bls12Fp2 mulByNonresidue() => Bls12Fp2(c0: c0 - c1, c1: c0 + c1);

  /// Check if zero
  @override
  bool isZero() => c0.isZero() && c1.isZero();

  bool lexicographicallyLargest() =>
      c1.lexicographicallyLargest() ||
      (c1.isZero() && c0.lexicographicallyLargest());

  /// Inverse in Fp2
  @override
  Bls12Fp2? invert() {
    final t = (c0 * c0 + c1 * c1).invert();
    if (t == null) return null;
    return Bls12Fp2(c0: c0 * t, c1: -c1 * t);
  }

  /// Raises this element to p.
  Bls12Fp2 frobeniusMap() => conjugate();

  Bls12Fp2 powVarTime(List<Uint64> exponent) {
    var res = Bls12Fp2.one;
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

  @override
  FieldSqrtResult<Bls12Fp2> sqrt() {
    if (isZero()) {
      return FieldSqrtResult(Bls12Fp2.zero, true);
    }
    const m = [
      Uint64.unsafe(4001349631, 4294961834),
      Uint64.unsafe(128647167, 2891251711),
      Uint64.unsafe(3654038696, 1034698121),
      Uint64.unsafe(3642610401, 1021396143),
      Uint64.unsafe(2462509549, 2429741877),
      Uint64.unsafe(109069434, 2388654502),
    ];

    // a1 = self^((p - 3) / 4)
    final a1 = powVarTime(m);

    // alpha = a1^2 * self = self^((p - 1) / 2)
    final alpha = a1.square() * this;

    // x0 = self^((p + 1) / 4)
    final x0 = a1 * this;

    // Case 1: alpha == -1
    if (alpha == -Bls12Fp2.one) {
      final sqrt = Bls12Fp2(c0: -x0.c1, c1: x0.c0);

      // Verify sqrt^2 == self
      return FieldSqrtResult(sqrt, sqrt.square() == this);
    }
    const m2 = [
      Uint64.unsafe(3707731967, 4294956373),
      Uint64.unsafe(257294335, 1487536127),
      Uint64.unsafe(3013110096, 2069396242),
      Uint64.unsafe(2990253506, 2042792287),
      Uint64.unsafe(630051803, 564516459),
      Uint64.unsafe(218138869, 482341709),
    ];
    // Case 2: general case
    final sqrt = (alpha + Bls12Fp2.one).powVarTime(m2) * x0;

    // Final verification
    return FieldSqrtResult(sqrt, sqrt.square() == this);
  }

  // On Bls12Fp2
  bool sgn0() {
    final sign0 = c0.sgn0();
    final zero0 = c0.isZero();
    final sign1 = c1.sgn0();
    return sign0 || (zero0 && sign1);
  }

  @override
  String toString() => '$c0 + $c1*u';

  @override
  List<dynamic> get variables => [c0, c1];

  @override
  Bls12Fp2 double() {
    return this + this;
  }
}
