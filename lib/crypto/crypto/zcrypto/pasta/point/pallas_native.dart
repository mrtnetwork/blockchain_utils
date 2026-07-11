import 'package:blockchain_utils/crypto/crypto/zcrypto/pasta/constants/pallas.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/pasta/fields/native/fq.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/pasta/fields/native/fp.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/pasta/point/core.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/pasta/utils/utils.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'iso_pallas_native.dart';

class PallasNativePoint
    extends PastaPoint<VestaNativeFq, PallasNativeFp, PallasNativePoint> {
  PallasNativePoint({required super.x, required super.y, required super.z});

  factory PallasNativePoint.fromAffine(PallasAffineNativePoint point) {
    return point.toCurve();
  }
  factory PallasNativePoint.random() {
    while (true) {
      final x = PallasNativeFp.random();
      final ySign = QuickCrypto.nextU32() % 2;
      final x3 = x.square() * x;
      var y = (x3 + PastaCurveParams.pallasNative.b).sqrt().sqrtOrNull();
      if (y == null) continue;
      if (y == PallasNativeFp.fromBytes(y.toBytes())) {
        final sign = y.isOdd() ? 1 : 0;
        if ((ySign ^ sign) != 0) {
          y = -y;
        }
        return PallasAffineNativePoint(x: x, y: y).toCurve();
      }
    }
  }

  factory PallasNativePoint.fromBytes(List<int> bytes) {
    return PallasAffineNativePoint.fromBytes(bytes).toCurve();
  }

  factory PallasNativePoint.hashToCurve({
    required String domainPrefix,
    required List<int> message,
  }) {
    final hashToField = PastaUtils.hashToFiled(
      curveId: PastaCurveParams.pallas.name.curveId,
      domainPrefix: domainPrefix,
      message: message,
    );
    final PallasNativeFp a = PallasNativeFp.fromBytes64(hashToField.$1);
    final PallasNativeFp b = PallasNativeFp.fromBytes64(hashToField.$2);
    final q0 = PastaUtils.mapToCurveSimpleSwu(
      u: a,
      theta: PallasNativeFp.theta(),
      z: PallasNativeFp.z(),
      isogenyParams: PastaCurveParams.isoPallasNative,
      r: PallasNativeFp.r(),
    );
    final q0Point = PallasIsoNativePoint(x: q0.$1, y: q0.$2, z: q0.$3);
    final q1 = PastaUtils.mapToCurveSimpleSwu(
      u: b,
      theta: PallasNativeFp.theta(),
      z: PallasNativeFp.z(),
      isogenyParams: PastaCurveParams.isoPallasNative,
      r: PallasNativeFp.r(),
    );

    final q1Point = PallasIsoNativePoint(x: q1.$1, y: q1.$2, z: q1.$3);
    final r = q0Point + q1Point;
    assert(r.isOnCurve());
    final point = PastaUtils.isoMap(
      p: (r.x, r.y, r.z),
      iso: PallasFPConst.isogenyConstantsNative,
    );
    return PallasNativePoint(x: point.$1, y: point.$2, z: point.$3);
  }

  static final _identity = PallasNativePoint(
    x: PallasNativeFp.zero(),
    y: PallasNativeFp.zero(),
    z: PallasNativeFp.zero(),
  );
  factory PallasNativePoint.identity() {
    return _identity;
  }
  factory PallasNativePoint.generator() {
    final negOne = -PallasNativeFp.one();
    final two = PallasNativeFp.two();
    return PallasNativePoint(x: negOne, y: two, z: PallasNativeFp.one());
  }

  @override
  PallasNativePoint from({
    required PallasNativeFp x,
    required PallasNativeFp y,
    required PallasNativeFp z,
  }) {
    return PallasNativePoint(x: x, y: y, z: z);
  }

  @override
  PallasNativePoint identity() {
    return PallasNativePoint.identity();
  }

  @override
  PallasNativePoint generator() {
    return PallasNativePoint.generator();
  }

  @override
  PastaCurveParams<PallasNativeFp> get curveParams =>
      PastaCurveParams.pallasNative;

  @override
  PallasAffineNativePoint toAffine() {
    final zInv = z.invert();
    if (zInv == null) {
      return PallasAffineNativePoint.identity();
    }
    final zInv2 = zInv.square();
    final x = this.x * zInv2;
    final zInv3 = zInv2 * zInv;
    final y = this.y * zInv3;
    return PallasAffineNativePoint(x: x, y: y);
  }

  @override
  PallasNativePoint endo() {
    return PallasNativePoint(x: x * PallasNativeFp.zeta(), y: y, z: z);
  }

  @override
  PallasNativePoint clearCofactor() {
    return this;
  }
}

