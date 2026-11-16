import 'package:blockchain_utils/crypto/crypto/group/jubjub/constants/constants.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/crypto/crypto/group/jubjub/fields/field.dart';
import 'package:blockchain_utils/crypto/crypto/group/jubjub/point/core.dart';
import 'package:blockchain_utils/crypto/crypto/group/jubjub/point/niels.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/helper/helper.dart';
import 'package:blockchain_utils/utils/numbers/fixed/src/u64/u64.dart';

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';
import 'package:blockchain_utils/utils/compare/hash_code.dart';
import 'package:blockchain_utils/utils/equatable/equatable.dart';

/// A JubJub point in extended coordinates `(u, v, z, t1, t2)`, the main
/// representation for group arithmetic.
class JubJubPoint extends BaseJubJubPoint<JubJubFr, JubJubPoint> {
  final JubJubFq u;
  final JubJubFq v;
  final JubJubFq z;
  final JubJubFq t1;
  final JubJubFq t2;

  const JubJubPoint({
    required this.u,
    required this.v,
    required this.z,
    required this.t1,
    required this.t2,
  });

  factory JubJubPoint.fromAffinePoint(JubJubAffinePoint point) {
    return JubJubPoint(
      u: point.u,
      v: point.v,
      z: JubJubFq.one,
      t1: point.u,
      t2: point.v,
    );
  }
  factory JubJubPoint.fromBytes(List<int> bytes, {bool zip216Enabled = true}) {
    return JubJubPoint.fromAffinePoint(
      JubJubAffinePoint.fromBytes(bytes, zip216Enabled: zip216Enabled),
    );
  }
  static final _identity = JubJubPoint(
    u: JubJubFq.zero,
    v: JubJubFq.one,
    z: JubJubFq.one,
    t1: JubJubFq.zero,
    t2: JubJubFq.zero,
  );

  factory JubJubPoint.identity() {
    return _identity;
  }

  @override
  bool isIdentity() {
    return u.isZero() && v == z;
  }

  @override
  bool isSmallOrder() {
    return double().double().u.isZero();
  }

  @override
  JubJubPoint operator *(JubJubFr rhs) {
    return toNiels() * rhs;
  }

  @override
  JubJubPoint operator +(BaseRedJubJubPoint rhs) {
    switch (rhs) {
      case final JubJubNielsPoint point:
        final a = (v - u) * point.vMinusU;
        final b = (v + u) * point.vPlusU;
        final c = t1 * t2 * point.t2d;
        final d = (z * point.z).double();
        return _JubJubCompletedPoint(
          u: b - a,
          v: b + a,
          z: d + c,
          t: d - c,
        ).toExtended();
      case final JubJubAffineNielsPoint point:
        final a = (v - u) * point.vMinusU;
        final b = (v + u) * point.vPlusU;
        final c = t1 * t2 * point.t2d;
        final d = z.double();
        return _JubJubCompletedPoint(
          u: b - a,
          v: b + a,
          z: d + c,
          t: d - c,
        ).toExtended();
      case final JubJubPoint point:
        return this + point.toNiels();
      case final JubJubAffinePoint point:
        return this + point.toNiels();
      default:
        throw CoreErrors.cryptoOperationNotSupported;
    }
  }

  @override
  JubJubPoint double() {
    final uu = u.square();
    final vv = v.square();
    final zz2 = z.square().double();
    final uv2 = (u + v).square();
    final vvPlus = vv + uu;
    final vvMinus = vv - uu;
    return _JubJubCompletedPoint(
      u: uv2 - vvPlus,
      v: vvPlus,
      z: vvMinus,
      t: zz2 - vvMinus,
    ).toExtended();
  }

  @override
  BuBytes toBytes() {
    return JubJubAffinePoint.fromExtendedPoint(this).toBytes();
  }

  @override
  JubJubNielsPoint toNiels() {
    return JubJubNielsPoint(
      vPlusU: v + u,
      vMinusU: v - u,
      z: z,
      t2d: t1 * t2 * JubJubFq.edwardsD2,
    );
  }

