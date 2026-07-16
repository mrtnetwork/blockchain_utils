import 'package:blockchain_utils/crypto/crypto/zcrypto/pasta/fields/native/fq.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/pasta/fields/native/fp.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/pasta/point/core.dart';
import 'package:blockchain_utils/crypto/crypto/exception/exception.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';

class PallasIsoNativePoint
    extends PastaPoint<VestaNativeFq, PallasNativeFp, PallasIsoNativePoint> {
  PallasIsoNativePoint({required super.x, required super.y, required super.z});
  static final identity_ = PallasIsoNativePoint(
    x: PallasNativeFp.zero(),
    y: PallasNativeFp.zero(),
    z: PallasNativeFp.zero(),
  );
  factory PallasIsoNativePoint.identity() {
    return identity_;
  }
  factory PallasIsoNativePoint.fromAffine(PallasIsoAffineNativePoint point) {
    return point.toCurve();
  }

  factory PallasIsoNativePoint.fromBytes(List<int> bytes) {
    return PallasIsoAffineNativePoint.fromBytes(bytes).toCurve();
  }
  @override
  PallasIsoNativePoint from({
    required PallasNativeFp x,
    required PallasNativeFp y,
    required PallasNativeFp z,
  }) {
    return PallasIsoNativePoint(x: x, y: y, z: z);
  }

  @override
  PallasIsoNativePoint identity() {
    return identity_;
  }

  @override
  PallasIsoNativePoint generator() {
    throw CryptoException.operationNotSupported;
  }

  @override
  PastaCurveParams<PallasNativeFp> get curveParams =>
      PastaCurveParams.isoPallasNative;

  @override
  PallasIsoAffineNativePoint toAffine() {
    final zInv = z.invert();
    if (zInv == null) {
      return PallasIsoAffineNativePoint.identity_;
    }
    final zInv2 = zInv.square();
    final x = this.x * zInv2;
    final zInv3 = zInv2 * zInv;
    final y = this.y * zInv3;
    return PallasIsoAffineNativePoint(x: x, y: y);
  }

  @override
  PallasIsoNativePoint endo() {
    throw CryptoException.operationNotSupported;
  }

  @override
  PallasIsoNativePoint clearCofactor() {
    return this;
  }
}

class PallasIsoAffineNativePoint
    extends
        PastaAffinePoint<VestaNativeFq, PallasNativeFp, PallasIsoNativePoint> {
  PallasIsoAffineNativePoint({required super.x, required super.y});
  static final identity_ = PallasIsoAffineNativePoint(
    x: PallasNativeFp.zero(),
    y: PallasNativeFp.zero(),
  );
  // factory PallasIsoAffineNativePoint.identity() {
  //   return _identity;
  // }
  factory PallasIsoAffineNativePoint.fromBytes(List<int> bytes) {
    if (bytes.length != 32) {
      throw ArgumentException.invalidOperationArguments(
        "PallasIsoAffineNativePoint",
        name: "bytes",
        reason: "Invalid point bytes length.",
      );
    }
    final tmp = bytes.clone();
    final ySign = (tmp[31] >> 7) & 1;
    tmp[31] &= 0x7F;
    final x = PallasNativeFp.fromBytes(tmp);
    if (x.isZero() && ySign == 0) {
      return identity_;
    }
    final x3 = x.square() * x;
    final rhs = (x3 + PastaCurveParams.isoPallasNative.b);
    final y = rhs.sqrt();
    if (!y.isSquare) {
      throw ArgumentException.invalidOperationArguments(
        "PallasIsoAffineNativePoint",
        name: "bytes",
        reason: "Invalid point bytes.",
      );
    }

    final sign = y.result.isOdd() ? 1 : 0;

    final flip = (ySign ^ sign) == 1;
    final yFinal = flip ? -y.result : y.result;
    return PallasIsoAffineNativePoint(x: x, y: yFinal);
  }

  factory PallasIsoAffineNativePoint.conditionalSelect(
    PallasIsoAffineNativePoint a,
    PallasIsoAffineNativePoint b,
    bool choice,
  ) {
    return choice ? b : a;
  }
  @override
  PallasIsoAffineNativePoint affineFrom({
    required PallasNativeFp x,
    required PallasNativeFp y,
  }) {
    return PallasIsoAffineNativePoint(x: x, y: y);
  }

  @override
  PallasIsoNativePoint conditionalSelectFrom({
    required PallasIsoNativePoint a,
    required PallasIsoNativePoint b,
    required bool choice,
  }) {
    return choice ? b : a;
  }

  @override
  PallasIsoNativePoint from({
    required PallasNativeFp x,
    required PallasNativeFp y,
    required PallasNativeFp z,
  }) {
    return PallasIsoNativePoint(x: x, y: y, z: z);
  }

  @override
  PallasIsoNativePoint identity() {
    return PallasIsoNativePoint.identity_;
  }

  @override
  PallasIsoNativePoint toCurve() {
    return PallasIsoNativePoint(
      x: x,
      y: y,
      z: isIdentity() ? PallasNativeFp.zero() : PallasNativeFp.one(),
    );
  }

  @override
  PallasIsoAffineNativePoint generator() {
    throw CryptoException.operationNotSupported;
  }

  @override
  PastaCurveParams<PallasNativeFp> get curveParams =>
      PastaCurveParams.isoPallasNative;
}
