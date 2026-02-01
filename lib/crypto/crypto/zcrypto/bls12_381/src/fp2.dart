import 'package:blockchain_utils/crypto/crypto/ec/core/field.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/bls12_381/src/fp.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/pasta/utils/utils.dart';
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

  const Bls12Fp2({required this.c0, required this.c1});

  factory Bls12Fp2.from(Bls12Fp f) => Bls12Fp2(c0: f, c1: Bls12Fp.zero());

  factory Bls12Fp2.b() {
    return Bls12Fp2(c0: Bls12Fp.b(), c1: Bls12Fp.b());
  }
  factory Bls12Fp2.b3() {
    final b = Bls12Fp2.b();
    return b + b + b;
  }

  /// Zero element
  factory Bls12Fp2.zero() => Bls12Fp2(c0: Bls12Fp.zero(), c1: Bls12Fp.zero());

  /// One element
  factory Bls12Fp2.one() => Bls12Fp2(c0: Bls12Fp.one(), c1: Bls12Fp.zero());

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

  Bls12Fp2 powVarTime(List<BigInt> exponent) {
    var res = Bls12Fp2.one();
    for (var limb in exponent.reversed) {
      for (var i = 63; i >= 0; i--) {
        res = res.square();
        if ((limb >> i) & BigInt.one == BigInt.one) {
          res = res * this;
        }
      }
    }
    return res;
  }

  @override
  FieldSqrtResult<Bls12Fp2> sqrt() {
    if (isZero()) {
      return FieldSqrtResult(Bls12Fp2.zero(), true);
    }

    // a1 = self^((p - 3) / 4)
    final a1 = powVarTime([
      BigInt.parse('0xee7fbfffffffeaaa'),
      BigInt.parse('0x07aaffffac54ffff'),
      BigInt.parse('0xd9cc34a83dac3d89'),
      BigInt.parse('0xd91dd2e13ce144af'),
      BigInt.parse('0x92c6e9ed90d2eb35'),
      BigInt.parse('0x0680447a8e5ff9a6'),
    ]);

    // alpha = a1^2 * self = self^((p - 1) / 2)
    final alpha = a1.square() * this;

    // x0 = self^((p + 1) / 4)
    final x0 = a1 * this;

    // Case 1: alpha == -1
    if (alpha == -Bls12Fp2.one()) {
      final sqrt = Bls12Fp2(c0: -x0.c1, c1: x0.c0);

      // Verify sqrt^2 == self
      return FieldSqrtResult(sqrt, sqrt.square() == this);
    }

    // Case 2: general case
    final sqrt =
        (alpha + Bls12Fp2.one()).powVarTime([
          BigInt.parse('0xdcff7fffffffd555'),
          BigInt.parse('0x0f55ffff58a9ffff'),
          BigInt.parse('0xb39869507b587b12'),
          BigInt.parse('0xb23ba5c279c2895f'),
          BigInt.parse('0x258dd3db21a5d66b'),
          BigInt.parse('0x0d0088f51cbff34d'),
        ]) *
        x0;

    // Final verification
    return FieldSqrtResult(sqrt, sqrt.square() == this);
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

/// Implements arithmetic over the quadratic extension field Fp2.
class Bls12NativeFp2 with Equality implements CryptoField<Bls12NativeFp2> {
  final Bls12NativeFp c0;
  final Bls12NativeFp c1;
  factory Bls12NativeFp2.conditionalSelect(
    Bls12NativeFp2 a,
    Bls12NativeFp2 b,
    bool choice,
  ) {
    return Bls12NativeFp2(
      c0: Bls12NativeFp.conditionalSelect(a.c0, b.c0, choice),
      c1: Bls12NativeFp.conditionalSelect(a.c1, b.c1, choice),
    );
  }

  const Bls12NativeFp2({required this.c0, required this.c1});
  Bls12NativeFp2 copyWith({Bls12NativeFp? c0, Bls12NativeFp? c1}) {
    return Bls12NativeFp2(c0: c0 ?? this.c0, c1: c1 ?? this.c1);
  }

  factory Bls12NativeFp2.from(Bls12NativeFp f) =>
      Bls12NativeFp2(c0: f, c1: Bls12NativeFp.zero());

  factory Bls12NativeFp2.b() {
    return Bls12NativeFp2(c0: Bls12NativeFp.b(), c1: Bls12NativeFp.b());
  }
  factory Bls12NativeFp2.b3() {
    final b = Bls12NativeFp2.b();
    return b + b + b;
  }
  static final _zero = Bls12NativeFp2(
    c0: Bls12NativeFp.zero(),
    c1: Bls12NativeFp.zero(),
  );

  /// Zero element
  factory Bls12NativeFp2.zero() => _zero;
  static final _one = Bls12NativeFp2(
    c0: Bls12NativeFp.one(),
    c1: Bls12NativeFp.zero(),
  );

  /// One element
  factory Bls12NativeFp2.one() => _one;

  Bls12NativeFp2 conjugate() => Bls12NativeFp2(c0: c0, c1: -c1);

  @override
  Bls12NativeFp2 operator -() => Bls12NativeFp2(c0: -c0, c1: -c1);

  /// Add two Fp2 elements
  @override
  Bls12NativeFp2 operator +(Bls12NativeFp2 rhs) =>
      Bls12NativeFp2(c0: c0 + rhs.c0, c1: c1 + rhs.c1);

  /// Subtract two Fp2 elements
  @override
  Bls12NativeFp2 operator -(Bls12NativeFp2 rhs) =>
      Bls12NativeFp2(c0: c0 - rhs.c0, c1: c1 - rhs.c1);

  /// Multiply two Fp2 elements
  @override
  Bls12NativeFp2 operator *(Bls12NativeFp2 rhs) {
    final t0 = c0 * rhs.c0;
    final t1 = c1 * rhs.c1;
    final c0Res = t0 - t1; // c0 = a0*b0 - a1*b1
    final c1Res = (c0 + c1) * (rhs.c0 + rhs.c1) - t0 - t1; // c1 = a0*b1 + a1*b0
    return Bls12NativeFp2(c0: c0Res, c1: c1Res);
  }

  /// Complex squaring
  @override
  Bls12NativeFp2 square() {
    final a = c0 + c1;
    final b = c0 - c1;
    final c = c0 + c0; // 2 * c0
    return Bls12NativeFp2(c0: a * b, c1: c * c1);
  }

  /// Multiply by non-residue (u + 1, beta = -1)
  Bls12NativeFp2 mulByNonresidue() => Bls12NativeFp2(c0: c0 - c1, c1: c0 + c1);

  /// Check if zero
  @override
  bool isZero() => c0.isZero() && c1.isZero();

  bool lexicographicallyLargest() =>
      c1.lexicographicallyLargest() ||
      (c1.isZero() && c0.lexicographicallyLargest());

  /// Inverse in Fp2
  @override
  Bls12NativeFp2? invert() {
    final t = (c0 * c0 + c1 * c1).invert();
    if (t == null) return null;
    return Bls12NativeFp2(c0: c0 * t, c1: -c1 * t);
  }

  /// Raises this element to p.
  Bls12NativeFp2 frobeniusMap() => conjugate();

  /// Raise to exponent given as 6-limb BigInt array (u64)
  Bls12NativeFp2 powVarTime(List<BigInt> exponent) {
    var res = Bls12NativeFp2.one();
    for (var limb in exponent.reversed) {
      for (var i = 63; i >= 0; i--) {
        res = res.square();
        if ((limb >> i) & BigInt.one == BigInt.one) {
          res = res * this;
        }
      }
    }
    return res;
  }

  Bls12NativeFp2 pow(BigInt exp) => _exp(exp);

  Bls12NativeFp2 _exp(BigInt e) {
    var result = Bls12NativeFp2.one();
    var base = this;
    var k = e;

    while (k > BigInt.zero) {
      if (k.isOdd) result = result * base;
      base = base * base;
      k >>= 1;
    }
    return result;
  }

  @override
  FieldSqrtResult<Bls12NativeFp2> sqrt() {
    // Zero is a quadratic residue; sqrt(0) = 0
    if (isZero()) {
      return FieldSqrtResult(Bls12NativeFp2.zero(), true);
    }

    // a1 = self^((p - 3) / 4)
    final a1 = _exp(
      BigInt.parse(
        "1000602388805416848354447456433976039139220704984751971333014534031007912622709466110671907282253916009473568139946",
      ),
    );

    // alpha = a1^2 * self = self^((p - 1) / 2)
    final alpha = a1.square() * this;

    // x0 = self^((p + 1) / 4)
    final x0 = a1 * this;

    // Case 1: alpha == -1
    if (alpha == -Bls12NativeFp2.one()) {
      final sqrt = Bls12NativeFp2(c0: -x0.c1, c1: x0.c0);

      // Verify sqrt^2 == self
      return FieldSqrtResult(sqrt, sqrt.square() == this);
    }

    // Case 2: general case
    final sqrt =
        (alpha + Bls12NativeFp2.one())._exp(
          BigInt.parse(
            "2001204777610833696708894912867952078278441409969503942666029068062015825245418932221343814564507832018947136279893",
          ),
        ) *
        x0;

    // Final verification
    return FieldSqrtResult(sqrt, sqrt.square() == this);
  }

  @override
  List<dynamic> get variables => [c0, c1];

  @override
  Bls12NativeFp2 double() {
    return this + this;
  }
}
