import 'package:blockchain_utils/crypto/crypto/group/bls12_381/src/fp.dart';
import 'package:blockchain_utils/crypto/crypto/group/bls12_381/src/fp2.dart';
import 'package:blockchain_utils/crypto/crypto/group/bls12_381/src/fp6.dart';
import 'package:blockchain_utils/utils/numbers/fixed/src/u64/u64.dart';
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
  Bls12Fp12 operator +(Bls12Fp12 rhs) =>
      Bls12Fp12(c0: c0 + rhs.c0, c1: c1 + rhs.c1);

  Bls12Fp12 operator -(Bls12Fp12 rhs) =>
      Bls12Fp12(c0: c0 - rhs.c0, c1: c1 - rhs.c1);

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
