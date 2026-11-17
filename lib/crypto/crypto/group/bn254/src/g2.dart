// BN254 G2 over Fp2: y^2 = x^3 + B2, B2 = 3/(u+9).
// EIP-197 encoding: 128 bytes c1||c0 for x then y (x1,x0,y1,y0), zeros = inf.
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/utils/numbers/fixed/src/u64/u64.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';
import 'package:blockchain_utils/utils/compare/hash_code.dart';
import 'package:blockchain_utils/utils/equatable/equatable.dart';
import 'package:blockchain_utils/utils/numbers/utils/int_utils.dart';

import 'package:blockchain_utils/crypto/crypto/group/bn254/src/fp.dart';
import 'package:blockchain_utils/crypto/crypto/group/bn254/src/fp2.dart';
import 'package:blockchain_utils/crypto/crypto/group/bn254/src/fr.dart';

class Bn254G2Projective {
  final Bn254Fp2 x;
  final Bn254Fp2 y;
  final Bn254Fp2 z;
  const Bn254G2Projective({required this.x, required this.y, required this.z});

  factory Bn254G2Projective.conditionalSelect(
    Bn254G2Projective a,
    Bn254G2Projective b,
    bool choice,
  ) {
    return Bn254G2Projective(
      x: Bn254Fp2.conditionalSelect(a.x, b.x, choice),
      y: Bn254Fp2.conditionalSelect(a.y, b.y, choice),
      z: Bn254Fp2.conditionalSelect(a.z, b.z, choice),
    );
  }

  factory Bn254G2Projective.conditionalSelectMask(
    Bn254G2Projective a,
    Bn254G2Projective b,
    Uint64 bit,
  ) {
    return Bn254G2Projective(
      x: Bn254Fp2.conditionalSelectMask(a.x, b.x, bit),
      y: Bn254Fp2.conditionalSelectMask(a.y, b.y, bit),
      z: Bn254Fp2.conditionalSelectMask(a.z, b.z, bit),
    );
  }

  static const identity = Bn254G2Projective(
    x: Bn254Fp2.zero,
    y: Bn254Fp2.one,
    z: Bn254Fp2.zero,
  );

  // Generator in Montgomery form (see README for decimal sources).
  static const generator = Bn254G2Projective(
    x: Bn254Fp2(
      c0: Bn254Fp.unsafe([
        Uint64.unsafe(2390996433, 45883430),
        Uint64.unsafe(3706394933, 1232798066),
        Uint64.unsafe(4223149639, 2541820639),
        Uint64.unsafe(425146433, 2945863739),
      ]),
      c1: Bn254Fp.unsafe([
        Uint64.unsafe(2947838845, 2823577920),
        Uint64.unsafe(1615060314, 1476581572),
        Uint64.unsafe(166285564, 1386229638),
        Uint64.unsafe(352252035, 988445547),
      ]),
    ),
    y: Bn254Fp2(
      c0: Bn254Fp.unsafe([
        Uint64.unsafe(1637743261, 2288773622),
        Uint64.unsafe(4269789847, 4120812408),
        Uint64.unsafe(4288551522, 589004286),
        Uint64.unsafe(687701739, 2929607174),
      ]),
      c1: Bn254Fp.unsafe([
        Uint64.unsafe(1678334806, 3340261102),
        Uint64.unsafe(3696752930, 847068347),
        Uint64.unsafe(1442395582, 859115638),
        Uint64.unsafe(228892902, 2482857090),
      ]),
    ),
    z: Bn254Fp2.one,
  );

  factory Bn254G2Projective.fromAffine(Bn254G2AffinePoint affine) {
    return Bn254G2Projective(
      x: affine.x,
      y: affine.y,
      z: Bn254Fp2.conditionalSelect(
        Bn254Fp2.one,
        Bn254Fp2.zero,
        affine.infinity,
      ),
    );
  }

  factory Bn254G2Projective.fromBytes(List<int> bytes) {
    return Bn254G2Projective.fromAffine(Bn254G2AffinePoint.fromBytes(bytes));
  }

  factory Bn254G2Projective.fromBytesUnchecked(List<int> bytes) {
    return Bn254G2Projective.fromAffine(
      Bn254G2AffinePoint.fromBytesUnchecked(bytes),
    );
  }

  Bn254G2Projective multiply(List<int> byBe) {
    if (byBe.length != 32) {
      throw CoreErrors.cryptoFailed(
        'Bn254G2.multiply',
        reason: 'Invalid scalar bytes length.',
      );
    }
    Bn254G2Projective acc = Bn254G2Projective.identity;
    for (int i = 0; i < 256; i++) {
      acc = acc.double();
      final byte = byBe[i >> 3];
      final bit = Uint64((byte >> (7 - (i & 7))) & 1);
      acc = Bn254G2Projective.conditionalSelectMask(acc, (acc + this), bit);
    }
    return acc;
  }

