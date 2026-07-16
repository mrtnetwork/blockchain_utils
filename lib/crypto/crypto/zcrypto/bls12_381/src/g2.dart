import 'package:blockchain_utils/bip/bip/types/types.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/bls12_381/src/core.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/bls12_381/src/fp.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/bls12_381/src/fp2.dart';
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

/// BLS12-381 G2 group in projective coordinates (x : y : z) over GF(p²).
class G2Projective extends Bls12Point<G2Projective> {
  final Bls12Fp2 x;
  final Bls12Fp2 y;
  final Bls12Fp2 z;
  const G2Projective({required this.x, required this.y, required this.z});

  factory G2Projective.conditionalSelect(
    G2Projective a,
    G2Projective b,
    bool choice,
  ) {
    return G2Projective(
      x: Bls12Fp2.conditionalSelect(a.x, b.x, choice),
      y: Bls12Fp2.conditionalSelect(a.y, b.y, choice),
      z: Bls12Fp2.conditionalSelect(a.z, b.z, choice),
    );
  }

  /// identity element
  static const G2Projective identity = G2Projective(
    x: Bls12Fp2.zero,
    y: Bls12Fp2.one,
    z: Bls12Fp2.zero,
  );

  /// generator
  static const G2Projective generator = G2Projective(
    x: Bls12Fp2(
      c0: Bls12Fp.unsafe([
        Uint64.unsafe(4126314402, 43256336),
        Uint64.unsafe(3019242278, 2276759066),
        Uint64.unsafe(2712179637, 1042998656),
        Uint64.unsafe(2559875485, 440184553),
        Uint64.unsafe(1869068131, 409155179),
        Uint64.unsafe(92377490, 1129364695),
      ]),
      c1: Bls12Fp.unsafe([
        Uint64.unsafe(2779365493, 2653156870),
        Uint64.unsafe(2862663069, 3167576259),
        Uint64.unsafe(1001487896, 3800463366),
        Uint64.unsafe(454735564, 2235675495),
        Uint64.unsafe(3266768142, 4061496647),
        Uint64.unsafe(294791689, 1935732211),
      ]),
    ),
    y: Bls12Fp2(
      c0: Bls12Fp.unsafe([
        Uint64.unsafe(1282607864, 1615416394),
        Uint64.unsafe(1501362719, 1580637274),
        Uint64.unsafe(3890644332, 2852807514),
        Uint64.unsafe(3153049065, 1846364511),
        Uint64.unsafe(131311989, 4042204578),
        Uint64.unsafe(8650126, 2122373861),
      ]),
      c1: Bls12Fp.unsafe([
        Uint64.unsafe(2915105938, 3747917917),
        Uint64.unsafe(413804298, 722756060),
        Uint64.unsafe(2259528810, 1004858272),
        Uint64.unsafe(2034850894, 3376259898),
        Uint64.unsafe(3877066832, 2755447533),
        Uint64.unsafe(187417249, 1675500530),
      ]),
    ),
    z: Bls12Fp2.one,
  );

  factory G2Projective.fromAffine(G2AffinePoint affine) {
    return G2Projective(
      x: affine.x,
      y: affine.y,
      z: Bls12Fp2.conditionalSelect(
        Bls12Fp2.one,
        Bls12Fp2.zero,
        affine.infinity,
      ),
    );
  }

  /// Creates a G2 point from bytes, validating that it is on-curve and in the correct subgroup.
  factory G2Projective.fromBytes(List<int> bytes) {
    return G2Projective.fromAffine(G2AffinePoint.fromBytes(bytes));
  }

  /// Creates a G2 point from bytes without checking curve or subgroup validity.
  factory G2Projective.fromBytesUnchecked(List<int> bytes) {
    return G2Projective.fromAffine(G2AffinePoint.fromBytesUnchecked(bytes));
  }

  /// simple double-and-add implementation of point multiplication
  G2Projective multiply(List<int> by) {
    assert(by.length == 32);
    G2Projective acc = G2Projective.identity;
    final bits = BytesUtils.bytesToBits(by); // length = 256
    final iterableBits = bits.reversed.skip(1);
    for (final bit in iterableBits) {
      acc = acc.double();
      acc = G2Projective.conditionalSelect(acc, (acc + this), bit);
    }
    return acc;
  }

  /// Multiply by `BLS_X`, using double and add.
  G2Projective mulByX() {
    G2Projective result = G2Projective.identity;
    const blsx = Uint64.unsafe(3523280896, 65536);
    Uint64 x = blsx >> 1; // skip the first bit
    G2Projective tmp = this;

    while (x != Uint64.zero) {
      tmp = tmp.double();

      if ((x & Uint64.one) == Uint64.one) {
        result = result + tmp;
      }
      x >>= 1;
    }
    return -result;
  }

  G2Projective psi() {
    const coeffX = Bls12Fp2(
      c0: Bls12Fp.zero,
      c1: Bls12Fp.unsafe([
        Uint64.unsafe(2299382244, 2255832515),
        Uint64.unsafe(720577107, 847619541),
        Uint64.unsafe(1351092326, 815496748),
        Uint64.unsafe(2718768012, 2122846244),
        Uint64.unsafe(350548047, 3806040168),
        Uint64.unsafe(350580031, 358909242),
      ]),
    );
    // 1 / ((u+1) ^ (p-1)/2)
    const coeffY = Bls12Fp2(
      c0: Bls12Fp.unsafe([
        Uint64.unsafe(1043290205, 2774309585),
        Uint64.unsafe(1117004093, 2260828547),
        Uint64.unsafe(942163144, 2338469682),
        Uint64.unsafe(2460822269, 420494872),
        Uint64.unsafe(494489167, 2893869241),
        Uint64.unsafe(198546172, 2105695944),
      ]),
      c1: Bls12Fp.unsafe([
        Uint64.unsafe(2077206434, 1520635866),
        Uint64.unsafe(3692551873, 714243708),
        Uint64.unsafe(789089752, 1800322801),
        Uint64.unsafe(3519684743, 3665089703),
        Uint64.unsafe(765614438, 2530130973),
        Uint64.unsafe(237731565, 3153954770),
      ]),
    );
    return G2Projective(
      x: x.frobeniusMap() * coeffX,
      y: y.frobeniusMap() * coeffY,
      z: z.frobeniusMap(),
    );
  }

