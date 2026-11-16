import 'package:blockchain_utils/crypto/crypto/group/core/point.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/crypto/crypto/group/bls12_381/src/fp12.dart';
import 'package:blockchain_utils/crypto/crypto/group/bls12_381/src/fp2.dart';
import 'package:blockchain_utils/crypto/crypto/group/bls12_381/src/fp6.dart';
import 'package:blockchain_utils/crypto/crypto/group/bls12_381/src/g1.dart';
import 'package:blockchain_utils/crypto/crypto/group/bls12_381/src/g2.dart';
import 'package:blockchain_utils/crypto/crypto/group/jubjub/fields/field.dart';
import 'package:blockchain_utils/helper/helper.dart';
import 'package:blockchain_utils/utils/binary/src/utils.dart';
import 'package:blockchain_utils/utils/numbers/fixed/src/u64/u64.dart';

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';
import 'package:blockchain_utils/utils/equatable/equatable.dart';

import 'package:blockchain_utils/crypto/crypto/group/bls12_381/src/pairing/types.dart';

/// Utilities for computing pairings and Miller loop operations on BLS12-381.
class Bls12PairingUtils {
  /// The BLS parameter x (`0xd201000000010000`) used in Miller loop.
  static const Uint64 blsX = Uint64.unsafe(3523280896, 65536);

  /// Performs the Miller loop using the given driver.
  static D millerLoop<D extends Object?>(MillerLoopDriver<D> deriver) {
    D f = deriver.one();
    const blsX = Bls12PairingUtils.blsX;
    bool foundOne = false;
    for (int b = 63; b >= 0; b--) {
      bool i = (((blsX >> 1) >> b) & Uint64.one) == Uint64.one;
      if (!foundOne) {
        foundOne = i;
        continue;
      }
      f = deriver.doublingStep(f);

      if (i) {
        f = deriver.additionStep(f);
      }

      f = deriver.squareOutput(f);
    }

    f = deriver.doublingStep(f);

    f = deriver.conjugate(f);

    return f;
  }

  /// Evaluates the line function in the Miller loop (ell function).
  static Bls12Fp12 ell(
    Bls12Fp12 f,
    (Bls12Fp2, Bls12Fp2, Bls12Fp2) coeffs,
    G1AffinePoint p,
  ) {
    Bls12Fp2 c0 = coeffs.$1;
    Bls12Fp2 c1 = coeffs.$2;
    c0 = c0.copyWith(c0: c0.c0 * p.y, c1: c0.c1 * p.y);
    c1 = c1.copyWith(c0: c1.c0 * p.x, c1: c1.c1 * p.x);
    return f.mulBy014(coeffs.$3, c1, c0);
  }

  /// Performs a doubling step on a G2 point and returns the new point with line coefficients.
  static (G2Projective, (Bls12Fp2, Bls12Fp2, Bls12Fp2)) doublingStep(
    G2Projective r,
  ) {
    Bls12Fp2 tmp0 = r.x.square();
    Bls12Fp2 tmp1 = r.y.square();
    Bls12Fp2 tmp2 = tmp1.square();
    Bls12Fp2 tmp3 = (tmp1 + r.x).square() - tmp0 - tmp2;
    tmp3 = tmp3 + tmp3;
    Bls12Fp2 tmp4 = tmp0 + tmp0 + tmp0;
    Bls12Fp2 tmp6 = r.x + tmp4;
    Bls12Fp2 tmp5 = tmp4.square();
    Bls12Fp2 zsquared = r.z.square();
    r = r.copyWith(x: tmp5 - tmp3 - tmp3);
    r = r.copyWith(z: (r.z + r.y).square() - tmp1 - zsquared);
    r = r.copyWith(y: (tmp3 - r.x) * tmp4);
    tmp2 = tmp2 + tmp2;
    tmp2 = tmp2 + tmp2;
    tmp2 = tmp2 + tmp2;
    r = r.copyWith(y: r.y - tmp2);
    tmp3 = tmp4 * zsquared;
    tmp3 = tmp3 + tmp3;
    tmp3 = -tmp3;
    tmp6 = tmp6.square() - tmp0 - tmp5;
    tmp1 = tmp1 + tmp1;
    tmp1 = tmp1 + tmp1;
    tmp6 = tmp6 - tmp1;
    tmp0 = r.z * zsquared;
    tmp0 = tmp0 + tmp0;
    return (r, (tmp0, tmp3, tmp6));
  }

