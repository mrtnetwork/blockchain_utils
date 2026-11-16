import 'package:blockchain_utils/crypto/crypto/keys/types/types.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/crypto/crypto/group/bls12_381/src/core.dart';
import 'package:blockchain_utils/crypto/crypto/group/bls12_381/src/fp.dart';
import 'package:blockchain_utils/crypto/crypto/group/jubjub/fields/field.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/utils/numbers/fixed/src/u64/u64.dart';

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';
import 'package:blockchain_utils/utils/compare/hash_code.dart';
import 'package:blockchain_utils/utils/equatable/equatable.dart';
import 'package:blockchain_utils/utils/numbers/utils/int_utils.dart';

/// BLS12-381 G1 group in projective coordinates (x : y : z).
class G1Projective extends Bls12Point<G1Projective> {
  final Bls12Fp x;
  final Bls12Fp y;
  final Bls12Fp z;
  const G1Projective({required this.x, required this.y, required this.z});
  G1Projective copyWith({Bls12Fp? x, Bls12Fp? y, Bls12Fp? z}) =>
      G1Projective(x: x ?? this.x, y: y ?? this.y, z: z ?? this.z);

  factory G1Projective.conditionalSelect(
    G1Projective a,
    G1Projective b,
    bool choice,
  ) {
    return G1Projective(
      x: Bls12Fp.conditionalSelect(a.x, b.x, choice),
      y: Bls12Fp.conditionalSelect(a.y, b.y, choice),
      z: Bls12Fp.conditionalSelect(a.z, b.z, choice),
    );
  }

  /// Mask form of [conditionalSelect]: [bit] is a 0/1 [Uint64] (never a
  /// `bool`), so scalar-multiplication selects stay straight-line.
  factory G1Projective.conditionalSelectMask(
    G1Projective a,
    G1Projective b,
    Uint64 bit,
  ) {
    return G1Projective(
      x: Bls12Fp.conditionalSelectMask(a.x, b.x, bit),
      y: Bls12Fp.conditionalSelectMask(a.y, b.y, bit),
      z: Bls12Fp.conditionalSelectMask(a.z, b.z, bit),
    );
  }

  /// identity point
  static const G1Projective identity = G1Projective(
    x: Bls12Fp.zero,
    y: Bls12Fp.one,
    z: Bls12Fp.zero,
  );

  /// generator
  static const G1Projective generator = G1Projective(
    x: Bls12Fp.unsafe([
      Uint64.unsafe(1555269520, 4250078230),
      Uint64.unsafe(2014837863, 2574712821),
      Uint64.unsafe(357537223, 339452353),
      Uint64.unsafe(4037962445, 4090554183),
      Uint64.unsafe(3989728972, 568063040),
      Uint64.unsafe(302085953, 2651585397),
    ]),
    y: Bls12Fp.unsafe([
      Uint64.unsafe(3131872213, 216474225),
      Uint64.unsafe(2351063834, 2031680910),
      Uint64.unsafe(3713621779, 1460086222),
      Uint64.unsafe(1370249257, 1346392468),
      Uint64.unsafe(236751935, 2902481344),
      Uint64.unsafe(196886268, 1342743146),
    ]),
    z: Bls12Fp.one,
  );

  factory G1Projective.fromAffine(G1AffinePoint affine) {
    return G1Projective(
      x: affine.x,
      y: affine.y,
      z: Bls12Fp.conditionalSelect(Bls12Fp.one, Bls12Fp.zero, affine.infinity),
    );
  }

  /// Creates a G1 point from bytes, validating that it is on-curve and in the correct subgroup.
  factory G1Projective.fromBytes(List<int> bytes) {
    return G1Projective.fromAffine(G1AffinePoint.fromBytes(bytes));
  }

  factory G1Projective.fromBytesUnchecked(List<int> bytes) {
    return G1Projective.fromAffine(G1AffinePoint.fromBytesUnchecked(bytes));
  }

