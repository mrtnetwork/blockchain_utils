import 'package:blockchain_utils/crypto/crypto/zcrypto/pasta/fields/native/fq.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/pasta/fields/native/fp.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/pasta/point/core.dart';
import 'package:blockchain_utils/crypto/crypto/exception/exception.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';

class VestaIsoNativePoint
    extends PastaPoint<PallasNativeFp, VestaNativeFq, VestaIsoNativePoint> {
  VestaIsoNativePoint({required super.x, required super.y, required super.z});
  factory VestaIsoNativePoint.fromAffine(VestaIsoAffineNativePoint point) {
    return point.toCurve();
  }

  factory VestaIsoNativePoint.fromBytes(List<int> bytes) {
    return VestaIsoAffineNativePoint.fromBytes(bytes).toCurve();
  }
  static final _identity = VestaIsoNativePoint(
    x: VestaNativeFq.zero(),
    y: VestaNativeFq.zero(),
    z: VestaNativeFq.zero(),
  );
  factory VestaIsoNativePoint.identity() {
    return _identity;
  }
  @override
  VestaIsoNativePoint from({
    required VestaNativeFq x,
    required VestaNativeFq y,
    required VestaNativeFq z,
  }) {
    return VestaIsoNativePoint(x: x, y: y, z: z);
  }

  @override
  VestaIsoNativePoint identity() {
    return identity();
  }

  @override
  VestaIsoNativePoint generator() {
    throw CryptoException.operationNotSupported;
  }

  @override
  PastaCurveParams<VestaNativeFq> get curveParams =>
      PastaCurveParams.isoVestaNative;

  @override
  VestaIsoAffineNativePoint toAffine() {
    final zInv = z.invert();
    if (zInv == null) {
      return VestaIsoAffineNativePoint.identity();
    }
    final zInv2 = zInv.square();
    final x = this.x * zInv2;
    final zInv3 = zInv2 * zInv;
    final y = this.y * zInv3;
    return VestaIsoAffineNativePoint(x: x, y: y);
  }

  @override
  VestaIsoNativePoint endo() {
    throw CryptoException.operationNotSupported;
  }

  @override
  VestaIsoNativePoint clearCofactor() {
    return this;
  }
}

class VestaIsoAffineNativePoint
    extends
        PastaAffinePoint<PallasNativeFp, VestaNativeFq, VestaIsoNativePoint> {
  VestaIsoAffineNativePoint({required super.x, required super.y});
  static final _identity = VestaIsoAffineNativePoint(
    x: VestaNativeFq.zero(),
    y: VestaNativeFq.zero(),
  );
  factory VestaIsoAffineNativePoint.identity() {
    return _identity;
  }

  factory VestaIsoAffineNativePoint.fromBytes(List<int> bytes) {
    if (bytes.length != 32) {
      throw ArgumentException.invalidOperationArguments(
        "VestaIsoAffineNativePoint",
        name: "bytes",
        reason: "Invalid point bytes length.",
      );
    }
    final tmp = bytes.clone();
    final ySign = (tmp[31] >> 7) & 1;
    tmp[31] &= 0x7F;
    final x = VestaNativeFq.fromBytes(tmp);
    if (x.isZero() && ySign == 0) {
      return VestaIsoAffineNativePoint.identity();
    }
    final x3 = x.square() * x;
    final rhs = (x3 + PastaCurveParams.isoVestaNative.b);
    final y = rhs.sqrt();
    if (!y.isSquare) {
      throw ArgumentException.invalidOperationArguments(
        "VestaIsoAffineNativePoint",
        name: "bytes",
        reason: "Invalid point bytes.",
      );
    }

    final sign = y.result.isOdd() ? 1 : 0;

    final flip = (ySign ^ sign) == 1;
    final yFinal = flip ? -y.result : y.result;
    return VestaIsoAffineNativePoint(x: x, y: yFinal);
  }

  @override
  PastaAffinePoint<PallasNativeFp, VestaNativeFq, VestaIsoNativePoint>
  affineFrom({required VestaNativeFq x, required VestaNativeFq y}) {
    return VestaIsoAffineNativePoint(x: x, y: y);
  }

  @override
  VestaIsoNativePoint conditionalSelectFrom({
    required VestaIsoNativePoint a,
    required VestaIsoNativePoint b,
    required bool choice,
  }) {
    return choice ? b : a;
  }

  @override
  VestaIsoNativePoint from({
    required VestaNativeFq x,
    required VestaNativeFq y,
    required VestaNativeFq z,
  }) {
    return VestaIsoNativePoint(x: x, y: y, z: z);
  }

  @override
  VestaIsoNativePoint identity() {
    return VestaIsoNativePoint.identity();
  }

  @override
  VestaIsoNativePoint toCurve() {
    return VestaIsoNativePoint(
      x: x,
      y: y,
      z: isIdentity() ? VestaNativeFq.zero() : VestaNativeFq.one(),
    );
  }

  @override
  VestaIsoAffineNativePoint generator() {
    throw CryptoException.operationNotSupported;
  }

  @override
  PastaCurveParams<VestaNativeFq> get curveParams =>
      PastaCurveParams.isoVestaNative;
}
