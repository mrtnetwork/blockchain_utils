import 'package:blockchain_utils/crypto/crypto/zcrypto/bls12_381/src/fp.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/bls12_381/src/fp2.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/bls12_381/src/fp6.dart';
import 'package:blockchain_utils/numbers/src/u64/u64.dart';
import 'package:blockchain_utils/utils/equatable/equatable.dart';

/// Quadratic extension field GF(p¹²) over GF(p⁶), represented as c0 + c1·w with w² = v.
class Bls12Fp12 with Equality {
  final Bls12Fp6 c0;
  final Bls12Fp6 c1;

  const Bls12Fp12({required this.c0, required this.c1});
  factory Bls12Fp12.conditionalSelect(Bls12Fp12 a, Bls12Fp12 b, bool choice) {
    return Bls12Fp12(
      c0: Bls12Fp6.conditionalSelect(a.c0, b.c0, choice),
      c1: Bls12Fp6.conditionalSelect(a.c1, b.c1, choice),
    );
  }
  static const zero = Bls12Fp12(c0: Bls12Fp6.zero, c1: Bls12Fp6.zero);
  static const one = Bls12Fp12(c0: Bls12Fp6.one, c1: Bls12Fp6.zero);

  Bls12Fp12 mulBy014(Bls12Fp2 c0, Bls12Fp2 c1, Bls12Fp2 c4) {
    // aa = this.c0 * (c0 + c1*u)
    final aa = this.c0.mulBy01(c0, c1);

    // bb = this.c1 * (c4*u)
    final bb = this.c1.mulBy1(c4);

    // o = c1 + c4
    final o = c1 + c4;

    // c1 = (this.c1 + this.c0) * (c0 + o*u)
    var c1_ = (this.c1 + this.c0).mulBy01(c0, o);

    // c1 = c1 - aa - bb
    c1_ = c1_ - aa - bb;

    // c0 = bb * nonresidue + aa
    var c0_ = bb.mulByNonresidue() + aa;

    return Bls12Fp12(c0: c0_, c1: c1_);
  }

  /// check is zero
  bool isZero() => c0.isZero() && c1.isZero();
  Bls12Fp12 conjugate() => Bls12Fp12(c0: c0, c1: -c1);

  Bls12Fp12 frobeniusMap() {
    // Apply Frobenius to both halves
    final c0 = this.c0.frobeniusMap();
    var c1 = this.c1.frobeniusMap();

    // Multiply c1 by (u + 1)^((p - 1) / 6)
    final frobCoeff = Bls12Fp6.fromBls12Fp2(
      const Bls12Fp2(
        c0: Bls12Fp.unsafe([
          Uint64.unsafe(118003026, 3004814437),
          Uint64.unsafe(3328794514, 3037365011),
          Uint64.unsafe(2548579532, 3507954319),
          Uint64.unsafe(2740694730, 3000773102),
          Uint64.unsafe(484676586, 1571475021),
          Uint64.unsafe(150086159, 2969265899),
        ]),
        c1: Bls12Fp.unsafe([
          Uint64.unsafe(3002493613, 1290131014),
          Uint64.unsafe(1480761451, 4232674540),
          Uint64.unsafe(3477640660, 630838164),
          Uint64.unsafe(3239812282, 1084811472),
          Uint64.unsafe(775427019, 3852525193),
          Uint64.unsafe(286191578, 2290384815),
        ]),
      ),
    );

    c1 = c1 * frobCoeff;

    return Bls12Fp12(c0: c0, c1: c1);
  }

  /// Operations
  Bls12Fp12 operator +(Bls12Fp12 rhs) => Bls12Fp12(c0: c0 + rhs.c0, c1: c1 + rhs.c1);

  Bls12Fp12 operator -(Bls12Fp12 rhs) => Bls12Fp12(c0: c0 - rhs.c0, c1: c1 - rhs.c1);

  Bls12Fp12 operator -() => Bls12Fp12(c0: -c0, c1: -c1);

  Bls12Fp12 operator *(Bls12Fp12 rhs) {
    Bls12Fp6 aa = this.c0 * rhs.c0;
    Bls12Fp6 bb = this.c1 * rhs.c1;
    Bls12Fp6 o = rhs.c0 + rhs.c1;
    Bls12Fp6 c1 = this.c1 + this.c0;
    c1 = c1 * o;
    c1 = c1 - aa;
    c1 = c1 - bb;
    Bls12Fp6 c0 = bb.mulByNonresidue();
    c0 = c0 + aa;
    return Bls12Fp12(c0: c0, c1: c1);
  }

  /// Squaring
  Bls12Fp12 square() {
    Bls12Fp6 ab = this.c0 * this.c1;
    Bls12Fp6 c0c1 = this.c0 + this.c1;
    Bls12Fp6 c0 = this.c1.mulByNonresidue();
    c0 = c0 + this.c0;
    c0 = c0 * c0c1;
    c0 = c0 - ab;
    Bls12Fp6 c1 = ab + ab;
    c0 = c0 - ab.mulByNonresidue();

    return Bls12Fp12(c0: c0, c1: c1);
  }

  /// Inversion
  Bls12Fp12? invert() {
    final tmp = (c0.square() - c1.square().mulByNonresidue()).invert();
    if (tmp == null) return null;
    return Bls12Fp12(c0: c0 * tmp, c1: c1 * -tmp);
  }

