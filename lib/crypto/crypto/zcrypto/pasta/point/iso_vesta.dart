import 'package:blockchain_utils/crypto/crypto/zcrypto/pasta/fields/pallas_fp.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/pasta/fields/vesta_fq.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/pasta/point/core.dart';
import 'package:blockchain_utils/crypto/crypto/exception/exception.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';

class VestaIsoPoint extends PastaPoint<PallasFp, VestaFq, VestaIsoPoint> {
  VestaIsoPoint({required super.x, required super.y, required super.z});
  factory VestaIsoPoint.fromAffine(VestaIsoAffinePoint point) {
    return point.toCurve();
  }

  factory VestaIsoPoint.fromBytes(List<int> bytes) {
    return VestaIsoAffinePoint.fromBytes(bytes).toCurve();
  }
  factory VestaIsoPoint.identity() {
    return VestaIsoPoint(
      x: VestaFq.zero(),
      y: VestaFq.zero(),
      z: VestaFq.zero(),
    );
  }
  @override
  VestaIsoPoint from({
    required VestaFq x,
    required VestaFq y,
    required VestaFq z,
  }) {
    return VestaIsoPoint(x: x, y: y, z: z);
  }

  @override
  VestaIsoPoint identity() {
    return identity();
  }

  @override
  VestaIsoPoint generator() {
    throw CryptoException.operationNotSupported;
  }

  @override
  PastaCurveParams<VestaFq> get curveParams => PastaCurveParams.isoVesta;

  @override
  VestaIsoAffinePoint toAffine() {
    final zInv = z.invert();
    if (zInv == null) {
      return VestaIsoAffinePoint.identity();
    }
    final zInv2 = zInv.square();
    final x = this.x * zInv2;
    final zInv3 = zInv2 * zInv;
    final y = this.y * zInv3;
    return VestaIsoAffinePoint(x: x, y: y);
  }

  @override
  VestaIsoPoint endo() {
    throw CryptoException.operationNotSupported;
  }

  @override
  VestaIsoPoint clearCofactor() {
    return this;
  }
}

class VestaIsoAffinePoint
    extends PastaAffinePoint<PallasFp, VestaFq, VestaIsoPoint> {
  VestaIsoAffinePoint({required super.x, required super.y});
  factory VestaIsoAffinePoint.identity() {
    return VestaIsoAffinePoint(x: VestaFq.zero(), y: VestaFq.zero());
  }
  factory VestaIsoAffinePoint.conditionalSelect(
    VestaIsoAffinePoint a,
    VestaIsoAffinePoint b,
    bool choice,
  ) {
    return VestaIsoAffinePoint(
      x: VestaFq.conditionalSelect(a.x, b.x, choice),
      y: VestaFq.conditionalSelect(a.y, b.y, choice),
    );
  }
  factory VestaIsoAffinePoint.fromBytes(List<int> bytes) {
    if (bytes.length != 32) {
      throw ArgumentException.invalidOperationArguments(
        "VestaIsoAffinePoint",
        name: "bytes",
        reason: "Invalid point bytes length.",
      );
    }
    final tmp = bytes.clone();
    final ySign = (tmp[31] >> 7) & 1;
    tmp[31] &= 0x7F;
    final x = VestaFq.fromBytes(tmp);
    if (x.isZero() && ySign == 0) {
      return VestaIsoAffinePoint.identity();
    }
    final x3 = x.square() * x;
    final rhs = (x3 + PastaCurveParams.isoVesta.b);
    final y = rhs.sqrt();
    if (!y.isSquare) {
      throw ArgumentException.invalidOperationArguments(
        "VestaIsoAffinePoint",
        name: "bytes",
        reason: "Invalid point bytes.",
      );
    }

    final sign = y.result.isOdd() ? 1 : 0;

    final flip = (ySign ^ sign) == 1;
    final yFinal = flip ? -y.result : y.result;
    return VestaIsoAffinePoint(x: x, y: yFinal);
  }

  @override
  PastaAffinePoint<PallasFp, VestaFq, VestaIsoPoint> affineFrom({
    required VestaFq x,
    required VestaFq y,
  }) {
    return VestaIsoAffinePoint(x: x, y: y);
  }

  @override
  VestaIsoPoint conditionalSelectFrom({
    required VestaIsoPoint a,
    required VestaIsoPoint b,
    required bool choice,
  }) {
    return VestaIsoPoint(
      x: VestaFq.conditionalSelect(a.x, b.x, choice),
      y: VestaFq.conditionalSelect(a.y, b.y, choice),
      z: VestaFq.conditionalSelect(a.z, b.z, choice),
    );
  }

  @override
  VestaIsoPoint from({
    required VestaFq x,
    required VestaFq y,
    required VestaFq z,
  }) {
    return VestaIsoPoint(x: x, y: y, z: z);
  }

  @override
  VestaIsoPoint identity() {
    return VestaIsoPoint.identity();
  }

  @override
  VestaIsoPoint toCurve() {
    return VestaIsoPoint(
      x: x,
      y: y,
      z: VestaFq.conditionalSelect(VestaFq.one(), VestaFq.zero(), isIdentity()),
    );
  }

  @override
  VestaIsoAffinePoint generator() {
    throw CryptoException.operationNotSupported;
  }

  @override
  PastaCurveParams<VestaFq> get curveParams => PastaCurveParams.isoVesta;
}