  Bn254Fp2 mulBy3b(Bn254Fp2 a) => (a + a + a) * Bn254Fp2.b;

  Bn254G2Projective double() {
    var t0 = y.square();
    var z3 = t0 + t0;
    z3 = z3 + z3;
    z3 = z3 + z3;
    var t1 = y * z;
    var t2 = z.square();
    t2 = mulBy3b(t2);
    var x3 = t2 * z3;
    var y3 = t0 + t2;
    z3 = t1 * z3;
    t1 = t2 + t2;
    t2 = t1 + t2;
    t0 = t0 - t2;
    y3 = t0 * y3;
    y3 = x3 + y3;
    t1 = x * y;
    x3 = t0 * t1;
    final x3d = x3 + x3;
    return Bn254G2Projective(x: x3d, y: y3, z: z3);
  }

  Bn254G2Projective operator +(Bn254G2Projective rhs) {
    var t0 = x * rhs.x;
    var t1 = y * rhs.y;
    var t2 = z * rhs.z;
    var t3 = x + y;
    var t4 = rhs.x + rhs.y;
    t3 = t3 * t4;
    t4 = t0 + t1;
    t3 = t3 - t4;
    t4 = y + z;
    var x3 = rhs.y + rhs.z;
    t4 = t4 * x3;
    x3 = t1 + t2;
    t4 = t4 - x3;
    x3 = x + z;
    var y3 = rhs.x + rhs.z;
    x3 = x3 * y3;
    y3 = t0 + t2;
    y3 = x3 - y3;
    x3 = t0 + t0;
    final t0b = x3 + t0;
    t2 = mulBy3b(t2);
    var z3 = t1 + t2;
    t1 = t1 - t2;
    y3 = mulBy3b(y3);
    x3 = t4 * y3;
    t2 = t3 * t1;
    x3 = t2 - x3;
    y3 = y3 * t0b;
    t1 = t1 * z3;
    y3 = t1 + y3;
    t0 = t0b * t3;
    z3 = z3 * t4;
    z3 = z3 + t0;
    return Bn254G2Projective(x: x3, y: y3, z: z3);
  }

  Bn254G2Projective operator -(Bn254G2Projective rhs) => this + (-rhs);
  Bn254G2Projective operator -() => Bn254G2Projective(x: x, y: -y, z: z);
  Bn254G2Projective operator *(Bn254Fr rhs) => multiply(rhs.toBytes().toList());

  BuBytes toBytes() => toAffine().toBytes();
  bool isIdentity() => z.isZero();

  bool isOnCurve() {
    return (y.square() * z) == (x.square() * x + z.square() * z * Bn254Fp2.b) ||
        z.isZero();
  }

  Bn254G2AffinePoint toAffine() {
    final zinv = z.invert() ?? Bn254Fp2.zero;
    final x = this.x * zinv;
    final y = this.y * zinv;
    final tmp = Bn254G2AffinePoint(x: x, y: y, infinity: false);
    return Bn254G2AffinePoint.conditionalSelect(
      tmp,
      Bn254G2AffinePoint.identity,
      zinv.isZero(),
    );
  }

  @override
  bool operator ==(other) {
    if (other is! Bn254G2Projective) return false;
    final x1 = x * other.z;
    final x2 = other.x * z;
    final y1 = y * other.z;
    final y2 = other.y * z;
    final isZero = z.isZero();
    final otherIsZero = other.z.isZero();
    return (isZero & otherIsZero) |
        ((!isZero) & (!otherIsZero) & (x1 == x2) & (y1 == y2));
  }

  @override
  int get hashCode => HashCodeGenerator.generateHashCode([x, y, z]);
}

class Bn254G2AffinePoint with Equality {
  final Bn254Fp2 x;
  final Bn254Fp2 y;
  final bool infinity;
  const Bn254G2AffinePoint({
    required this.x,
    required this.y,
    required this.infinity,
  });

  static const identity = Bn254G2AffinePoint(
    x: Bn254Fp2.zero,
    y: Bn254Fp2.one,
    infinity: true,
  );

