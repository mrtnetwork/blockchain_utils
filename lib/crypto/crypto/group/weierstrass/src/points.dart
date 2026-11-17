import 'dart:typed_data';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/crypto/crypto/group/core/field.dart';
import 'package:blockchain_utils/crypto/crypto/group/core/point.dart';
import 'package:blockchain_utils/crypto/crypto/group/weierstrass/src/fields.dart';
import 'package:blockchain_utils/crypto/crypto/keys/types/types.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/utils/numbers/fixed/src/u64/u64.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

bool _isZeroEncoding(List<int> b) {
  for (final e in b) {
    if (e != 0) return false;
  }
  return true;
}

abstract class WeierstrassCurveParams<B> {
  B get a;
  B get b;
}

class Secp256k1Params implements WeierstrassCurveParams<Secp256k1Fp> {
  @override
  final Secp256k1Fp a = Secp256k1Fp.zero;
  @override
  final Secp256k1Fp b = Secp256k1Fp.unsafe([
    Uint64.unsafe(7, 6839),
    Uint64.zero,
    Uint64.zero,
    Uint64.zero,
  ]);
}

class Secp256r1Params implements WeierstrassCurveParams<Secp256r1Fp> {
  @override
  final Secp256r1Fp a = Secp256r1Fp.unsafe([
    Uint64.unsafe(4294967295, 4294967292),
    Uint64.unsafe(3, 4294967295),
    Uint64.unsafe(0, 0),
    Uint64.unsafe(4294967292, 4),
  ]);
  @override
  final Secp256r1Fp b = Secp256r1Fp.unsafe([
    Uint64.unsafe(3634159458, 700759519),
    Uint64.unsafe(2901411277, 2021929104),
    Uint64.unsafe(3852607659, 4146147030),
    Uint64.unsafe(3694134813, 75974708),
  ]);
}

abstract class WeierstrassPoint<
  SCALAR extends CryptoField<SCALAR>,
  BASE extends CryptoField<BASE>,
  P extends WeierstrassPoint<SCALAR, BASE, P>
>
    extends ECPoint<SCALAR, P> {
  const WeierstrassPoint();
  BASE get x;
  BASE get y;
  BASE get z;
  WeierstrassCurveParams<BASE> get params;
  P from({required BASE x, required BASE y, required BASE z});
  P identity();
  bool isIdentity();
  P double();
  @override
  P operator +(P other);
  P operator -(P other);
  @override
  P operator -();
  @override
  P operator *(SCALAR s);
  bool isOnCurve();
  bool isZero();
  bool get isOdd;
  bool get isEven;
  @override
  BuBytes toBytes([CryptoKeyEncoding encoding = CryptoKeyEncoding.base]);
  BuBytes toUncompressed();
  BuBytes toXOnly();
}

