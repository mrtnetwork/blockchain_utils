import 'package:blockchain_utils/crypto/crypto/group/pasta/constants/vesta.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/crypto/crypto/group/pasta/fields/pallas_fp.dart';
import 'package:blockchain_utils/crypto/crypto/group/pasta/fields/vesta_fq.dart';
import 'package:blockchain_utils/crypto/crypto/group/pasta/point/core.dart';
import 'package:blockchain_utils/crypto/crypto/group/pasta/point/iso_vesta.dart';
import 'package:blockchain_utils/crypto/crypto/group/pasta/utils/utils.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/helper/helper.dart';
import 'package:blockchain_utils/utils/numbers/fixed/src/u64/u64.dart';

/// A Vesta point in projective (Montgomery-limb) coordinates.
class VestaPoint extends PastaPoint<PallasFp, VestaFq, VestaPoint> {
  const VestaPoint({required super.x, required super.y, required super.z});
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
    final hashToField = PastaUtils.hashToField(
      curveId: PastaCurveParams.vesta.name.curveId,
      domainPrefix: domainPrefix,
      message: message,
    );
    final VestaFq a = VestaFq.fromBytes64(hashToField.$1);
    final VestaFq b = VestaFq.fromBytes64(hashToField.$2);
    final q0 = PastaUtils.mapToCurveSimpleSwu(
      u: a,
      theta: VestaFq.theta,
      z: VestaFq.z,
      isogenyParams: PastaCurveParams.isoVesta,
      r: VestaFq.r,
    );
    final q0Point = VestaIsoPoint(x: q0.$1, y: q0.$2, z: q0.$3);

    final q1 = PastaUtils.mapToCurveSimpleSwu(
      u: b,
      theta: VestaFq.theta,
      z: VestaFq.z,
      isogenyParams: PastaCurveParams.isoVesta,
      r: VestaFq.r,
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
  static const identity_ = VestaPoint(
    x: VestaFq.zero,
    y: VestaFq.zero,
    z: VestaFq.zero,
  );
  static const generator_ = VestaPoint(
    x: VestaFq.unsafe([
      Uint64.unsafe(823897220, 4),
      Uint64.unsafe(2300208112, 642950006),
      Uint64.zero,
      Uint64.zero,
    ]),
    y: VestaFq.unsafe([
      Uint64.unsafe(705663512, 4294967289),
      Uint64.unsafe(269603099, 3169804785),
      Uint64.unsafe(4294967295, 4294967295),
      Uint64.unsafe(1073741823, 4294967295),
    ]),
    z: VestaFq.one,
  );
  factory VestaPoint.identity() {
    return VestaPoint(x: VestaFq.zero, y: VestaFq.zero, z: VestaFq.zero);
  }
  factory VestaPoint.generator() {
    return generator_;
  }
  @override
  VestaPoint from({
    required VestaFq x,
    required VestaFq y,
    required VestaFq z,
  }) {
    return VestaPoint(x: x, y: y, z: z);
  }

  /// Mask form of point select: returns [b] iff [bit] == 1, else [a].
  /// [bit] is a 0/1 [Uint64] (never a `bool`).
  static VestaPoint conditionalSelectMask(
    VestaPoint a,
    VestaPoint b,
    Uint64 bit,
  ) => VestaPoint(
    x: VestaFq.conditionalSelectMask(a.x, b.x, bit),
    y: VestaFq.conditionalSelectMask(a.y, b.y, bit),
    z: VestaFq.conditionalSelectMask(a.z, b.z, bit),
  );

  @override
  VestaPoint selectMask(VestaPoint other, Uint64 bit) =>
      VestaPoint.conditionalSelectMask(this, other, bit);

  @override
  VestaPoint identity() {
    return identity_;
  }

  @override
  VestaPoint generator() {
    return VestaPoint.generator_;
  }

  @override
  final PastaCurveParams<VestaFq> curveParams = PastaCurveParams.vesta;

  @override
  VestaAffinePoint toAffine() {
    final zInv = z.invert();
    if (zInv == null) {
      return VestaAffinePoint.identity_;
    }
    final zInv2 = zInv.square();
    final x = this.x * zInv2;
    final zInv3 = zInv2 * zInv;
    final y = this.y * zInv3;
    return VestaAffinePoint(x: x, y: y);
  }

  @override
  VestaPoint endo() {
    return VestaPoint(x: x * VestaFq.zeta, y: y, z: z);
  }

  @override
  VestaPoint clearCofactor() {
    return this;
  }
}

/// A Vesta point in affine (Montgomery-limb) coordinates.
class VestaAffinePoint extends PastaAffinePoint<PallasFp, VestaFq, VestaPoint> {
  const VestaAffinePoint({required super.x, required super.y});
  static const identity_ = VestaAffinePoint(x: VestaFq.zero, y: VestaFq.zero);
  static const generator_ = VestaAffinePoint(
    x: VestaFq.unsafe([
      Uint64.unsafe(823897220, 4),
      Uint64.unsafe(2300208112, 642950006),
      Uint64.zero,
      Uint64.zero,
    ]),
    y: VestaFq.unsafe([
      Uint64.unsafe(705663512, 4294967289),
      Uint64.unsafe(269603099, 3169804785),
      Uint64.unsafe(4294967295, 4294967295),
      Uint64.unsafe(1073741823, 4294967295),
    ]),
  );
  factory VestaAffinePoint.identity() {
    return identity_;
  }
  factory VestaAffinePoint.fromBytes(List<int> bytes) {
    if (bytes.length != 32) {
      throw CoreErrors.invalidOperationArguments(
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
      return VestaAffinePoint.identity_;
    }
    final x3 = x.square() * x;
    final rhs = (x3 + PastaCurveParams.vesta.b);
    final y = rhs.sqrt().sqrtOrNull();
    if (y == null) {
      throw CoreErrors.invalidOperationArguments(
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
    return VestaPoint.identity_;
  }

  @override
  VestaPoint toCurve() {
    return VestaPoint(
      x: x,
      y: y,
      z: VestaFq.conditionalSelect(VestaFq.one, VestaFq.zero, isIdentity()),
    );
  }

  @override
  VestaAffinePoint generator() {
    return generator_;
  }

  @override
  PastaCurveParams<VestaFq> get curveParams => PastaCurveParams.vesta;
}
