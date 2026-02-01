import 'package:blockchain_utils/crypto/crypto/ec/core/field.dart';
import 'package:blockchain_utils/crypto/crypto/ec/core/point.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/pasta/fields/core.dart'
    show PastaFieldElement;
import 'package:blockchain_utils/crypto/crypto/zcrypto/pasta/fields/native/fq.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/pasta/fields/native/fp.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/pasta/fields/pallas_fp.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/pasta/fields/vesta_fq.dart';
import 'package:blockchain_utils/crypto/crypto/exception/exception.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/utils/compare/hash_code.dart';
import 'package:blockchain_utils/utils/equatable/equatable.dart';
import 'package:blockchain_utils/utils/binary/utils.dart';

/// ---------------------------------------------------------------------------
/// Native vs Non-Native representations
///
/// * Both native and non-native field implementations are backed by `BigInt`.
///
/// * Non-native types (e.g. `PallasFp`, `PastaPoint`) represent field elements as
///   multiple fixed-size limbs (typically 6 `BigInt`s) and use algorithms written
///   in a constant-time style. However, because they rely on `BigInt`, these
///   implementations are **not guaranteed to be constant-time** at the machine
///   level and should not be considered fully side-channel resistant. They are,
///   however, safer than native representations.
///
/// * Native types (e.g. `PallasNativeFp`, `PastaNativePoint`) represent each field
///   element as a single `BigInt` and use variable-time algorithms. These are not
///   constant-time and are not intended to be safe against side-channel attacks.
///
/// Both representations share identical curve and algebraic semantics; the
/// differences lie in representation, performance, and side-channel behavior.
/// ---------------------------------------------------------------------------

enum PastaCurveName {
  pallas("pallas"),
  vesta("vesta"),
  isoPallas("iso-pallas"),
  isoVesta("iso-vesta");

  bool get isIso => this == isoPallas || this == isoVesta;
  const PastaCurveName(this.curveId);
  final String curveId;
}

class PastaCurveParams<F extends PastaFieldElement<F>> with Equality {
  final F a;
  final F b;
  final PastaCurveName name;
  const PastaCurveParams({
    required this.a,
    required this.b,
    required this.name,
  });
  static PastaCurveParams<PallasFp> get pallas => PastaCurveParams<PallasFp>(
    a: PallasFp.fromRaw([BigInt.zero, BigInt.zero, BigInt.zero, BigInt.zero]),
    b: PallasFp.fromRaw([
      BigInt.from(5),
      BigInt.zero,
      BigInt.zero,
      BigInt.zero,
    ]),
    name: PastaCurveName.pallas,
  );
  static PastaCurveParams<PallasNativeFp> get pallasNative =>
      PastaCurveParams<PallasNativeFp>(
        a: PallasNativeFp(BigInt.zero),
        b: PallasNativeFp(BigInt.from(5)),
        name: PastaCurveName.pallas,
      );

  static PastaCurveParams<VestaFq> get vesta => PastaCurveParams<VestaFq>(
    a: VestaFq.fromRaw([BigInt.zero, BigInt.zero, BigInt.zero, BigInt.zero]),
    b: VestaFq.fromRaw([BigInt.from(5), BigInt.zero, BigInt.zero, BigInt.zero]),
    name: PastaCurveName.vesta,
  );
  static PastaCurveParams<VestaNativeFq> get vestaNative =>
      PastaCurveParams<VestaNativeFq>(
        a: VestaNativeFq(BigInt.zero),
        b: VestaNativeFq(BigInt.from(5)),
        name: PastaCurveName.vesta,
      );

  static PastaCurveParams<PallasNativeFp>
  get isoPallasNative => PastaCurveParams<PallasNativeFp>(
    a: PallasNativeFp(
      BigInt.parse(
        "10949663248450308183708987909873589833737836120165333298109615750520499732811",
      ),
    ),
    b: PallasNativeFp(BigInt.from(1265)),
    name: PastaCurveName.isoPallas,
  );

  static PastaCurveParams<VestaNativeFq>
  get isoVestaNative => PastaCurveParams<VestaNativeFq>(
    a: VestaNativeFq(
      BigInt.parse(
        "17413348858408915339762682399132325137863850198379221683097628341577494210225",
      ),
    ),
    b: VestaNativeFq(BigInt.from(1265)),
    name: PastaCurveName.isoVesta,
  );

  static PastaCurveParams<PallasFp> get isoPallas => PastaCurveParams<PallasFp>(
    a: PallasFp.fromRaw([
      BigInt.parse("0x92bb4b0b657a014b"),
      BigInt.parse("0xb74134581a27a59f"),
      BigInt.parse("0x49be2d7258370742"),
      BigInt.parse("0x18354a2eb0ea8c9c"),
    ]),
    b: PallasFp.fromRaw([
      BigInt.from(1265),
      BigInt.zero,
      BigInt.zero,
      BigInt.zero,
    ]),
    name: PastaCurveName.isoPallas,
  );
  static PastaCurveParams<VestaFq> get isoVesta => PastaCurveParams<VestaFq>(
    a: VestaFq.fromRaw([
      BigInt.parse("0xc515ad7242eaa6b1"),
      BigInt.parse("0x9673928c7d01b212"),
      BigInt.parse("0x81639c4d96f78773"),
      BigInt.parse("0x267f9b2ee592271a"),
    ]),
    b: VestaFq.fromRaw([
      BigInt.from(1265),
      BigInt.zero,
      BigInt.zero,
      BigInt.zero,
    ]),
    name: PastaCurveName.isoVesta,
  );
  @override
  List<dynamic> get variables => [a, b];
}