// Concrete projective points copy Pasta formulas directly (no mixin casts).
class Secp256k1Point
    implements
        WeierstrassPoint<Secp256k1Fr, Secp256k1Fp, Secp256k1Point>,
        CryptoGroupElement<Secp256k1Point, Secp256k1Fr>,
        CofactorGroupElement<Secp256k1Fr, Secp256k1Point> {
  @override
  final Secp256k1Fp x;
  @override
  final Secp256k1Fp y;
  @override
  final Secp256k1Fp z;
  const Secp256k1Point({required this.x, required this.y, required this.z});
  static final params_ = Secp256k1Params();
  @override
  WeierstrassCurveParams<Secp256k1Fp> get params => params_;
  @override
  Secp256k1Point from({
    required Secp256k1Fp x,
    required Secp256k1Fp y,
    required Secp256k1Fp z,
  }) => Secp256k1Point(x: x, y: y, z: z);
  static final identity_ = Secp256k1Point(
    x: Secp256k1Fp.zero,
    y: Secp256k1Fp.zero,
    z: Secp256k1Fp.zero,
  );
  @override
  Secp256k1Point identity() => identity_;
  static const generator_ = Secp256k1Point(
    x: Secp256k1Fp.unsafe([
      Uint64.unsafe(3610652250, 1216225431),
      Uint64.unsafe(589179219, 700212955),
      Uint64.unsafe(2543798464, 872223388),
      Uint64.unsafe(2575427139, 3909656392),
    ]),
    y: Secp256k1Fp.unsafe([
      Uint64.unsafe(2975770322, 3554388962),
      Uint64.unsafe(2382126429, 522045005),
      Uint64.unsafe(1891022234, 2887369014),
      Uint64.unsafe(3477046559, 3567616726),
    ]),
    z: Secp256k1Fp.one,
  );
  Secp256k1Point generator() => generator_;
  Secp256k1AffinePoint toAffine() {
    if (isIdentity()) return Secp256k1AffinePoint.identity();
    final zInv = z.invert();
    if (zInv == null) return Secp256k1AffinePoint.identity();
    final zInv2 = zInv.square();
    return Secp256k1AffinePoint(x: x * zInv2, y: y * zInv2 * zInv);
  }

  @override
  bool isIdentity() => z.isZero();
  @override
  bool isOnCurve() {
    if (isIdentity()) return true;
    final z2 = z.square();
    final z4 = z2.square();
    final z6 = z4 * z2;
    final lhs = y.square() - (x.square() + params_.a * z4) * x;
    return lhs == params_.b * z6;
  }

  static Secp256k1Point conditionalSelect(
    Secp256k1Point a,
    Secp256k1Point b,
    bool choice,
  ) => Secp256k1Point(
    x: Secp256k1Fp.conditionalSelect(a.x, b.x, choice),
    y: Secp256k1Fp.conditionalSelect(a.y, b.y, choice),
    z: Secp256k1Fp.conditionalSelect(a.z, b.z, choice),
  );

  /// Mask form of [conditionalSelect]: [bit] is a 0/1 [Uint64] (never a
  /// `bool`), so point addition and scalar multiplication stay
  /// straight-line on secret data.
  static Secp256k1Point conditionalSelectMask(
    Secp256k1Point a,
    Secp256k1Point b,
    Uint64 bit,
  ) => Secp256k1Point(
    x: Secp256k1Fp.conditionalSelectMask(a.x, b.x, bit),
    y: Secp256k1Fp.conditionalSelectMask(a.y, b.y, bit),
    z: Secp256k1Fp.conditionalSelectMask(a.z, b.z, bit),
  );

  @override
  Secp256k1Point double() {
    // No early-return: formula gives (0,0,0) for identity.
    final xx = x.square();
    final yy = y.square();
    var aVal = yy.square();
    final zz = z.square();
    var s = (x + yy).square() - xx - aVal;
    s = s + s;
    final m = xx + xx + xx; // a=0
    final x3 = m.square() - s - s;
    aVal = aVal + aVal;
    aVal = aVal + aVal;
    aVal = aVal + aVal;
    final y3 = m * (s - x3) - aVal;
    final z3 = (y + z).square() - yy - zz;
    return from(x: x3, y: y3, z: z3);
  }

  @override
  Secp256k1Point operator +(Secp256k1Point other) {
    // Branch-free style: always compute formula + double, select via masks.
    final z1z1 = z.square();
    final z2z2 = other.z.square();
    final u1 = x * z2z2;
    final u2 = other.x * z1z1;
    var s1 = y * z2z2 * other.z;
    var s2 = other.y * z1z1 * z;
    final h = u2 - u1;
    final i = (h + h).square();
    final j = h * i;
    var r = (s2 - s1);
    r = r + r;
    final v = u1 * i;
    final x3 = r.square() - j - v - v;
    final s1j = s1 * j;
    final y3 = r * (v - x3) - s1j - s1j;
    final z3 = ((z + other.z).square() - z1z1 - z2z2) * h;
    var sum = from(x: x3, y: y3, z: z3);
    // All comparisons below fold to 0/1 masks: no bool branches on the
    // (secret) point data.
    final eqU = Uint64.ctEqualsMask(u1.limbs, u2.limbs) & Uint64.one;
    final eqS = Uint64.ctEqualsMask(s1.limbs, s2.limbs) & Uint64.one;
    sum = conditionalSelectMask(sum, double(), eqU & eqS);
    sum = conditionalSelectMask(sum, identity(), eqU & ~eqS);
    final inf1 =
        Uint64.isZeroMask(z.limbs[0] | z.limbs[1] | z.limbs[2] | z.limbs[3]) &
        Uint64.one;
    final inf2 =
        Uint64.isZeroMask(
          other.z.limbs[0] |
              other.z.limbs[1] |
              other.z.limbs[2] |
              other.z.limbs[3],
        ) &
        Uint64.one;
    sum = conditionalSelectMask(sum, other, inf1);
    sum = conditionalSelectMask(sum, this, inf2);
    return sum;
  }

  @override
  @override
  Secp256k1Point operator -(Secp256k1Point o) => this + (-o);
  @override
  Secp256k1Point operator -() => from(x: x, y: -y, z: z);

  @override
  Secp256k1Point operator *(Secp256k1Fr s) {
    // Double-and-add-always + mask select. Uniform 256x double+add+select,
    // including for the zero scalar (which yields identity).
    var acc = identity();
    final bytes = s.toBytes(endian: Endian.little);
    for (int i = 255; i >= 0; i--) {
      acc = acc.double();
      final add = acc + this;
      final bit = Uint64((bytes[i >> 3] >> (i & 7)) & 1);
      acc = conditionalSelectMask(acc, add, bit);
    }
    return acc;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Secp256k1Point) return false;
    if (isIdentity() || other.isIdentity()) {
      return isIdentity() == other.isIdentity();
    }
    final z1z1 = z.square();
    final z2z2 = other.z.square();
    final u1 = x * z2z2;
    final u2 = other.x * z1z1;
    final s1 = y * z2z2 * other.z;
    final s2 = other.y * z1z1 * z;
    return u1 == u2 && s1 == s2;
  }

  @override
  bool isZero() => isIdentity();

  // Prime-order curve (cofactor 1): no small-order points besides identity.
  @override
  bool isSmallOrder() => isIdentity();

  // Prime-order curve (cofactor 1): projection is the identity function.
  @override
  Secp256k1Point clearCofactor() => this;

  @override
  T cast<T extends ECPoint<Secp256k1Fr, Secp256k1Point>>() {
    if (this is! T)
      throw BuError(
        DefaultErrorType.castFailed,
        "Failed to cast value",
        details: {"expected": "T", "value": runtimeType.toString()},
      );
    return this as T;
  }

  @override
  int recommendedWnafForNumScalars(int total) {
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
    var ret = 4;
    for (final r in recommendations) {
      if (total > r) {
        ret += 1;
      } else {
        break;
      }
    }
    return ret;
  }

  @override
  bool get isOdd => toAffine().isOdd;

  @override
  bool get isEven => toAffine().isEven;

  @override
  int get hashCode {
    // Affine-normalized so equal points (even with different z, or any
    // z == 0 identity encoding) share a hashCode, matching operator ==.
    final a = toAffine();
    return Object.hash(a.x, a.y);
  }

  BuBytes toCompressed() => toAffine().toCompressed();
  static Secp256k1Point fromCompressed(List<int> b) =>
      Secp256k1AffinePoint.fromCompressed(b).toCurve();
  @override
  BuBytes toUncompressed() => toAffine().toUncompressed();
  static Secp256k1Point fromUncompressed(List<int> b) =>
      Secp256k1AffinePoint.fromUncompressed(b).toCurve();
  @override
  BuBytes toXOnly() => toAffine().toXOnly();

  /// SEC1 decoding with the same identity convention as
  /// [ProjectiveECCPoint]: lone `0x00` and all-zero 33/65-byte buffers
  /// decode to infinity (and infinity encodes back to those zero buffers
  /// via [toBytes]). Non-identity inputs are strictly validated
  /// (canonical range via field decoding plus an explicit on-curve check,
  /// including for the raw 64-byte form).
  @override
  BuBytes toBytes([CryptoKeyEncoding encoding = CryptoKeyEncoding.base]) {
    if (isIdentity()) {
      return BuBytes.fill(encoding == CryptoKeyEncoding.base ? 33 : 65);
    }
    switch (encoding) {
      case CryptoKeyEncoding.uncompressed:
        return toUncompressed();
      case CryptoKeyEncoding.base:
        return toCompressed();
    }
  }

  static Secp256k1Point fromBytes(List<int> data) {
    if (data.length == 1 && data[0] == 0x00) return identity_;
    if (data.length == 33 && _isZeroEncoding(data)) return identity_;
    if (data.length == 65 && _isZeroEncoding(data)) return identity_;
    if (data.length == 33) return fromCompressed(data);
    if (data.length == 65) return fromUncompressed(data);
    if (data.length == 64) {
      // Raw x||y has no infinity encoding: (0, 0) is rejected even though
      // the affine identity shares those coordinates.
      final p = Secp256k1AffinePoint(
        x: Secp256k1Fp.fromBytes(data.sublist(0, 32)),
        y: Secp256k1Fp.fromBytes(data.sublist(32, 64)),
      );
      if (p.isIdentity() || !p.isOnCurve()) {
        throw CoreErrors.invalidOperationArguments(
          "fromBytes",
          reason: "Not on curve.",
        );
      }
      return p.toCurve();
    }
    throw CoreErrors.invalidOperationArguments(
      "fromBytes",
      reason: "Invalid point encoding bytes length.",
    );
  }
}