class PallasAffineNativePoint
    extends PastaAffinePoint<VestaNativeFq, PallasNativeFp, PallasNativePoint> {
  PallasAffineNativePoint({required super.x, required super.y});
  static final _identity = PallasAffineNativePoint(
    x: PallasNativeFp.zero(),
    y: PallasNativeFp.zero(),
  );
  factory PallasAffineNativePoint.identity() {
    return _identity;
  }

  factory PallasAffineNativePoint.fromBytes(List<int> bytes) {
    if (bytes.length != 32) {
      throw ArgumentException.invalidOperationArguments(
        "PallasAffineNativePoint",
        name: "bytes",
        reason: "Invalid point bytes length.",
      );
    }

    final tmp = bytes.clone();

    final ySign = (tmp[31] >> 7) & 1;

    tmp[31] &= 0x7F;

    final x = PallasNativeFp.fromBytes(tmp);
    if (x.isZero() && ySign == 0) {
      return PallasAffineNativePoint.identity();
    }
    final x3 = x.square() * x;
    final rhs = (x3 + PastaCurveParams.pallasNative.b);
    final y = rhs.sqrt();
    if (!y.isSquare) {
      throw ArgumentException.invalidOperationArguments(
        "PallasAffineNativePoint",
        name: "bytes",
        reason: "Invalid point bytes.",
      );
    }

    final sign = y.result.isOdd() ? 1 : 0;
    final flip = (ySign ^ sign) == 1;
    final yFinal = flip ? -y.result : y.result;
    return PallasAffineNativePoint(x: x, y: yFinal);
  }

  // factory PallasAffineNativePoint.conditionalSelect(
  //   PallasAffineNativePoint a,
  //   PallasAffineNativePoint b,
  //   bool choice,
  // ) {
  //   return PallasAffineNativePoint(
  //     x: PallasNativeFp.conditionalSelect(a.x, b.x, choice),
  //     y: PallasNativeFp.conditionalSelect(a.y, b.y, choice),
  //   );
  // }
  @override
  PallasAffineNativePoint affineFrom({
    required PallasNativeFp x,
    required PallasNativeFp y,
  }) {
    return PallasAffineNativePoint(x: x, y: y);
  }

  @override
  PallasNativePoint conditionalSelectFrom({
    required PallasNativePoint a,
    required PallasNativePoint b,
    required bool choice,
  }) {
    return choice ? b : a;
  }

  @override
  PallasNativePoint from({
    required PallasNativeFp x,
    required PallasNativeFp y,
    required PallasNativeFp z,
  }) {
    return PallasNativePoint(x: x, y: y, z: z);
  }

  @override
  PallasNativePoint identity() {
    return PallasNativePoint.identity();
  }

  @override
  PallasNativePoint toCurve() {
    return PallasNativePoint(
      x: x,
      y: y,
      z: isIdentity() ? PallasNativeFp.zero() : PallasNativeFp.one(),
    );
  }

  @override
  PallasAffineNativePoint generator() {
    final negOne = -PallasNativeFp.one();
    final two = PallasNativeFp.two();
    return PallasAffineNativePoint(x: negOne, y: two);
  }

  @override
  PastaCurveParams<PallasNativeFp> get curveParams =>
      PastaCurveParams.pallasNative;
}