  @override
  JubJubPoint operator -(BaseRedJubJubPoint rhs) {
    switch (rhs) {
      case final JubJubNielsPoint point:
        final a = (v - u) * point.vPlusU;
        final b = (v + u) * point.vMinusU;
        final c = t1 * t2 * point.t2d;
        final d = (z * point.z).double();
        return _JubJubCompletedPoint(
          u: b - a,
          v: b + a,
          z: d - c,
          t: d + c,
        ).toExtended();
      case final JubJubAffineNielsPoint point:
        final a = (v - u) * point.vPlusU;
        final b = (v + u) * point.vMinusU;
        final c = t1 * t2 * point.t2d;
        final d = z.double();
        return _JubJubCompletedPoint(
          u: b - a,
          v: b + a,
          z: d - c,
          t: d + c,
        ).toExtended();
      case final JubJubPoint point:
        return this - point.toNiels();
      case final JubJubAffinePoint point:
        return this - point.toNiels();
      default:
        throw CoreErrors.cryptoOperationNotSupported;
    }
  }

  @override
  JubJubPoint operator -() {
    return JubJubPoint(u: -u, v: v, z: z, t1: -t1, t2: t2);
  }

  bool isOnCurve() {
    final point = JubJubAffinePoint.fromExtendedPoint(this);

    return (z != JubJubFq.zero &&
        point.isOnCurve() &&
        (point.u * point.v * z) == (t1 * t2));
  }

  @override
  JubJubPoint mulByCofactor() {
    return double().double().double();
  }

  @override
  operator ==(other) {
    if (other is! JubJubPoint) return false;
    return (u * other.z) == (other.u * z) && (v * other.z) == (other.v * z);
  }

  @override
  int get hashCode => HashCodeGenerator.generateHashCode([u, v, t1, t2, z]);

  @override
  JubJubPoint multiply(List<int> by) {
    return toNiels().multiply(by);
  }

  bool isTorsionFree() {
    return multiply(JubJubFrConst.frModulusBytes).isIdentity();
  }

  JubJubAffinePoint toAffine() {
    return JubJubAffinePoint.fromExtendedPoint(this);
  }

  @override
  JubJubPoint identity() {
    return JubJubPoint.identity();
  }

  @override
  int recommendedWnafForNumScalars(int numScalars) {
    const List<int> rec = <int>[
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
    for (final r in rec) {
      if (numScalars > r) {
        ret += 1;
      } else {
        break;
      }
    }
    return ret;
  }
}

/// A point in "completed" coordinates `(u, v, z, t)`, the intermediate
/// output of an addition/doubling formula before it's reduced to [JubJubPoint].
class _JubJubCompletedPoint {
  final JubJubFq u;
  final JubJubFq v;
  final JubJubFq z;
  final JubJubFq t;
  const _JubJubCompletedPoint({
    required this.u,
    required this.v,
    required this.z,
    required this.t,
  });
  JubJubPoint toExtended() {
    return JubJubPoint(u: u * t, v: v * z, z: z * t, t1: u, t2: v);
  }
}

/// A JubJub point in affine coordinates `(u, v)`.
class JubJubAffinePoint extends BaseJubJubAffinePoint<JubJubFr> with Equality {
  final JubJubFq u;
  final JubJubFq v;