class Secp256k1AffinePoint {
  final Secp256k1Fp x;
  final Secp256k1Fp y;
  const Secp256k1AffinePoint({required this.x, required this.y});
  static Secp256k1AffinePoint identity() =>
      const Secp256k1AffinePoint(x: Secp256k1Fp.zero, y: Secp256k1Fp.zero);
  bool isIdentity() => x.isZero() && y.isZero();
  bool get isOdd => (y.toBytes(endian: Endian.little)[0] & 1) == 1;
  bool get isEven => !isOdd;

  /// BIP340-style x-only lift: the point with even y for 32-byte big-endian
  /// [x]. Throws if [x] is out of range or has no square root (not on curve).
  static Secp256k1AffinePoint liftX(List<int> x) =>
      fromCompressed([0x02, ...x]);
  bool isOnCurve() {
    if (isIdentity()) return true;
    return y.square() == x.square() * x + Secp256k1Point.params_.b;
  }

  Secp256k1Point toCurve() {
    if (isIdentity()) return Secp256k1Point.identity_;
    return Secp256k1Point(x: x, y: y, z: Secp256k1Fp.one);
  }

  BuBytes toCompressed() {
    if (isIdentity()) {
      throw CoreErrors.invalidOperationArguments(
        "toCompressed",
        reason: "infinity",
      );
    }
    final xb = x.toBytes();
    final yb = y.toBytes(endian: Endian.little);
    final out = BuBytes.fill(33);
    out[0] = (yb[0] & 1) == 0 ? 0x02 : 0x03;
    out.setRange(1, 33, xb);
    return out;
  }

