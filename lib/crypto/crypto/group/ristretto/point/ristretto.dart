import 'package:blockchain_utils/crypto/crypto/group/core/field.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/crypto/crypto/group/core/point.dart';
import 'package:blockchain_utils/crypto/crypto/group/edwards_limb/fields.dart';
import 'package:blockchain_utils/crypto/crypto/group/edwards_limb/points.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/utils/numbers/fixed/src/u64/u64.dart';

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// A Ristretto255 point: a coset representative stored as an
/// [EdwardsLimbPoint] in extended coordinates.
///
class RistrettoPoint extends ECPoint<Ed25519Fr, RistrettoPoint>
    implements
        CryptoGroupElement<RistrettoPoint, Ed25519Fr>,
        CofactorGroupElement<Ed25519Fr, RistrettoPoint> {
  final EdwardsLimbPoint point;
  const RistrettoPoint._(this.point);

  /// Fixed field constants (Montgomery form).
  static const Ed25519Fp _sqrtM1 = Ed25519Fp.unsafe([
    Uint64.unsafe(995624916, 4264286980),
    Uint64.unsafe(66425085, 3038505453),
    Uint64.unsafe(1835931327, 862061265),
    Uint64.unsafe(1970760459, 3603372968),
  ]);
  static const Ed25519Fp _minusOneSq = Ed25519Fp.unsafe([
    Uint64.unsafe(1606120774, 993621166),
    Uint64.unsafe(1132397218, 611830973),
    Uint64.unsafe(1757894918, 1124972289),
    Uint64.unsafe(1166713920, 2483885489),
  ]);
  static const Ed25519Fp _oneMinusDSq = Ed25519Fp.unsafe([
    Uint64.unsafe(2657710780, 104249220),
    Uint64.unsafe(2604527214, 2080104539),
    Uint64.unsafe(3423699690, 1153514462),
    Uint64.unsafe(1634796810, 2259902464),
  ]);
  static const Ed25519Fp _sqrtAdMinusOne = Ed25519Fp.unsafe([
    Uint64.unsafe(3398343626, 3897088306),
    Uint64.unsafe(291706316, 333222944),
    Uint64.unsafe(1124959709, 1786588072),
    Uint64.unsafe(966615648, 1971112330),
  ]);
  static const Ed25519Fp _invSqrt = Ed25519Fp.unsafe([
    Uint64.unsafe(3553994575, 232236373),
    Uint64.unsafe(1425885047, 1706494026),
    Uint64.unsafe(1625184171, 3024492951),
    Uint64.unsafe(1612469980, 3558834191),
  ]);

  static Ed25519Fp _pow2k(Ed25519Fp x, int k) {
    var res = x;
    for (var i = 0; i < k; i++) {
      res = res.square();
    }
    return res;
  }

  /// Computes `x^((p-5)/8)` via the ref10 addition chain.
  static Ed25519Fp _pow252(Ed25519Fp x) {
    final xSquared = x.square();
    final xCubed = xSquared * x;
    final xTo4th = _pow2k(xCubed, 2) * xCubed;
    final xTo5th = _pow2k(xTo4th, 1) * x;
    final xTo10th = _pow2k(xTo5th, 5) * xTo5th;
    final xTo20th = _pow2k(xTo10th, 10) * xTo10th;
    final xTo40th = _pow2k(xTo20th, 20) * xTo20th;
    final xTo80th = _pow2k(xTo40th, 40) * xTo40th;
    final xTo160th = _pow2k(xTo80th, 80) * xTo80th;
    final xTo240th = _pow2k(xTo160th, 80) * xTo80th;
    final xTo250th = _pow2k(xTo240th, 10) * xTo10th;
    return _pow2k(xTo250th, 2) * x;
  }

  static bool _isOdd(Ed25519Fp v) => (v.toBytes()[0] & 1) == 1;

  /// sqrt(u/v): returns (wasSquare, x) with x² == u/v or the closest miss.
  static (bool, Ed25519Fp) _sqrtUV(Ed25519Fp u, Ed25519Fp v) {
    final v3 = v.square() * v;
    final v7 = v3.square() * v;
    final pow = _pow252(u * v7);
    var x = u * v3 * pow;
    final vx2 = v * x.square();
    final root1 = x;
    final root2 = x * _sqrtM1;
    final useRoot1 = vx2 == u;
    final useRoot2 = vx2 == -u;
    final noRoot = vx2 == -u * _sqrtM1;
    if (useRoot1) x = root1;
    if (useRoot2 || noRoot) x = root2;
    if (_isOdd(x)) x = -x;
    return (useRoot1 || useRoot2, x);
  }

  /// Creates a RistrettoPoint from an underlying Edwards point.
  factory RistrettoPoint.fromEdwardsPoint(EdwardsLimbPoint point) {
    return RistrettoPoint._(point);
  }

  factory RistrettoPoint.fromEdwardBytes(List<int> bytes) {
    return RistrettoPoint.fromEdwardsPoint(EdwardsLimbPoint.fromBytes(bytes));
  }

  /// Decodes a RistrettoPoint from its compressed [bytes] encoding.
  /// Throws [BuError] if the encoding is invalid.
  factory RistrettoPoint.fromBytes(List<int> bytes) {
    if (bytes.length != 32) {
      throw CoreErrors.invalidOperationArguments(
        "RistrettoPoint",
        name: "bytes",
        reason: "Invalid point bytes length.",
      );
    }
    // Unchecked + canonical parity below: matches the legacy decode, which
    // accepted non-canonical s and judged parity of s mod p.
    final s = Ed25519Fp.fromBytesUnchecked(bytes);
    if (_isOdd(s)) {
      throw CoreErrors.invalidOperationArguments(
        "RistrettoPoint",
        name: "bytes",
        reason: "Invalid point bytes.",
      );
    }
    final s2 = s.square();
    final u1 = Ed25519Fp.one - s2; // 1 + a*s2, a = -1
    final u2 = Ed25519Fp.one + s2; // 1 - a*s2, a = -1
    final u1_2 = u1.square();
    final u2_2 = u2.square();
    final v = -EdwardsLimbParams.d * u1_2 - u2_2; // a*d*u1²-u2², a = -1
    final invSqrt = _sqrtUV(Ed25519Fp.one, v * u2_2);
    final x2 = invSqrt.$2 * u2;
    final y2 = invSqrt.$2 * x2 * v;

    var x = (s + s) * x2;
    if (_isOdd(x)) x = -x;

    final y = u1 * y2;
    final t = x * y;
    if (!invSqrt.$1 || _isOdd(t) || y == Ed25519Fp.zero) {
      throw CoreErrors.invalidOperationArguments(
        "RistrettoPoint",
        reason: "Invalid ristretto point encoding bytes.",
      );
    }
    return RistrettoPoint.fromEdwardsPoint(
      EdwardsLimbPoint(x: x, y: y, z: Ed25519Fp.one, t: t),
    );
  }

  /// Maps 32 masked LE bytes (< 2^255) to an Edwards curve point.
  static EdwardsLimbPoint _mapToPoint(List<int> r0bytes) {
    final r0 = Ed25519Fp.fromBytesUnchecked(r0bytes);
    final rSquared = _sqrtM1 * r0.square();
    final numeratorS = (rSquared + Ed25519Fp.one) * _oneMinusDSq;

    var c = -Ed25519Fp.one;

    final d =
        (c - EdwardsLimbParams.d * rSquared) * (rSquared + EdwardsLimbParams.d);

    final uvRatio = _sqrtUV(numeratorS, d);

    final useSecondRoot = uvRatio.$1;
    var sValue = uvRatio.$2;

    var sComputed = sValue * r0;

    if (!_isOdd(sComputed)) {
      sComputed = -sComputed;
    }

    if (!useSecondRoot) {
      sValue = sComputed;
    }

    if (!useSecondRoot) {
      c = rSquared;
    }

    final ntValue = c * (rSquared - Ed25519Fp.one) * _minusOneSq - d;

    final sSquared = sValue.square();
    final w0 = (sValue + sValue) * d;
    final w1 = ntValue * _sqrtAdMinusOne;
    final w2 = Ed25519Fp.one - sSquared;
    final w3 = Ed25519Fp.one + sSquared;

    return EdwardsLimbPoint(x: w0 * w3, y: w2 * w1, z: w1 * w3, t: w0 * w2);
  }

  /// Maps a uniformly-random 64-byte [hash] to a RistrettoPoint
  /// (the two-round Elligator construction).
  factory RistrettoPoint.fromUniform(List<int> hash) {
    if (hash.length != 64) {
      throw CoreErrors.invalidOperationArguments(
        "RistrettoPoint.fromUniform",
        name: "hash",
        reason: "Invalid hash bytes length.",
      );
    }
    final rB = hash.sublist(0, 32).toList()..[31] &= 0x7F;
    final rPoint = _mapToPoint(rB);

    final lB = hash.sublist(32, 64).toList()..[31] &= 0x7F;
    final lPoint = _mapToPoint(lB);

    return RistrettoPoint.fromEdwardsPoint(rPoint + lPoint);
  }

  bool isZero() => point.isIdentity();

  static final RistrettoPoint identity_ = RistrettoPoint.fromEdwardsPoint(
    EdwardsLimbPoint.identity_,
  );

  @override
  RistrettoPoint identity() => identity_;

  @override
  RistrettoPoint double() => RistrettoPoint.fromEdwardsPoint(point.double());

  /// Converts the RistrettoPoint to a byte array in Edwards curve encoding.
  BuBytes toEdwardBytes() => point.toBytes();

  /// multiply a RistrettoPoint by a scalar.
  @override
  RistrettoPoint operator *(Ed25519Fr s) {
    return RistrettoPoint.fromEdwardsPoint(point * s);
  }

  /// add a RistrettoPoint to another RistrettoPoint.
  @override
  RistrettoPoint operator +(RistrettoPoint other) {
    return RistrettoPoint.fromEdwardsPoint(point + other.point);
  }

  /// subtract a RistrettoPoint from another RistrettoPoint.
  @override
  RistrettoPoint operator -(RistrettoPoint other) {
    return RistrettoPoint.fromEdwardsPoint(point + (-other.point));
  }

  /// negate a RistrettoPoint.
  @override
  RistrettoPoint operator -() {
    return RistrettoPoint.fromEdwardsPoint(-point);
  }

  // Prime-order group: no small-order points besides identity.
  @override
  bool isSmallOrder() => isZero();

  // Prime-order group: projection is the identity function.
  @override
  RistrettoPoint clearCofactor() => this;

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

  /// convert the RistrettoPoint to a byte array.
  @override
  BuBytes toBytes() {
    final coords = point;
    final x = coords.x;
    final y = coords.y;
    final z = coords.z;
    final t = coords.t;

    final u1 = (z + y) * (z - y);
    final u2 = x * y;

    final u2Squared = u2.square();
    final invS = _sqrtUV(Ed25519Fp.one, u1 * u2Squared).$2;
    final d1 = invS * u1;
    final d2 = invS * u2;
    final zInverse = d1 * d2 * t;
    Ed25519Fp d;
    var xx = x;
    var yy = y;
    if (_isOdd(t * zInverse)) {
      xx = y * _sqrtM1;
      yy = x * _sqrtM1;
      d = d1 * _invSqrt;
    } else {
      d = d2;
    }
    if (_isOdd(xx * zInverse)) {
      yy = -yy;
    }
    var s = (z - yy) * d;
    if (_isOdd(s)) {
      s = -s;
    }
    return s.toBytes();
  }

  @override
  bool operator ==(Object other) {
    if (other is! RistrettoPoint) return false;
    final x1 = point.x, y1 = point.y;
    final x2 = other.point.x, y2 = other.point.y;
    final check1 = x1 * y2 == x2 * y1;
    final check2 = y1 * y2 == x1 * x2;
    return check1 || check2;
  }

  // NOTE: hashCode is derived from the raw (x, y) coordinates, but
  // operator== treats two different coordinate representations of the same
  // point as equal (see check1/check2 above). Two equal RistrettoPoints can
  // therefore have different hashCodes, which breaks the hashCode/== contract
  // for Set/Map usage — canonicalize (e.g. via toBytes()) before hashing if
  // that matters for your use case.
  @override
  int get hashCode => Object.hash(point.x, point.y);
}