abstract class BasePastaPoint<
  SCALAR extends PastaFieldElement<SCALAR>,
  BASE extends PastaFieldElement<BASE>
>
    extends ECPoint<SCALAR, BasePastaPoint<SCALAR, BASE>> {
  abstract final PastaCurveParams<BASE> curveParams;
  abstract final BASE x;
  abstract final BASE y;

  bool isIdentity();
}

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

  PastaPoint({required this.x, required this.y, required this.z});
  PastaAffinePoint<SCALAR, BASE, P> toAffine();
  P from({required BASE x, required BASE y, required BASE z});
  @override
  P identity();
  P generator();
  P endo();

  P _isoDouble() {
    if (isIdentity()) return identity();
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
    return from(x: x3, y: y3, z: z3);
  }

  @override
  P double() {
    if (isIdentity()) return identity();
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
    return from(x: x3, y: y3, z: z3);
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
        if (isIdentity()) {
          return other.toCurve();
        } else if (other.isIdentity()) {
          return cast<P>();
        }
        final z1z1 = z.square();
        final u2 = other.x * z1z1;
        final s2 = other.y * z1z1 * z;
        if (x == u2) {
          if (y == s2) {
            return double();
          } else {
            return identity();
          }
        }
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
        return from(x: x3, y: y3, z: z3);
      case final P other:
        // Handle identity points
        if (isIdentity()) {
          return other;
        } else if (other.isIdentity()) {
          return cast<P>();
        } else {
          final z1z1 = z.square();
          final z2z2 = other.z.square();

          final u1 = x * z2z2;
          final u2 = other.x * z1z1;

          final s1 = y * z2z2 * other.z;
          final s2 = other.y * z1z1 * z;

          if (u1 == u2) {
            if (s1 == s2) {
              return double();
            } else {
              return identity();
            }
          } else {
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

            return from(x: x3, y: y3, z: z3);
          }
        }
      default:
        throw CryptoException.operationNotSupported;
    }
  }

  @override
  P operator -(BasePastaPoint<SCALAR, BASE> other) {
    return this + (-other);
  }

  @override
  P operator *(SCALAR other) {
    P acc = identity();

    // Convert JubJubNativeFq scalar to 32-byte big-endian array
    final byteList = other.toBytes().reversed.toList();

    // Iterate bits from most significant to least significant, skipping leading bit
    for (int i = 0; i < byteList.length; i++) {
      final byte = byteList[i];
      for (int j = 7; j >= 0; j--) {
        if (i == 0 && j == 7) continue; // skip leading bit

        final bit = ((byte >> j) & 1) == 1; // Choice as bool
        acc = acc.double();
        acc = bit ? (acc + this) : acc;
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
  List<int> toBytes() {
    return toAffine().toBytes();
  }

  @override
  bool isSmallOrder() {
    return clearCofactor().isIdentity();
  }
}

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
  PastaAffinePoint({required this.x, required this.y});
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
    final bits = BytesUtils.bytesToBits(rhs.toBytes());
    final iterableBits = bits.reversed.skip(1);
    for (final i in iterableBits) {
      acc = acc.double();
      acc = i ? acc + this : acc;
    }
    return acc;
  }

  @override
  P operator +(BasePastaPoint<SCALAR, BASE> rhs) {
    switch (rhs) {
      case final PastaAffinePoint<SCALAR, BASE, P> other:
        if (isIdentity()) {
          return other.toCurve();
        } else if (other.isIdentity()) {
          return toCurve();
        }
        if (x == other.x) {
          if (y == other.y) {
            return toCurve().double();
          }
          return identity();
        }
        final h = rhs.x - x;
        final hh = h.square();
        BASE i = hh + hh;
        i = i + i;
        BASE j = h * i;
        BASE r = rhs.y - y;
        r = r + r;
        final v = x * i;
        final x3 = r.square() - j - v - v;
        j = y * j;
        j = j + j;
        final y3 = r * (v - x3) - j;
        final z3 = h + h;
        return from(x: x3, y: y3, z: z3);

      case final P other:
        return other + this;
      default:
        throw CryptoException.operationNotSupported;
    }
  }

  P operator -(BasePastaPoint<SCALAR, BASE> other) {
    return this + (-other);
  }

  @override
  List<int> toBytes() {
    if (isIdentity()) {
      return List<int>.filled(32, 0);
    } else {
      final sign = ((y.isOdd() ? 1 : 0) << 7).toU8;
      final xBytes = x.toBytes();
      xBytes[31] |= sign;
      return xBytes;
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
