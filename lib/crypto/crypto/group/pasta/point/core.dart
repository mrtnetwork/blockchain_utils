import 'package:blockchain_utils/crypto/crypto/group/core/field.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/crypto/crypto/group/core/point.dart';
import 'package:blockchain_utils/crypto/crypto/group/pasta/fields/core.dart'
    show PastaFieldElement;
import 'package:blockchain_utils/crypto/crypto/group/pasta/fields/pallas_fp.dart';
import 'package:blockchain_utils/crypto/crypto/group/pasta/fields/vesta_fq.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/utils/numbers/fixed/src/u64/u64.dart';

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';
import 'package:blockchain_utils/utils/compare/hash_code.dart';
import 'package:blockchain_utils/utils/equatable/equatable.dart';

/// Field elements are represented as multiple fixed-size limbs (typically
/// 4 `Uint64`s) with algorithms written in a constant-time style. Because
/// they rely on multi-precision arithmetic over Dart ints, these
/// implementations are **not guaranteed to be constant-time** at the machine
/// level and should not be considered fully side-channel resistant.

/// Identifies which of the four Pasta curves a point belongs to.
enum PastaCurveName {
  pallas("pallas"),
  vesta("vesta"),
  isoPallas("iso-pallas"),
  isoVesta("iso-vesta");

  bool get isIso => this == isoPallas || this == isoVesta;
  const PastaCurveName(this.curveId);
  final String curveId;
}

/// 0/1 mask: 1 iff the field element is zero. Branch-free identity test
/// for point arithmetic (no `bool` on secret data).
Uint64 pastaIsZeroMask(PastaFieldElement e) {
  assert(e.limbs.length == 4);
  return Uint64.isZeroMask(e.limbs[0] | e.limbs[1] | e.limbs[2] | e.limbs[3]) &
      Uint64.one;
}

/// 0/1 mask: 1 iff the field elements are equal. Fixed iteration count,
/// no early exit.
Uint64 pastaCtEqualsMask(PastaFieldElement a, PastaFieldElement b) =>
    Uint64.ctEqualsMask(a.limbs, b.limbs) & Uint64.one;

/// A Pasta curve's Weierstrass coefficients (`y^2 = x^3 + a*x + b`).
class PastaCurveParams<F extends PastaFieldElement<F>> with Equality {
  final F a;
  final F b;
  final PastaCurveName name;
  const PastaCurveParams({
    required this.a,
    required this.b,
    required this.name,
  });
  static const PastaCurveParams<PallasFp> pallas = PastaCurveParams<PallasFp>(
    a: PallasFp.unsafe([Uint64.zero, Uint64.zero, Uint64.zero, Uint64.zero]),
    b: PallasFp.unsafe([
      Uint64.unsafe(2711969384, 4294967277),
      Uint64.unsafe(1958913355, 1330217715),
      Uint64.unsafe(4294967295, 4294967293),
      Uint64.unsafe(1073741823, 4294967295),
    ]),
    name: PastaCurveName.pallas,
  );

  static const PastaCurveParams<VestaFq> vesta = PastaCurveParams<VestaFq>(
    a: VestaFq.unsafe([Uint64.zero, Uint64.zero, Uint64.zero, Uint64.zero]),
    b: VestaFq.unsafe([
      Uint64.unsafe(2528939148, 4294967277),
      Uint64.unsafe(1958913355, 1240954766),
      Uint64.unsafe(4294967295, 4294967293),
      Uint64.unsafe(1073741823, 4294967295),
    ]),
    name: PastaCurveName.vesta,
  );

  static const PastaCurveParams<PallasFp> isoPallas =
      PastaCurveParams<PallasFp>(
        a: PallasFp.unsafe([
          Uint64.unsafe(2143670928, 2008746206),
          Uint64.unsafe(2466841170, 3474071816),
          Uint64.unsafe(1240874997, 3658565051),
          Uint64.unsafe(476925704, 1899491548),
        ]),
        b: PallasFp.unsafe([
          Uint64.unsafe(4159841400, 4294962237),
          Uint64.unsafe(2799616852, 870396827),
          Uint64.unsafe(4294967295, 4294966618),
          Uint64.unsafe(1073741823, 4294967295),
        ]),
        name: PastaCurveName.isoPallas,
      );
  static const PastaCurveParams<VestaFq> isoVesta = PastaCurveParams<VestaFq>(
    a: VestaFq.unsafe([
      Uint64.unsafe(3818772284, 3858374752),
      Uint64.unsafe(2793033388, 1102944330),
      Uint64.unsafe(1318270008, 478479374),
      Uint64.unsafe(678844599, 540353717),
    ]),
    b: VestaFq.unsafe([
      Uint64.unsafe(3800527580, 4294962237),
      Uint64.unsafe(2799616846, 2872765908),
      Uint64.unsafe(4294967295, 4294966618),
      Uint64.unsafe(1073741823, 4294967295),
    ]),
    name: PastaCurveName.isoVesta,
  );
  @override
  List<dynamic> get variables => [a, b];
}