  /// Performs an addition step in the Miller loop and returns the new point with line coefficients.
  static (G2Projective, (Bls12Fp2, Bls12Fp2, Bls12Fp2)) additionStep(
    G2Projective r,
    G2AffinePoint q,
  ) {
    Bls12Fp2 zsquared = r.z.square();
    Bls12Fp2 ysquared = q.y.square();
    Bls12Fp2 t0 = zsquared * q.x;
    Bls12Fp2 t1 = ((q.y + r.z).square() - ysquared - zsquared) * zsquared;
    Bls12Fp2 t2 = t0 - r.x;
    Bls12Fp2 t3 = t2.square();
    Bls12Fp2 t4 = t3 + t3;
    t4 = t4 + t4;
    Bls12Fp2 t5 = t4 * t2;
    Bls12Fp2 t6 = t1 - r.y - r.y;
    Bls12Fp2 t9 = t6 * q.x;
    Bls12Fp2 t7 = t4 * r.x;
    r = r.copyWith(x: t6.square() - t5 - t7 - t7);
    r = r.copyWith(z: (r.z + t2).square() - zsquared - t3);
    Bls12Fp2 t10 = q.y + r.z;
    Bls12Fp2 t8 = (t7 - r.x) * t6;
    t0 = r.y * t5;
    t0 = t0 + t0;
    r = r.copyWith(y: t8 - t0);
    t10 = t10.square() - ysquared;
    Bls12Fp2 ztsquared = r.z.square();
    t10 = t10 - ztsquared;
    t9 = t9 + t9 - t10;
    t10 = r.z + r.z;
    t6 = -t6;
    t1 = t6 + t6;
    return (r, (t10, t1, t9));
  }

  /// Computes the optimal Ate pairing e(P, Q) ∈ GT for affine points P and Q.
  static Gt pairing(G1AffinePoint p, G2AffinePoint q) {
    final identity = p.isIdentity() || q.isIdentity();
    final newP = G1AffinePoint.conditionalSelect(
      p,
      G1AffinePoint.generator,
      identity,
    );
    final newQ = G2AffinePoint.conditionalSelect(
      q,
      G2AffinePoint.generator,
      identity,
    );
    final adder = MillerLoopDriverBls12Pairing(
      cur: newQ.toProjective(),
      base: newQ,
      p: newP,
    );
    final tmp = millerLoop(adder);
    final result = MillerLoopResultBls12(
      Bls12Fp12.conditionalSelect(tmp, Bls12Fp12.one, identity),
    );
    return result.finalExponentiation();
  }
}

/// Precomputes Miller loop coefficients for a G2 point to speed up pairings.
class G2Prepared {
  final List<(Bls12Fp2, Bls12Fp2, Bls12Fp2)> coeffs;

  /// Whether the point is the point at infinity.
  final bool infinity;
  const G2Prepared({required this.coeffs, required this.infinity});
  factory G2Prepared.fromG2(G2AffinePoint q) {
    bool isIdentity = q.isIdentity();
    final a = G2AffinePoint.conditionalSelect(
      q,
      G2AffinePoint.generator,
      isIdentity,
    );

    final adder = _G2AffineMillerLoopDriver(
      cur: G2Projective.fromAffine(q),
      base: a,
    );
    Bls12PairingUtils.millerLoop(adder);
    assert(adder.length == 68);
    return G2Prepared(coeffs: adder._coeffs, infinity: isIdentity);
  }
}

/// The accumulated (unreduced) output of the Miller loop; call
/// [MillerLoopResultBls12.finalExponentiation] to get a [Gt] element.
class MillerLoopResultBls12 {
  final Bls12Fp12 inner;
  const MillerLoopResultBls12(this.inner);

  // Helper: fp4 squaring
  static (Bls12Fp2, Bls12Fp2) fp4Square(Bls12Fp2 a, Bls12Fp2 b) {
    Bls12Fp2 t0 = a.square();
    Bls12Fp2 t1 = b.square();
    Bls12Fp2 t2 = t1.mulByNonresidue();
    Bls12Fp2 c0 = t2 + t0;
    t2 = a + b;
    t2 = t2.square();
    t2 -= t0;
    Bls12Fp2 c1 = t2 - t1;

    return (c0, c1);
  }

  // Cyclotomic squaring
  static Bls12Fp12 cyclotomicSquare(Bls12Fp12 f) {
    Bls12Fp2 z0 = f.c0.c0;
    Bls12Fp2 z4 = f.c0.c1;
    Bls12Fp2 z3 = f.c0.c2;
    Bls12Fp2 z2 = f.c1.c0;
    Bls12Fp2 z1 = f.c1.c1;
    Bls12Fp2 z5 = f.c1.c2;

    var t = fp4Square(z0, z1);
    var t0 = t.$1;
    var t1 = t.$2;
    // For A
    z0 = t0 - z0;
    z0 = z0 + z0 + t0;

    z1 = t1 + z1;
    z1 = z1 + z1 + t1;

    t = fp4Square(z2, z3);
    t0 = t.$1;
    t1 = t.$2;
    t = fp4Square(z4, z5);
    var t2 = t.$1;
    var t3 = t.$2;
    // For C
    z4 = t0 - z4;
    z4 = z4 + z4 + t0;

    z5 = t1 + z5;
    z5 = z5 + z5 + t1;

    // For B
    t0 = t3.mulByNonresidue();
    z2 = t0 + z2;
    z2 = z2 + z2 + t0;

    z3 = t2 - z3;
    z3 = z3 + z3 + t2;

    return Bls12Fp12(
      c0: Bls12Fp6(c0: z0, c1: z4, c2: z3),
      c1: Bls12Fp6(c0: z2, c1: z1, c2: z5),
    );
  }