  G1Projective _multiply(List<int> by) {
    assert(by.length == 32);
    G1Projective acc = G1Projective.identity;
    // Same bit sequence as before (`bytesToBits` LE, top bit skipped), but
    // the per-bit select is a Uint64 mask blend — no `bool` on the secret.
    for (int i = 254; i >= 0; i--) {
      acc = acc.double();
      final bit = Uint64((by[i >> 3] >> (i & 7)) & 1);
      acc = G1Projective.conditionalSelectMask(acc, (acc + this), bit);
    }
    return acc;
  }

  /// Multiply this point by `BLS_X` using double-and-add over the public
  /// constant Uint64.
  G1Projective mulByX() {
    G1Projective result = G1Projective.identity;

    const blsx = Uint64.unsafe(3523280896, 65536); // 0xd201000000010000
    Uint64 x = blsx >> 1; // skip the first bit
    G1Projective tmp = this;

    while (x != Uint64.zero) {
      tmp = tmp.double();

      if ((x & Uint64.one) == Uint64.one) {
        result = result + tmp;
      }
      x >>= 1;
    }
    return -result;
  }

  /// Clears the G1 cofactor by subtracting [mulByX] from the point.
  G1Projective clearCofactor() => this - mulByX();

  Bls12Fp mulBy3b(Bls12Fp a) {
    a = a + a;
    a = a + a;
    return a + a + a;
  }

  @override
  G1Projective double() {
    Bls12Fp t0 = y.square();
    Bls12Fp z3 = t0 + t0;
    z3 = z3 + z3;
    z3 = z3 + z3;
    Bls12Fp t1 = y * z;
    Bls12Fp t2 = z.square();
    t2 = mulBy3b(t2);
    Bls12Fp x3 = t2 * z3;
    Bls12Fp y3 = t0 + t2;
    z3 = t1 * z3;
    t1 = t2 + t2;
    t2 = t1 + t2;
    t0 = t0 - t2;
    y3 = t0 * y3;
    y3 = x3 + y3;
    t1 = x * y;
    x3 = t0 * t1;
    x3 = x3 + x3;
    return G1Projective(x: x3, y: y3, z: z3);
  }

  /// operations
  ///

  @override
  G1Projective operator *(JubJubFq rhs) {
    return _multiply(rhs.toBytes());
  }

  G1Projective operator -(Bls12Point<G1Projective> rhs) {
    switch (rhs) {
      case final G1Projective rhs:
        return this + (-rhs);
      case final G1AffinePoint rhs:
        return this + (-rhs);
      default:
        throw CoreErrors.cryptoOperationNotSupported;
    }
  }

  @override
  G1Projective operator +(Bls12Point<G1Projective> rhs) {
    switch (rhs) {
      case final G1Projective rhs:
        Bls12Fp t0 = x * rhs.x;
        Bls12Fp t1 = y * rhs.y;
        Bls12Fp t2 = z * rhs.z;
        Bls12Fp t3 = x + y;
        Bls12Fp t4 = rhs.x + rhs.y;
        t3 = t3 * t4;
        t4 = t0 + t1;
        t3 = t3 - t4;
        t4 = y + z;
        Bls12Fp x3 = rhs.y + rhs.z;
        t4 = t4 * x3;
        x3 = t1 + t2;
        t4 = t4 - x3;
        x3 = x + z;
        Bls12Fp y3 = rhs.x + rhs.z;
        x3 = x3 * y3;
        y3 = t0 + t2;
        y3 = x3 - y3;
        x3 = t0 + t0;
        t0 = x3 + t0;
        t2 = mulBy3b(t2);
        Bls12Fp z3 = t1 + t2;
        t1 = t1 - t2;
        y3 = mulBy3b(y3);
        x3 = t4 * y3;
        t2 = t3 * t1;
        x3 = t2 - x3;
        y3 = y3 * t0;
        t1 = t1 * z3;
        y3 = t1 + y3;
        t0 = t0 * t3;
        z3 = z3 * t4;
        z3 = z3 + t0;
        return G1Projective(x: x3, y: y3, z: z3);
      case final G1AffinePoint rhs:
        // Lift to projective and reuse the complete formula: the only
        // secret-data decision (infinity) becomes a z-mask select instead
        // of a `bool` branch. Formula output for an infinity addend is
        // discarded by the select below.
        final q = G1Projective.fromAffine(rhs);
        final sum = this + q;
        final inf =
            Uint64.isZeroMask(
              q.z.limbs[0] |
                  q.z.limbs[1] |
                  q.z.limbs[2] |
                  q.z.limbs[3] |
                  q.z.limbs[4] |
                  q.z.limbs[5],
            ) &
            Uint64.one;
        return G1Projective.conditionalSelectMask(sum, this, inf);
    }

    throw CoreErrors.cryptoOperationNotSupported;
  }