/// Contract shared by every Pasta point representation (projective and affine).
abstract class BasePastaPoint<
  SCALAR extends PastaFieldElement<SCALAR>,
  BASE extends PastaFieldElement<BASE>
>
    extends ECPoint<SCALAR, BasePastaPoint<SCALAR, BASE>> {
  const BasePastaPoint();
  abstract final PastaCurveParams<BASE> curveParams;
  abstract final BASE x;
  abstract final BASE y;

  bool isIdentity();
}

/// A Pasta point in projective coordinates, with full group and
/// cofactor operations.
abstract class PastaPoint<
  SCALAR extends PastaFieldElement<SCALAR>,
  BASE extends PastaFieldElement<BASE>,
  P extends PastaPoint<SCALAR, BASE, P>
>
    extends BasePastaPoint<SCALAR, BASE>
    implements CryptoGroupElement<P, SCALAR>, CofactorGroupElement<SCALAR, P> {
  @override
  final BASE x;
  @override
  final BASE y;
  final BASE z;

  const PastaPoint({required this.x, required this.y, required this.z});
  PastaAffinePoint<SCALAR, BASE, P> toAffine();
  P from({required BASE x, required BASE y, required BASE z});

  /// Mask select: returns [other] iff [bit] == 1, else `this`. [bit] is a
  /// 0/1 [Uint64] (never a `bool`), so secret-data selects in addition and
  /// scalar multiplication stay straight-line.
  P selectMask(P other, Uint64 bit);
  @override
  P identity();
  P generator();
  P endo();

  P _isoDouble() {
    // No early-return: the formula maps identity to identity, and the
    // z-mask select below pins that for any encoding.
    // xx = X^2
    final xx = x.square();
    // yy = Y^2
    final yy = y.square();
    // a = yy^2
    BASE aVal = yy.square();

    // zz = Z^2
    final zz = z.square();

    // s = 2 * ((X + yy)^2 - xx - a)
    BASE s = (x + yy).square() - xx - aVal;
    s = s.double();

    // m = 3*xx + A*zz^2
    final m = xx.double() + xx + curveParams.a * zz.square();

    // x3 = m^2 - 2*s
    final x3 = m.square() - s.double();

    // a = 8 * a
    aVal = aVal.double();
    aVal = aVal.double();
    aVal = aVal.double(); // now 8a

    // y3 = m*(s - x3) - a
    final y3 = m * (s - x3) - aVal;

    // z3 = (Y + Z)^2 - yy - zz
    final z3 = (y + z).square() - yy - zz;
    final dbl = from(x: x3, y: y3, z: z3);
    return dbl.selectMask(identity(), pastaIsZeroMask(z));
  }

  @override
  P double() {
    // `isIso` is a per-curve-type constant (public), not secret point data.
    if (curveParams.name.isIso) return _isoDouble();

    final a = x.square();
    final b = y.square();
    BASE c = b.square();

    BASE d = x + b;
    d = d.square();
    d = d - a - c;
    d = d + d; // 2 * d

    final e = a + a + a; // 3 * a
    final f = e.square();

    BASE z3 = z * y;
    z3 = z3 + z3; // 2 * z*y

    final x3 = f - (d + d); // X3 = f - 2*d

    c = c + c; // 2*c
    c = c + c; // 4*c
    c = c + c; // 8*c
    final y3 = e * (d - x3) - c;
    final dbl = from(x: x3, y: y3, z: z3);
    // No early-return: the formula maps identity to identity, and the
    // z-mask select below pins that for any encoding.
    return dbl.selectMask(identity(), pastaIsZeroMask(z));
  }

  bool isOnCurve() {
    // z2 = z²
    final z2 = z.square();

    // z4 = z⁴
    final z4 = z2.square();

    // z6 = z⁶
    final z6 = z4 * z2;
    // left = y² - (x² + A*z⁴) * x
    final left = y.square() - (((x.square() + (curveParams.a * z4))) * x);
    // right = B * z⁶
    final right = z6 * curveParams.b;

    // Check equation OR point at infinity (z == 0)
    return (left == right) | z.isZero();
  }

  @override
  bool isIdentity() {
    return z.isZero();
  }

  P operator +(BasePastaPoint<SCALAR, BASE> other) {
    switch (other) {
      case final PastaAffinePoint<SCALAR, BASE, P> other:
        // Branch-free style: always compute the formula, then fold the
        // doubling / opposite / identity cases into 0/1 mask selects (the
        // incomplete formula's output for those cases is discarded).
        final z1z1 = z.square();
        final u2 = other.x * z1z1;
        final s2 = other.y * z1z1 * z;
        final h = u2 - x;
        final hh = h.square();
        BASE i = hh + hh;
        i = i + i;
        BASE j = h * i;
        BASE r = s2 - y;
        r = r + r;
        final v = x * i;
        final x3 = r.square() - j - v - v;
        j = y * j;
        j = j + j;
        final y3 = r * (v - x3) - j;
        final z3 = (z + h).square() - z1z1 - hh;
        var sum = from(x: x3, y: y3, z: z3);
        final eqU = pastaCtEqualsMask(x, u2);
        final eqS = pastaCtEqualsMask(y, s2);
        sum = sum.selectMask(double(), eqU & eqS);
        sum = sum.selectMask(identity(), eqU & ~eqS);
        final inf1 = pastaIsZeroMask(z);
        final inf2 = pastaIsZeroMask(other.x) & pastaIsZeroMask(other.y);
        sum = sum.selectMask(other.toCurve(), inf1);
        sum = sum.selectMask(cast<P>(), inf2);
        return sum;
      case final P other:
        // Same mask discipline as above for the projective-projective case.
        final z1z1 = z.square();
        final z2z2 = other.z.square();

        final u1 = x * z2z2;
        final u2 = other.x * z1z1;

        final s1 = y * z2z2 * other.z;
        final s2 = other.y * z1z1 * z;

        final h = u2 - u1;
        final i = (h + h).square();
        final j = h * i;
        BASE r = s2 - s1;
        r = r + r; // 2 * r
        final v = u1 * i;

        final x3 = r.square() - j - v - v; // X3 = r^2 - j - 2*v
        BASE s1Double = s1 * j;
        s1Double = s1Double + s1Double; // 2 * s1*j
        final y3 = r * (v - x3) - s1Double;

        BASE z3 = (z + other.z).square() - z1z1 - z2z2;
        z3 = z3 * h;

        var sum = from(x: x3, y: y3, z: z3);
        final eqU = pastaCtEqualsMask(u1, u2);
        final eqS = pastaCtEqualsMask(s1, s2);
        sum = sum.selectMask(double(), eqU & eqS);
        sum = sum.selectMask(identity(), eqU & ~eqS);
        final inf1 = pastaIsZeroMask(z);
        final inf2 = pastaIsZeroMask(other.z);
        sum = sum.selectMask(other, inf1);
        sum = sum.selectMask(cast<P>(), inf2);
        return sum;
      default:
        throw CoreErrors.cryptoOperationNotSupported;
    }
  }

  @override
  P operator -(BasePastaPoint<SCALAR, BASE> other) {
    return this + (-other);
  }

  @override
  P operator *(SCALAR other) {
    P acc = identity();

    // Convert scalar to 32-byte big-endian array
    final byteList = other.toBytes().reversed.toList();

    // Iterate bits from most significant to least significant, skipping leading bit
    for (int i = 0; i < byteList.length; i++) {
      final byte = byteList[i];
      for (int j = 7; j >= 0; j--) {
        if (i == 0 && j == 7) continue; // skip leading bit

        // 0/1 mask (never a `bool`): the add-select below is a limb blend.
        final bit = Uint64((byte >> j) & 1);
        acc = acc.double();
        acc = acc.selectMask(acc + this, bit);
      }
    }
    return acc;
  }

  @override
  P operator -() {
    return from(x: x, y: -y, z: z);
  }

  @override
  operator ==(other) {
    if (other is! P) return false;
    BASE z = other.z.square();
    final x1 = x * z;
    z = z * other.z;
    BASE y1 = y * z;
    z = this.z.square();
    BASE x2 = other.x * z;
    z = z * this.z;
    BASE y2 = other.y * z;
    final isZero = isIdentity();
    final otherIsZero = other.isIdentity();
    return (isZero & otherIsZero) |
        ((!isZero) & (!otherIsZero) & (x1 == x2) & (y1 == y2));
  }

  @override
  int get hashCode =>
      HashCodeGenerator.generateHashCode([x, y, z, curveParams]);
  @override
  int recommendedWnafForNumScalars(int numScalars) {
    // Copied from bls12_381::g1
    const recommendations = <int>[
      1,
      3,
      7,
      20,
      43,
      120,
      273,
      563,
      1630,
      3128,
      7933,
      62569,
    ];

    int ret = 4;

    for (final r in recommendations) {
      if (numScalars > r) {
        ret += 1;
      } else {
        break;
      }
    }

    return ret;
  }

  @override
  BuBytes toBytes() {
    return toAffine().toBytes();
  }

  @override
  bool isSmallOrder() {
    return clearCofactor().isIdentity();
  }
}