  G2Projective psi2() {
    // 1 / ((u+1) ^ ((q-1)/3))
    const coeffX = Bls12Fp2(
      c0: Bls12Fp.unsafe([
        Uint64.unsafe(3439577572, 2255614065),
        Uint64.unsafe(1571496518, 533571026),
        Uint64.unsafe(1483752111, 3548715925),
        Uint64.unsafe(2394295998, 29019038),
        Uint64.unsafe(66682222, 2211467474),
        Uint64.unsafe(418390117, 1415808833),
      ]),
      c1: Bls12Fp.zero,
    );

    return G2Projective(x: x * coeffX, y: -y, z: z);
  }

  /// Clears the G2 cofactor.
  G2Projective clearCofactor() {
    final t1 = mulByX();
    final t2 = psi();
    return double().psi2() + (t1 + t2).mulByX() - t1 - t2 - this;
  }

  Bls12Fp2 mulBy3b(Bls12Fp2 x) {
    return x * Bls12Fp2.b3();
  }

  @override
  G2Projective double() {
    Bls12Fp2 t0 = y.square();
    Bls12Fp2 z3 = t0 + t0;
    z3 = z3 + z3;
    z3 = z3 + z3;
    Bls12Fp2 t1 = y * z;
    Bls12Fp2 t2 = z.square();
    t2 = mulBy3b(t2);
    Bls12Fp2 x3 = t2 * z3;
    Bls12Fp2 y3 = t0 + t2;
    z3 = t1 * z3;
    t1 = t2 + t2;
    t2 = t1 + t2;
    t0 = t0 - t2;
    y3 = t0 * y3;
    y3 = x3 + y3;
    t1 = x * y;
    x3 = t0 * t1;
    x3 = x3 + x3;
    return G2Projective(x: x3, y: y3, z: z3);
  }

  @override
  G2Projective operator *(JubJubFq rhs) {
    return multiply(rhs.toBytes());
  }

  G2Projective operator -(Bls12Point<G2Projective> rhs) {
    switch (rhs) {
      case final G2Projective rhs:
        return this + (-rhs);
      case final G2AffinePoint rhs:
        return this + (-rhs);
      default:
        throw CryptoException.operationNotSupported;
    }
  }

  @override
  G2Projective operator +(Bls12Point<G2Projective> rhs) {
    switch (rhs) {
      case final G2Projective rhs:
        Bls12Fp2 t0 = x * rhs.x;
        Bls12Fp2 t1 = y * rhs.y;
        Bls12Fp2 t2 = z * rhs.z;
        Bls12Fp2 t3 = x + y;
        Bls12Fp2 t4 = rhs.x + rhs.y;
        t3 = t3 * t4;
        t4 = t0 + t1;
        t3 = t3 - t4;
        t4 = y + z;
        Bls12Fp2 x3 = rhs.y + rhs.z;
        t4 = t4 * x3;
        x3 = t1 + t2;
        t4 = t4 - x3;
        x3 = x + z;
        Bls12Fp2 y3 = rhs.x + rhs.z;
        x3 = x3 * y3;
        y3 = t0 + t2;
        y3 = x3 - y3;
        x3 = t0 + t0;
        t0 = x3 + t0;
        t2 = mulBy3b(t2);
        Bls12Fp2 z3 = t1 + t2;
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
        return G2Projective(x: x3, y: y3, z: z3);
      case final G2AffinePoint rhs:
        Bls12Fp2 t0 = x * rhs.x;
        Bls12Fp2 t1 = y * rhs.y;
        Bls12Fp2 t3 = rhs.x + rhs.y;
        Bls12Fp2 t4 = x + y;
        t3 = t3 * t4;
        t4 = t0 + t1;
        t3 = t3 - t4;
        t4 = rhs.y * z;
        t4 = t4 + y;
        Bls12Fp2 y3 = rhs.x * z;
        y3 = y3 + x;
        Bls12Fp2 x3 = t0 + t0;
        t0 = x3 + t0;
        Bls12Fp2 t2 = mulBy3b(z);
        Bls12Fp2 z3 = t1 + t2;
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
        final tmp = G2Projective(x: x3, y: y3, z: z3);
        return G2Projective.conditionalSelect(tmp, this, rhs.infinity);
    }

    throw CryptoException.operationNotSupported;
  }

  /// Serializes the point to bytes in either compressed or uncompressed form.
  @override
  List<int> toBytes({PubKeyModes mode = PubKeyModes.compressed}) {
    return toAffine().toBytes(mode: mode);
  }

  @override
  G2Projective operator -() {
    return G2Projective(x: x, y: -y, z: z);
  }

  /// check identity
  @override
  bool isIdentity() {
    return z.isZero();
  }

  /// Checks whether the point satisfies the BLS12-381 curve equation in projective form.
  bool isOnCurve() {
    // Y^2 * Z = X^3 + b * Z^3
    return (y.square() * z) == (x.square() * x + z.square() * z * Bls12Fp2.b) ||
        z.isZero();
  }

  G2AffinePoint toAffine() {
    final zinv = z.invert() ?? Bls12Fp2.zero;
    final x = this.x * zinv;
    final y = this.y * zinv;
    final tmp = G2AffinePoint(x: x, y: y, infinity: false);
    return G2AffinePoint.conditionalSelect(
      tmp,
      G2AffinePoint.identity,
      zinv.isZero(),
    );
  }

