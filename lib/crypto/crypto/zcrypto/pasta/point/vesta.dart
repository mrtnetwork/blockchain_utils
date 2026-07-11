import 'package:blockchain_utils/crypto/crypto/zcrypto/pasta/constants/vesta.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/pasta/fields/pallas_fp.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/pasta/fields/vesta_fq.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/pasta/point/core.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/pasta/point/iso_vesta.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/pasta/utils/utils.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/helper/helper.dart';

class VestaPoint extends PastaPoint<PallasFp, VestaFq, VestaPoint> {
  VestaPoint({required super.x, required super.y, required super.z});
  factory VestaPoint.random() {
    while (true) {
      final x = VestaFq.random();
      final ySign = QuickCrypto.nextU32() % 2;
      final x3 = x.square() * x;
      VestaFq? y = (x3 + PastaCurveParams.vesta.b).sqrt().sqrtOrNull();
      if (y == null) continue;
      if (y == VestaFq.fromBytes(y.toBytes())) {
        final sign = y.isOdd() ? 1 : 0;
        if ((ySign ^ sign) != 0) {
          y = -y;
        }
        return VestaAffinePoint(x: x, y: y).toCurve();
      }
    }
  }

  factory VestaPoint.hashToCurve({
    required String domainPrefix,
    required List<int> message,
  }) {
    final hashToField = PastaUtils.hashToFiled(
      curveId: PastaCurveParams.vesta.name.curveId,
      domainPrefix: domainPrefix,
      message: message,
    );
    final VestaFq a = VestaFq.fromBytes64(hashToField.$1);
    final VestaFq b = VestaFq.fromBytes64(hashToField.$2);
    final q0 = PastaUtils.mapToCurveSimpleSwu(
      u: a,
      theta: VestaFq.theta(),
      z: VestaFq.z(),
      isogenyParams: PastaCurveParams.isoVesta,
      r: VestaFq.r(),
    );
    final q0Point = VestaIsoPoint(x: q0.$1, y: q0.$2, z: q0.$3);

    final q1 = PastaUtils.mapToCurveSimpleSwu(
      u: b,
      theta: VestaFq.theta(),
      z: VestaFq.z(),
      isogenyParams: PastaCurveParams.isoVesta,
      r: VestaFq.r(),
    );
    final q1Point = VestaIsoPoint(x: q1.$1, y: q1.$2, z: q1.$3);
    final r = q0Point + q1Point;
    final point = PastaUtils.isoMap(
      p: (r.x, r.y, r.z),
      iso: VestaFQConst.isogenyConstants,
    );
    return VestaPoint(x: point.$1, y: point.$2, z: point.$3);
  }

  factory VestaPoint.fromAffine(VestaAffinePoint point) {
    return point.toCurve();
  }

  factory VestaPoint.fromBytes(List<int> bytes) {
    return VestaAffinePoint.fromBytes(bytes).toCurve();
  }
  factory VestaPoint.identity() {
    return VestaPoint(x: VestaFq.zero(), y: VestaFq.zero(), z: VestaFq.zero());
  }
  factory VestaPoint.generator() {
    final negOne = -VestaFq.one();
    final two = VestaFq.fromRaw([
      BigInt.two,
      BigInt.zero,
      BigInt.zero,
      BigInt.zero,
    ]);
    return VestaPoint(x: negOne, y: two, z: VestaFq.one());
  }
  @override
  VestaPoint from({
    required VestaFq x,
    required VestaFq y,
    required VestaFq z,
  }) {
    return VestaPoint(x: x, y: y, z: z);
  }

  @override
  VestaPoint identity() {
    return VestaPoint.identity();
  }

  @override
  VestaPoint generator() {
    return VestaPoint.generator();
  }

  @override
  PastaCurveParams<VestaFq> get curveParams => PastaCurveParams.vesta;

