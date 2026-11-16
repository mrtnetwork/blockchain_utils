import 'package:blockchain_utils/crypto/crypto/group/core/field.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/crypto/crypto/group/core/point.dart';
import 'package:blockchain_utils/crypto/crypto/group/edwards_limb/fields.dart';
import 'package:blockchain_utils/crypto/crypto/group/extended/monero.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/utils/numbers/fixed/src/u64/u64.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

class EdwardsLimbParams {
  static final a = Ed25519Fp.unsafe([
    Uint64.unsafe(4294967295, 4294967239),
    Uint64.unsafe(4294967295, 4294967295),
    Uint64.unsafe(4294967295, 4294967295),
    Uint64.unsafe(2147483647, 4294967295),
  ]);
  static final d = Ed25519Fp.unsafe([
    Uint64.unsafe(2163051518, 3746032122),
    Uint64.unsafe(279021431, 2948999539),
    Uint64.unsafe(3851653639, 3155723920),
    Uint64.unsafe(746728282, 1923073318),
  ]);

  /// Precomputed 2*d (as field, Montgomery).
  static final twoD = d + d;
}

class EdwardsLimbPoint extends ECPoint<Ed25519Fr, EdwardsLimbPoint>
    implements
        CryptoGroupElement<EdwardsLimbPoint, Ed25519Fr>,
        CofactorGroupElement<Ed25519Fr, EdwardsLimbPoint> {
  final Ed25519Fp x;
  final Ed25519Fp y;
  final Ed25519Fp z;
  final Ed25519Fp t;
  const EdwardsLimbPoint({
    required this.x,
    required this.y,
    required this.z,
    required this.t,
  });

  static final identity_ = EdwardsLimbPoint(
    x: Ed25519Fp.zero,
    y: Ed25519Fp.one,
    z: Ed25519Fp.one,
    t: Ed25519Fp.zero,
  );
  static final generator_ = EdwardsLimbPoint(
    x: Ed25519Fp.unsafe([
      Uint64.unsafe(3804937301, 1067295367),
      Uint64.unsafe(2628098134, 597091465),
      Uint64.unsafe(2558104427, 2917447095),
      Uint64.unsafe(1973298032, 2120251344),
    ]),
    y: Ed25519Fp.unsafe([
      Uint64.unsafe(858993459, 858993482),
      Uint64.unsafe(858993459, 858993459),
      Uint64.unsafe(858993459, 858993459),
      Uint64.unsafe(858993459, 858993459),
    ]),
    z: Ed25519Fp.one,
    t: Ed25519Fp.unsafe([
      Uint64.unsafe(1325962922, 2571823212),
      Uint64.unsafe(3820465425, 3054653550),
      Uint64.unsafe(1187490082, 4051944594),
      Uint64.unsafe(1578638425, 4273181453),
    ]),
  );

  @override
  EdwardsLimbPoint identity() => identity_;
  bool isIdentity() => x.isZero() && y == z;

  static EdwardsLimbPoint conditionalSelect(
    EdwardsLimbPoint a,
    EdwardsLimbPoint b,
    bool c,
  ) => EdwardsLimbPoint(
    x: Ed25519Fp.conditionalSelect(a.x, b.x, c),
    y: Ed25519Fp.conditionalSelect(a.y, b.y, c),
    z: Ed25519Fp.conditionalSelect(a.z, b.z, c),
    t: Ed25519Fp.conditionalSelect(a.t, b.t, c),
  );

  /// Mask form of [conditionalSelect]: [bit] is a 0/1 [Uint64] (never a
  /// `bool`), so point addition and scalar multiplication stay
  /// straight-line on secret data.
  static EdwardsLimbPoint conditionalSelectMask(
    EdwardsLimbPoint a,
    EdwardsLimbPoint b,
    Uint64 bit,
  ) => EdwardsLimbPoint(
    x: Ed25519Fp.conditionalSelectMask(a.x, b.x, bit),
    y: Ed25519Fp.conditionalSelectMask(a.y, b.y, bit),
    z: Ed25519Fp.conditionalSelectMask(a.z, b.z, bit),
    t: Ed25519Fp.conditionalSelectMask(a.t, b.t, bit),
  );

  bool isOnCurve() {
    // a*x^2 + y^2 == 1 + d*x^2*y^2  (affine check via toAffine)
    final aff = toAffineXY();
    final x = aff.$1;
    final y = aff.$2;
    final x2 = x.square();
    final y2 = y.square();
    final lhs = EdwardsLimbParams.a * x2 + y2;
    final rhs = Ed25519Fp.one + EdwardsLimbParams.d * x2 * y2;
    return lhs == rhs;
  }

  (Ed25519Fp, Ed25519Fp) toAffineXY() {
    final zInv = z.invert()!;
    return (x * zInv, y * zInv);
  }

  @override
  EdwardsLimbPoint double() {
    // dbl-2008-hwcd
    final A = x.square();
    final B = y.square();
    final C = z.square() + z.square();
    final D = EdwardsLimbParams.a * A;
    final E = (x + y).square() - A - B;
    final G = D + B;
    final F = G - C;
    final H = D - B;
    return EdwardsLimbPoint(x: E * F, y: G * H, z: F * G, t: E * H);
  }

  EdwardsLimbPoint add(EdwardsLimbPoint o) {
    // Complete hwcd-3 formula (Hisil-Wong-Carter-Dawson): exception-free
    // for all on-curve inputs — doubling, identity, and torsion-shifted
    // H == 0 pairs alike. Single straight-line evaluation, no selects.
    final A = (y - x) * (o.y - o.x);
    final B = (y + x) * (o.y + o.x);
    final C = t * o.t * EdwardsLimbParams.twoD;
    final D = z * o.z + z * o.z;
    final E = B - A;
    final F = D - C;
    final G = D + C;
    final H = B + A;
    return EdwardsLimbPoint(x: E * F, y: G * H, z: F * G, t: E * H);
  }

  @override
  EdwardsLimbPoint operator +(EdwardsLimbPoint o) {
    // Identity selects via masks — no bool branches on point data.
    final inf1 =
        (Uint64.isZeroMask(x.limbs[0] | x.limbs[1] | x.limbs[2] | x.limbs[3]) &
            Uint64.one) &
        (Uint64.ctEqualsMask(y.limbs, z.limbs) & Uint64.one);
    final inf2 =
        (Uint64.isZeroMask(
              o.x.limbs[0] | o.x.limbs[1] | o.x.limbs[2] | o.x.limbs[3],
            ) &
            Uint64.one) &
        (Uint64.ctEqualsMask(o.y.limbs, o.z.limbs) & Uint64.one);
    var sum = add(o);
    sum = conditionalSelectMask(sum, o, inf1);
    sum = conditionalSelectMask(sum, this, inf2);
    return sum;
  }

  @override
  EdwardsLimbPoint operator -() => EdwardsLimbPoint(x: -x, y: y, z: z, t: -t);

  @override
  EdwardsLimbPoint operator -(EdwardsLimbPoint o) => this + (-o);

  @override
  EdwardsLimbPoint operator *(Ed25519Fr s) {
    // Double-and-add-always + mask select. Uniform 256x double+add+select,
    // including for the zero scalar (which yields identity).
    var acc = identity();
    final bytes = s.toBytes();
    for (int i = 255; i >= 0; i--) {
      acc = acc.double();
      final add = acc + this;
      final bit = Uint64((bytes[i >> 3] >> (i & 7)) & 1);
      acc = conditionalSelectMask(acc, add, bit);
    }
    return acc;
  }

  @override
  BuBytes toBytes() {
    final zInv = z.invert()!;
    final x = (this.x * zInv).toBytes();
    final y = (this.y * zInv).toBytes();
    final out = BuBytes.fill(32);
    out.setRange(0, 32, y);
    if ((x[0] & 1) == 1) out[31] |= 0x80;
    return out;
  }

  /// Edwards25519 cofactor is 8: ×8 projects into the prime-order subgroup.
  @override
  EdwardsLimbPoint clearCofactor() => double().double().double();

  @override
  bool isSmallOrder() => clearCofactor().isIdentity();

  @override
  int recommendedWnafForNumScalars(int total) {
    const recommendations = <int>[
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
    for (final r in recommendations) {
      if (total > r) {
        ret += 1;
      } else {
        break;
      }
    }
    return ret;
  }

  static EdwardsLimbPoint fromBytes(List<int> b) {
    if (b.length != 32) {
      throw CoreErrors.invalidOperationArguments(
        "fromBytes",
        reason: "Invalid length.",
      );
    }
    final bit = (b[31] >> 7) & 1;
    final yb = List<int>.of(b)..[31] &= 0x7F;
    final y = Ed25519Fp.fromBytes(yb);
    // x^2 = (y^2-1)/(d*y^2+1)  (a=-1)
    final y2 = y.square();
    final num = y2 - Ed25519Fp.one;
    final den = EdwardsLimbParams.d * y2 + Ed25519Fp.one;
    final x2 = num * den.invert()!;
    final r = x2.sqrt();
    if (!r.isSquare) {
      // Matches the legacy decoder contract (non-residue surfaced as
      // CryptoException through the old sqrt helper).
      throw CoreErrors.cryptoFailed(
        "EdwardsLimbPoint.fromBytes",
        reason: "Not on curve.",
      );
    }
    var x = r.result;
    if (((x.toBytes()[0] & 1) != bit)) x = -x;
    final z = Ed25519Fp.one;
    final t = x * y;
    return EdwardsLimbPoint(x: x, y: y, z: z, t: t);
  }

  static EdwardsLimbPoint moneroHashToPoint(List<int> bytes) {
    // Direct limb Elligator map (vartime on the public hashed input):
    // no BigInt, no EDPoint bridge.
    return MoneroH2C.geFromFeFromBytesVartime(bytes);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! EdwardsLimbPoint) return false;
    return (x * other.z == other.x * z) && (y * other.z == other.y * z);
  }

  @override
  int get hashCode => Object.hash(x, y, z, t);
}
