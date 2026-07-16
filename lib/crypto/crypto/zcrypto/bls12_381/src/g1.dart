import 'package:blockchain_utils/bip/bip/types/types.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/bls12_381/src/core.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/bls12_381/src/fp.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/jubjub/fields/field.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/jubjub/fields/native.dart';
import 'package:blockchain_utils/crypto/crypto/exception/exception.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/numbers/src/u64.dart';
import 'package:blockchain_utils/utils/binary/utils.dart';
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

  /// Creates a G1 affine point from bytes without checking curve or subgroup validity.
  factory G1Projective.fromBytesUnchecked(List<int> bytes) {
    return G1Projective.fromAffine(G1AffinePoint.fromBytesUnchecked(bytes));
  }

  G1Projective _multiply(List<int> by) {
    assert(by.length == 32);
    G1Projective acc = G1Projective.identity;
    final bits = BytesUtils.bytesToBits(by); // length = 256
    final iterableBits = bits.reversed.skip(1);
    for (final bit in iterableBits) {
      acc = acc.double();
      acc = G1Projective.conditionalSelect(acc, (acc + this), bit);
    }
    return acc;
  }

  /// Multiply this point by `BLS_X` using double-and-add
  G1Projective mulByX() {
    G1Projective result = G1Projective.identity;

    BigInt x = BigInt.parse("0xd201000000010000") >> 1; // skip the first bit
    G1Projective tmp = this;

    while (x != BigInt.zero) {
      tmp = tmp.double();

      if ((x & BigInt.one) == BigInt.one) {
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
        throw CryptoException.operationNotSupported;
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
        Bls12Fp t0 = x * rhs.x;
        Bls12Fp t1 = y * rhs.y;
        Bls12Fp t3 = rhs.x + rhs.y;
        Bls12Fp t4 = x + y;
        t3 = t3 * t4;
        t4 = t0 + t1;
        t3 = t3 - t4;
        t4 = rhs.y * z;
        t4 = t4 + y;
        Bls12Fp y3 = rhs.x * z;
        y3 = y3 + x;
        Bls12Fp x3 = t0 + t0;
        t0 = x3 + t0;
        Bls12Fp t2 = mulBy3b(z);
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
        final tmp = G1Projective(x: x3, y: y3, z: z3);
        return G1Projective.conditionalSelect(tmp, this, rhs.isIdentity());
    }

    throw CryptoException.operationNotSupported;
  }

  @override
  G1Projective operator -() {
    return G1Projective(x: x, y: -y, z: z);
  }

  /// Serializes the point to bytes in either compressed or uncompressed form.
  @override
  List<int> toBytes({PubKeyModes mode = PubKeyModes.compressed}) {
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

/// BLS12-381 G1 group in projective coordinates (x : y : z).
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
      throw ArgumentException.invalidOperationArguments(
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
      throw ArgumentException.invalidOperationArguments(
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
      throw ArgumentException.invalidOperationArguments(
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
    throw ArgumentException.invalidOperationArguments(
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
    throw ArgumentException.invalidOperationArguments(
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
        throw CryptoException.operationNotSupported;
    }
  }

  @override
  G1Projective operator +(Bls12Point<G1Projective> rhs) {
    switch (rhs) {
      case final G1Projective rhs:
        return rhs + this;
      default:
        throw CryptoException.operationNotSupported;
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
  List<int> toBytes({PubKeyModes mode = PubKeyModes.compressed}) {
    return switch (mode) {
      PubKeyModes.compressed => _toCompressed(),
      PubKeyModes.uncompressed => _toUncompressed(),
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

/// BLS12-381 G1 group in projective coordinates (x : y : z).
class G1NativeProjective extends Bls12NativePoint<G1NativeProjective> {
  final Bls12NativeFp x;
  final Bls12NativeFp y;
  final Bls12NativeFp z;
  G1NativeProjective({required this.x, required this.y, required this.z});
  G1NativeProjective copyWith({
    Bls12NativeFp? x,
    Bls12NativeFp? y,
    Bls12NativeFp? z,
  }) => G1NativeProjective(x: x ?? this.x, y: y ?? this.y, z: z ?? this.z);

  factory G1NativeProjective.conditionalSelect(
    G1NativeProjective a,
    G1NativeProjective b,
    bool choice,
  ) {
    return G1NativeProjective(
      x: Bls12NativeFp.conditionalSelect(a.x, b.x, choice),
      y: Bls12NativeFp.conditionalSelect(a.y, b.y, choice),
      z: Bls12NativeFp.conditionalSelect(a.z, b.z, choice),
    );
  }

  factory G1NativeProjective.identity() => G1NativeProjective(
    x: Bls12NativeFp.zero(),
    y: Bls12NativeFp.one(),
    z: Bls12NativeFp.zero(),
  );
  factory G1NativeProjective.generator() => G1NativeProjective(
    x: Bls12NativeFp.nP(
      BigInt.parse(
        "3685416753713387016781088315183077757961620795782546409894578378688607592378376318836054947676345821548104185464507",
      ),
    ),
    y: Bls12NativeFp.nP(
      BigInt.parse(
        "1339506544944476473020471379941921221584933875938349620426543736416511423956333506472724655353366534992391756441569",
      ),
    ),
    z: Bls12NativeFp.one(),
  );

  factory G1NativeProjective.fromAffine(G1NativeAffinePoint affine) {
    return G1NativeProjective(
      x: affine.x,
      y: affine.y,
      z: Bls12NativeFp.conditionalSelect(
        Bls12NativeFp.one(),
        Bls12NativeFp.zero(),
        affine.infinity,
      ),
    );
  }

  /// Creates a G1 affine point from bytes, validating that it is on-curve and in the correct subgroup.
  factory G1NativeProjective.fromBytes(List<int> bytes) {
    return G1NativeProjective.fromAffine(G1NativeAffinePoint.fromBytes(bytes));
  }

  /// Creates a G1 point from bytes without checking curve or subgroup validity.
  factory G1NativeProjective.fromBytesUnchecked(List<int> bytes) {
    return G1NativeProjective.fromAffine(
      G1NativeAffinePoint.fromBytesUnchecked(bytes),
    );
  }

  G1NativeProjective _multiply(List<int> by) {
    assert(by.length == 32);
    G1NativeProjective acc = G1NativeProjective.identity();
    final bits = BytesUtils.bytesToBits(by); // length = 256
    final iterableBits = bits.reversed.skip(1);
    for (final bit in iterableBits) {
      acc = acc.double();
      acc = G1NativeProjective.conditionalSelect(acc, (acc + this), bit);
    }
    return acc;
  }

  /// Multiply this point by `BLS_X` using double-and-add
  G1NativeProjective mulByX() {
    G1NativeProjective result = G1NativeProjective.identity();

    BigInt x = BigInt.parse("0xd201000000010000") >> 1; // skip the first bit
    G1NativeProjective tmp = this;

    while (x != BigInt.zero) {
      tmp = tmp.double();

      if ((x & BigInt.one) == BigInt.one) {
        result = result + tmp;
      }
      x >>= 1;
    }
    return -result;
  }

  /// Clears the G1 cofactor by subtracting [mulByX] from the point.
  G1NativeProjective clearCofactor() => this - mulByX();

  Bls12NativeFp mulBy3b(Bls12NativeFp a) {
    a = a + a;
    a = a + a;
    return a + a + a;
  }

  @override
  G1NativeProjective double() {
    Bls12NativeFp t0 = y.square();
    Bls12NativeFp z3 = t0 + t0;
    z3 = z3 + z3;
    z3 = z3 + z3;
    Bls12NativeFp t1 = y * z;
    Bls12NativeFp t2 = z.square();
    t2 = mulBy3b(t2);
    Bls12NativeFp x3 = t2 * z3;
    Bls12NativeFp y3 = t0 + t2;
    z3 = t1 * z3;
    t1 = t2 + t2;
    t2 = t1 + t2;
    t0 = t0 - t2;
    y3 = t0 * y3;
    y3 = x3 + y3;
    t1 = x * y;
    x3 = t0 * t1;
    x3 = x3 + x3;
    return G1NativeProjective(x: x3, y: y3, z: z3);
  }

  @override
  G1NativeProjective operator *(JubJubNativeFq rhs) {
    return _multiply(rhs.toBytes());
  }

  G1NativeProjective operator -(Bls12NativePoint<G1NativeProjective> rhs) {
    switch (rhs) {
      case final G1NativeProjective rhs:
        return this + (-rhs);
      case final G1NativeAffinePoint rhs:
        return this + (-rhs);
      default:
        throw CryptoException.operationNotSupported;
    }
  }

  @override
  G1NativeProjective operator +(Bls12NativePoint<G1NativeProjective> rhs) {
    switch (rhs) {
      case final G1NativeProjective rhs:
        Bls12NativeFp t0 = x * rhs.x;
        Bls12NativeFp t1 = y * rhs.y;
        Bls12NativeFp t2 = z * rhs.z;
        Bls12NativeFp t3 = x + y;
        Bls12NativeFp t4 = rhs.x + rhs.y;
        t3 = t3 * t4;
        t4 = t0 + t1;
        t3 = t3 - t4;
        t4 = y + z;
        Bls12NativeFp x3 = rhs.y + rhs.z;
        t4 = t4 * x3;
        x3 = t1 + t2;
        t4 = t4 - x3;
        x3 = x + z;
        Bls12NativeFp y3 = rhs.x + rhs.z;
        x3 = x3 * y3;
        y3 = t0 + t2;
        y3 = x3 - y3;
        x3 = t0 + t0;
        t0 = x3 + t0;
        t2 = mulBy3b(t2);
        Bls12NativeFp z3 = t1 + t2;
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
        return G1NativeProjective(x: x3, y: y3, z: z3);
      case final G1NativeAffinePoint rhs:
        Bls12NativeFp t0 = x * rhs.x;
        Bls12NativeFp t1 = y * rhs.y;
        Bls12NativeFp t3 = rhs.x + rhs.y;
        Bls12NativeFp t4 = x + y;
        t3 = t3 * t4;
        t4 = t0 + t1;
        t3 = t3 - t4;
        t4 = rhs.y * z;
        t4 = t4 + y;
        Bls12NativeFp y3 = rhs.x * z;
        y3 = y3 + x;
        Bls12NativeFp x3 = t0 + t0;
        t0 = x3 + t0;
        Bls12NativeFp t2 = mulBy3b(z);
        Bls12NativeFp z3 = t1 + t2;
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
        final tmp = G1NativeProjective(x: x3, y: y3, z: z3);
        return G1NativeProjective.conditionalSelect(
          tmp,
          this,
          rhs.isIdentity(),
        );
    }

    throw CryptoException.operationNotSupported;
  }

  /// Serializes the point to bytes in either compressed or uncompressed form.
  @override
  List<int> toBytes({PubKeyModes mode = PubKeyModes.compressed}) {
    return toAffine().toBytes(mode: mode);
  }

  @override
  G1NativeProjective operator -() {
    return G1NativeProjective(x: x, y: -y, z: z);
  }

  /// check identity
  @override
  bool isIdentity() {
    return z.isZero();
  }

  /// Checks whether the point satisfies the BLS12-381 curve equation in projective form.
  bool isOnCurve() {
    // Y^2 * Z = X^3 + b * Z^3
    return (y.square() * z) ==
            (x.square() * x + z.square() * z * Bls12NativeFp.b()) ||
        z.isZero();
  }

  G1NativeAffinePoint toAffine() {
    final zinv = z.invert() ?? Bls12NativeFp.zero();
    final x = this.x * zinv;
    final y = this.y * zinv;
    final tmp = G1NativeAffinePoint(x: x, y: y, infinity: false);
    return G1NativeAffinePoint.conditionalSelect(
      tmp,
      G1NativeAffinePoint.identity(),
      zinv.isZero(),
    );
  }

  @override
  operator ==(other) {
    if (other is! G1NativeProjective) return false;
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

/// BLS12-381 G1 group in projective coordinates (x : y : z).
class G1NativeAffinePoint extends Bls12NativeAffinePoint<G1NativeProjective>
    with Equality {
  final Bls12NativeFp x;
  final Bls12NativeFp y;
  final bool infinity;
  G1NativeAffinePoint({
    required this.x,
    required this.y,
    required this.infinity,
  });
  factory G1NativeAffinePoint._fromUncompressedBytes(List<int> bytes) {
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
    final x = Bls12NativeFp.fromBytes(xBytes);
    final y = Bls12NativeFp.fromBytes(bytes.sublist(48));

    final p = G1NativeAffinePoint(x: x, y: y, infinity: infinityFlagSet);
    final isValid =
        ((!infinityFlagSet) | (infinityFlagSet & x.isZero() & y.isZero())) &
        (!compressionFlagSet) &
        (!sortFlagSet);
    if (!isValid) {
      throw ArgumentException.invalidOperationArguments(
        "fromUncompressedBytes",
        reason: "Invalid uncompressed bytes",
      );
    }
    return p;
  }
  factory G1NativeAffinePoint._fromCompressedBytes(List<int> bytes) {
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
    final x = Bls12NativeFp.fromBytes(xBytes);

    final infinity =
        infinityFlagSet & compressionFlagSet & (!sortFlagSet) & x.isZero();
    if (infinity) return G1NativeAffinePoint.identity();
    final l = ((x.square() * x) + Bls12NativeFp.b()).sqrt();
    if (!l.isSquare) {
      throw ArgumentException.invalidOperationArguments(
        "fromCompressedBytes",
        reason: "Invalid compressed bytes",
      );
    }
    final y = Bls12NativeFp.conditionalSelect(
      l.result,
      -l.result,
      l.result.lexicographicallyLargest() ^ sortFlagSet,
    );
    final isValid = (!infinityFlagSet) & compressionFlagSet;
    if (!isValid) {
      throw ArgumentException.invalidOperationArguments(
        "fromCompressedBytes",
        reason: "Invalid compressed bytes",
      );
    }
    return G1NativeAffinePoint(x: x, y: y, infinity: infinityFlagSet);
  }

  /// Creates a G1 affine point from bytes without checking curve or subgroup validity.
  factory G1NativeAffinePoint.fromBytesUnchecked(List<int> bytes) {
    if (bytes.length == 48) {
      return G1NativeAffinePoint._fromCompressedBytes(bytes);
    } else if (bytes.length == 96) {
      return G1NativeAffinePoint._fromUncompressedBytes(bytes);
    }
    throw ArgumentException.invalidOperationArguments(
      "fromBytes",
      reason: "Invalid point bytes length.",
    );
  }

  /// Creates a G1 affine point from bytes, validating that it is on-curve and in the correct subgroup.
  factory G1NativeAffinePoint.fromBytes(List<int> bytes, {bool check = true}) {
    final affine = G1NativeAffinePoint.fromBytesUnchecked(bytes);
    if (!check) return affine;
    if (affine.isOnCurve() && affine.isTorsionFree()) {
      return affine;
    }
    throw ArgumentException.invalidOperationArguments(
      "fromBytes",
      reason: "Invalid G1 encoding.",
    );
  }

  factory G1NativeAffinePoint.conditionalSelect(
    G1NativeAffinePoint a,
    G1NativeAffinePoint b,
    bool choice,
  ) {
    return G1NativeAffinePoint(
      x: Bls12NativeFp.conditionalSelect(a.x, b.x, choice),
      y: Bls12NativeFp.conditionalSelect(a.y, b.y, choice),
      infinity: IntUtils.ctSelectBool(a.infinity, b.infinity, choice),
    );
  }
  factory G1NativeAffinePoint.identity() => G1NativeAffinePoint(
    x: Bls12NativeFp.zero(),
    y: Bls12NativeFp.one(),
    infinity: true,
  );
  factory G1NativeAffinePoint.generator() => G1NativeAffinePoint(
    x: Bls12NativeFp.nP(
      BigInt.parse(
        "3685416753713387016781088315183077757961620795782546409894578378688607592378376318836054947676345821548104185464507",
      ),
    ),
    y: Bls12NativeFp.nP(
      BigInt.parse(
        "1339506544944476473020471379941921221584933875938349620426543736416511423956333506472724655353366534992391756441569",
      ),
    ),
    infinity: false,
  );

  factory G1NativeAffinePoint.fromProjective(G1NativeProjective p) {
    final zInv = p.z.invert() ?? Bls12NativeFp.zero();
    final x = p.x * zInv;
    final y = p.y * zInv;
    final tmp = G1NativeAffinePoint(x: x, y: y, infinity: false);
    return G1NativeAffinePoint.conditionalSelect(
      tmp,
      G1NativeAffinePoint.identity(),
      zInv.isZero(),
    );
  }

  @override
  G1NativeAffinePoint operator -() {
    return G1NativeAffinePoint(
      x: x,
      y: Bls12NativeFp.conditionalSelect(-y, Bls12NativeFp.one(), infinity),
      infinity: infinity,
    );
  }

  @override
  G1NativeProjective operator *(JubJubNativeFq rhs) {
    return toProjective()._multiply(rhs.toBytes());
  }

  G1NativeProjective operator -(Bls12NativePoint<G1NativeProjective> rhs) {
    switch (rhs) {
      case final G1NativeProjective rhs:
        return this + -rhs;
      default:
        throw CryptoException.operationNotSupported;
    }
  }

  @override
  G1NativeProjective operator +(Bls12NativePoint<G1NativeProjective> rhs) {
    switch (rhs) {
      case final G1NativeProjective rhs:
        return rhs + this;
      default:
        throw CryptoException.operationNotSupported;
    }
  }

  G1NativeAffinePoint _endomorphism() {
    return G1NativeAffinePoint(
      x: x * Bls12NativeFp.beta(),
      y: y,
      infinity: infinity,
    );
  }

  /// Converts this affine point to its projective representation.
  G1NativeProjective toProjective() => G1NativeProjective.fromAffine(this);

  /// Checks whether the point is in the correct G1 subgroup (torsion-free).
  bool isTorsionFree() {
    final minusX = -G1NativeProjective.fromAffine(this).mulByX().mulByX();
    final endomorphismP = _endomorphism();
    return minusX == endomorphismP.toProjective();
  }

  /// Checks whether the point satisfies the BLS12-381 curve equation in projective form.
  bool isOnCurve() {
    if (infinity) return true;
    return (y.square() - (x.square() * x)) == Bls12NativeFp.b();
  }

  List<int> _toCompressed() {
    final res =
        Bls12NativeFp.conditionalSelect(
          x,
          Bls12NativeFp.zero(),
          infinity,
        ).toBytes();
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
      ...Bls12NativeFp.conditionalSelect(
        x,
        Bls12NativeFp.zero(),
        infinity,
      ).toBytes(),
      ...Bls12NativeFp.conditionalSelect(
        y,
        Bls12NativeFp.zero(),
        infinity,
      ).toBytes(),
    ];
    res[0] |= IntUtils.ctSelectInt(0, 1 << 6, infinity);
    return res;
  }

  /// Serializes the point to bytes in either compressed or uncompressed form.
  @override
  List<int> toBytes({PubKeyModes mode = PubKeyModes.compressed}) {
    return switch (mode) {
      PubKeyModes.compressed => _toCompressed(),
      PubKeyModes.uncompressed => _toUncompressed(),
    };
  }

  /// check identity
  @override
  bool isIdentity() {
    return infinity;
  }

  @override
  List<dynamic> get variables => [x, y, infinity];

  @override
  G1NativeProjective double() {
    return toProjective().double();
  }
}