  @override
  VestaAffinePoint toAffine() {
    final zInv = z.invert();
    if (zInv == null) {
      return VestaAffinePoint.identity();
    }
    final zInv2 = zInv.square();
    final x = this.x * zInv2;
    final zInv3 = zInv2 * zInv;
    final y = this.y * zInv3;
    return VestaAffinePoint(x: x, y: y);
  }

  @override
  VestaPoint endo() {
    return VestaPoint(x: x * VestaFq.zeta(), y: y, z: z);
  }

  @override
  VestaPoint clearCofactor() {
    return this;
  }
}

class VestaAffinePoint extends PastaAffinePoint<PallasFp, VestaFq, VestaPoint> {
  VestaAffinePoint({required super.x, required super.y});
  factory VestaAffinePoint.identity() {
    return VestaAffinePoint(x: VestaFq.zero(), y: VestaFq.zero());
  }
  factory VestaAffinePoint.fromBytes(List<int> bytes) {
    if (bytes.length != 32) {
      throw ArgumentException.invalidOperationArguments(
        "VestaAffinePoint",
        name: "bytes",
        reason: "Invalid point bytes length.",
      );
    }

    final tmp = bytes.clone();

    final ySign = (tmp[31] >> 7) & 1;

    tmp[31] &= 0x7F;

    final x = VestaFq.fromBytes(tmp);
    if (x.isZero() && ySign == 0) {
      return VestaAffinePoint.identity();
    }
    final x3 = x.square() * x;
    final rhs = (x3 + PastaCurveParams.vesta.b);
    final y = rhs.sqrt().sqrtOrNull();
    if (y == null) {
      throw ArgumentException.invalidOperationArguments(
        "VestaAffinePoint",
        name: "bytes",
        reason: "Invalid point bytes.",
      );
    }

    final sign = y.isOdd() ? 1 : 0;

    final flip = (ySign ^ sign) == 1;
    final yFinal = flip ? -y : y;
    return VestaAffinePoint(x: x, y: yFinal);
  }

  factory VestaAffinePoint.conditionalSelect(
    VestaAffinePoint a,
    VestaAffinePoint b,
    bool choice,
  ) {
    return VestaAffinePoint(
      x: VestaFq.conditionalSelect(a.x, b.x, choice),
      y: VestaFq.conditionalSelect(a.y, b.y, choice),
    );
  }
  @override
  VestaAffinePoint affineFrom({required VestaFq x, required VestaFq y}) {
    return VestaAffinePoint(x: x, y: y);
  }

  @override
  VestaPoint conditionalSelectFrom({
    required VestaPoint a,
    required VestaPoint b,
    required bool choice,
    required,
  }) {
    return VestaPoint(
      x: VestaFq.conditionalSelect(a.x, b.x, choice),
      y: VestaFq.conditionalSelect(a.y, b.y, choice),
      z: VestaFq.conditionalSelect(a.z, b.z, choice),
    );
  }

  @override
  VestaPoint from({
    required VestaFq x,
    required VestaFq y,
    required VestaFq z,
  }) {
    return VestaPoint(x: x, y: y, z: z);
  }

  @override
  VestaPoint identity() {
    return VestaPoint.identity();
  }

  @override
  VestaPoint toCurve() {
    return VestaPoint(
      x: x,
      y: y,
      z: VestaFq.conditionalSelect(VestaFq.one(), VestaFq.zero(), isIdentity()),
    );
  }

  @override
  VestaAffinePoint generator() {
    final negOne =
        -VestaFq.fromRaw([BigInt.one, BigInt.zero, BigInt.zero, BigInt.zero]);
    final two = VestaFq.fromRaw([
      BigInt.two,
      BigInt.zero,
      BigInt.zero,
      BigInt.zero,
    ]);
    return VestaAffinePoint(x: negOne, y: two);
  }

  @override
  PastaCurveParams<VestaFq> get curveParams => PastaCurveParams.vesta;
}
