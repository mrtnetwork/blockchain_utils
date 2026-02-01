import 'package:blockchain_utils/crypto/crypto/ec/core/point.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/bls12_381/src/fp.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/bls12_381/src/fp12.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/bls12_381/src/fp2.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/bls12_381/src/fp6.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/bls12_381/src/g1.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/bls12_381/src/g2.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/jubjub/fields/native.dart';
import 'package:blockchain_utils/crypto/crypto/exception/exception.dart';
import 'package:blockchain_utils/helper/helper.dart';
import 'package:blockchain_utils/utils/binary/utils.dart';
import 'package:blockchain_utils/utils/equatable/equatable.dart';

/// Utilities for computing pairings and Miller loop operations on BLS12-381.
class Bls12PairingUtils {
  /// The BLS parameter x used in Miller loop.
  static BigInt get blsX => BigInt.parse("0xd201000000010000");

  /// Performs the Miller loop using the given driver.
  static D millerLoop<D extends Object?>(MillerLoopDriver<D> deriver) {
    D f = deriver.one();
    final blsX = Bls12PairingUtils.blsX;
    bool foundOne = false;
    for (int b = 63; b >= 0; b--) {
      bool i = (((blsX >> 1) >> b) & BigInt.one) == BigInt.one;
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
  static Bls12NativeFp12 ell(
    Bls12NativeFp12 f,
    (Bls12NativeFp2, Bls12NativeFp2, Bls12NativeFp2) coeffs,
    G1NativeAffinePoint p,
  ) {
    Bls12NativeFp2 c0 = coeffs.$1;
    Bls12NativeFp2 c1 = coeffs.$2;
    c0 = c0.copyWith(c0: c0.c0 * p.y, c1: c0.c1 * p.y);
    c1 = c1.copyWith(c0: c1.c0 * p.x, c1: c1.c1 * p.x);
    return f.mulBy014(coeffs.$3, c1, c0);
  }

  /// Performs a doubling step on a G2 point and returns the new point with line coefficients.
  static (G2NativeProjective, (Bls12NativeFp2, Bls12NativeFp2, Bls12NativeFp2))
  doublingStep(G2NativeProjective r) {
    Bls12NativeFp2 tmp0 = r.x.square();
    Bls12NativeFp2 tmp1 = r.y.square();
    Bls12NativeFp2 tmp2 = tmp1.square();
    Bls12NativeFp2 tmp3 = (tmp1 + r.x).square() - tmp0 - tmp2;
    tmp3 = tmp3 + tmp3;
    Bls12NativeFp2 tmp4 = tmp0 + tmp0 + tmp0;
    Bls12NativeFp2 tmp6 = r.x + tmp4;
    Bls12NativeFp2 tmp5 = tmp4.square();
    Bls12NativeFp2 zsquared = r.z.square();
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
  static (G2NativeProjective, (Bls12NativeFp2, Bls12NativeFp2, Bls12NativeFp2))
  additionStep(G2NativeProjective r, G2NativeAffinePoint q) {
    Bls12NativeFp2 zsquared = r.z.square();
    Bls12NativeFp2 ysquared = q.y.square();
    Bls12NativeFp2 t0 = zsquared * q.x;
    Bls12NativeFp2 t1 = ((q.y + r.z).square() - ysquared - zsquared) * zsquared;
    Bls12NativeFp2 t2 = t0 - r.x;
    Bls12NativeFp2 t3 = t2.square();
    Bls12NativeFp2 t4 = t3 + t3;
    t4 = t4 + t4;
    Bls12NativeFp2 t5 = t4 * t2;
    Bls12NativeFp2 t6 = t1 - r.y - r.y;
    Bls12NativeFp2 t9 = t6 * q.x;
    Bls12NativeFp2 t7 = t4 * r.x;
    r = r.copyWith(x: t6.square() - t5 - t7 - t7);
    r = r.copyWith(z: (r.z + t2).square() - zsquared - t3);
    Bls12NativeFp2 t10 = q.y + r.z;
    Bls12NativeFp2 t8 = (t7 - r.x) * t6;
    t0 = r.y * t5;
    t0 = t0 + t0;
    r = r.copyWith(y: t8 - t0);
    t10 = t10.square() - ysquared;
    Bls12NativeFp2 ztsquared = r.z.square();
    t10 = t10 - ztsquared;
    t9 = t9 + t9 - t10;
    t10 = r.z + r.z;
    t6 = -t6;
    t1 = t6 + t6;
    return (r, (t10, t1, t9));
  }

  /// Computes the optimal Ate pairing e(P, Q) ∈ GT for affine points P and Q.
  static GtNative pairing(G1NativeAffinePoint p, G2NativeAffinePoint q) {
    final identity = p.isIdentity() || q.isIdentity();
    final newP = G1NativeAffinePoint.conditionalSelect(
      p,
      G1NativeAffinePoint.generator(),
      identity,
    );
    final newQ = G2NativeAffinePoint.conditionalSelect(
      q,
      G2NativeAffinePoint.generator(),
      identity,
    );
    final adder = MillerLoopDriverBls12Pairing(
      cur: newQ.toProjective(),
      base: newQ,
      p: newP,
    );
    final tmp = millerLoop(adder);
    final result = MillerLoopResultBls12(
      Bls12NativeFp12.conditionalSelect(tmp, Bls12NativeFp12.one(), identity),
    );
    return result.finalExponentiation();
  }
}

/// Precomputes Miller loop coefficients for a G2 point to speed up pairings.
class G2NativePrepared {
  final List<(Bls12NativeFp2, Bls12NativeFp2, Bls12NativeFp2)> coeffs;

  /// Whether the point is the point at infinity.
  final bool infinity;
  const G2NativePrepared({required this.coeffs, required this.infinity});
  factory G2NativePrepared.fromG2(G2NativeAffinePoint q) {
    bool isIdentity = q.isIdentity();
    final a = G2NativeAffinePoint.conditionalSelect(
      q,
      G2NativeAffinePoint.generator(),
      isIdentity,
    );

    final adder = _G2AffineMillerLoopDriver(
      cur: G2NativeProjective.fromAffine(q),
      base: a,
    );
    Bls12PairingUtils.millerLoop(adder);
    assert(adder.length == 68);
    return G2NativePrepared(coeffs: adder._coeffs, infinity: isIdentity);
  }
}

/// Interface for performing multi-Miller loop computations over multiple term pairs.
abstract mixin class MultiMillerLoop<
  TERMS extends Object,
  RESULT extends Object
> {
  RESULT multiMillerLoop(TERMS terms);
}

class MillerLoopResultBls12 {
  final Bls12NativeFp12 inner;
  const MillerLoopResultBls12(this.inner);

  // Helper: fp4 squaring
  static (Bls12NativeFp2, Bls12NativeFp2) fp4Square(
    Bls12NativeFp2 a,
    Bls12NativeFp2 b,
  ) {
    Bls12NativeFp2 t0 = a.square();
    Bls12NativeFp2 t1 = b.square();
    Bls12NativeFp2 t2 = t1.mulByNonresidue();
    Bls12NativeFp2 c0 = t2 + t0;
    t2 = a + b;
    t2 = t2.square();
    t2 -= t0;
    Bls12NativeFp2 c1 = t2 - t1;

    return (c0, c1);
  }

  // Cyclotomic squaring
  static Bls12NativeFp12 cyclotomicSquare(Bls12NativeFp12 f) {
    Bls12NativeFp2 z0 = f.c0.c0;
    Bls12NativeFp2 z4 = f.c0.c1;
    Bls12NativeFp2 z3 = f.c0.c2;
    Bls12NativeFp2 z2 = f.c1.c0;
    Bls12NativeFp2 z1 = f.c1.c1;
    Bls12NativeFp2 z5 = f.c1.c2;

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

    return Bls12NativeFp12(
      c0: Bls12NativeFp6(c0: z0, c1: z4, c2: z3),
      c1: Bls12NativeFp6(c0: z2, c1: z1, c2: z5),
    );
  }

  // Cyclotomic exponentiation
  static Bls12NativeFp12 cyclotomicExp(Bls12NativeFp12 f) {
    var tmp = Bls12NativeFp12.one();
    bool foundOne = false;
    final blsX = Bls12PairingUtils.blsX;
    for (int b = 63; b >= 0; b--) {
      bool bit = ((blsX >> b) & BigInt.one) == BigInt.one;
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
  GtNative finalExponentiation() {
    Bls12NativeFp12 f = inner;
    // Compute t0 = f^(p^6)
    Bls12NativeFp12 t0 =
        f
            .frobeniusMap()
            .frobeniusMap()
            .frobeniusMap()
            .frobeniusMap()
            .frobeniusMap()
            .frobeniusMap();

    Bls12NativeFp12? t1 = f.invert();
    if (t1 == null) {
      throw CryptoException.failed(
        "finalExponentiation",
        reason: "Non-invertible Fp12",
      );
    }

    Bls12NativeFp12 t2 = t0 * t1;
    t1 = t2;
    t2 = t2.frobeniusMap().frobeniusMap();
    t2 *= t1;
    t1 = cyclotomicSquare(t2).conjugate();

    Bls12NativeFp12 t3 = cyclotomicExp(t2);
    Bls12NativeFp12 t4 = cyclotomicSquare(t3);
    Bls12NativeFp12 t5 = t1 * t3;
    t1 = cyclotomicExp(t5);
    t0 = cyclotomicExp(t1);
    Bls12NativeFp12 t6 = cyclotomicExp(t0);
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
    return GtNative(f);
  }
}

/// Computes a combined Miller loop over multiple G1/G2 pairs for BLS12-381.
class MultiMillerLoopBls12
    with
        MultiMillerLoop<
          List<(G1NativeAffinePoint, G2NativePrepared)>,
          MillerLoopResultBls12
        > {
  /// Executes the multi-Miller loop for the given list of term pairs.
  @override
  MillerLoopResultBls12 multiMillerLoop(
    List<(G1NativeAffinePoint, G2NativePrepared)> terms,
  ) {
    final adder = MillerLoopDriverBls12(terms: terms, index: 0);
    final tmp = Bls12PairingUtils.millerLoop(adder);
    return MillerLoopResultBls12(tmp);
  }
}

/// Interface defining operations required to drive a Miller loop computation.
abstract class MillerLoopDriver<O> {
  /// Performs a doubling step on the accumulated value.
  O doublingStep(O acc);

  /// Performs an addition step on the accumulated value.
  O additionStep(O acc);

  /// Squares the accumulated output.
  O squareOutput(O acc);

  /// Computes the conjugate of the accumulated value.
  O conjugate(O acc);

  /// Returns the multiplicative identity element for the accumulation.
  O one();
}

class MillerLoopDriverBls12 implements MillerLoopDriver<Bls12NativeFp12> {
  final List<(G1NativeAffinePoint, G2NativePrepared)> terms;
  int _index;
  int get index => _index;
  MillerLoopDriverBls12({required this.terms, int index = 0}) : _index = index;

  @override
  Bls12NativeFp12 additionStep(Bls12NativeFp12 f) {
    for (final term in terms) {
      final eitherIdentity = term.$1.isIdentity() | term.$2.infinity;

      final newF = Bls12PairingUtils.ell(f, term.$2.coeffs[index], term.$1);
      f = Bls12NativeFp12.conditionalSelect(newF, f, eitherIdentity);
    }
    _index += 1;
    return f;
  }

  @override
  Bls12NativeFp12 conjugate(Bls12NativeFp12 acc) {
    return acc.conjugate();
  }

  @override
  Bls12NativeFp12 doublingStep(Bls12NativeFp12 f) {
    for (final term in terms) {
      final eitherIdentity = term.$1.isIdentity() | term.$2.infinity;

      final newF = Bls12PairingUtils.ell(f, term.$2.coeffs[index], term.$1);
      f = Bls12NativeFp12.conditionalSelect(newF, f, eitherIdentity);
    }
    _index += 1;
    return f;
  }

  @override
  Bls12NativeFp12 one() {
    return Bls12NativeFp12.one();
  }

  @override
  Bls12NativeFp12 squareOutput(Bls12NativeFp12 acc) {
    return acc.square();
  }
}

/// Element of GT, the BLS12-381 pairing target group, represented additively.
class GtNative extends ECPoint<JubJubNativeFq, GtNative> with Equality {
  final Bls12NativeFp12 inner;

  const GtNative(this.inner);
  static final _identity = GtNative(Bls12NativeFp12.one());

  factory GtNative.identity() {
    return _identity;
  }
  factory GtNative.generator() {
    return GtNative(
      Bls12NativeFp12(
        c0: Bls12NativeFp6(
          c0: Bls12NativeFp2(
            c0: Bls12NativeFp.nP(
              BigInt.parse(
                "2819105605953691245277803056322684086884703000473961065716485506033588504203831029066448642358042597501014294104502",
              ),
            ),
            c1: Bls12NativeFp.nP(
              BigInt.parse(
                "1323968232986996742571315206151405965104242542339680722164220900812303524334628370163366153839984196298685227734799",
              ),
            ),
          ),
          c1: Bls12NativeFp2(
            c0: Bls12NativeFp.nP(
              BigInt.parse(
                "2987335049721312504428602988447616328830341722376962214011674875969052835043875658579425548512925634040144704192135",
              ),
            ),
            c1: Bls12NativeFp.nP(
              BigInt.parse(
                "3879723582452552452538684314479081967502111497413076598816163759028842927668327542875108457755966417881797966271311",
              ),
            ),
          ),
          c2: Bls12NativeFp2(
            c0: Bls12NativeFp.nP(
              BigInt.parse(
                "261508182517997003171385743374653339186059518494239543139839025878870012614975302676296704930880982238308326681253",
              ),
            ),
            c1: Bls12NativeFp.nP(
              BigInt.parse(
                "231488992246460459663813598342448669854473942105054381511346786719005883340876032043606739070883099647773793170614",
              ),
            ),
          ),
        ),
        c1: Bls12NativeFp6(
          c0: Bls12NativeFp2(
            c0: Bls12NativeFp.nP(
              BigInt.parse(
                "3993582095516422658773669068931361134188738159766715576187490305611759126554796569868053818105850661142222948198557",
              ),
            ),
            c1: Bls12NativeFp.nP(
              BigInt.parse(
                "1074773511698422344502264006159859710502164045911412750831641680783012525555872467108249271286757399121183508900634",
              ),
            ),
          ),
          c1: Bls12NativeFp2(
            c0: Bls12NativeFp.nP(
              BigInt.parse(
                "2727588299083545686739024317998512740561167011046940249988557419323068809019137624943703910267790601287073339193943",
              ),
            ),
            c1: Bls12NativeFp.nP(
              BigInt.parse(
                "493643299814437640914745677854369670041080344349607504656543355799077485536288866009245028091988146107059514546594",
              ),
            ),
          ),
          c2: Bls12NativeFp2(
            c0: Bls12NativeFp.nP(
              BigInt.parse(
                "734401332196641441839439105942623141234148957972407782257355060229193854324927417865401895596108124443575283868655",
              ),
            ),
            c1: Bls12NativeFp.nP(
              BigInt.parse(
                "2348330098288556420918672502923664952620152483128593484301759394583320358354186482723629999370241674973832318248497",
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Conditional select: chooses `a` if choice == 0, else `b`
  factory GtNative.conditionalSelect(GtNative a, GtNative b, bool choice) {
    return GtNative(
      Bls12NativeFp12.conditionalSelect(a.inner, b.inner, choice),
    );
  }

  /// Double this element (square in multiplicative group)
  GtNative double() => GtNative(inner.square());

  /// Negate this element (conjugate in unitary group)
  @override
  GtNative operator -() => GtNative(inner.conjugate());
  @override
  GtNative operator +(GtNative rhs) {
    return GtNative(inner * rhs.inner);
  }

  /// Add two GtNative elements (multiplicative in Fp12)
  @override
  GtNative operator *(JubJubNativeFq rhs) {
    GtNative acc = GtNative.identity();

    final bits = BytesUtils.bytesToBits(rhs.toBytes()); // length = 256
    final iterableBits = bits.reversed.skip(1);
    for (final bit in iterableBits) {
      acc = acc.double();
      acc = GtNative.conditionalSelect(acc, (acc + this), bit);
    }

    return acc;
  }

  /// Subtract two GtNative elements (multiply by conjugate)
  GtNative operator -(GtNative rhs) => this + (-rhs);

  bool isIdentity() => this == GtNative.identity();

  @override
  List<int> toBytes() {
    throw CryptoException.operationNotSupported;
  }

  @override
  List<dynamic> get variables => [inner];
}

class _G2AffineMillerLoopDriver implements MillerLoopDriver<void> {
  G2NativeProjective cur;
  final G2NativeAffinePoint base;
  final List<(Bls12NativeFp2, Bls12NativeFp2, Bls12NativeFp2)> _coeffs = [];
  List<(Bls12NativeFp2, Bls12NativeFp2, Bls12NativeFp2)> get coeffs =>
      _coeffs.clone();
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
class MillerLoopDriverBls12Pairing
    implements MillerLoopDriver<Bls12NativeFp12> {
  /// Current G2 point in projective coordinates.
  G2NativeProjective _cur;

  /// Base G2 point in affine coordinates.
  final G2NativeAffinePoint base;

  /// G1 affine point used in the pairing.
  final G1NativeAffinePoint p;

  /// Accessor for the current projective point.
  G2NativeProjective get cur => _cur;
  MillerLoopDriverBls12Pairing({
    required G2NativeProjective cur,
    required this.base,
    required this.p,
  }) : _cur = cur;

  /// Performs a doubling step and updates the current G2 point.
  @override
  Bls12NativeFp12 doublingStep(Bls12NativeFp12 acc) {
    final coeffs = Bls12PairingUtils.doublingStep(_cur);
    _cur = coeffs.$1;
    final e = Bls12PairingUtils.ell(acc, coeffs.$2, p);
    return e;
  }

  /// Performs an addition step using the base G2 point and updates the current G2 point.
  @override
  Bls12NativeFp12 additionStep(Bls12NativeFp12 acc) {
    final coeffs = Bls12PairingUtils.additionStep(_cur, base);
    _cur = coeffs.$1;
    return Bls12PairingUtils.ell(acc, coeffs.$2, p);
  }

  /// Conjugates the accumulated value.
  @override
  Bls12NativeFp12 conjugate(Bls12NativeFp12 acc) {
    return acc.conjugate();
  }

  /// Returns the multiplicative identity in Fp¹².
  @override
  Bls12NativeFp12 one() {
    return Bls12NativeFp12.one();
  }

  /// Squares the accumulated output.
  @override
  Bls12NativeFp12 squareOutput(Bls12NativeFp12 acc) {
    return acc.square();
  }
}
