import 'package:blockchain_utils/crypto/crypto/zcrypto/pasta/constants/pallas.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/pasta/fields/pallas_fp.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/pasta/fields/vesta_fq.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/pasta/point/core.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/pasta/point/iso_pallas.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/pasta/utils/utils.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/numbers/src/u64/u64.dart';

class PallasPoint extends PastaPoint<VestaFq, PallasFp, PallasPoint> {
  const PallasPoint({required super.x, required super.y, required super.z});

  factory PallasPoint.fromAffine(PallasAffinePoint point) {
    return point.toCurve();
  }
  factory PallasPoint.random() {
    while (true) {
      final x = PallasFp.random();
      final ySign = QuickCrypto.nextU32() % 2;
      final x3 = x.square() * x;
      PallasFp? y = (x3 + PastaCurveParams.pallas.b).sqrt().sqrtOrNull();
      if (y == null) continue;
      if (y == PallasFp.fromBytes(y.toBytes())) {
        final sign = y.isOdd() ? 1 : 0;
        if ((ySign ^ sign) != 0) {
          y = -y;
        }
        return PallasAffinePoint(x: x, y: y).toCurve();
      }
    }
  }

  factory PallasPoint.fromBytes(List<int> bytes) {
    return PallasAffinePoint.fromBytes(bytes).toCurve();
  }
  factory PallasPoint.hashToCurve({
    required String domainPrefix,
    required List<int> message,
  }) {
    final hashToField = PastaUtils.hashToFiled(
      curveId: PastaCurveParams.pallas.name.curveId,
      domainPrefix: domainPrefix,
      message: message,
    );
    final PallasFp a = PallasFp.fromBytes64(hashToField.$1);
    final PallasFp b = PallasFp.fromBytes64(hashToField.$2);
    final q0 = PastaUtils.mapToCurveSimpleSwu(
      u: a,
      theta: PallasFp.theta,
      z: PallasFp.z,
      isogenyParams: PastaCurveParams.isoPallas,
      r: PallasFp.r,
    );
    final q0Point = PallasIsoPoint(x: q0.$1, y: q0.$2, z: q0.$3);

    final q1 = PastaUtils.mapToCurveSimpleSwu(
      u: b,
      theta: PallasFp.theta,
      z: PallasFp.z,
      isogenyParams: PastaCurveParams.isoPallas,
      r: PallasFp.r,
    );
    final q1Point = PallasIsoPoint(x: q1.$1, y: q1.$2, z: q1.$3);
    final r = q0Point + q1Point;
    assert(r.isOnCurve());
    final point = PastaUtils.isoMap(
      p: (r.x, r.y, r.z),
      iso: PallasFPConst.isogenyConstants,
    );
    return PallasPoint(x: point.$1, y: point.$2, z: point.$3);
  }
  static const identity_ = PallasPoint(
    x: PallasFp.zero,
    y: PallasFp.zero,
    z: PallasFp.zero,
  );
  static const generator_ = PallasPoint(
    x: PallasFp.unsafe([
      Uint64.unsafe(1689568180, 4),
      Uint64.unsafe(2300208112, 624157806),
      Uint64.zero,
      Uint64.zero,
    ]),
    y: PallasFp.unsafe([
      Uint64.unsafe(3485706628, 4294967289),
      Uint64.unsafe(269603099, 3202691134),
      Uint64.unsafe(4294967295, 4294967295),
      Uint64.unsafe(1073741823, 4294967295),
    ]),
    z: PallasFp.unsafe([
      Uint64.unsafe(880307512, 4294967293),
      Uint64.unsafe(2569811211, 3826848941),
      Uint64.unsafe(4294967295, 4294967295),
      Uint64.unsafe(1073741823, 4294967295),
    ]),
  );

  @override
  PallasPoint from({required PallasFp x, required PallasFp y, required PallasFp z}) {
    return PallasPoint(x: x, y: y, z: z);
  }

  @override
  PallasPoint identity() {
    return PallasPoint.identity_;
  }

  @override
  PallasPoint generator() {
    return PallasPoint.generator_;
  }

  @override
  final PastaCurveParams<PallasFp> curveParams = PastaCurveParams.pallas;

