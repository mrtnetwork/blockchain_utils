import 'package:blockchain_utils/crypto/crypto/zcrypto/pasta/fields/pallas_fp.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/pasta/fields/vesta_fq.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/pasta/point/core.dart';
import 'package:blockchain_utils/crypto/crypto/exception/exception.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';

class PallasIsoPoint extends PastaPoint<VestaFq, PallasFp, PallasIsoPoint> {
  const PallasIsoPoint({required super.x, required super.y, required super.z});
  static const identity_ = PallasIsoPoint(
    x: PallasFp.zero,
    y: PallasFp.zero,
    z: PallasFp.zero,
  );

  factory PallasIsoPoint.fromAffine(PallasIsoAffinePoint point) {
    return point.toCurve();
  }

  factory PallasIsoPoint.fromBytes(List<int> bytes) {
    return PallasIsoAffinePoint.fromBytes(bytes).toCurve();
  }
  @override
  PallasIsoPoint from({
    required PallasFp x,
    required PallasFp y,
    required PallasFp z,
  }) {
    return PallasIsoPoint(x: x, y: y, z: z);
  }

  @override
  PallasIsoPoint identity() {
    return identity_;
  }

  @override
  PallasIsoPoint generator() {
    throw CryptoException.operationNotSupported;
  }

  @override
  final PastaCurveParams<PallasFp> curveParams = PastaCurveParams.isoPallas;

  @override
  PallasIsoAffinePoint toAffine() {
    final zInv = z.invert();
    if (zInv == null) return PallasIsoAffinePoint.identity_;
    final zInv2 = zInv.square();
    final x = this.x * zInv2;
    final zInv3 = zInv2 * zInv;
    final y = this.y * zInv3;
    return PallasIsoAffinePoint(x: x, y: y);
  }

  @override
  PallasIsoPoint endo() {
    throw CryptoException.operationNotSupported;
  }

  @override
  PallasIsoPoint clearCofactor() {
    return this;
  }
}

class PallasIsoAffinePoint
    extends PastaAffinePoint<VestaFq, PallasFp, PallasIsoPoint> {
  const PallasIsoAffinePoint({required super.x, required super.y});
  static const PallasIsoAffinePoint identity_ = PallasIsoAffinePoint(
    x: PallasFp.zero,
    y: PallasFp.zero,
  );

  factory PallasIsoAffinePoint.fromBytes(List<int> bytes) {
    if (bytes.length != 32) {
      throw ArgumentException.invalidOperationArguments(
        "PallasIsoAffinePoint",
        name: "bytes",
        reason: "Invalid point bytes length.",
      );
    }
    final tmp = bytes.clone();
    final ySign = (tmp[31] >> 7) & 1;
    tmp[31] &= 0x7F;
    final x = PallasFp.fromBytes(tmp);
    if (x.isZero() && ySign == 0) {
      return identity_;
    }
    final x3 = x.square() * x;
    final rhs = (x3 + PastaCurveParams.isoPallas.b);
    final y = rhs.sqrt();
    if (!y.isSquare) {
      throw ArgumentException.invalidOperationArguments(
        "PallasIsoAffinePoint",
        name: "bytes",
        reason: "Invalid point bytes.",
      );
    }

    final sign = y.result.isOdd() ? 1 : 0;

    final flip = (ySign ^ sign) == 1;
    final yFinal = flip ? -y.result : y.result;
    return PallasIsoAffinePoint(x: x, y: yFinal);
  }

  factory PallasIsoAffinePoint.conditionalSelect(
    PallasIsoAffinePoint a,
    PallasIsoAffinePoint b,
    bool choice,
  ) {
    return PallasIsoAffinePoint(
      x: PallasFp.conditionalSelect(a.x, b.x, choice),
      y: PallasFp.conditionalSelect(a.y, b.y, choice),
    );
  }
  @override
  PallasIsoAffinePoint affineFrom({required PallasFp x, required PallasFp y}) {
    return PallasIsoAffinePoint(x: x, y: y);
  }

  @override
  PallasIsoPoint conditionalSelectFrom({
    required PallasIsoPoint a,
    required PallasIsoPoint b,
    required bool choice,
  }) {
    return PallasIsoPoint(
      x: PallasFp.conditionalSelect(a.x, b.x, choice),
      y: PallasFp.conditionalSelect(a.y, b.y, choice),
      z: PallasFp.conditionalSelect(a.z, b.z, choice),
    );
  }

  @override
  PallasIsoPoint from({
    required PallasFp x,
    required PallasFp y,
    required PallasFp z,
  }) {
    return PallasIsoPoint(x: x, y: y, z: z);
  }

  @override
  PallasIsoPoint identity() {
    return PallasIsoPoint.identity_;
  }

  @override
  PallasIsoPoint toCurve() {
    return PallasIsoPoint(
      x: x,
      y: y,
      z: PallasFp.conditionalSelect(PallasFp.one, PallasFp.zero, isIdentity()),
    );
  }

  @override
  PallasIsoAffinePoint generator() {
    throw CryptoException.operationNotSupported;
  }

  @override
  final PastaCurveParams<PallasFp> curveParams = PastaCurveParams.isoPallas;
}