  /// SEC1 `0x04 || BE(x) || BE(y)`. Infinity encodes as 65 zero bytes,
  /// matching [ProjectiveECCPoint].
  BuBytes toUncompressed() {
    if (isIdentity()) return BuBytes.fill(65);
    final out = BuBytes.fill(65);
    out[0] = 0x04;
    out.setRange(1, 33, x.toBytes());
    out.setRange(33, 65, y.toBytes());
    return out;
  }

  /// BIP340-style x-only encoding (32-byte big-endian x). Infinity
  /// encodes as 32 zero bytes, matching `ProjectiveECCPoint.toXonly`.
  BuBytes toXOnly() {
    if (isIdentity()) return BuBytes.fill(32);
    return x.toBytes();
  }

  static Secp256k1AffinePoint fromUncompressed(List<int> b) {
    if (b.length != 65) {
      throw CoreErrors.invalidOperationArguments(
        "fromUncompressed",
        reason: "Invalid uncompressed.",
      );
    }
    if (_isZeroEncoding(b)) return identity();
    if (b[0] != 0x04) {
      throw CoreErrors.invalidOperationArguments(
        "fromUncompressed",
        reason: "Invalid uncompressed.",
      );
    }
    final p = Secp256k1AffinePoint(
      x: Secp256k1Fp.fromBytes(b.sublist(1, 33)),
      y: Secp256k1Fp.fromBytes(b.sublist(33, 65)),
    );
    if (!p.isOnCurve()) {
      throw CoreErrors.invalidOperationArguments(
        "fromUncompressed",
        reason: "Not on curve.",
      );
    }
    return p;
  }

