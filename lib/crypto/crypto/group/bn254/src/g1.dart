// BN254 G1: y^2 = x^3 + 3 over Fp, generator (1, 2).
// Projective (x:y:z) + affine (x, y, infinity), EIP-197 uncompressed bytes.
// Complete RCB15 formulas + mask selects, mirroring Bls12 G1.
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/utils/numbers/fixed/src/u64/u64.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';
import 'package:blockchain_utils/utils/compare/hash_code.dart';
import 'package:blockchain_utils/utils/equatable/equatable.dart';
import 'package:blockchain_utils/utils/numbers/utils/int_utils.dart';

import 'package:blockchain_utils/crypto/crypto/group/bn254/src/fp.dart';
import 'package:blockchain_utils/crypto/crypto/group/bn254/src/fr.dart';

class Bn254G1Projective {
  final Bn254Fp x;
  final Bn254Fp y;
  final Bn254Fp z;
  const Bn254G1Projective({required this.x, required this.y, required this.z});

  factory Bn254G1Projective.conditionalSelect(
    Bn254G1Projective a,
    Bn254G1Projective b,
    bool choice,
  ) {
    return Bn254G1Projective(
      x: Bn254Fp.conditionalSelect(a.x, b.x, choice),
      y: Bn254Fp.conditionalSelect(a.y, b.y, choice),
      z: Bn254Fp.conditionalSelect(a.z, b.z, choice),
    );
  }

  factory Bn254G1Projective.conditionalSelectMask(
    Bn254G1Projective a,
    Bn254G1Projective b,
    Uint64 bit,
  ) {
    return Bn254G1Projective(
      x: Bn254Fp.conditionalSelectMask(a.x, b.x, bit),
      y: Bn254Fp.conditionalSelectMask(a.y, b.y, bit),
      z: Bn254Fp.conditionalSelectMask(a.z, b.z, bit),
    );
  }

  static const identity = Bn254G1Projective(
    x: Bn254Fp.zero,
    y: Bn254Fp.one,
    z: Bn254Fp.zero,
  );

  // (1, 2) in Montgomery form: 1*R, 2*R
  static const generator = Bn254G1Projective(
    x: Bn254Fp.one,
    y: Bn254Fp.unsafe([
      Uint64.unsafe(2797242139, 2334006074),
      Uint64.unsafe(351393361, 3951957627),
      Uint64.unsafe(3437053662, 4042427480),
      Uint64.unsafe(471134083, 873447006),
    ]),
    z: Bn254Fp.one,
  );

  factory Bn254G1Projective.fromAffine(Bn254G1AffinePoint affine) {
    return Bn254G1Projective(
      x: affine.x,
      y: affine.y,
      z: Bn254Fp.conditionalSelect(
        Bn254Fp.one,
        Bn254Fp.zero,
        affine.infinity,
      ),
    );
  }

  factory Bn254G1Projective.fromBytes(List<int> bytes) {
    return Bn254G1Projective.fromAffine(Bn254G1AffinePoint.fromBytes(bytes));
  }

  factory Bn254G1Projective.fromBytesUnchecked(List<int> bytes) {
    return Bn254G1Projective.fromAffine(
      Bn254G1AffinePoint.fromBytesUnchecked(bytes),
    );
  }

  /// EIP-196 scalar mul: 32-byte BE scalar, full 256-bit double-and-add,
  /// per-bit select is a Uint64 mask blend (no bool on the secret).
  Bn254G1Projective multiply(List<int> byBe) {
    if (byBe.length != 32) {
      throw CoreErrors.cryptoFailed(
        'Bn254G1.multiply',
        reason: 'Invalid scalar bytes length.',
      );
    }
    Bn254G1Projective acc = Bn254G1Projective.identity;
    for (int i = 0; i < 256; i++) {
      acc = acc.double();
      final byte = byBe[i >> 3];
      final bit = Uint64((byte >> (7 - (i & 7))) & 1);
      acc = Bn254G1Projective.conditionalSelectMask(acc, (acc + this), bit);
    }
    return acc;
  }

  Bn254Fp mulBy3b(Bn254Fp a) {
    // 3*b = 9 for b = 3
    Bn254Fp t = a + a; // 2
    t = t + t; // 4
    t = t + t; // 8
    return t + a; // 9
  }

  Bn254G1Projective double() {
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
    return Bn254G1Projective(x: x3d, y: y3, z: z3);
  }

  Bn254G1Projective operator +(Bn254G1Projective rhs) {
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
    return Bn254G1Projective(x: x3, y: y3, z: z3);
  }

  Bn254G1Projective operator -(Bn254G1Projective rhs) => this + (-rhs);