  @override
  PallasAffinePoint toAffine() {
    final zInv = z.invert();
    if (zInv == null) {
      return PallasAffinePoint.identity_;
    }
    final zInv2 = zInv.square();
    final x = this.x * zInv2;
    final zInv3 = zInv2 * zInv;
    final y = this.y * zInv3;
    return PallasAffinePoint(x: x, y: y);
  }

  @override
  PallasPoint endo() {
    return PallasPoint(x: x * PallasFp.zeta, y: y, z: z);
  }

  @override
  PallasPoint clearCofactor() {
    return this;
  }
}

class PallasAffinePoint extends PastaAffinePoint<VestaFq, PallasFp, PallasPoint> {
  const PallasAffinePoint({required super.x, required super.y});
  static const identity_ = PallasAffinePoint(x: PallasFp.zero, y: PallasFp.zero);

  static const generator_ = PallasAffinePoint(
    x: PallasFp.unsafe([
      Uint64.unsafe(1689568180, 4),
      Uint64.unsafe(2300208112, 624157806),
      Uint64.zero,
      Uint64.zero,
    ]),
    y: PallasFp.unsafe([
      Uint64.unsafe(3485706628, 4294967289),
      Uint64.unsafe(269603099, 3202691134),
      Uint64.unsafe(4294967295, 4294967295),
      Uint64.unsafe(1073741823, 4294967295),
    ]),
  );
  factory PallasAffinePoint.identity() {
    return identity_;
  }
  factory PallasAffinePoint.fromBytes(List<int> bytes) {
    if (bytes.length != 32) {
      throw ArgumentException.invalidOperationArguments(
        "PallasAffinePoint",
        name: "bytes",
        reason: "Invalid point bytes length.",
      );
    }

    final tmp = bytes.clone();

    final ySign = (tmp[31] >> 7) & 1;

    tmp[31] &= 0x7F;

    final x = PallasFp.fromBytes(tmp);
    if (x.isZero() && ySign == 0) {
      return PallasAffinePoint.identity_;
    }
    final x3 = x.square() * x;
    final rhs = (x3 + PastaCurveParams.pallas.b);
    final y = rhs.sqrt().sqrtOrNull();
    if (y == null) {
      throw ArgumentException.invalidOperationArguments(
        "PallasAffinePoint",
        name: "bytes",
        reason: "Invalid point bytes.",
      );
    }

    final sign = y.isOdd() ? 1 : 0;
    final flip = (ySign ^ sign) == 1;
    final yFinal = flip ? -y : y;
    return PallasAffinePoint(x: x, y: yFinal);
  }

  factory PallasAffinePoint.conditionalSelect(
    PallasAffinePoint a,
    PallasAffinePoint b,
    bool choice,
  ) {
    return PallasAffinePoint(
      x: PallasFp.conditionalSelect(a.x, b.x, choice),
      y: PallasFp.conditionalSelect(a.y, b.y, choice),
    );
  }
  @override
  PallasAffinePoint affineFrom({required PallasFp x, required PallasFp y}) {
    return PallasAffinePoint(x: x, y: y);
  }

  @override
  PallasPoint conditionalSelectFrom({
    required PallasPoint a,
    required PallasPoint b,
    required bool choice,
  }) {
    return PallasPoint(
      x: PallasFp.conditionalSelect(a.x, b.x, choice),
      y: PallasFp.conditionalSelect(a.y, b.y, choice),
      z: PallasFp.conditionalSelect(a.z, b.z, choice),
    );
  }

  @override
  PallasPoint from({required PallasFp x, required PallasFp y, required PallasFp z}) {
    return PallasPoint(x: x, y: y, z: z);
  }

  @override
  PallasPoint identity() {
    return PallasPoint.identity_;
  }

  @override
  PallasPoint toCurve() {
    return PallasPoint(
      x: x,
      y: y,
      z: PallasFp.conditionalSelect(PallasFp.one, PallasFp.zero, isIdentity()),
    );
  }

  @override
  PallasAffinePoint generator() {
    return generator_;
  }

  @override
  final PastaCurveParams<PallasFp> curveParams = PastaCurveParams.pallas;
}