  static Secp256k1AffinePoint fromCompressed(List<int> b) {
    if (b.length != 33 || (b[0] != 0x02 && b[0] != 0x03)) {
      throw CoreErrors.invalidOperationArguments(
        "fromCompressed",
        reason: "Invalid compressed.",
      );
    }
    final x = Secp256k1Fp.fromBytes(b.sublist(1, 33));
    final p = Secp256k1Params();
    final y2 = x.square() * x + p.b;
    final r = y2.sqrt();
    if (!r.isSquare) {
      throw CoreErrors.invalidOperationArguments(
        "fromCompressed",
        reason: "Not on curve.",
      );
    }
    var y = r.result;
    final yLe = y.toBytes(endian: Endian.little);
    final wantOdd = b[0] == 0x03;
    if (((yLe[0] & 1) == 1) != wantOdd) y = -y;
    return Secp256k1AffinePoint(x: x, y: y);
  }
}

class Secp256r1Point
    implements
        WeierstrassPoint<Secp256r1Fr, Secp256r1Fp, Secp256r1Point>,
        CryptoGroupElement<Secp256r1Point, Secp256r1Fr>,
        CofactorGroupElement<Secp256r1Fr, Secp256r1Point> {
  @override
  final Secp256r1Fp x;
  @override
  final Secp256r1Fp y;
  @override
  final Secp256r1Fp z;
  const Secp256r1Point({required this.x, required this.y, required this.z});
  static final params_ = Secp256r1Params();
  @override
  WeierstrassCurveParams<Secp256r1Fp> get params => params_;
  @override
  Secp256r1Point from({
    required Secp256r1Fp x,
    required Secp256r1Fp y,
    required Secp256r1Fp z,
  }) => Secp256r1Point(x: x, y: y, z: z);
  static final identity_ = Secp256r1Point(
    x: Secp256r1Fp.zero,
    y: Secp256r1Fp.zero,
    z: Secp256r1Fp.zero,
  );
  @override
  Secp256r1Point identity() => identity_;
  static final generator_ = Secp256r1Point(
    x: Secp256r1Fp.unsafe([
      Uint64.unsafe(2045194452, 413733948),
      Uint64.unsafe(1975162364, 1609414145),
      Uint64.unsafe(2046522155, 2002920720),
      Uint64.unsafe(412114806, 2771867078),
    ]),
    y: Secp256r1Fp.unsafe([
      Uint64.unsafe(3723645783, 3465893386),
      Uint64.unsafe(2336930020, 3122259036),
      Uint64.unsafe(3538454152, 3709989669),
      Uint64.unsafe(2238840600, 629693829),
    ]),
    z: Secp256r1Fp.one,
  );
  Secp256r1Point generator() => generator_;
  Secp256r1AffinePoint toAffine() {
    if (isIdentity()) return Secp256r1AffinePoint.identity();
    final zInv = z.invert();
    if (zInv == null) return Secp256r1AffinePoint.identity();
    final zInv2 = zInv.square();
    return Secp256r1AffinePoint(x: x * zInv2, y: y * zInv2 * zInv);
  }

  @override
  bool isIdentity() => z.isZero();
  @override
  bool isOnCurve() {
    if (isIdentity()) return true;
    final z2 = z.square();
    final z4 = z2.square();
    final z6 = z4 * z2;
    final lhs = y.square() - (x.square() + params_.a * z4) * x;
    return lhs == params_.b * z6;
  }

  static Secp256r1Point conditionalSelect(
    Secp256r1Point a,
    Secp256r1Point b,
    bool choice,
  ) => Secp256r1Point(
    x: Secp256r1Fp.conditionalSelect(a.x, b.x, choice),
    y: Secp256r1Fp.conditionalSelect(a.y, b.y, choice),
    z: Secp256r1Fp.conditionalSelect(a.z, b.z, choice),
  );

  /// Mask form of [conditionalSelect]: [bit] is a 0/1 [Uint64] (never a
  /// `bool`), so point addition and scalar multiplication stay
  /// straight-line on secret data.
  static Secp256r1Point conditionalSelectMask(
    Secp256r1Point a,
    Secp256r1Point b,
    Uint64 bit,
  ) => Secp256r1Point(
    x: Secp256r1Fp.conditionalSelectMask(a.x, b.x, bit),
    y: Secp256r1Fp.conditionalSelectMask(a.y, b.y, bit),
    z: Secp256r1Fp.conditionalSelectMask(a.z, b.z, bit),
  );

  @override
  Secp256r1Point double() {
    final xx = x.square();
    final yy = y.square();
    var aVal = yy.square();
    final zz = z.square();
    var s = (x + yy).square() - xx - aVal;
    s = s + s;
    final m = xx + xx + xx + params_.a * zz.square();
    final x3 = m.square() - s - s;
    aVal = aVal + aVal;
    aVal = aVal + aVal;
    aVal = aVal + aVal;
    final y3 = m * (s - x3) - aVal;
    final z3 = (y + z).square() - yy - zz;
    return from(x: x3, y: y3, z: z3);
  }

  @override
  Secp256r1Point operator +(Secp256r1Point other) {
    // Branch-free style: always compute formula + double, select via masks.
    final z1z1 = z.square();
    final z2z2 = other.z.square();
    final u1 = x * z2z2;
    final u2 = other.x * z1z1;
    var s1 = y * z2z2 * other.z;
    var s2 = other.y * z1z1 * z;
    final h = u2 - u1;
    final i = (h + h).square();
    final j = h * i;
    var r = (s2 - s1);
    r = r + r;
    final v = u1 * i;
    final x3 = r.square() - j - v - v;
    final s1j = s1 * j;
    final y3 = r * (v - x3) - s1j - s1j;
    final z3 = ((z + other.z).square() - z1z1 - z2z2) * h;
    var sum = from(x: x3, y: y3, z: z3);
    // All comparisons below fold to 0/1 masks: no bool branches on the
    // (secret) point data.
    final eqU = Uint64.ctEqualsMask(u1.limbs, u2.limbs) & Uint64.one;
    final eqS = Uint64.ctEqualsMask(s1.limbs, s2.limbs) & Uint64.one;
    sum = conditionalSelectMask(sum, double(), eqU & eqS);
    sum = conditionalSelectMask(sum, identity(), eqU & ~eqS);
    final inf1 =
        Uint64.isZeroMask(z.limbs[0] | z.limbs[1] | z.limbs[2] | z.limbs[3]) &
        Uint64.one;
    final inf2 =
        Uint64.isZeroMask(
          other.z.limbs[0] |
              other.z.limbs[1] |
              other.z.limbs[2] |
              other.z.limbs[3],
        ) &
        Uint64.one;
    sum = conditionalSelectMask(sum, other, inf1);
    sum = conditionalSelectMask(sum, this, inf2);
    return sum;
  }

  @override
  @override
  Secp256r1Point operator -(Secp256r1Point o) => this + (-o);
  @override
  Secp256r1Point operator -() => from(x: x, y: -y, z: z);

  @override
  Secp256r1Point operator *(Secp256r1Fr s) {
    // Double-and-add-always + mask select. Uniform 256x double+add+select,
    // including for the zero scalar (which yields identity).
    var acc = identity();
    final bytes = s.toBytes(endian: Endian.little);
    for (int i = 255; i >= 0; i--) {
      acc = acc.double();
      final add = acc + this;
      final bit = Uint64((bytes[i >> 3] >> (i & 7)) & 1);
      acc = conditionalSelectMask(acc, add, bit);
    }
    return acc;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Secp256r1Point) return false;
    if (isIdentity() || other.isIdentity()) {
      return isIdentity() == other.isIdentity();
    }
    final z1z1 = z.square();
    final z2z2 = other.z.square();
    return (x * z2z2) == (other.x * z1z1) &&
        (y * z2z2 * other.z) == (other.y * z1z1 * z);
  }

  @override
  bool isZero() => isIdentity();

  // Prime-order curve (cofactor 1): no small-order points besides identity.
  @override
  bool isSmallOrder() => isIdentity();

  // Prime-order curve (cofactor 1): projection is the identity function.
  @override
  Secp256r1Point clearCofactor() => this;

  @override
  T cast<T extends ECPoint<Secp256r1Fr, Secp256r1Point>>() {
    if (this is! T)
      throw BuError(
        DefaultErrorType.castFailed,
        "Failed to cast value",
        details: {"expected": "T", "value": runtimeType.toString()},
      );
    return this as T;
  }

  @override
  int recommendedWnafForNumScalars(int total) {
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
    var ret = 4;
    for (final r in recommendations) {
      if (total > r) {
        ret += 1;
      } else {
        break;
      }
    }
    return ret;
  }

  @override
  bool get isOdd => toAffine().isOdd;

  @override
  bool get isEven => toAffine().isEven;

  @override
  int get hashCode {
    // Affine-normalized so equal points (even with different z, or any
    // z == 0 identity encoding) share a hashCode, matching operator ==.
    final a = toAffine();
    return Object.hash(a.x, a.y);
  }

  BuBytes toCompressed() => toAffine().toCompressed();
  static Secp256r1Point fromCompressed(List<int> b) =>
      Secp256r1AffinePoint.fromCompressed(b).toCurve();
  @override
  BuBytes toUncompressed() => toAffine().toUncompressed();
  static Secp256r1Point fromUncompressed(List<int> b) =>
      Secp256r1AffinePoint.fromUncompressed(b).toCurve();
  @override
  BuBytes toXOnly() => toAffine().toXOnly();

  /// SEC1 decoding with the same identity convention as
  /// [ProjectiveECCPoint]: lone `0x00` and all-zero 33/65-byte buffers
  /// decode to infinity (and infinity encodes back to those zero buffers
  /// via [toBytes]). Non-identity inputs are strictly validated
  /// (canonical range via field decoding plus an explicit on-curve check,
  /// including for the raw 64-byte form).
  @override
  BuBytes toBytes([CryptoKeyEncoding encoding = CryptoKeyEncoding.base]) {
    if (isIdentity()) {
      return BuBytes.fill(encoding == CryptoKeyEncoding.base ? 33 : 65);
    }
    switch (encoding) {
      case CryptoKeyEncoding.uncompressed:
        return toUncompressed();
      case CryptoKeyEncoding.base:
        return toCompressed();
    }
  }

  static Secp256r1Point fromBytes(List<int> data) {
    if (data.length == 1 && data[0] == 0x00) return identity_;
    if (data.length == 33 && _isZeroEncoding(data)) return identity_;
    if (data.length == 65 && _isZeroEncoding(data)) return identity_;
    if (data.length == 33) return fromCompressed(data);
    if (data.length == 65) return fromUncompressed(data);
    if (data.length == 64) {
      // Raw x||y has no infinity encoding: (0, 0) is rejected even though
      // the affine identity shares those coordinates.
      final p = Secp256r1AffinePoint(
        x: Secp256r1Fp.fromBytes(data.sublist(0, 32)),
        y: Secp256r1Fp.fromBytes(data.sublist(32, 64)),
      );
      if (p.isIdentity() || !p.isOnCurve()) {
        throw CoreErrors.invalidOperationArguments(
          "fromBytes",
          reason: "Not on curve.",
        );
      }
      return p.toCurve();
    }
    throw CoreErrors.invalidOperationArguments(
      "fromBytes",
      reason: "Invalid point encoding bytes length.",
    );
  }
}