  Bn254G1Projective operator -() =>
      Bn254G1Projective(x: x, y: -y, z: z);

  Bn254G1Projective operator *(Bn254Fr rhs) => multiply(rhs.toBytes().toList());

  BuBytes toBytes() => toAffine().toBytes();

  bool isIdentity() => z.isZero();

  bool isOnCurve() {
    return (y.square() * z) == (x.square() * x + z.square() * z * Bn254Fp.b) ||
        z.isZero();
  }

  Bn254G1AffinePoint toAffine() {
    final zinv = z.invert() ?? Bn254Fp.zero;
    final x = this.x * zinv;
    final y = this.y * zinv;
    final tmp = Bn254G1AffinePoint(x: x, y: y, infinity: false);
    return Bn254G1AffinePoint.conditionalSelect(
      tmp,
      Bn254G1AffinePoint.identity,
      zinv.isZero(),
    );
  }

  @override
  bool operator ==(other) {
    if (other is! Bn254G1Projective) return false;
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

class Bn254G1AffinePoint with Equality {
  final Bn254Fp x;
  final Bn254Fp y;
  final bool infinity;
  const Bn254G1AffinePoint({
    required this.x,
    required this.y,
    required this.infinity,
  });

  static const identity = Bn254G1AffinePoint(
    x: Bn254Fp.zero,
    y: Bn254Fp.one,
    infinity: true,
  );

  // generator affine = same Montgomery limbs as projective
  static const generator = Bn254G1AffinePoint(
    x: Bn254Fp.one,
    y: Bn254Fp.unsafe([
      Uint64.unsafe(2797242139, 2334006074),
      Uint64.unsafe(351393361, 3951957627),
      Uint64.unsafe(3437053662, 4042427480),
      Uint64.unsafe(471134083, 873447006),
    ]),
    infinity: false,
  );

  factory Bn254G1AffinePoint.conditionalSelect(
    Bn254G1AffinePoint a,
    Bn254G1AffinePoint b,
    bool choice,
  ) {
    return Bn254G1AffinePoint(
      x: Bn254Fp.conditionalSelect(a.x, b.x, choice),
      y: Bn254Fp.conditionalSelect(a.y, b.y, choice),
      infinity: IntUtils.ctSelectBool(a.infinity, b.infinity, choice),
    );
  }

  /// EIP-197: 64 bytes x||y BE, all-zero = infinity. No flags.
  factory Bn254G1AffinePoint.fromBytesUnchecked(List<int> bytes) {
    bytes = bytes.exc(
      length: 64,
      operation: 'Bn254G1.fromBytesUnchecked',
      reason: 'Invalid point bytes length.',
    );
    bool allZero = true;
    for (final b in bytes) {
      if (b != 0) {
        allZero = false;
        break;
      }
    }
    if (allZero) return Bn254G1AffinePoint.identity;
    final x = Bn254Fp.fromBytes(bytes.sublist(0, 32));
    final y = Bn254Fp.fromBytes(bytes.sublist(32, 64));
    return Bn254G1AffinePoint(x: x, y: y, infinity: false);
  }

  factory Bn254G1AffinePoint.fromBytes(List<int> bytes) {
    final p = Bn254G1AffinePoint.fromBytesUnchecked(bytes);
    if (p.isOnCurve() && p.isTorsionFree()) return p;
    throw CoreErrors.invalidOperationArguments(
      'Bn254G1.fromBytes',
      reason: 'Invalid G1 encoding.',
    );
  }

  factory Bn254G1AffinePoint.fromProjective(Bn254G1Projective p) =>
      p.toAffine();

  Bn254G1Projective toProjective() => Bn254G1Projective.fromAffine(this);

  Bn254G1Projective operator +(Bn254G1Projective rhs) => rhs + toProjective();
  Bn254G1Projective operator *(Bn254Fr rhs) =>
      toProjective().multiply(rhs.toBytes().toList());

  Bn254G1AffinePoint operator -() {
    return Bn254G1AffinePoint(
      x: x,
      y: Bn254Fp.conditionalSelect(-y, Bn254Fp.one, infinity),
      infinity: infinity,
    );
  }

  /// h = 1, so on-curve implies in-subgroup.
  bool isTorsionFree() => isOnCurve() || infinity;

  bool isOnCurve() {
    if (infinity) return true;
    return (y.square() - (x.square() * x)) == Bn254Fp.b;
  }

  bool isIdentity() => infinity;

  BuBytes toBytes() {
    if (infinity) return BuBytes(List.filled(64, 0));
    return BuBytes([...x.toBytes(), ...y.toBytes()]);
  }

  @override
  List<dynamic> get variables => [x, y, infinity];
}
