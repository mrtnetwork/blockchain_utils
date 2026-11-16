import 'package:blockchain_utils/crypto/crypto/keys/types/types.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/crypto/crypto/group/bls12_381/src/core.dart';
import 'package:blockchain_utils/crypto/crypto/group/bls12_381/src/fp.dart';
import 'package:blockchain_utils/crypto/crypto/group/bls12_381/src/fp2.dart';
import 'package:blockchain_utils/crypto/crypto/group/jubjub/fields/field.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/utils/numbers/fixed/src/u64/u64.dart';

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';
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

  /// Mask form of [conditionalSelect]: [bit] is a 0/1 [Uint64] (never a
  /// `bool`), so scalar-multiplication selects stay straight-line.
  factory G2Projective.conditionalSelectMask(
    G2Projective a,
    G2Projective b,
    Uint64 bit,
  ) {
    return G2Projective(
      x: Bls12Fp2.conditionalSelectMask(a.x, b.x, bit),
      y: Bls12Fp2.conditionalSelectMask(a.y, b.y, bit),
      z: Bls12Fp2.conditionalSelectMask(a.z, b.z, bit),
    );
  }
  G2Projective copyWith({Bls12Fp2? x, Bls12Fp2? y, Bls12Fp2? z}) {
    return G2Projective(x: x ?? this.x, y: y ?? this.y, z: z ?? this.z);
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
    if (by.length != 32) {
      throw CoreErrors.cryptoFailed(
        "G2Projective.multiply",
        reason: "Invalid scalar bytes length.",
      );
    }
    G2Projective acc = G2Projective.identity;
    // Same bit sequence as before (`bytesToBits` LE, top bit skipped), but
    // the per-bit select is a Uint64 mask blend — no `bool` on the secret.
    for (int i = 254; i >= 0; i--) {
      acc = acc.double();
      final bit = Uint64((by[i >> 3] >> (i & 7)) & 1);
      acc = G2Projective.conditionalSelectMask(acc, (acc + this), bit);
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
        throw CoreErrors.cryptoOperationNotSupported;
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
        // Lift to projective and reuse the complete formula: the only
        // secret-data decision (infinity) becomes a z-mask select instead
        // of a `bool` branch. Formula output for an infinity addend is
        // discarded by the select below.
        final q = G2Projective.fromAffine(rhs);
        final sum = this + q;
        final inf =
            Uint64.isZeroMask(
              q.z.c0.limbs[0] |
                  q.z.c0.limbs[1] |
                  q.z.c0.limbs[2] |
                  q.z.c0.limbs[3] |
                  q.z.c0.limbs[4] |
                  q.z.c0.limbs[5] |
                  q.z.c1.limbs[0] |
                  q.z.c1.limbs[1] |
                  q.z.c1.limbs[2] |
                  q.z.c1.limbs[3] |
                  q.z.c1.limbs[4] |
                  q.z.c1.limbs[5],
            ) &
            Uint64.one;
        return G2Projective.conditionalSelectMask(sum, this, inf);
    }

    throw CoreErrors.cryptoOperationNotSupported;
  }

  /// Serializes the point to bytes in either compressed or uncompressed form.
  @override
  BuBytes toBytes({CryptoKeyEncoding mode = CryptoKeyEncoding.base}) {
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
      throw CoreErrors.invalidOperationArguments(
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
      throw CoreErrors.invalidOperationArguments(
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
      throw CoreErrors.invalidOperationArguments(
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
    throw CoreErrors.invalidOperationArguments(
      "fromBytes",
      reason: "Invalid G2 encoding.",
    );
  }

  /// Creates a G2 affine point from bytes without checking curve or subgroup validity.
  factory G2AffinePoint.fromBytesUnchecked(List<int> bytes) {
    if (bytes.length == 96) {
      return G2AffinePoint._fromCompressedBytes(bytes);
    } else if (bytes.length == 192) {
      return G2AffinePoint._fromUncompressedBytes(bytes);
    }
    throw CoreErrors.invalidOperationArguments(
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
        throw CoreErrors.cryptoOperationNotSupported;
    }
  }

  @override
  G2Projective operator +(Bls12Point<G2Projective> rhs) {
    switch (rhs) {
      case final G2Projective rhs:
        return rhs + this;
      default:
        throw CoreErrors.cryptoOperationNotSupported;
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

  BuBytes toCompressed() {
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

    return BuBytes(res);
  }

  BuBytes toUncompressed() {
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

    return BuBytes(res);
  }

  /// Serializes the point to bytes in either compressed or uncompressed form.
  @override
  BuBytes toBytes({CryptoKeyEncoding mode = CryptoKeyEncoding.base}) {
    return switch (mode) {
      CryptoKeyEncoding.base => toCompressed(),
      CryptoKeyEncoding.uncompressed => toUncompressed(),
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