  @override
  operator ==(other) {
    if (other is! G2Projective) return false;
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

/// BLS12-381 G2 group afiine in projective coordinates (x : y : z) over GF(p²).
class G2AffinePoint extends Bls12AffinePoint<G2Projective> with Equality {
  final Bls12Fp2 x;
  final Bls12Fp2 y;
  final bool infinity;
  const G2AffinePoint({
    required this.x,
    required this.y,
    required this.infinity,
  });
  factory G2AffinePoint._fromUncompressedBytes(List<int> bytes) {
    bytes = bytes.exc(
      length: 192,
      operation: "fromUncompressedBytes",
      reason: "Invalid uncompressed bytes length.",
    );
    // Extract flags
    final compressionFlagSet = ((bytes[0] >> 7) & 1) == 1;
    final infinityFlagSet = ((bytes[0] >> 6) & 1) == 1;
    final sortFlagSet = ((bytes[0] >> 5) & 1) == 1;

    // ---- Parse x-coordinate ----
    final xc1Bytes = List<int>.from(bytes.sublist(0, 48));
    xc1Bytes[0] &= 31; // mask flags

    final xc0Bytes = bytes.sublist(48, 96);

    final xc1 = Bls12Fp.fromBytes(xc1Bytes);
    final xc0 = Bls12Fp.fromBytes(xc0Bytes);

    // ---- Parse y-coordinate ----
    final yc1Bytes = bytes.sublist(96, 144);
    final yc0Bytes = bytes.sublist(144, 192);

    final yc1 = Bls12Fp.fromBytes(yc1Bytes);
    final yc0 = Bls12Fp.fromBytes(yc0Bytes);

    // Construct Fp2 elements
    final x = Bls12Fp2(c0: xc0, c1: xc1);
    final y = Bls12Fp2(c0: yc0, c1: yc1);

    // conditional_select(identity, p, infinity)
    final p =
        infinityFlagSet
            ? G2AffinePoint.identity
            : G2AffinePoint(x: x, y: y, infinity: false);

    // Validity checks (bitwise logic, not short-circuit)
    final isValid =
        ((!infinityFlagSet) | (infinityFlagSet & x.isZero() & y.isZero())) &
        (!compressionFlagSet) &
        (!sortFlagSet);

    if (!isValid) {
      throw ArgumentException.invalidOperationArguments(
        "_fromUncompressedBytes",
        reason: 'Invalid uncompressed G2 encoding',
      );
    }

    return p;
  }

  factory G2AffinePoint._fromCompressedBytes(List<int> bytes) {
    bytes = bytes.exc(
      length: 96,
      operation: "fromCompressedBytes",
      reason: "Invalid compressed bytes length.",
    );
    // ---- Extract flags ----
    final compressionFlagSet = ((bytes[0] >> 7) & 1) == 1;
    final infinityFlagSet = ((bytes[0] >> 6) & 1) == 1;
    final sortFlagSet = ((bytes[0] >> 5) & 1) == 1;

    // ---- Parse x-coordinate ----
    final xc1Bytes = List<int>.from(bytes.sublist(0, 48));
    xc1Bytes[0] &= 31; // mask flag bits

    final xc0Bytes = bytes.sublist(48, 96);

    final xc1 = Bls12Fp.fromBytes(xc1Bytes);
    final xc0 = Bls12Fp.fromBytes(xc0Bytes);

    final x = Bls12Fp2(c0: xc0, c1: xc1);

    // ---- Infinity case ----
    final infinityValid =
        infinityFlagSet & compressionFlagSet & (!sortFlagSet) & x.isZero();

    if (infinityValid) {
      return G2AffinePoint.identity;
    }

    // ---- Recover y from x ----
    // y^2 = x^3 + B
    final rhs = (x.square() * x) + Bls12Fp2.b;
    final yOpt = rhs.sqrt();

    if (!yOpt.isSquare) {
      throw ArgumentException.invalidOperationArguments(
        "_fromCompressedBytes",
        reason: 'Invalid compressed G2 encoding.',
      );
    }

    var y = yOpt.result;

    // Select correct y based on sort flag
    final flip = y.lexicographicallyLargest() ^ sortFlagSet;
    if (flip) {
      y = -y;
    }

    // ---- Final validity checks ----
    final isValid = (!infinityFlagSet) & compressionFlagSet;

    if (!isValid) {
      throw ArgumentException.invalidOperationArguments(
        "_fromCompressedBytes",
        reason: 'Invalid compressed G2 encoding',
      );
    }

    return G2AffinePoint(x: x, y: y, infinity: false);
  }

  /// Creates a G2 affine point from bytes, validating that it is on-curve and in the correct subgroup.
  factory G2AffinePoint.fromBytes(List<int> bytes) {
    final affine = G2AffinePoint.fromBytesUnchecked(bytes);
    if (affine.isOnCurve() && affine.isTorsionFree()) {
      return affine;
    }
    throw ArgumentException.invalidOperationArguments(
      "fromBytes",
      reason: "Invalid G2 encoding.",
    );
  }

  /// Creates a G2 affine point from bytes without checking curve or subgroup validity.
  factory G2AffinePoint.fromBytesUnchecked(List<int> bytes) {
    if (bytes.length == 48) {
      return G2AffinePoint._fromCompressedBytes(bytes);
    } else if (bytes.length == 96) {
      return G2AffinePoint._fromUncompressedBytes(bytes);
    }
    throw ArgumentException.invalidOperationArguments(
      "fromBytes",
      reason: "Invalid point bytes length.",
    );
  }

  factory G2AffinePoint.conditionalSelect(
    G2AffinePoint a,
    G2AffinePoint b,
    bool choice,
  ) {
    return G2AffinePoint(
      x: Bls12Fp2.conditionalSelect(a.x, b.x, choice),
      y: Bls12Fp2.conditionalSelect(a.y, b.y, choice),
      infinity: IntUtils.ctSelectBool(a.infinity, b.infinity, choice),
    );
  }

  /// identity element
  static const G2AffinePoint identity = G2AffinePoint(
    x: Bls12Fp2.zero,
    y: Bls12Fp2.one,
    infinity: true,
  );

  /// generator
  static const G2AffinePoint generator = G2AffinePoint(
    x: Bls12Fp2(
      c0: Bls12Fp.unsafe([
        Uint64.unsafe(4126314402, 43256336),
        Uint64.unsafe(3019242278, 2276759066),
        Uint64.unsafe(2712179637, 1042998656),
        Uint64.unsafe(2559875485, 440184553),
        Uint64.unsafe(1869068131, 409155179),
        Uint64.unsafe(92377490, 1129364695),
      ]),
      c1: Bls12Fp.unsafe([
        Uint64.unsafe(2779365493, 2653156870),
        Uint64.unsafe(2862663069, 3167576259),
        Uint64.unsafe(1001487896, 3800463366),
        Uint64.unsafe(454735564, 2235675495),
        Uint64.unsafe(3266768142, 4061496647),
        Uint64.unsafe(294791689, 1935732211),
      ]),
    ),
    y: Bls12Fp2(
      c0: Bls12Fp.unsafe([
        Uint64.unsafe(1282607864, 1615416394),
        Uint64.unsafe(1501362719, 1580637274),
        Uint64.unsafe(3890644332, 2852807514),
        Uint64.unsafe(3153049065, 1846364511),
        Uint64.unsafe(131311989, 4042204578),
        Uint64.unsafe(8650126, 2122373861),
      ]),
      c1: Bls12Fp.unsafe([
        Uint64.unsafe(2915105938, 3747917917),
        Uint64.unsafe(413804298, 722756060),
        Uint64.unsafe(2259528810, 1004858272),
        Uint64.unsafe(2034850894, 3376259898),
        Uint64.unsafe(3877066832, 2755447533),
        Uint64.unsafe(187417249, 1675500530),
      ]),
    ),
    infinity: false,
  );

  factory G2AffinePoint.fromProjective(G2Projective p) {
    final zInv = p.z.invert() ?? Bls12Fp2.zero;
    final x = p.x * zInv;
    final y = p.y * zInv;
    final tmp = G2AffinePoint(x: x, y: y, infinity: false);
    return G2AffinePoint.conditionalSelect(
      tmp,
      G2AffinePoint.identity,
      zInv.isZero(),
    );
  }

  @override
  G2Projective operator *(JubJubFq rhs) {
    return toProjective().multiply(rhs.toBytes());
  }

  G2Projective operator -(Bls12Point<G2Projective> rhs) {
    switch (rhs) {
      case final G2Projective rhs:
        return this + -rhs;
      default:
        throw CryptoException.operationNotSupported;
    }
  }

  @override
  G2Projective operator +(Bls12Point<G2Projective> rhs) {
    switch (rhs) {
      case final G2Projective rhs:
        return rhs + this;
      default:
        throw CryptoException.operationNotSupported;
    }
  }

  G2Projective toProjective() => G2Projective.fromAffine(this);

  bool isTorsionFree() {
    final p = toProjective();
    return p.psi() == p.mulByX();
  }

  /// Checks whether the point satisfies the BLS12-381 curve equation in projective form.
  bool isOnCurve() {
    if (infinity) return true;
    return (y.square() - (x.square() * x)) == Bls12Fp2.b;
  }

  List<int> toCompressed() {
    // conditional_select(&self.x, &Fp2::zero(), self.infinity)
    final Bls12Fp2 xc = Bls12Fp2.conditionalSelect(x, Bls12Fp2.zero, infinity);

    // Allocate 96 bytes explicitly
    final res = List<int>.filled(96, 0);

    // Rust:
    // res[0..48]  = x.c1
    // res[48..96] = x.c0
    final c1 = xc.c1.toBytes(); // 48 bytes
    final c0 = xc.c0.toBytes(); // 48 bytes

    for (var i = 0; i < 48; i++) {
      res[i] = c1[i];
      res[i + 48] = c0[i];
    }

    // Set compressed flag (MSB)
    res[0] |= 1 << 7;

    // Set infinity flag (2nd MSB)
    res[0] |= IntUtils.ctSelectInt(0, 1 << 6, infinity);

    // Set lexicographically largest Y flag (3rd MSB),
    // but only if not infinity
    res[0] |= IntUtils.ctSelectInt(
      0,
      1 << 5,
      (!infinity) & y.lexicographicallyLargest(),
    );

    return res;
  }

  List<int> toUncompressed() {
    // Allocate 192 bytes
    final res = List<int>.filled(192, 0);

    // conditional_select(&self.x, &Fp2::zero(), self.infinity)
    final Bls12Fp2 xc = Bls12Fp2.conditionalSelect(x, Bls12Fp2.zero, infinity);

    final Bls12Fp2 yc = Bls12Fp2.conditionalSelect(y, Bls12Fp2.zero, infinity);

    // x = c1 || c0
    final xc1 = xc.c1.toBytes(); // 48 bytes
    final xc0 = xc.c0.toBytes(); // 48 bytes

    // y = c1 || c0
    final yc1 = yc.c1.toBytes(); // 48 bytes
    final yc0 = yc.c0.toBytes(); // 48 bytes

    for (var i = 0; i < 48; i++) {
      res[i] = xc1[i];
      res[i + 48] = xc0[i];
      res[i + 96] = yc1[i];
      res[i + 144] = yc0[i];
    }

    // Is this point at infinity? If so, set the second-most significant bit.
    res[0] |= IntUtils.ctSelectInt(0, 1 << 6, infinity);

    return res;
  }

  /// Serializes the point to bytes in either compressed or uncompressed form.
  @override
  List<int> toBytes({PubKeyModes mode = PubKeyModes.compressed}) {
    return switch (mode) {
      PubKeyModes.compressed => toCompressed(),
      PubKeyModes.uncompressed => toUncompressed(),
    };
  }

  /// check identity
  @override
  bool isIdentity() {
    return infinity;
  }

  @override
  G2AffinePoint operator -() {
    return G2AffinePoint(
      x: x,
      y: Bls12Fp2.conditionalSelect(-y, Bls12Fp2.one, infinity),
      infinity: infinity,
    );
  }

  @override
  List<dynamic> get variables => [x, y, infinity];

  @override
  G2Projective double() {
    return toProjective().double();
  }
}

/// BLS12-381 G2 group in projective coordinates (x : y : z) over GF(p²).
class G2NativeProjective extends Bls12NativePoint<G2NativeProjective> {
  final Bls12NativeFp2 x;
  final Bls12NativeFp2 y;
  final Bls12NativeFp2 z;
  G2NativeProjective({required this.x, required this.y, required this.z});

  G2NativeProjective copyWith({
    Bls12NativeFp2? x,
    Bls12NativeFp2? y,
    Bls12NativeFp2? z,
  }) {
    return G2NativeProjective(x: x ?? this.x, y: y ?? this.y, z: z ?? this.z);
  }

  factory G2NativeProjective.conditionalSelect(
    G2NativeProjective a,
    G2NativeProjective b,
    bool choice,
  ) {
    return G2NativeProjective(
      x: Bls12NativeFp2.conditionalSelect(a.x, b.x, choice),
      y: Bls12NativeFp2.conditionalSelect(a.y, b.y, choice),
      z: Bls12NativeFp2.conditionalSelect(a.z, b.z, choice),
    );
  }
  static final _identity = G2NativeProjective(
    x: Bls12NativeFp2.zero(),
    y: Bls12NativeFp2.one(),
    z: Bls12NativeFp2.zero(),
  );

  /// identity element
  factory G2NativeProjective.identity() => _identity;

  /// generator
  factory G2NativeProjective.generator() => G2NativeProjective(
    x: Bls12NativeFp2(
      c0: Bls12NativeFp.nP(
        BigInt.parse(
          "352701069587466618187139116011060144890029952792775240219908644239793785735715026873347600343865175952761926303160",
        ),
      ),
      c1: Bls12NativeFp.nP(
        BigInt.parse(
          "3059144344244213709971259814753781636986470325476647558659373206291635324768958432433509563104347017837885763365758",
        ),
      ),
    ),
    y: Bls12NativeFp2(
      c0: Bls12NativeFp.nP(
        BigInt.parse(
          "1985150602287291935568054521177171638300868978215655730859378665066344726373823718423869104263333984641494340347905",
        ),
      ),
      c1: Bls12NativeFp.nP(
        BigInt.parse(
          "927553665492332455747201965776037880757740193453592970025027978793976877002675564980949289727957565575433344219582",
        ),
      ),
    ),
    z: Bls12NativeFp2.one(),
  );

  factory G2NativeProjective.fromAffine(G2NativeAffinePoint affine) {
    return G2NativeProjective(
      x: affine.x,
      y: affine.y,
      z: Bls12NativeFp2.conditionalSelect(
        Bls12NativeFp2.one(),
        Bls12NativeFp2.zero(),
        affine.infinity,
      ),
    );
  }

  /// Creates a G2 point from bytes, validating that it is on-curve and in the correct subgroup.
  factory G2NativeProjective.fromBytes(List<int> bytes) {
    return G2NativeProjective.fromAffine(G2NativeAffinePoint.fromBytes(bytes));
  }

  /// Creates a G2 point from bytes without checking curve or subgroup validity.
  factory G2NativeProjective.fromBytesUnchecked(List<int> bytes) {
    return G2NativeProjective.fromAffine(
      G2NativeAffinePoint.fromBytesUnchecked(bytes),
    );
  }

  /// simple double-and-add implementation of point multiplication
  G2NativeProjective multiply(List<int> by) {
    assert(by.length == 32);
    G2NativeProjective acc = G2NativeProjective.identity();
    final bits = BytesUtils.bytesToBits(by); // length = 256
    final iterableBits = bits.reversed.skip(1);
    for (final bit in iterableBits) {
      acc = acc.double();
      acc = G2NativeProjective.conditionalSelect(acc, (acc + this), bit);
    }
    return acc;
  }

  /// Multiply by `BLS_X`, using double and add.
  G2NativeProjective mulByX() {
    G2NativeProjective result = G2NativeProjective.identity();

    BigInt x = BigInt.parse("0xd201000000010000") >> 1; // skip the first bit
    G2NativeProjective tmp = this;

    while (x != BigInt.zero) {
      tmp = tmp.double();

      if ((x & BigInt.one) == BigInt.one) {
        result = result + tmp;
      }
      x >>= 1;
    }
    return -result;
  }

  G2NativeProjective psi() {
    // 1 / ((u+1) ^ ((q-1)/3))
    final coeffX = Bls12NativeFp2(
      c0: Bls12NativeFp.zero(),
      c1: Bls12NativeFp.nP(
        BigInt.parse(
          "4002409555221667392624310435006688643935503118305586438271171395842971157480381377015405980053539358417135540939437",
        ),
      ),
    );
    // 1 / ((u+1) ^ (p-1)/2)
    final coeffY = Bls12NativeFp2(
      c0: Bls12NativeFp.nP(
        BigInt.parse(
          "2973677408986561043442465346520108879172042883009249989176415018091420807192182638567116318576472649347015917690530",
        ),
      ),
      c1: Bls12NativeFp.nP(
        BigInt.parse(
          "1028732146235106349975324479215795277384839936929757896155643118032610843298655225875571310552543014690878354869257",
        ),
      ),
    );
    return G2NativeProjective(
      x: x.frobeniusMap() * coeffX,
      y: y.frobeniusMap() * coeffY,
      z: z.frobeniusMap(),
    );
  }

  G2NativeProjective psi2() {
    // 1 / ((u+1) ^ ((q-1)/3))
    final coeffX = Bls12NativeFp2(
      c0: Bls12NativeFp.nP(
        BigInt.parse(
          "4002409555221667392624310435006688643935503118305586438271171395842971157480381377015405980053539358417135540939436",
        ),
      ),
      c1: Bls12NativeFp.zero(),
    );

    return G2NativeProjective(x: x * coeffX, y: -y, z: z);
  }

  /// Clears the G2 cofactor.
  G2NativeProjective clearCofactor() {
    final t1 = mulByX();
    final t2 = psi();
    return double().psi2() + (t1 + t2).mulByX() - t1 - t2 - this;
  }

  Bls12NativeFp2 mulBy3b(Bls12NativeFp2 x) {
    return x * Bls12NativeFp2.b3();
  }

  @override
  G2NativeProjective double() {
    Bls12NativeFp2 t0 = y.square();
    Bls12NativeFp2 z3 = t0 + t0;
    z3 = z3 + z3;
    z3 = z3 + z3;
    Bls12NativeFp2 t1 = y * z;
    Bls12NativeFp2 t2 = z.square();
    t2 = mulBy3b(t2);
    Bls12NativeFp2 x3 = t2 * z3;
    Bls12NativeFp2 y3 = t0 + t2;
    z3 = t1 * z3;
    t1 = t2 + t2;
    t2 = t1 + t2;
    t0 = t0 - t2;
    y3 = t0 * y3;
    y3 = x3 + y3;
    t1 = x * y;
    x3 = t0 * t1;
    x3 = x3 + x3;
    return G2NativeProjective(x: x3, y: y3, z: z3);
  }

  @override
  G2NativeProjective operator *(JubJubNativeFq rhs) {
    return multiply(rhs.toBytes());
  }

  G2NativeProjective operator -(Bls12NativePoint<G2NativeProjective> rhs) {
    switch (rhs) {
      case final G2NativeProjective rhs:
        return this + (-rhs);
      case final G2NativeAffinePoint rhs:
        return this + (-rhs);
      default:
        throw CryptoException.operationNotSupported;
    }
  }

  @override
  G2NativeProjective operator +(Bls12NativePoint<G2NativeProjective> rhs) {
    switch (rhs) {
      case final G2NativeProjective rhs:
        Bls12NativeFp2 t0 = x * rhs.x;
        Bls12NativeFp2 t1 = y * rhs.y;
        Bls12NativeFp2 t2 = z * rhs.z;
        Bls12NativeFp2 t3 = x + y;
        Bls12NativeFp2 t4 = rhs.x + rhs.y;
        t3 = t3 * t4;
        t4 = t0 + t1;
        t3 = t3 - t4;
        t4 = y + z;
        Bls12NativeFp2 x3 = rhs.y + rhs.z;
        t4 = t4 * x3;
        x3 = t1 + t2;
        t4 = t4 - x3;
        x3 = x + z;
        Bls12NativeFp2 y3 = rhs.x + rhs.z;
        x3 = x3 * y3;
        y3 = t0 + t2;
        y3 = x3 - y3;
        x3 = t0 + t0;
        t0 = x3 + t0;
        t2 = mulBy3b(t2);
        Bls12NativeFp2 z3 = t1 + t2;
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
        return G2NativeProjective(x: x3, y: y3, z: z3);
      case final G2NativeAffinePoint rhs:
        Bls12NativeFp2 t0 = x * rhs.x;
        Bls12NativeFp2 t1 = y * rhs.y;
        Bls12NativeFp2 t3 = rhs.x + rhs.y;
        Bls12NativeFp2 t4 = x + y;
        t3 = t3 * t4;
        t4 = t0 + t1;
        t3 = t3 - t4;
        t4 = rhs.y * z;
        t4 = t4 + y;
        Bls12NativeFp2 y3 = rhs.x * z;
        y3 = y3 + x;
        Bls12NativeFp2 x3 = t0 + t0;
        t0 = x3 + t0;
        Bls12NativeFp2 t2 = mulBy3b(z);
        Bls12NativeFp2 z3 = t1 + t2;
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
        final tmp = G2NativeProjective(x: x3, y: y3, z: z3);
        return G2NativeProjective.conditionalSelect(tmp, this, rhs.infinity);
    }

    throw CryptoException.operationNotSupported;
  }

  /// Serializes the point to bytes in either compressed or uncompressed form.
  @override
  List<int> toBytes({PubKeyModes mode = PubKeyModes.compressed}) {
    return toAffine().toBytes(mode: mode);
  }

  @override
  G2NativeProjective operator -() {
    return G2NativeProjective(x: x, y: -y, z: z);
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
            (x.square() * x + z.square() * z * Bls12NativeFp2.b()) ||
        z.isZero();
  }

  G2NativeAffinePoint toAffine() {
    final zinv = z.invert() ?? Bls12NativeFp2.zero();
    final x = this.x * zinv;
    final y = this.y * zinv;
    final tmp = G2NativeAffinePoint(x: x, y: y, infinity: false);
    return G2NativeAffinePoint.conditionalSelect(
      tmp,
      G2NativeAffinePoint.identity(),
      zinv.isZero(),
    );
  }

  @override
  operator ==(other) {
    if (other is! G2NativeProjective) return false;
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

/// BLS12-381 G2 group affine in projective coordinates (x : y : z) over GF(p²).
class G2NativeAffinePoint extends Bls12NativeAffinePoint<G2NativeProjective>
    with Equality {
  final Bls12NativeFp2 x;
  final Bls12NativeFp2 y;
  final bool infinity;
  G2NativeAffinePoint({
    required this.x,
    required this.y,
    required this.infinity,
  });
  factory G2NativeAffinePoint._fromUncompressedBytes(List<int> bytes) {
    bytes = bytes.exc(
      length: 192,
      operation: "fromUncompressedBytes",
      reason: "Invalid uncompressed bytes length.",
    );
    // Extract flags
    final compressionFlagSet = ((bytes[0] >> 7) & 1) == 1;
    final infinityFlagSet = ((bytes[0] >> 6) & 1) == 1;
    final sortFlagSet = ((bytes[0] >> 5) & 1) == 1;

    // ---- Parse x-coordinate ----
    final xc1Bytes = List<int>.from(bytes.sublist(0, 48));
    xc1Bytes[0] &= 31; // mask flags

    final xc0Bytes = bytes.sublist(48, 96);

    final xc1 = Bls12NativeFp.fromBytes(xc1Bytes);
    final xc0 = Bls12NativeFp.fromBytes(xc0Bytes);

    // ---- Parse y-coordinate ----
    final yc1Bytes = bytes.sublist(96, 144);
    final yc0Bytes = bytes.sublist(144, 192);

    final yc1 = Bls12NativeFp.fromBytes(yc1Bytes);
    final yc0 = Bls12NativeFp.fromBytes(yc0Bytes);

    // Construct Fp2 elements
    final x = Bls12NativeFp2(c0: xc0, c1: xc1);
    final y = Bls12NativeFp2(c0: yc0, c1: yc1);

    // conditional_select(identity, p, infinity)
    final p =
        infinityFlagSet
            ? G2NativeAffinePoint.identity()
            : G2NativeAffinePoint(x: x, y: y, infinity: false);

    // Validity checks (bitwise logic, not short-circuit)
    final isValid =
        ((!infinityFlagSet) | (infinityFlagSet & x.isZero() & y.isZero())) &
        (!compressionFlagSet) &
        (!sortFlagSet);

    if (!isValid) {
      throw ArgumentException.invalidOperationArguments(
        "_fromUncompressedBytes",
        reason: 'Invalid uncompressed G2 encoding',
      );
    }

    return p;
  }

  factory G2NativeAffinePoint._fromCompressedBytes(List<int> bytes) {
    bytes = bytes.exc(
      length: 96,
      operation: "fromCompressedBytes",
      reason: "Invalid compressed bytes length.",
    );
    // ---- Extract flags ----
    final compressionFlagSet = ((bytes[0] >> 7) & 1) == 1;
    final infinityFlagSet = ((bytes[0] >> 6) & 1) == 1;
    final sortFlagSet = ((bytes[0] >> 5) & 1) == 1;

    // ---- Parse x-coordinate ----
    final xc1Bytes = List<int>.from(bytes.sublist(0, 48));
    xc1Bytes[0] &= 31; // mask flag bits

    final xc0Bytes = bytes.sublist(48, 96);

    final xc1 = Bls12NativeFp.fromBytes(xc1Bytes);
    final xc0 = Bls12NativeFp.fromBytes(xc0Bytes);

    final x = Bls12NativeFp2(c0: xc0, c1: xc1);

    // ---- Infinity case ----
    final infinityValid =
        infinityFlagSet & compressionFlagSet & (!sortFlagSet) & x.isZero();

    if (infinityValid) {
      return G2NativeAffinePoint.identity();
    }

    // ---- Recover y from x ----
    // y^2 = x^3 + B
    final rhs = (x.square() * x) + Bls12NativeFp2.b();
    final yOpt = rhs.sqrt();

    if (!yOpt.isSquare) {
      throw ArgumentException.invalidOperationArguments(
        "fromCompressedBytes",
        reason: 'Invalid compressed G2 encoding.',
      );
    }

    var y = yOpt.result;

    // Select correct y based on sort flag
    final flip = y.lexicographicallyLargest() ^ sortFlagSet;
    if (flip) {
      y = -y;
    }

    // ---- Final validity checks ----
    final isValid = (!infinityFlagSet) & compressionFlagSet;

    if (!isValid) {
      throw ArgumentException.invalidOperationArguments(
        "_fromCompressedBytes",
        reason: 'Invalid compressed G2 encoding',
      );
    }

    return G2NativeAffinePoint(x: x, y: y, infinity: false);
  }

  /// Creates a G2 point from bytes, validating that it is on-curve and in the correct subgroup.
  factory G2NativeAffinePoint.fromBytes(List<int> bytes, {bool check = true}) {
    final affine = G2NativeAffinePoint.fromBytesUnchecked(bytes);
    if (!check) return affine;
    if (affine.isOnCurve() && affine.isTorsionFree()) {
      return affine;
    }
    throw ArgumentException.invalidOperationArguments(
      "fromBytes",
      reason: "Invalid G2 encoding.",
    );
  }

  /// Creates a G2 affine point from bytes without checking curve or subgroup validity.
  factory G2NativeAffinePoint.fromBytesUnchecked(List<int> bytes) {
    if (bytes.length == 96) {
      return G2NativeAffinePoint._fromCompressedBytes(bytes);
    } else if (bytes.length == 192) {
      return G2NativeAffinePoint._fromUncompressedBytes(bytes);
    }
    throw ArgumentException.invalidOperationArguments(
      "fromBytes",
      reason: "Invalid point bytes length.",
    );
  }

  factory G2NativeAffinePoint.conditionalSelect(
    G2NativeAffinePoint a,
    G2NativeAffinePoint b,
    bool choice,
  ) {
    return G2NativeAffinePoint(
      x: Bls12NativeFp2.conditionalSelect(a.x, b.x, choice),
      y: Bls12NativeFp2.conditionalSelect(a.y, b.y, choice),
      infinity: IntUtils.ctSelectBool(a.infinity, b.infinity, choice),
    );
  }
  static final _identity = G2NativeAffinePoint(
    x: Bls12NativeFp2.zero(),
    y: Bls12NativeFp2.one(),
    infinity: true,
  );

  /// identity element
  factory G2NativeAffinePoint.identity() => _identity;

  /// generator
  factory G2NativeAffinePoint.generator() => G2NativeAffinePoint(
    x: Bls12NativeFp2(
      c0: Bls12NativeFp.nP(
        BigInt.parse(
          "352701069587466618187139116011060144890029952792775240219908644239793785735715026873347600343865175952761926303160",
        ),
      ),
      c1: Bls12NativeFp.nP(
        BigInt.parse(
          "3059144344244213709971259814753781636986470325476647558659373206291635324768958432433509563104347017837885763365758",
        ),
      ),
    ),
    y: Bls12NativeFp2(
      c0: Bls12NativeFp.nP(
        BigInt.parse(
          "1985150602287291935568054521177171638300868978215655730859378665066344726373823718423869104263333984641494340347905",
        ),
      ),
      c1: Bls12NativeFp.nP(
        BigInt.parse(
          "927553665492332455747201965776037880757740193453592970025027978793976877002675564980949289727957565575433344219582",
        ),
      ),
    ),
    infinity: false,
  );

  factory G2NativeAffinePoint.fromProjective(G2NativeProjective p) {
    final zInv = p.z.invert() ?? Bls12NativeFp2.zero();
    final x = p.x * zInv;
    final y = p.y * zInv;
    final tmp = G2NativeAffinePoint(x: x, y: y, infinity: false);
    return G2NativeAffinePoint.conditionalSelect(
      tmp,
      G2NativeAffinePoint.identity(),
      zInv.isZero(),
    );
  }

  @override
  G2NativeProjective operator *(JubJubNativeFq rhs) {
    return toProjective().multiply(rhs.toBytes());
  }

  G2NativeProjective operator -(Bls12NativePoint<G2NativeProjective> rhs) {
    switch (rhs) {
      case final G2NativeProjective rhs:
        return this + -rhs;
      default:
        throw CryptoException.operationNotSupported;
    }
  }

  @override
  G2NativeProjective operator +(Bls12NativePoint<G2NativeProjective> rhs) {
    switch (rhs) {
      case final G2NativeProjective rhs:
        return rhs + this;
      default:
        throw CryptoException.operationNotSupported;
    }
  }

  G2NativeProjective toProjective() => G2NativeProjective.fromAffine(this);

  bool isTorsionFree() {
    final p = toProjective();
    return p.psi() == p.mulByX();
  }

  /// Checks whether the point satisfies the BLS12-381 curve equation in projective form.
  bool isOnCurve() {
    if (infinity) return true;
    return (y.square() - (x.square() * x)) == Bls12NativeFp2.b();
  }

  List<int> toCompressed() {
    // conditional_select(&self.x, &Fp2::zero(), self.infinity)
    final Bls12NativeFp2 xc = Bls12NativeFp2.conditionalSelect(
      x,
      Bls12NativeFp2.zero(),
      infinity,
    );

    // Allocate 96 bytes explicitly
    final res = List<int>.filled(96, 0);

    // Rust:
    // res[0..48]  = x.c1
    // res[48..96] = x.c0
    final c1 = xc.c1.toBytes(); // 48 bytes
    final c0 = xc.c0.toBytes(); // 48 bytes

    for (var i = 0; i < 48; i++) {
      res[i] = c1[i];
      res[i + 48] = c0[i];
    }

    // Set compressed flag (MSB)
    res[0] |= 1 << 7;

    // Set infinity flag (2nd MSB)
    res[0] |= IntUtils.ctSelectInt(0, 1 << 6, infinity);

    // Set lexicographically largest Y flag (3rd MSB),
    // but only if not infinity
    res[0] |= IntUtils.ctSelectInt(
      0,
      1 << 5,
      (!infinity) & y.lexicographicallyLargest(),
    );

    return res;
  }

  List<int> toUncompressed() {
    // Allocate 192 bytes
    final res = List<int>.filled(192, 0);

    // conditional_select(&self.x, &Fp2::zero(), self.infinity)
    final Bls12NativeFp2 xc = Bls12NativeFp2.conditionalSelect(
      x,
      Bls12NativeFp2.zero(),
      infinity,
    );

    final Bls12NativeFp2 yc = Bls12NativeFp2.conditionalSelect(
      y,
      Bls12NativeFp2.zero(),
      infinity,
    );

    // x = c1 || c0
    final xc1 = xc.c1.toBytes(); // 48 bytes
    final xc0 = xc.c0.toBytes(); // 48 bytes

    // y = c1 || c0
    final yc1 = yc.c1.toBytes(); // 48 bytes
    final yc0 = yc.c0.toBytes(); // 48 bytes

    for (var i = 0; i < 48; i++) {
      res[i] = xc1[i];
      res[i + 48] = xc0[i];
      res[i + 96] = yc1[i];
      res[i + 144] = yc0[i];
    }

    // Is this point at infinity? If so, set the second-most significant bit.
    res[0] |= IntUtils.ctSelectInt(0, 1 << 6, infinity);

    return res;
  }

  /// Serializes the point to bytes in either compressed or uncompressed form.
  @override
  List<int> toBytes({PubKeyModes mode = PubKeyModes.compressed}) {
    return switch (mode) {
      PubKeyModes.compressed => toCompressed(),
      PubKeyModes.uncompressed => toUncompressed(),
    };
  }

  /// check identity
  @override
  bool isIdentity() {
    return infinity;
  }

  @override
  G2NativeAffinePoint operator -() {
    return G2NativeAffinePoint(
      x: x,
      y: Bls12NativeFp2.conditionalSelect(-y, Bls12NativeFp2.one(), infinity),
      infinity: infinity,
    );
  }

  @override
  List<dynamic> get variables => [x, y, infinity];

  @override
  G2NativeProjective double() {
    return toProjective().double();
  }
}
