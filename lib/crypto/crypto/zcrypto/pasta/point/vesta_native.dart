import 'package:blockchain_utils/crypto/crypto/zcrypto/pasta/constants/vesta.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/pasta/fields/native/fq.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/pasta/fields/native/fp.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/pasta/point/core.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/pasta/point/iso_vesta_native.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/pasta/utils/utils.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/exception/exception/exception.dart';
import 'package:blockchain_utils/helper/helper.dart';

class VestaNativePoint
    extends PastaPoint<PallasNativeFp, VestaNativeFq, VestaNativePoint> {
  VestaNativePoint({required super.x, required super.y, required super.z});
  factory VestaNativePoint.random() {
    while (true) {
      final x = VestaNativeFq.random();
      final ySign = QuickCrypto.nextU32() % 2;
      final x3 = x.square() * x;
      VestaNativeFq? y =
          (x3 + PastaCurveParams.vestaNative.b).sqrt().sqrtOrNull();
      if (y == null) continue;
      if (y == VestaNativeFq.fromBytes(y.toBytes())) {
        final sign = y.isOdd() ? 1 : 0;
        if ((ySign ^ sign) != 0) {
          y = -y;
        }
        return VestaAffineNativePoint(x: x, y: y).toCurve();
      }
    }
  }
  factory VestaNativePoint.hashToCurve({
    required String domainPrefix,
    required List<int> message,
  }) {
    final hashToField = PastaUtils.hashToFiled(
      curveId: PastaCurveParams.vesta.name.curveId,
      domainPrefix: domainPrefix,
      message: message,
    );
    final VestaNativeFq a = VestaNativeFq.fromBytes64(hashToField.$1);
    final VestaNativeFq b = VestaNativeFq.fromBytes64(hashToField.$2);
    final q0 = PastaUtils.mapToCurveSimpleSwu(
      u: a,
      theta: VestaNativeFq.theta(),
      z: VestaNativeFq.z(),
      isogenyParams: PastaCurveParams.isoVestaNative,
      r: VestaNativeFq.one(),
    );
    final q0Point = VestaIsoNativePoint(x: q0.$1, y: q0.$2, z: q0.$3);

    final q1 = PastaUtils.mapToCurveSimpleSwu(
      u: b,
      theta: VestaNativeFq.theta(),
      z: VestaNativeFq.z(),
      isogenyParams: PastaCurveParams.isoVestaNative,
      r: VestaNativeFq.one(),
    );
    final q1Point = VestaIsoNativePoint(x: q1.$1, y: q1.$2, z: q1.$3);
    final r = q0Point + q1Point;
    final point = PastaUtils.isoMap(
      p: (r.x, r.y, r.z),
      iso: VestaFQConst.isogenyNativeConstants,
    );
    return VestaNativePoint(x: point.$1, y: point.$2, z: point.$3);
  }

  factory VestaNativePoint.fromAffine(VestaAffineNativePoint point) {
    return point.toCurve();
  }

  factory VestaNativePoint.fromBytes(List<int> bytes) {
    return VestaAffineNativePoint.fromBytes(bytes).toCurve();
  }
  static final VestaNativePoint _identity = VestaNativePoint(
    x: VestaNativeFq.zero(),
    y: VestaNativeFq.zero(),
    z: VestaNativeFq.zero(),
  );
  @override
  factory VestaNativePoint.identity() {
    return _identity;
  }
  @override
  factory VestaNativePoint.generator() {
    final negOne = -VestaNativeFq.one();
    final two = VestaNativeFq.two();
    return VestaNativePoint(x: negOne, y: two, z: VestaNativeFq.one());
  }
  @override
  VestaNativePoint from({
    required VestaNativeFq x,
    required VestaNativeFq y,
    required VestaNativeFq z,
  }) {
    return VestaNativePoint(x: x, y: y, z: z);
  }

  @override
  VestaNativePoint double() {
    if (isIdentity()) return identity();
    // Step 1: Squares
    final a = x.square(); // a = x^2
    final b = y.square(); // b = y^2
    final c = VestaNativeFq(b.v * b.v); // c = b^2

    // Step 2: d = 2*((x+b)^2 - a - c)
    final dRaw = ((x.v + b.v) * (x.v + b.v)) - a.v - c.v;
    final d = VestaNativeFq(dRaw * BigInt.from(2));

    // Step 3: e = 3*a
    final e = VestaNativeFq(a.v * BigInt.from(3));
    final f = e.square();

    // Step 4: z3 = 2*y*z
    final z3 = VestaNativeFq(y.v * z.v * BigInt.from(2));

    // Step 5: x3 = f - 2*d
    final x3 = VestaNativeFq(f.v - d.v * BigInt.from(2));

    // Step 6: c = 8*c
    final c8 = VestaNativeFq(c.v << 3);

    // Step 7: y3 = e*(d - x3) - 8*c
    final y3 = VestaNativeFq(e.v * (d.v - x3.v) - c8.v);

    return from(x: x3, y: y3, z: z3);
  }

  @override
  VestaNativePoint identity() {
    return VestaNativePoint.identity();
  }

  @override
  VestaNativePoint generator() {
    return VestaNativePoint.generator();
  }

  @override
  PastaCurveParams<VestaNativeFq> get curveParams =>
      PastaCurveParams.vestaNative;

  @override
  VestaAffineNativePoint toAffine() {
    final zInv = z.invert();
    if (zInv == null) {
      return VestaAffineNativePoint.identity();
    }
    final zInv2 = zInv.square();
    final x = this.x * zInv2;
    final zInv3 = zInv2 * zInv;
    final y = this.y * zInv3;
    return VestaAffineNativePoint(x: x, y: y);
  }

  @override
  VestaNativePoint endo() {
    return VestaNativePoint(x: x * VestaNativeFq.zeta(), y: y, z: z);
  }

  @override
  VestaNativePoint clearCofactor() {
    return this;
  }
}