  JubJubAffinePoint({required this.u, required this.v});
  factory JubJubAffinePoint.conditionalSelect(
    JubJubAffinePoint a,
    JubJubAffinePoint b,
    bool choice,
  ) {
    return JubJubAffinePoint(
      u: JubJubFq.conditionalSelect(a.u, b.u, choice),
      v: JubJubFq.conditionalSelect(a.v, b.v, choice),
    );
  }
  factory JubJubAffinePoint.identity() {
    return JubJubAffinePoint(u: JubJubFq.zero, v: JubJubFq.one);
  }
  /// Zcash JubJub generator, matching `jubjub::AffinePoint::generator`
  /// (zkcrypto): the point with the lowest positive v-coordinate and positive
  /// u-coordinate (compressed `0b00…00`).
  ///
  /// Note this point has full-curve order 8r, not prime order. Use
  /// `mulByCofactor()` for the prime-order subgroup generator
  /// (`jubjub::SubgroupPoint::generator`).
  factory JubJubAffinePoint.generator() {
    // Plain LE limbs for fromRaw (which maps into Montgomery form),
    // same semantics as zkcrypto `Fq::from_raw`.
    return JubJubAffinePoint(
      u: JubJubFq.fromRaw([
        Uint64.parseHex("0xe4b3d35df1a7adfe"),
        Uint64.parseHex("0xcaf55d1b29bf81af"),
        Uint64.parseHex("0x8b0f03ddd60a8187"),
        Uint64.parseHex("0x62edcbb8bf3787c8"),
      ]),
      v: JubJubFq.fromRaw([
        Uint64.parseHex("0x0b"),
        Uint64.parseHex("0x00"),
        Uint64.parseHex("0x00"),
        Uint64.parseHex("0x00"),
      ]),
    );
  }
  factory JubJubAffinePoint.fromExtendedPoint(JubJubPoint point) {
    final zinv = point.z.invert();
    if (zinv == null) {
      throw CoreErrors.invalidOperationArguments(
        "JubJubAffinePoint",
        reason: "Invalid Extended point.",
      );
    }
    return JubJubAffinePoint(u: point.u * zinv, v: point.v * zinv);
  }
  factory JubJubAffinePoint.fromBytes(
    List<int> bytes, {
    bool zip216Enabled = false,
  }) {
    final b =
        bytes
            .exc(
              length: 32,
              operation: "fromBytes",
              reason: "Invalid point encoding bytes length.",
            )
            .clone();
    // Grab the sign bit
    final sign = (b[31] >> 7).toU8;

    // Mask away the sign bit
    b[31] &= 0x7F;

    // Interpret remaining bytes as v-coordinate
    final v = JubJubFq.fromBytes(b);
    final v2 = v.square();

    // u^2 = (v^2 - 1) / (1 + d*v^2)
    final denominator = JubJubFq.one + JubJubFq.edwardsD * v2;
    JubJubFq invDenominator = denominator.invert() ?? JubJubFq.zero;
    final u2 = (v2 - JubJubFq.one) * invDenominator;
    final u = u2.sqrt().sqrtOrNull();
    if (u == null) {
      throw CoreErrors.invalidOperationArguments(
        "JubJubAffinePoint",
        reason: "Invalid point encoding bytes.",
      );
    }

    // Fix the sign of u if necessary
    final flipSign = ((u.toBytes()[0] ^ sign) & 1) == 1;
    final finalU = JubJubFq.conditionalSelect(u, -u, flipSign);

    final uIsZero = u.isZero();

    // ZIP 216 check: reject encoding if enabled and u == 0 and flipSign == true
    final isValid = !(zip216Enabled && uIsZero && flipSign);
    if (!isValid) {
      throw CoreErrors.invalidOperationArguments(
        "JubJubAffinePoint",
        reason: "Invalid point encoding bytes.",
      );
    }
    return JubJubAffinePoint(u: finalU, v: v);
  }

  @override
  JubJubPoint operator *(JubJubFr rhs) {
    return toNiels().multiply(rhs.toBytes());
  }

  @override
  JubJubAffinePoint operator +(BaseRedJubJubPoint rhs) {
    throw CoreErrors.cryptoOperationNotSupported;
  }

  @override
  JubJubAffinePoint operator -(BaseRedJubJubPoint rhs) {
    throw CoreErrors.cryptoOperationNotSupported;
  }

  @override
  BuBytes toBytes() {
    final tmp = v.toBytes().clone();
    final u = this.u.toBytes();

    // Encode the sign of the u-coordinate in the most
    // significant bit.
    tmp[31] |= (u[0] << 7).toU8;
    return BuBytes(tmp);
  }

  @override
  JubJubAffineNielsPoint toNiels() {
    return JubJubAffineNielsPoint(
      vPlusU: v + u,
      vMinusU: v - u,
      t2d: (u * v) * JubJubFq.edwardsD2,
    );
  }

  @override
  JubJubAffinePoint operator -() {
    return JubJubAffinePoint(u: -u, v: v);
  }

  bool isOnCurve() {
    final u2 = u.square();
    final v2 = v.square();

    return v2 - u2 == JubJubFq.one + JubJubFq.edwardsD * u2 * v2;
  }

  @override
  List<dynamic> get variables => [u, v];

  @override
  JubJubPoint multiply(List<int> by) {
    return toNiels().multiply(by);
  }

  JubJubPoint mulByCofactor() {
    return JubJubPoint.fromAffinePoint(this).mulByCofactor();
  }

  bool isSmallOrder() {
    return JubJubPoint.fromAffinePoint(this).isSmallOrder();
  }

  JubJubPoint toExtended() {
    return JubJubPoint.fromAffinePoint(this);
  }

  bool isIdentity() {
    return toExtended().isIdentity();
  }
}