  @override
  G1Projective operator -() {
    return G1Projective(x: x, y: -y, z: z);
  }

  /// Serializes the point to bytes in either compressed or uncompressed form.
  @override
  BuBytes toBytes({CryptoKeyEncoding mode = CryptoKeyEncoding.base}) {
    return toAffine().toBytes(mode: mode);
  }

  /// check identity
  @override
  bool isIdentity() {
    return z.isZero();
  }

  /// Checks whether the point satisfies the BLS12-381 curve equation in projective form.
  bool isOnCurve() {
    // Y^2 * Z = X^3 + b * Z^3
    return (y.square() * z) == (x.square() * x + z.square() * z * Bls12Fp.b) ||
        z.isZero();
  }

  /// convert point to affine
  G1AffinePoint toAffine() {
    final zinv = z.invert() ?? Bls12Fp.zero;
    final x = this.x * zinv;
    final y = this.y * zinv;
    final tmp = G1AffinePoint(x: x, y: y, infinity: false);
    return G1AffinePoint.conditionalSelect(
      tmp,
      G1AffinePoint.identity,
      zinv.isZero(),
    );
  }

  @override
  operator ==(other) {
    if (other is! G1Projective) return false;
    final x1 = x * other.z;
    final x2 = other.x * z;
    final y1 = y * other.z;
    final y2 = other.y * z;
    final isZero = z.isZero();
    final otherIsZero = other.z.isZero();
    return (isZero & otherIsZero) // Both point at infinity
        |
        ((!isZero) & (!otherIsZero) & (x1 == x2) & (y1 == y2));
  }

  @override
  int get hashCode => HashCodeGenerator.generateHashCode([x, y, z]);
}