class Secp256r1AffinePoint {
  final Secp256r1Fp x;
  final Secp256r1Fp y;
  const Secp256r1AffinePoint({required this.x, required this.y});
  static Secp256r1AffinePoint identity() =>
      const Secp256r1AffinePoint(x: Secp256r1Fp.zero, y: Secp256r1Fp.zero);
  bool isIdentity() => x.isZero() && y.isZero();
  bool get isOdd => (y.toBytes(endian: Endian.little)[0] & 1) == 1;
  bool get isEven => !isOdd;

  /// BIP340-style x-only lift: the point with even y for 32-byte big-endian
  /// [x]. Throws if [x] is out of range or has no square root (not on curve).
  static Secp256r1AffinePoint liftX(List<int> x) =>
      fromCompressed([0x02, ...x]);
  bool isOnCurve() {
    if (isIdentity()) return true;
    final p = Secp256r1Point.params_;
    return y.square() == x.square() * x + p.a * x + p.b;
  }

  Secp256r1Point toCurve() {
    if (isIdentity()) return Secp256r1Point.identity_;
    return Secp256r1Point(x: x, y: y, z: Secp256r1Fp.one);
  }

  BuBytes toCompressed() {
    if (isIdentity()) {
      throw CoreErrors.invalidOperationArguments(
        "toCompressed",
        reason: "infinity",
      );
    }
    final xb = x.toBytes();
    final yb = y.toBytes(endian: Endian.little);
    final out = BuBytes.fill(33);
    out[0] = (yb[0] & 1) == 0 ? 0x02 : 0x03;
    out.setRange(1, 33, xb);
    return out;
  }