  // Cyclotomic exponentiation
  static Bls12Fp12 cyclotomicExp(Bls12Fp12 f) {
    var tmp = Bls12Fp12.one;
    bool foundOne = false;
    const blsX = Bls12PairingUtils.blsX;
    for (int b = 63; b >= 0; b--) {
      bool bit = ((blsX >> b) & Uint64.one) == Uint64.one;
      if (foundOne) {
        tmp = cyclotomicSquare(tmp);
      } else {
        foundOne = bit;
      }

      if (bit) {
        tmp *= f;
      }
    }

    return tmp.conjugate();
  }

  // Final exponentiation
  Gt finalExponentiation() {
    Bls12Fp12 f = inner;
    // Compute t0 = f^(p^6)
    Bls12Fp12 t0 =
        f
            .frobeniusMap()
            .frobeniusMap()
            .frobeniusMap()
            .frobeniusMap()
            .frobeniusMap()
            .frobeniusMap();

    Bls12Fp12? t1 = f.invert();
    if (t1 == null) {
      throw CoreErrors.cryptoFailed(
        "finalExponentiation",
        reason: "Non-invertible Fp12",
      );
    }

    Bls12Fp12 t2 = t0 * t1;
    t1 = t2;
    t2 = t2.frobeniusMap().frobeniusMap();
    t2 *= t1;
    t1 = cyclotomicSquare(t2).conjugate();

    Bls12Fp12 t3 = cyclotomicExp(t2);
    Bls12Fp12 t4 = cyclotomicSquare(t3);
    Bls12Fp12 t5 = t1 * t3;
    t1 = cyclotomicExp(t5);
    t0 = cyclotomicExp(t1);
    Bls12Fp12 t6 = cyclotomicExp(t0);
    t6 *= t4;
    t4 = cyclotomicExp(t6);
    t5 = t5.conjugate();
    t4 *= t5 * t2;
    t5 = t2.conjugate();
    t1 *= t2;
    t1 = t1.frobeniusMap().frobeniusMap().frobeniusMap();
    t6 *= t5;
    t6 = t6.frobeniusMap();
    t3 *= t0;
    t3 = t3.frobeniusMap().frobeniusMap();
    t3 *= t1;
    t3 *= t6;
    f = t3 * t4;
    return Gt(f);
  }
}

/// Computes a combined Miller loop over multiple G1/G2 pairs for BLS12-381.
class MultiMillerLoopBls12
    with
        MultiMillerLoop<
          List<(G1AffinePoint, G2Prepared)>,
          MillerLoopResultBls12
        > {
  /// Executes the multi-Miller loop for the given list of term pairs.
  @override
  MillerLoopResultBls12 multiMillerLoop(
    List<(G1AffinePoint, G2Prepared)> terms,
  ) {
    final adder = MillerLoopDriverBls12(terms: terms, index: 0);
    final tmp = Bls12PairingUtils.millerLoop(adder);
    return MillerLoopResultBls12(tmp);
  }
}

/// Drives a multi-pairing Miller loop over a batch of (G1, prepared-G2) terms.
class MillerLoopDriverBls12 implements MillerLoopDriver<Bls12Fp12> {
  final List<(G1AffinePoint, G2Prepared)> terms;
  int _index;
  int get index => _index;
  MillerLoopDriverBls12({required this.terms, int index = 0}) : _index = index;

  @override
  Bls12Fp12 additionStep(Bls12Fp12 f) {
    for (final term in terms) {
      final eitherIdentity = term.$1.isIdentity() | term.$2.infinity;

      final newF = Bls12PairingUtils.ell(f, term.$2.coeffs[index], term.$1);
      f = Bls12Fp12.conditionalSelect(newF, f, eitherIdentity);
    }
    _index += 1;
    return f;
  }

  @override
  Bls12Fp12 conjugate(Bls12Fp12 acc) {
    return acc.conjugate();
  }

  @override
  Bls12Fp12 doublingStep(Bls12Fp12 f) {
    for (final term in terms) {
      final eitherIdentity = term.$1.isIdentity() | term.$2.infinity;

      final newF = Bls12PairingUtils.ell(f, term.$2.coeffs[index], term.$1);
      f = Bls12Fp12.conditionalSelect(newF, f, eitherIdentity);
    }
    _index += 1;
    return f;
  }