  static const generator = Bn254G2AffinePoint(
    x: Bn254Fp2(
      c0: Bn254Fp.unsafe([
        Uint64.unsafe(2390996433, 45883430),
        Uint64.unsafe(3706394933, 1232798066),
        Uint64.unsafe(4223149639, 2541820639),
        Uint64.unsafe(425146433, 2945863739),
      ]),
      c1: Bn254Fp.unsafe([
        Uint64.unsafe(2947838845, 2823577920),
        Uint64.unsafe(1615060314, 1476581572),
        Uint64.unsafe(166285564, 1386229638),
        Uint64.unsafe(352252035, 988445547),
      ]),
    ),
    y: Bn254Fp2(
      c0: Bn254Fp.unsafe([
        Uint64.unsafe(1637743261, 2288773622),
        Uint64.unsafe(4269789847, 4120812408),
        Uint64.unsafe(4288551522, 589004286),
        Uint64.unsafe(687701739, 2929607174),
      ]),
      c1: Bn254Fp.unsafe([
        Uint64.unsafe(1678334806, 3340261102),
        Uint64.unsafe(3696752930, 847068347),
        Uint64.unsafe(1442395582, 859115638),
        Uint64.unsafe(228892902, 2482857090),
      ]),
    ),
    infinity: false,
  );

  factory Bn254G2AffinePoint.conditionalSelect(
    Bn254G2AffinePoint a,
    Bn254G2AffinePoint b,
    bool choice,
  ) {
    return Bn254G2AffinePoint(
      x: Bn254Fp2.conditionalSelect(a.x, b.x, choice),
      y: Bn254Fp2.conditionalSelect(a.y, b.y, choice),
      infinity: IntUtils.ctSelectBool(a.infinity, b.infinity, choice),
    );
  }

  /// EIP-197 word order x1,x0,y1,y0 (each 32 BE), zeros = infinity.
  factory Bn254G2AffinePoint.fromBytesUnchecked(List<int> bytes) {
    bytes = bytes.exc(
      length: 128,
      operation: 'Bn254G2.fromBytesUnchecked',
      reason: 'Invalid point bytes length.',
    );
    bool allZero = true;
    for (final b in bytes) {
      if (b != 0) {
        allZero = false;
        break;
      }
    }
    if (allZero) return Bn254G2AffinePoint.identity;
    final x1 = Bn254Fp.fromBytes(bytes.sublist(0, 32));
    final x0 = Bn254Fp.fromBytes(bytes.sublist(32, 64));
    final y1 = Bn254Fp.fromBytes(bytes.sublist(64, 96));
    final y0 = Bn254Fp.fromBytes(bytes.sublist(96, 128));
    return Bn254G2AffinePoint(
      x: Bn254Fp2(c0: x0, c1: x1),
      y: Bn254Fp2(c0: y0, c1: y1),
      infinity: false,
    );
  }

  factory Bn254G2AffinePoint.fromBytes(List<int> bytes) {
    final p = Bn254G2AffinePoint.fromBytesUnchecked(bytes);
    if (p.isOnCurve() && p.isTorsionFree()) return p;
    throw CoreErrors.invalidOperationArguments(
      'Bn254G2.fromBytes',
      reason: 'Invalid G2 encoding.',
    );
  }

  Bn254G2Projective toProjective() => Bn254G2Projective.fromAffine(this);

  /// Subgroup check: [r]P == 0 (r = group order). Slow but exact;
  /// mirrors BLS `isTorsionFree` semantics without endomorphism tricks.
  bool isTorsionFree() {
    if (infinity) return true;
    if (!isOnCurve()) return false;
    const rBe = [
      0x30, 0x64, 0x4e, 0x72, 0xe1, 0x31, 0xa0, 0x29, //
      0xb8, 0x50, 0x45, 0xb6, 0x81, 0x81, 0x58, 0x5d,
      0x28, 0x33, 0xe8, 0x48, 0x79, 0xb9, 0x70, 0x91,
      0x43, 0xe1, 0xf5, 0x93, 0xf0, 0x00, 0x00, 0x01,
    ];
    return toProjective().multiply(rBe).isIdentity();
  }

  bool isOnCurve() {
    if (infinity) return true;
    return (y.square() - (x.square() * x)) == Bn254Fp2.b;
  }

  bool isIdentity() => infinity;

  Bn254G2AffinePoint operator -() {
    return Bn254G2AffinePoint(
      x: x,
      y: Bn254Fp2.conditionalSelect(-y, Bn254Fp2.one, infinity),
      infinity: infinity,
    );
  }

  BuBytes toBytes() {
    if (infinity) return BuBytes(List.filled(128, 0));
    return BuBytes([
      ...x.c1.toBytes(),
      ...x.c0.toBytes(),
      ...y.c1.toBytes(),
      ...y.c0.toBytes(),
    ]);
  }

  @override
  List<dynamic> get variables => [x, y, infinity];
}