/// BLS12-381 G1 group in affine coordinates (x, y) plus infinity flag.
class G1AffinePoint extends Bls12AffinePoint<G1Projective> with Equality {
  final Bls12Fp x;
  final Bls12Fp y;
  final bool infinity;
  const G1AffinePoint({
    required this.x,
    required this.y,
    required this.infinity,
  });
  factory G1AffinePoint._fromUncompressedBytes(List<int> bytes) {
    bytes = bytes.exc(
      length: 96,
      operation: "fromUncompressedBytes",
      reason: "Invalid uncompressed bytes.",
    );
    final compressionFlagSet = ((bytes[0] >> 7) & 1) == 1;
    final infinityFlagSet = ((bytes[0] >> 6) & 1) == 1;
    final sortFlagSet = ((bytes[0] >> 5) & 1) == 1;
    final xBytes = bytes.sublist(0, 48);
    xBytes[0] &= 31;
    final x = Bls12Fp.fromBytes(xBytes);
    final y = Bls12Fp.fromBytes(bytes.sublist(48));

    final p = G1AffinePoint(x: x, y: y, infinity: infinityFlagSet);
    final isValid =
        ((!infinityFlagSet) | (infinityFlagSet & x.isZero() & y.isZero())) &
        (!compressionFlagSet) &
        (!sortFlagSet);
    if (!isValid) {
      throw CoreErrors.invalidOperationArguments(
        "fromUncompressedBytes",
        reason: "Invalid uncompressed bytes",
      );
    }
    return p;
  }
  factory G1AffinePoint._fromCompressedBytes(List<int> bytes) {
    bytes = bytes.exc(
      length: 48,
      operation: "fromCompressedBytes",
      reason: "Invalid compressed bytes.",
    );
    final compressionFlagSet = ((bytes[0] >> 7) & 1) == 1;
    final infinityFlagSet = ((bytes[0] >> 6) & 1) == 1;
    final sortFlagSet = ((bytes[0] >> 5) & 1) == 1;
    final xBytes = bytes.clone();
    xBytes[0] &= 31;
    final x = Bls12Fp.fromBytes(xBytes);

    final infinity =
        infinityFlagSet & compressionFlagSet & (!sortFlagSet) & x.isZero();
    if (infinity) return G1AffinePoint.identity;
    final l = ((x.square() * x) + Bls12Fp.b).sqrt();
    if (!l.isSquare) {
      throw CoreErrors.invalidOperationArguments(
        "fromCompressedBytes",
        reason: "Invalid compressed bytes",
      );
    }
    final y = Bls12Fp.conditionalSelect(
      l.result,
      -l.result,
      l.result.lexicographicallyLargest() ^ sortFlagSet,
    );
    final isValid = (!infinityFlagSet) & compressionFlagSet;
    if (!isValid) {
      throw CoreErrors.invalidOperationArguments(
        "fromCompressedBytes",
        reason: "Invalid compressed bytes",
      );
    }
    return G1AffinePoint(x: x, y: y, infinity: infinityFlagSet);
  }

  /// Creates a G1 affine point from bytes without checking curve or subgroup validity.
  factory G1AffinePoint.fromBytesUnchecked(List<int> bytes) {
    if (bytes.length == 48) {
      return G1AffinePoint._fromCompressedBytes(bytes);
    } else if (bytes.length == 96) {
      return G1AffinePoint._fromUncompressedBytes(bytes);
    }
    throw CoreErrors.invalidOperationArguments(
      "fromBytes",
      reason: "Invalid point bytes length.",
    );
  }

  /// Creates a G1 affine point from bytes, validating that it is on-curve and in the correct subgroup.
  factory G1AffinePoint.fromBytes(List<int> bytes) {
    final affine = G1AffinePoint.fromBytesUnchecked(bytes);
    if (affine.isOnCurve() && affine.isTorsionFree()) {
      return affine;
    }
    throw CoreErrors.invalidOperationArguments(
      "fromBytes",
      reason: "Invalid G1 encoding.",
    );
  }

  factory G1AffinePoint.conditionalSelect(
    G1AffinePoint a,
    G1AffinePoint b,
    bool choice,
  ) {
    return G1AffinePoint(
      x: Bls12Fp.conditionalSelect(a.x, b.x, choice),
      y: Bls12Fp.conditionalSelect(a.y, b.y, choice),
      infinity: IntUtils.ctSelectBool(a.infinity, b.infinity, choice),
    );
  }
  static const identity = G1AffinePoint(
    x: Bls12Fp.zero,
    y: Bls12Fp.one,
    infinity: true,
  );
  static const G1AffinePoint generator = G1AffinePoint(
    x: Bls12Fp.unsafe([
      Uint64.unsafe(1555269520, 4250078230),
      Uint64.unsafe(2014837863, 2574712821),
      Uint64.unsafe(357537223, 339452353),
      Uint64.unsafe(4037962445, 4090554183),
      Uint64.unsafe(3989728972, 568063040),
      Uint64.unsafe(302085953, 2651585397),
    ]),
    y: Bls12Fp.unsafe([
      Uint64.unsafe(3131872213, 216474225),
      Uint64.unsafe(2351063834, 2031680910),
      Uint64.unsafe(3713621779, 1460086222),
      Uint64.unsafe(1370249257, 1346392468),
      Uint64.unsafe(236751935, 2902481344),
      Uint64.unsafe(196886268, 1342743146),
    ]),
    infinity: false,
  );