  /// SEC1 `0x04 || BE(x) || BE(y)`. Infinity encodes as 65 zero bytes,
  /// matching [ProjectiveECCPoint].
  BuBytes toUncompressed() {
    if (isIdentity()) return BuBytes.fill(65);
    final out = BuBytes.fill(65);
    out[0] = 0x04;
    out.setRange(1, 33, x.toBytes());
    out.setRange(33, 65, y.toBytes());
    return out;
  }

  /// BIP340-style x-only encoding (32-byte big-endian x). Infinity
  /// encodes as 32 zero bytes, matching `ProjectiveECCPoint.toXonly`.
  BuBytes toXOnly() {
    if (isIdentity()) return BuBytes.fill(32);
    return x.toBytes();
  }

  static Secp256r1AffinePoint fromUncompressed(List<int> b) {
    if (b.length != 65) {
      throw CoreErrors.invalidOperationArguments(
        "fromUncompressed",
        reason: "Invalid uncompressed.",
      );
    }
    if (_isZeroEncoding(b)) return identity();
    if (b[0] != 0x04) {
      throw CoreErrors.invalidOperationArguments(
        "fromUncompressed",
        reason: "Invalid uncompressed.",
      );
    }
    final p = Secp256r1AffinePoint(
      x: Secp256r1Fp.fromBytes(b.sublist(1, 33)),
      y: Secp256r1Fp.fromBytes(b.sublist(33, 65)),
    );
    if (!p.isOnCurve()) {
      throw CoreErrors.invalidOperationArguments(
        "fromUncompressed",
        reason: "Not on curve.",
      );
    }
    return p;
  }

  static Secp256r1AffinePoint fromCompressed(List<int> b) {
    if (b.length != 33 || (b[0] != 0x02 && b[0] != 0x03)) {
      throw CoreErrors.invalidOperationArguments(
        "fromCompressed",
        reason: "Invalid compressed.",
      );
    }
    final x = Secp256r1Fp.fromBytes(b.sublist(1, 33));
    final p = Secp256r1Params();
    final y2 = x.square() * x + p.a * x + p.b;
    final r = y2.sqrt();
    if (!r.isSquare) {
      throw CoreErrors.invalidOperationArguments(
        "fromCompressed",
        reason: "Not on curve.",
      );
    }
    var y = r.result;
    if ((((y.toBytes(endian: Endian.little)[0] & 1) == 1)) != (b[0] == 0x03))
      // ignore: curly_braces_in_flow_control_structures
      y = -y;
    return Secp256r1AffinePoint(x: x, y: y);
  }
}