  @override
  List<dynamic> get variables => [c0, c1];
}

/// Quadratic extension field GF(p¹²) over GF(p⁶), represented as c0 + c1·w with w² = v.
class Bls12NativeFp12 with Equality {
  final Bls12NativeFp6 c0;
  final Bls12NativeFp6 c1;

  const Bls12NativeFp12({required this.c0, required this.c1});
  factory Bls12NativeFp12.conditionalSelect(
    Bls12NativeFp12 a,
    Bls12NativeFp12 b,
    bool choice,
  ) {
    return Bls12NativeFp12(
      c0: Bls12NativeFp6.conditionalSelect(a.c0, b.c0, choice),
      c1: Bls12NativeFp6.conditionalSelect(a.c1, b.c1, choice),
    );
  }
  static final _zero = Bls12NativeFp12(
    c0: Bls12NativeFp6.zero(),
    c1: Bls12NativeFp6.zero(),
  );
  static final _one = Bls12NativeFp12(
    c0: Bls12NativeFp6.one(),
    c1: Bls12NativeFp6.zero(),
  );

  /// zero element
  factory Bls12NativeFp12.zero() => _zero;

  /// one element
  factory Bls12NativeFp12.one() => _one;
  Bls12NativeFp12 mulBy014(Bls12NativeFp2 c0, Bls12NativeFp2 c1, Bls12NativeFp2 c4) {
    // aa = this.c0 * (c0 + c1*u)
    final aa = this.c0.mulBy01(c0, c1);

    // bb = this.c1 * (c4*u)
    final bb = this.c1.mulBy1(c4);

    // o = c1 + c4
    final o = c1 + c4;

    // c1 = (this.c1 + this.c0) * (c0 + o*u)
    var c1_ = (this.c1 + this.c0).mulBy01(c0, o);

    // c1 = c1 - aa - bb
    c1_ = c1_ - aa - bb;

    // c0 = bb * nonresidue + aa
    var c0_ = bb.mulByNonresidue() + aa;

    return Bls12NativeFp12(c0: c0_, c1: c1_);
  }

  /// check is zero
  bool isZero() => c0.isZero() && c1.isZero();
  Bls12NativeFp12 conjugate() => Bls12NativeFp12(c0: c0, c1: -c1);

  Bls12NativeFp12 frobeniusMap() {
    // Apply Frobenius to both halves
    final c0 = this.c0.frobeniusMap();
    var c1 = this.c1.frobeniusMap();

    // Multiply c1 by (u + 1)^((p - 1) / 6)
    final frobCoeff = Bls12NativeFp6.fromFp2(
      Bls12NativeFp2(
        c0: Bls12NativeFp.nP(
          BigInt.parse(
            "3850754370037169011952147076051364057158807420970682438676050522613628423219637725072182697113062777891589506424760",
          ),
        ),
        c1: Bls12NativeFp.nP(
          BigInt.parse(
            "151655185184498381465642749684540099398075398968325446656007613510403227271200139370504932015952886146304766135027",
          ),
        ),
      ),
    );

    c1 = c1 * frobCoeff;

    return Bls12NativeFp12(c0: c0, c1: c1);
  }

  /// operations
  Bls12NativeFp12 operator +(Bls12NativeFp12 rhs) =>
      Bls12NativeFp12(c0: c0 + rhs.c0, c1: c1 + rhs.c1);

  Bls12NativeFp12 operator -(Bls12NativeFp12 rhs) =>
      Bls12NativeFp12(c0: c0 - rhs.c0, c1: c1 - rhs.c1);

  Bls12NativeFp12 operator -() => Bls12NativeFp12(c0: -c0, c1: -c1);

  Bls12NativeFp12 operator *(Bls12NativeFp12 rhs) {
    Bls12NativeFp6 aa = this.c0 * rhs.c0;
    Bls12NativeFp6 bb = this.c1 * rhs.c1;
    Bls12NativeFp6 o = rhs.c0 + rhs.c1;
    Bls12NativeFp6 c1 = this.c1 + this.c0;
    c1 = c1 * o;
    c1 = c1 - aa;
    c1 = c1 - bb;
    Bls12NativeFp6 c0 = bb.mulByNonresidue();
    c0 = c0 + aa;
    return Bls12NativeFp12(c0: c0, c1: c1);
  }

  /// Squaring
  Bls12NativeFp12 square() {
    Bls12NativeFp6 ab = this.c0 * this.c1;
    Bls12NativeFp6 c0c1 = this.c0 + this.c1;
    Bls12NativeFp6 c0 = this.c1.mulByNonresidue();
    c0 = c0 + this.c0;
    c0 = c0 * c0c1;
    c0 = c0 - ab;
    Bls12NativeFp6 c1 = ab + ab;
    c0 = c0 - ab.mulByNonresidue();

    return Bls12NativeFp12(c0: c0, c1: c1);
  }

  /// Inversion
  Bls12NativeFp12? invert() {
    final tmp = (c0.square() - c1.square().mulByNonresidue()).invert();
    if (tmp == null) return null;
    return Bls12NativeFp12(c0: c0 * tmp, c1: c1 * -tmp);
  }

  @override
  List<dynamic> get variables => [c0, c1];

  @override
  String toString() {
    return "$c0 + $c1";
  }
}
