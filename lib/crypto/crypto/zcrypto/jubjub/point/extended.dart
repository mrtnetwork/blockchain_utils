import 'package:blockchain_utils/crypto/crypto/zcrypto/jubjub/constants/constants.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/jubjub/fields/field.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/jubjub/fields/native.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/jubjub/point/core.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/jubjub/point/niels.dart';
import 'package:blockchain_utils/crypto/crypto/exception/exception.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/helper/helper.dart';
import 'package:blockchain_utils/utils/compare/hash_code.dart';
import 'package:blockchain_utils/utils/equatable/equatable.dart';

class JubJubPoint extends BaseJubJubPoint<JubJubFr, JubJubPoint> {
  final JubJubFq u;
  final JubJubFq v;
  final JubJubFq z;
  final JubJubFq t1;
  final JubJubFq t2;

  JubJubPoint({
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
      z: JubJubFq.one(),
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
    u: JubJubFq.zero(),
    v: JubJubFq.one(),
    z: JubJubFq.one(),
    t1: JubJubFq.zero(),
    t2: JubJubFq.zero(),
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
        return _JubjubCompletedPoint(
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
        return _JubjubCompletedPoint(
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
        throw CryptoException.operationNotSupported;
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
    return _JubjubCompletedPoint(
      u: uv2 - vvPlus,
      v: vvPlus,
      z: vvMinus,
      t: zz2 - vvMinus,
    ).toExtended();
  }

  @override
  List<int> toBytes() {
    return JubJubAffinePoint.fromExtendedPoint(this).toBytes();
  }

  @override
  JubJubNielsPoint toNiels() {
    return JubJubNielsPoint(
      vPlusU: v + u,
      vMinusU: v - u,
      z: z,
      t2d: t1 * t2 * JubJubFq.edwardsD2(),
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
        return _JubjubCompletedPoint(
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
        return _JubjubCompletedPoint(
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
        throw CryptoException.operationNotSupported;
    }
  }

  @override
  JubJubPoint operator -() {
    return JubJubPoint(u: -u, v: v, z: z, t1: -t1, t2: t2);
  }

  bool isOnCurve() {
    final point = JubJubAffinePoint.fromExtendedPoint(this);

    return (z != JubJubFq.zero() &&
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

class _JubjubCompletedPoint {
  final JubJubFq u;
  final JubJubFq v;
  final JubJubFq z;
  final JubJubFq t;
  const _JubjubCompletedPoint({
    required this.u,
    required this.v,
    required this.z,
    required this.t,
  });
  JubJubPoint toExtended() {
    return JubJubPoint(u: u * t, v: v * z, z: z * t, t1: u, t2: v);
  }
}

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
    return JubJubAffinePoint(u: JubJubFq.zero(), v: JubJubFq.one());
  }
  factory JubJubAffinePoint.generator() {
    return JubJubAffinePoint(
      u: JubJubFq.fromRaw([
        BigInt.parse("0xe4b3d35df1a7adfe"),
        BigInt.parse("0xcaf55d1b29bf81af"),
        BigInt.parse("0x8b0f03ddd60a8187"),
        BigInt.parse("0x62edcbb8bf3787c8"),
      ]),
      v: JubJubFq.fromRaw([
        BigInt.parse("0x000000000000000b"),
        BigInt.parse("0x0000000000000000"),
        BigInt.parse("0x0000000000000000"),
        BigInt.parse("0x0000000000000000"),
      ]),
    );
  }
  factory JubJubAffinePoint.fromExtendedPoint(JubJubPoint point) {
    final zinv = point.z.invert();
    if (zinv == null) {
      throw ArgumentException.invalidOperationArguments(
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
    final denominator = JubJubFq.one() + JubJubFq.edwardsD() * v2;
    JubJubFq invDenominator = denominator.invert() ?? JubJubFq.zero();
    final u2 = (v2 - JubJubFq.one()) * invDenominator;
    final u = u2.sqrt().sqrtOrNull();
    if (u == null) {
      throw ArgumentException.invalidOperationArguments(
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
      throw ArgumentException.invalidOperationArguments(
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
    throw CryptoException.operationNotSupported;
  }

  @override
  JubJubAffinePoint operator -(BaseRedJubJubPoint rhs) {
    throw CryptoException.operationNotSupported;
  }

  @override
  List<int> toBytes() {
    final tmp = v.toBytes().clone();
    final u = this.u.toBytes();

    // Encode the sign of the u-coordinate in the most
    // significant bit.
    tmp[31] |= (u[0] << 7).toU8;
    return tmp;
  }

  @override
  JubJubAffineNielsPoint toNiels() {
    return JubJubAffineNielsPoint(
      vPlusU: v + u,
      vMinusU: v - u,
      t2d: (u * v) * JubJubFq.edwardsD2(),
    );
  }

  @override
  JubJubAffinePoint operator -() {
    return JubJubAffinePoint(u: -u, v: v);
  }

  bool isOnCurve() {
    final u2 = u.square();
    final v2 = v.square();

    return v2 - u2 == JubJubFq.one() + JubJubFq.edwardsD() * u2 * v2;
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

class JubJubNativePoint
    extends BaseJubJubPoint<JubJubNativeFr, JubJubNativePoint> {
  final JubJubNativeFq u;
  final JubJubNativeFq v;
  final JubJubNativeFq z;
  final JubJubNativeFq t1;
  final JubJubNativeFq t2;

  JubJubNativePoint({
    required this.u,
    required this.v,
    required this.z,
    required this.t1,
    required this.t2,
  });

  factory JubJubNativePoint.fromAffinePoint(JubJubAffineNativePoint point) {
    return JubJubNativePoint(
      u: point.u,
      v: point.v,
      z: JubJubNativeFq.one(),
      t1: point.u,
      t2: point.v,
    );
  }
  factory JubJubNativePoint.fromBytes(
    List<int> bytes, {
    bool zip216Enabled = true,
  }) {
    return JubJubNativePoint.fromAffinePoint(
      JubJubAffineNativePoint.fromBytes(bytes, zip216Enabled: zip216Enabled),
    );
  }
  static final _identity = JubJubNativePoint(
    u: JubJubNativeFq.zero(),
    v: JubJubNativeFq.one(),
    z: JubJubNativeFq.one(),
    t1: JubJubNativeFq.zero(),
    t2: JubJubNativeFq.zero(),
  );

  factory JubJubNativePoint.identity() {
    return _identity;
  }
  factory JubJubNativePoint.random({bool subgroupPoint = false}) {
    while (true) {
      JubJubNativeFq v = JubJubNativeFq.random();
      final flipSign = (QuickCrypto.nextU32() % 2) != 0;
      JubJubNativeFq v2 = v.square();
      final n =
          ((v2 - JubJubNativeFq.one()) *
                  ((JubJubNativeFq.one() + JubJubNativeFq.edwardsD() * v2)
                          .invert() ??
                      JubJubNativeFq.zero()))
              .sqrt()
              .sqrtOrNull();
      if (n != null) {
        JubJubNativePoint extended =
            JubJubAffineNativePoint(u: flipSign ? -n : n, v: v).toExtended();
        if (!extended.isIdentity()) {
          if (subgroupPoint) {
            extended = extended.mulByCofactor();
            if (!extended.isIdentity()) return extended;
            continue;
          }
          return extended;
        }
      }
    }
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
  JubJubNativePoint operator *(JubJubNativeFr rhs) {
    return toNiels() * rhs;
  }

  @override
  JubJubNativePoint operator +(BaseRedJubJubPoint<JubJubNativeFr> rhs) {
    switch (rhs) {
      case final JubJubNielsNativePoint point:
        final a = (v - u) * point.vMinusU;
        final b = (v + u) * point.vPlusU;
        final c = t1 * t2 * point.t2d;
        final d = (z * point.z).double();
        return _JubjubCompletedNativePoint(
          u: b - a,
          v: b + a,
          z: d + c,
          t: d - c,
        ).toExtended();
      case final JubJubAffineNielsNativePoint point:
        final a = (v - u) * point.vMinusU;
        final b = (v + u) * point.vPlusU;
        final c = t1 * t2 * point.t2d;
        final d = z.double();
        return _JubjubCompletedNativePoint(
          u: b - a,
          v: b + a,
          z: d + c,
          t: d - c,
        ).toExtended();
      case final JubJubNativePoint point:
        return this + point.toNiels();
      case final JubJubAffineNativePoint point:
        return this + point.toNiels();
      default:
        throw CryptoException.operationNotSupported;
    }
  }

  @override
  JubJubNativePoint double() {
    final uu = u.square();
    final vv = v.square();
    final zz2 = z.square().double();
    final uv2 = (u + v).square();
    final vvPlus = vv + uu;
    final vvMinus = vv - uu;
    return _JubjubCompletedNativePoint(
      u: uv2 - vvPlus,
      v: vvPlus,
      z: vvMinus,
      t: zz2 - vvMinus,
    ).toExtended();
  }

  @override
  List<int> toBytes() {
    return JubJubAffineNativePoint.fromExtendedPoint(this).toBytes();
  }

  @override
  JubJubNielsNativePoint toNiels() {
    final d2 = JubJubNativeFq.edwardsD2();
    return JubJubNielsNativePoint(
      vPlusU: v + u,
      vMinusU: v - u,
      z: z,
      t2d: t1 * t2 * d2,
    );
  }

  @override
  JubJubNativePoint operator -(BaseRedJubJubPoint<JubJubNativeFr> rhs) {
    switch (rhs) {
      case final JubJubNielsNativePoint point:
        final a = (v - u) * point.vPlusU;
        final b = (v + u) * point.vMinusU;
        final c = t1 * t2 * point.t2d;
        final d = (z * point.z).double();
        return _JubjubCompletedNativePoint(
          u: b - a,
          v: b + a,
          z: d - c,
          t: d + c,
        ).toExtended();
      case final JubJubAffineNielsNativePoint point:
        final a = (v - u) * point.vPlusU;
        final b = (v + u) * point.vMinusU;
        final c = t1 * t2 * point.t2d;
        final d = z.double();
        return _JubjubCompletedNativePoint(
          u: b - a,
          v: b + a,
          z: d - c,
          t: d + c,
        ).toExtended();
      case final JubJubNativePoint point:
        return this - point.toNiels();
      case final JubJubAffineNativePoint point:
        return this - point.toNiels();
      default:
        throw CryptoException.operationNotSupported;
    }
  }

  @override
  JubJubNativePoint operator -() {
    return JubJubNativePoint(u: -u, v: v, z: z, t1: -t1, t2: t2);
  }

  bool isOnCurve() {
    final point = JubJubAffineNativePoint.fromExtendedPoint(this);

    return (z != JubJubNativeFq.zero() &&
        point.isOnCurve() &&
        (point.u * point.v * z) == (t1 * t2));
  }

  @override
  JubJubNativePoint mulByCofactor() {
    return double().double().double();
  }

  @override
  operator ==(other) {
    if (other is! JubJubNativePoint) return false;
    return (u * other.z) == (other.u * z) && (v * other.z) == (other.v * z);
  }

  @override
  int get hashCode => HashCodeGenerator.generateHashCode([u, v, t1, t2, z]);

  @override
  JubJubNativePoint multiply(List<int> by) {
    return toNiels().multiply(by);
  }

  bool isTorsionFree() {
    return multiply(JubJubFrConst.frModulusBytes).isIdentity();
  }

  JubJubAffineNativePoint toAffine() {
    return JubJubAffineNativePoint.fromExtendedPoint(this);
  }

  @override
  JubJubNativePoint identity() {
    return JubJubNativePoint.identity();
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

class _JubjubCompletedNativePoint {
  final JubJubNativeFq u;
  final JubJubNativeFq v;
  final JubJubNativeFq z;
  final JubJubNativeFq t;
  const _JubjubCompletedNativePoint({
    required this.u,
    required this.v,
    required this.z,
    required this.t,
  });
  JubJubNativePoint toExtended() {
    return JubJubNativePoint(u: u * t, v: v * z, z: z * t, t1: u, t2: v);
  }
}

class JubJubAffineNativePoint extends BaseJubJubAffinePoint<JubJubNativeFr>
    with Equality {
  final JubJubNativeFq u;
  final JubJubNativeFq v;

  JubJubAffineNativePoint({required this.u, required this.v});
  factory JubJubAffineNativePoint.identity() {
    return JubJubAffineNativePoint(
      u: JubJubNativeFq.zero(),
      v: JubJubNativeFq.one(),
    );
  }
  factory JubJubAffineNativePoint.generator() {
    return JubJubAffineNativePoint.fromBytes(
      JubJubAffinePoint(
        u: JubJubFq.fromRaw([
          BigInt.parse("0xe4b3d35df1a7adfe"),
          BigInt.parse("0xcaf55d1b29bf81af"),
          BigInt.parse("0x8b0f03ddd60a8187"),
          BigInt.parse("0x62edcbb8bf3787c8"),
        ]),
        v: JubJubFq.fromRaw([
          BigInt.parse("0x000000000000000b"),
          BigInt.parse("0x0000000000000000"),
          BigInt.parse("0x0000000000000000"),
          BigInt.parse("0x0000000000000000"),
        ]),
      ).toBytes(),
    );
  }
  factory JubJubAffineNativePoint.fromExtendedPoint(JubJubNativePoint point) {
    final zinv = point.z.invert();
    if (zinv == null) {
      throw ArgumentException.invalidOperationArguments(
        "JubJubAffineNativePoint",
        reason: "Invalid Extended point.",
      );
    }
    return JubJubAffineNativePoint(u: point.u * zinv, v: point.v * zinv);
  }
  factory JubJubAffineNativePoint.fromBytes(
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
    final v = JubJubNativeFq.fromBytes(b);
    final v2 = v.square();

    // u^2 = (v^2 - 1) / (1 + d*v^2)
    final denominator = (JubJubNativeFq.one() + JubJubNativeFq.edwardsD() * v2);
    JubJubNativeFq invDenominator =
        denominator.invert() ?? JubJubNativeFq.zero();
    final u2 = (v2 - JubJubNativeFq.one()) * invDenominator;
    final u = u2.sqrt().sqrtOrNull();
    if (u == null) {
      throw ArgumentException.invalidOperationArguments(
        "JubJubAffinePoint",
        reason: "Invalid point encoding bytes.",
      );
    }

    // Fix the sign of u if necessary
    final flipSign = ((u.toBytes()[0] ^ sign) & 1) == 1;
    final finalU = flipSign ? -u : u;

    final uIsZero = u.isZero();

    // ZIP 216 check: reject encoding if enabled and u == 0 and flipSign == true
    final isValid = !(zip216Enabled && uIsZero && flipSign);
    if (!isValid) {
      throw ArgumentException.invalidOperationArguments(
        "JubJubAffinePoint",
        reason: "Invalid point encoding bytes.",
      );
    }
    return JubJubAffineNativePoint(u: finalU, v: v);
  }

  @override
  JubJubNativePoint operator *(JubJubNativeFr rhs) {
    return toNiels().multiply(rhs.toBytes());
  }

  @override
  JubJubAffineNativePoint operator +(BaseRedJubJubPoint<JubJubNativeFr> rhs) {
    throw CryptoException.operationNotSupported;
  }

  @override
  JubJubAffineNativePoint operator -(BaseRedJubJubPoint<JubJubNativeFr> rhs) {
    throw CryptoException.operationNotSupported;
  }

  @override
  List<int> toBytes() {
    final tmp = v.toBytes().clone();
    final u = this.u.toBytes();

    // Encode the sign of the u-coordinate in the most
    // significant bit.
    tmp[31] |= (u[0] << 7).toU8;
    return tmp;
  }

  @override
  JubJubAffineNielsNativePoint toNiels() {
    return JubJubAffineNielsNativePoint(
      vPlusU: v + u,
      vMinusU: v - u,
      t2d: (u * v) * JubJubNativeFq.edwardsD2(),
    );
  }

  @override
  JubJubAffineNativePoint operator -() {
    return JubJubAffineNativePoint(u: -u, v: v);
  }

  bool isOnCurve() {
    final u2 = u.square();
    final v2 = v.square();
    final eq = JubJubNativeFq.edwardsD();

    return v2 - u2 == JubJubNativeFq.one() + eq * u2 * v2;
  }

  @override
  List<dynamic> get variables => [u, v];

  @override
  JubJubNativePoint multiply(List<int> by) {
    return toNiels().multiply(by);
  }

  JubJubNativePoint mulByCofactor() {
    return JubJubNativePoint.fromAffinePoint(this).mulByCofactor();
  }

  bool isSmallOrder() {
    return JubJubNativePoint.fromAffinePoint(this).isSmallOrder();
  }

  JubJubNativePoint toExtended() {
    return JubJubNativePoint.fromAffinePoint(this);
  }

  bool isIdentity() {
    return toExtended().isIdentity();
  }
}