class VestaAffineNativePoint
    extends PastaAffinePoint<PallasNativeFp, VestaNativeFq, VestaNativePoint> {
  VestaAffineNativePoint({required super.x, required super.y});
  static final _identity = VestaAffineNativePoint(
    x: VestaNativeFq.zero(),
    y: VestaNativeFq.zero(),
  );
  factory VestaAffineNativePoint.identity() {
    return _identity;
  }
  factory VestaAffineNativePoint.fromBytes(List<int> bytes) {
    if (bytes.length != 32) {
      throw ArgumentException.invalidOperationArguments(
        "VestaAffineNativePoint",
        name: "bytes",
        reason: "Invalid point bytes length.",
        expecteLen: 32,
      );
    }

    final tmp = bytes.clone();

    final ySign = (tmp[31] >> 7) & 1;

    tmp[31] &= 0x7F;

    final x = VestaNativeFq.fromBytes(tmp);
    if (x.isZero() && ySign == 0) {
      return VestaAffineNativePoint.identity();
    }
    final x3 = x.square() * x;
    final rhs = (x3 + PastaCurveParams.vestaNative.b);
    final y = rhs.sqrt().sqrtOrNull();
    if (y == null) {
      throw ArgumentException.invalidOperationArguments(
        "VestaAffineNativePoint",
        name: "bytes",
        reason: "Invalid point bytes.",
      );
    }

    final sign = y.isOdd() ? 1 : 0;

    final flip = (ySign ^ sign) == 1;
    final yFinal = flip ? -y : y;
    return VestaAffineNativePoint(x: x, y: yFinal);
  }

  @override
  VestaAffineNativePoint affineFrom({
    required VestaNativeFq x,
    required VestaNativeFq y,
  }) {
    return VestaAffineNativePoint(x: x, y: y);
  }

  @override
  VestaNativePoint conditionalSelectFrom({
    required VestaNativePoint a,
    required VestaNativePoint b,
    required bool choice,
  }) {
    return choice ? b : a;
  }

  @override
  VestaNativePoint from({
    required VestaNativeFq x,
    required VestaNativeFq y,
    required VestaNativeFq z,
  }) {
    return VestaNativePoint(x: x, y: y, z: z);
  }

  @override
  VestaNativePoint identity() {
    return VestaNativePoint.identity();
  }

  @override
  VestaNativePoint toCurve() {
    return VestaNativePoint(
      x: x,
      y: y,
      z: isIdentity() ? VestaNativeFq.zero() : VestaNativeFq.one(),
    );
  }

  @override
  VestaAffineNativePoint generator() {
    final negOne = -VestaNativeFq.one();
    final two = VestaNativeFq.two();
    return VestaAffineNativePoint(x: negOne, y: two);
  }

  @override
  PastaCurveParams<VestaNativeFq> get curveParams =>
      PastaCurveParams.vestaNative;
}