/// A Pasta point in affine coordinates.
abstract class PastaAffinePoint<
  SCALAR extends PastaFieldElement<SCALAR>,
  BASE extends PastaFieldElement<BASE>,
  P extends PastaPoint<SCALAR, BASE, P>
>
    extends BasePastaPoint<SCALAR, BASE>
    with Equality {
  @override
  final BASE x;
  @override
  final BASE y;
  const PastaAffinePoint({required this.x, required this.y});
  P toCurve();
  P from({required BASE x, required BASE y, required BASE z});
  PastaAffinePoint<SCALAR, BASE, P> affineFrom({
    required BASE x,
    required BASE y,
  });
  P identity();
  P conditionalSelectFrom({required P a, required P b, required bool choice});
  @override
  bool isIdentity() {
    return x.isZero() && y.isZero();
  }

  @override
  P operator *(SCALAR rhs) {
    P acc = identity();
    // Same bit sequence as before (`toBytes` LE, top bit skipped), but the
    // per-bit select is a Uint64 mask blend — no `bool` on the secret.
    final bytes = rhs.toBytes();
    for (int i = 254; i >= 0; i--) {
      acc = acc.double();
      final bit = Uint64((bytes[i >> 3] >> (i & 7)) & 1);
      acc = acc.selectMask(acc + this, bit);
    }
    return acc;
  }

  @override
  P operator +(BasePastaPoint<SCALAR, BASE> rhs) {
    switch (rhs) {
      case final PastaAffinePoint<SCALAR, BASE, P> other:
        // Branch-free style: always compute the formula, then fold the
        // doubling / opposite / identity cases into 0/1 mask selects.
        final h = other.x - x;
        final hh = h.square();
        BASE i = hh + hh;
        i = i + i;
        BASE j = h * i;
        BASE r = other.y - y;
        r = r + r;
        final v = x * i;
        final x3 = r.square() - j - v - v;
        j = y * j;
        j = j + j;
        final y3 = r * (v - x3) - j;
        final z3 = h + h;
        var sum = from(x: x3, y: y3, z: z3);
        final eqU = pastaCtEqualsMask(x, other.x);
        final eqS = pastaCtEqualsMask(y, other.y);
        sum = sum.selectMask(toCurve().double(), eqU & eqS);
        sum = sum.selectMask(identity(), eqU & ~eqS);
        final inf1 = pastaIsZeroMask(x) & pastaIsZeroMask(y);
        final inf2 = pastaIsZeroMask(other.x) & pastaIsZeroMask(other.y);
        sum = sum.selectMask(other.toCurve(), inf1);
        sum = sum.selectMask(toCurve(), inf2);
        return sum;

      case final P other:
        return other + this;
      default:
        throw CoreErrors.cryptoOperationNotSupported;
    }
  }

  P operator -(BasePastaPoint<SCALAR, BASE> other) {
    return this + (-other);
  }

  @override
  BuBytes toBytes() {
    if (isIdentity()) {
      return BuBytes.zero(32);
    } else {
      final sign = ((y.isOdd() ? 1 : 0) << 7).toU8;
      final xBytes = x.toBytes();
      xBytes[31] |= sign;
      return BuBytes(xBytes);
    }
  }

  @override
  BasePastaPoint<SCALAR, BASE> operator -() {
    return affineFrom(x: x, y: -y);
  }

  PastaAffinePoint<SCALAR, BASE, P> generator();

  @override
  List<dynamic> get variables => [x, y, curveParams];

  Coordinates<BASE> coordinates() => Coordinates(x, y);
}