  @override
  Bls12Fp12 one() {
    return Bls12Fp12.one;
  }

  @override
  Bls12Fp12 squareOutput(Bls12Fp12 acc) {
    return acc.square();
  }
}

/// Element of GT, the BLS12-381 pairing target group, represented additively.
class Gt extends ECPoint<JubJubFq, Gt> with Equality {
  final Bls12Fp12 inner;

  const Gt(this.inner);
  static const _identity = Gt(Bls12Fp12.one);

  factory Gt.identity() {
    return _identity;
  }

  /// Conditional select: chooses `a` if choice == 0, else `b`
  factory Gt.conditionalSelect(Gt a, Gt b, bool choice) {
    return Gt(Bls12Fp12.conditionalSelect(a.inner, b.inner, choice));
  }

  /// Double this element (square in multiplicative group)
  Gt double() => Gt(inner.square());

  /// Negate this element (conjugate in unitary group)
  @override
  Gt operator -() => Gt(inner.conjugate());
  @override
  Gt operator +(Gt rhs) {
    return Gt(inner * rhs.inner);
  }

  /// Add two Gt elements (multiplicative in Fp12)
  @override
  Gt operator *(JubJubFq rhs) {
    Gt acc = Gt.identity();

    final bits = BytesUtils.bytesToBits(rhs.toBytes()); // length = 256
    final iterableBits = bits.reversed.skip(1);
    for (final bit in iterableBits) {
      acc = acc.double();
      acc = Gt.conditionalSelect(acc, (acc + this), bit);
    }

    return acc;
  }

  /// Subtract two Gt elements (multiply by conjugate)
  Gt operator -(Gt rhs) => this + (-rhs);

  bool isIdentity() => this == Gt.identity();

  @override
  BuBytes toBytes() {
    throw CoreErrors.cryptoOperationNotSupported;
  }

  @override
  List<dynamic> get variables => [inner];
}

/// Drives the Miller loop for [G2Prepared]'s coefficient precomputation pass.
class _G2AffineMillerLoopDriver implements MillerLoopDriver<void> {
  G2Projective cur;
  final G2AffinePoint base;
  final List<(Bls12Fp2, Bls12Fp2, Bls12Fp2)> _coeffs = [];
  List<(Bls12Fp2, Bls12Fp2, Bls12Fp2)> get coeffs => _coeffs.clone();
  _G2AffineMillerLoopDriver({required this.base, required this.cur});
  int get length => _coeffs.length;
  @override
  void additionStep(void acc) {
    final coeffs = Bls12PairingUtils.additionStep(cur, base);
    cur = coeffs.$1;
    _coeffs.add(coeffs.$2);
  }

  @override
  void conjugate(void acc) {}

  @override
  void doublingStep(void acc) {
    final coeffs = Bls12PairingUtils.doublingStep(cur);
    cur = coeffs.$1;
    _coeffs.add(coeffs.$2);
  }

  @override
  void one() {}

  @override
  void squareOutput(void acc) {}
}

/// Implements the Miller loop driver for BLS12-381 pairings using affine G1 and projective G2 points.
class MillerLoopDriverBls12Pairing implements MillerLoopDriver<Bls12Fp12> {
  /// Current G2 point in projective coordinates.
  G2Projective _cur;

  /// Base G2 point in affine coordinates.
  final G2AffinePoint base;

  /// G1 affine point used in the pairing.
  final G1AffinePoint p;

  /// Accessor for the current projective point.
  G2Projective get cur => _cur;
  MillerLoopDriverBls12Pairing({
    required G2Projective cur,
    required this.base,
    required this.p,
  }) : _cur = cur;

  /// Performs a doubling step and updates the current G2 point.
  @override
  Bls12Fp12 doublingStep(Bls12Fp12 acc) {
    final coeffs = Bls12PairingUtils.doublingStep(_cur);
    _cur = coeffs.$1;
    final e = Bls12PairingUtils.ell(acc, coeffs.$2, p);
    return e;
  }

  /// Performs an addition step using the base G2 point and updates the current G2 point.
  @override
  Bls12Fp12 additionStep(Bls12Fp12 acc) {
    final coeffs = Bls12PairingUtils.additionStep(_cur, base);
    _cur = coeffs.$1;
    return Bls12PairingUtils.ell(acc, coeffs.$2, p);
  }

  /// Conjugates the accumulated value.
  @override
  Bls12Fp12 conjugate(Bls12Fp12 acc) {
    return acc.conjugate();
  }

  /// Returns the multiplicative identity in Fp¹².
  @override
  Bls12Fp12 one() {
    return Bls12Fp12.one;
  }

  /// Squares the accumulated output.
  @override
  Bls12Fp12 squareOutput(Bls12Fp12 acc) {
    return acc.square();
  }
}