  factory G1AffinePoint.fromProjective(G1Projective p) {
    final zInv = p.z.invert() ?? Bls12Fp.zero;
    final x = p.x * zInv;
    final y = p.y * zInv;
    final tmp = G1AffinePoint(x: x, y: y, infinity: false);
    return G1AffinePoint.conditionalSelect(
      tmp,
      G1AffinePoint.identity,
      zInv.isZero(),
    );
  }

  @override
  G1Projective operator *(JubJubFq rhs) {
    return toProjective()._multiply(rhs.toBytes());
  }

  G1Projective operator -(Bls12Point<G1Projective> rhs) {
    switch (rhs) {
      case final G1Projective rhs:
        return this + -rhs;
      default:
        throw CoreErrors.cryptoOperationNotSupported;
    }
  }

  @override
  G1Projective operator +(Bls12Point<G1Projective> rhs) {
    switch (rhs) {
      case final G1Projective rhs:
        return rhs + this;
      default:
        throw CoreErrors.cryptoOperationNotSupported;
    }
  }

  G1AffinePoint _endomorphism() {
    return G1AffinePoint(x: x * Bls12Fp.beta, y: y, infinity: infinity);
  }

  /// Converts this affine point to its projective representation.
  G1Projective toProjective() => G1Projective.fromAffine(this);

  /// Checks whether the point is in the correct G1 subgroup (torsion-free).
  bool isTorsionFree() {
    final minusX = -G1Projective.fromAffine(this).mulByX().mulByX();
    final endomorphismP = _endomorphism();
    return minusX == endomorphismP.toProjective();
  }

  /// Checks whether the point satisfies the BLS12-381 curve equation in projective form.
  bool isOnCurve() {
    if (infinity) return true;
    return (y.square() - (x.square() * x)) == Bls12Fp.b;
  }

  List<int> _toCompressed() {
    final res = Bls12Fp.conditionalSelect(x, Bls12Fp.zero, infinity).toBytes();
    res[0] |= 1 << 7;
    // Is this point at infinity? If so, set the second-most significant bit.
    res[0] |= IntUtils.ctSelectInt(0, 1 << 6, infinity);
    res[0] |= IntUtils.ctSelectInt(
      0,
      1 << 5,
      (!infinity) && y.lexicographicallyLargest(),
    );
    return res;
  }

  List<int> _toUncompressed() {
    final res = [
      ...Bls12Fp.conditionalSelect(x, Bls12Fp.zero, infinity).toBytes(),
      ...Bls12Fp.conditionalSelect(y, Bls12Fp.zero, infinity).toBytes(),
    ];
    res[0] |= IntUtils.ctSelectInt(0, 1 << 6, infinity);
    return res;
  }

  /// Serializes the point to bytes in either compressed or uncompressed form.
  @override
  BuBytes toBytes({CryptoKeyEncoding mode = CryptoKeyEncoding.base}) {
    return switch (mode) {
      CryptoKeyEncoding.base => BuBytes(_toCompressed()),
      CryptoKeyEncoding.uncompressed => BuBytes(_toUncompressed()),
    };
  }

  /// check identity
  @override
  bool isIdentity() {
    return infinity;
  }

  @override
  G1AffinePoint operator -() {
    return G1AffinePoint(
      x: x,
      y: Bls12Fp.conditionalSelect(-y, Bls12Fp.one, infinity),
      infinity: infinity,
    );
  }

  @override
  List<dynamic> get variables => [x, y, infinity];

  @override
  G1Projective double() {
    return toProjective().double();
  }
}
