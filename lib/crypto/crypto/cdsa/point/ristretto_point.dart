import 'dart:typed_data';
import 'package:blockchain_utils/crypto/crypto/exception/exception.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/curve/curve.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/curve/curves.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/point/base.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/point/edwards.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/utils/ristretto.dart';

/// A class representing a RistrettoPoint, a point on an elliptic curve
/// in the Ristretto255 group, derived from an Edwards curve point.
class RistrettoPoint extends EDPoint {
  /// Private constructor for a RistrettoPoint.
  ///
  /// This constructor is used to create a RistrettoPoint instance with
  /// the provided parameters, including the required coordinates (x, y, z, t),
  /// the associated elliptic curve, and optional properties such as generator
  /// status and order.
  ///
  /// Parameters:
  ///   - super.curve: The elliptic curve associated with the point.
  ///   - super.x: The x-coordinate of the point.
  ///   - super.y: The y-coordinate of the point.
  ///   - super.z: The z-coordinate of the point.
  ///   - super.t: The t-coordinate of the point.
  ///   - super.generator: A flag indicating if the point is a generator (default is false).
  ///   - super.order: The order of the point in the group (optional).
  RistrettoPoint._(
      {required super.curve,
      required super.x,
      required super.y,
      required super.z,
      required super.t,
      bool generator = false,
      super.order})
      : super(generator: false);

  /// Create a RistrettoPoint from an EdwardsPoint.
  ///
  /// This factory method takes an EdwardsPoint 'point' and extracts its
  /// coordinates to create a new RistrettoPoint. It inherits various
  /// properties from the EdwardsPoint, such as the curve, generator status,
  /// and order.
  ///
  /// Parameters:
  ///   - point: An EdwardsPoint to derive the RistrettoPoint from.
  ///
  /// Returns:
  ///   - RistrettoPoint: A RistrettoPoint created from the EdwardsPoint.
  factory RistrettoPoint.fromEdwardsPoint(EDPoint point) {
    final coords = point.getCoords();
    return RistrettoPoint._(
        curve: point.curve,
        x: coords[0],
        y: coords[1],
        z: coords[2],
        t: coords[3],
        generator: point.generator,
        order: point.order);
  }

  factory RistrettoPoint.fromEdwardBytes(List<int> bytes) {
    return RistrettoPoint.fromEdwardsPoint(
        EDPoint.fromBytes(curve: Curves.curveEd25519, data: bytes));
  }

  /// Factory method to create a RistrettoPoint from a byte representation.
  ///
  /// This factory method creates a RistrettoPoint instance from a byte
  /// representation of a RistrettoPoint. It follows a series of calculations
  /// and checks to ensure the validity of the input bytes and derive the
  /// RistrettoPoint coordinates.
  ///
  /// Parameters:
  ///   - bytes: The byte representation of the RistrettoPoint.
  ///   - curveEdTw: An optional parameter specifying the curve (default is Ed25519).
  ///
  /// Returns:
  ///   - RistrettoPoint: A RistrettoPoint instance created from the input bytes.
  ///
  /// Throws:
  ///   - CryptoException: If the input bytes result in an invalid RistrettoPoint.
  ///   - Exception: If the RistrettoPoint creation fails any validity checks.
  factory RistrettoPoint.fromBytes(List<int> bytes, {CurveED? curveEdTw}) {
    final List<int> hex = bytes;
    final c = curveEdTw ?? Curves.curveEd25519;
    final a = c.a;
    final d = c.d;
    final P = c.p;
    final s = BigintUtils.fromBytes(hex, byteOrder: Endian.little);
    if (RistrettoUtils.isOdd(s, P)) {
      throw const CryptoException("Invalid RistrettoPoint");
    }
    final s2 = RistrettoUtils.positiveMod(s * s, P);
    final u1 = RistrettoUtils.positiveMod(BigInt.one + a * s2, P);
    final u2 = RistrettoUtils.positiveMod(BigInt.one - a * s2, P);
    final u1_2 = RistrettoUtils.positiveMod(u1 * u1, P);
    final u2_2 = RistrettoUtils.positiveMod(u2 * u2, P);
    final v = RistrettoUtils.positiveMod(a * d * u1_2 - u2_2, P);
    final invSqrt = RistrettoUtils.sqrtUV(
        BigInt.one, RistrettoUtils.positiveMod(v * u2_2, P));
    final x2 = RistrettoUtils.positiveMod(invSqrt.item2 * u2, P);
    final y2 = RistrettoUtils.positiveMod(invSqrt.item2 * x2 * v, P);

    BigInt x = RistrettoUtils.positiveMod((s + s) * x2, P);
    if (RistrettoUtils.isOdd(x, P)) {
      x = RistrettoUtils.positiveMod(-x, P);
    }

    final y = RistrettoUtils.positiveMod(u1 * y2, P);
    final t = RistrettoUtils.positiveMod(x * y, P);
    if (!invSqrt.item1 || RistrettoUtils.isOdd(t, P) || y == BigInt.zero) {
      throw const CryptoException("Invalid RistrettoPoint");
    }
    return RistrettoPoint.fromEdwardsPoint(
        EDPoint(curve: c, x: x, y: y, z: BigInt.one, t: t));
  }

  /// Maps a BigInt 'r0' to an Edwards curve point (EDPoint).
  ///
  /// This static method maps a given 'r0' value to an Edwards curve point
  /// using a series of calculations and modular arithmetic. The resulting
  /// point is returned as an instance of EDPoint.
  ///
  /// Parameters:
  ///   - r0: The input BigInt 'r0' value to be mapped to a point.
  ///
  /// Returns:
  ///   - EDPoint: The Edwards curve point mapped from the input 'r0'.
  ///
  /// Details:
  ///   - The method performs calculations to derive various intermediate values,
  ///     computes the coordinates of the Edwards curve point, and ensures that
  ///     the final point is correctly mapped from the input 'r0'.
  static EDPoint mapToPoint(BigInt r0) {
    final curveD = Curves.generatorED25519.curve.d;
    final primeP = Curves.curveEd25519.p;

    final rSquared =
        RistrettoUtils.positiveMod(RistrettoUtils.sqrtM1 * r0 * r0, primeP);
    final numeratorS = RistrettoUtils.positiveMod(
        (rSquared + BigInt.one) * RistrettoUtils.oneMinusDSq, primeP);

    var c = BigInt.from(-1);

    final D = RistrettoUtils.positiveMod(
        (c - curveD * rSquared) *
            RistrettoUtils.positiveMod(rSquared + curveD, primeP),
        primeP);

    final uvRatio = RistrettoUtils.sqrtUV(numeratorS, D);

    final useSecondRoot = uvRatio.item1;
    BigInt sValue = uvRatio.item2;

    BigInt sComputed = RistrettoUtils.positiveMod(sValue * r0, primeP);

    if (!RistrettoUtils.isOdd(sComputed, primeP)) {
      sComputed = RistrettoUtils.positiveMod(-sComputed, primeP);
    }

    if (!useSecondRoot) {
      sValue = sComputed;
    }

    if (!useSecondRoot) {
      c = rSquared;
    }

    final ntValue = RistrettoUtils.positiveMod(
        c * (rSquared - BigInt.one) * RistrettoUtils.minusOneSq - D, primeP);

    final sSquared = sValue * sValue;
    final w0 = RistrettoUtils.positiveMod((sValue + sValue) * D, primeP);
    final w1 = RistrettoUtils.positiveMod(
        ntValue * RistrettoUtils.sqrtAdMinusOne, primeP);
    final w2 = RistrettoUtils.positiveMod(BigInt.one - sSquared, primeP);
    final w3 = RistrettoUtils.positiveMod(BigInt.one + sSquared, primeP);

    return EDPoint(
        curve: Curves.curveEd25519,
        x: RistrettoUtils.positiveMod(w0 * w3, primeP),
        y: RistrettoUtils.positiveMod(w2 * w1, primeP),
        z: RistrettoUtils.positiveMod(w1 * w3, primeP),
        t: RistrettoUtils.positiveMod(w0 * w2, primeP));
  }

  /// Factory method to create a RistrettoPoint from a uniform byte representation.
  ///
  /// This factory method creates a RistrettoPoint from a uniform byte representation,
  /// which is typically used for generating keys or secret values. It takes the
  /// input 'hash' as a byte array, extracts two parts ('rB' and 'lB') from it,
  /// maps them to Edwards curve points, adds them together, and returns the result
  /// as a RistrettoPoint.
  ///
  /// Parameters:
  ///   - hash: A `List<int>` representing the uniform byte value to be converted.
  ///
  /// Returns:
  ///   - RistrettoPoint: A RistrettoPoint instance created from the uniform byte input.
  ///
  /// Details:
  ///   - The method extracts two parts ('rB' and 'lB') from the input 'hash',
  ///     maps them to Edwards curve points, and combines them to produce the
  ///     resulting RistrettoPoint. This is often used in key generation processes.
  factory RistrettoPoint.fromUniform(List<int> hash) {
    final rB =
        BigintUtils.fromBytes(hash.sublist(0, 32), byteOrder: Endian.little) &
            RistrettoUtils.mask255;
    final rPoint = mapToPoint(rB);

    final lB =
        BigintUtils.fromBytes(hash.sublist(32, 64), byteOrder: Endian.little) &
            RistrettoUtils.mask255;
    final lPoint = mapToPoint(lB);

    final sumPoint = rPoint + lPoint;
    return RistrettoPoint.fromEdwardsPoint(sumPoint);
  }

  /// Converts the RistrettoPoint to a byte array in Edwards curve encoding.
  ///
  /// This method converts the RistrettoPoint to a byte array using the specified
  /// encoding type (default is compressed). It delegates the conversion to the
  /// superclass method and returns the result.
  ///
  /// Parameters:
  ///   - encodeType: The encoding type for the output byte array (default is compressed).
  ///
  /// Returns:
  ///   - `List<int>`: A byte array representing the RistrettoPoint in Edwards encoding.
  List<int> toEdwardBytes([EncodeType encodeType = EncodeType.comprossed]) {
    return super.toBytes(encodeType);
  }

  /// Overrides the '*' operator to multiply a RistrettoPoint by another object.
  ///
  /// This operator override allows you to multiply a RistrettoPoint by another object.
  /// It delegates the multiplication to the superclass and then converts the result
  /// to a RistrettoPoint.
  ///
  /// Parameters:
  ///   - other: The object to multiply with the RistrettoPoint.
  ///
  /// Returns:
  ///   - RistrettoPoint: The result of the multiplication as a RistrettoPoint.
  @override
  RistrettoPoint operator *(other) {
    final mul = super * other;
    return RistrettoPoint.fromEdwardsPoint(mul);
  }

  /// Overrides the '+' operator to add a RistrettoPoint to another object.
  ///
  /// This operator override allows you to add a RistrettoPoint to another object.
  /// It delegates the addition to the superclass and then converts the result
  /// to a RistrettoPoint.
  ///
  /// Parameters:
  ///   - other: The object to add to the RistrettoPoint.
  ///
  /// Returns:
  ///   - RistrettoPoint: The result of the addition as a RistrettoPoint.
  @override
  RistrettoPoint operator +(other) {
    final add = super + other;
    return RistrettoPoint.fromEdwardsPoint(add);
  }

  /// Overrides the unary negation '-' operator to negate a RistrettoPoint.
  ///
  /// This operator override allows you to negate a RistrettoPoint using the unary
  /// negation operator '-'. It delegates the negation to the superclass and then
  /// converts the result to a RistrettoPoint.
  ///
  /// Returns:
  ///   - RistrettoPoint: The negated RistrettoPoint.
  @override
  RistrettoPoint operator -() {
    final neg = -super;
    return RistrettoPoint.fromEdwardsPoint(neg);
  }

  /// Overrides the 'toBytes' method to convert the RistrettoPoint to a byte array.
  ///
  /// This method converts the RistrettoPoint to a byte array by computing its
  /// coordinates and encoding them according to the default Ristretto encoding rules.
  /// The resulting byte array represents the RistrettoPoint in a format suitable
  /// for serialization and other data storage or transmission purposes.
  ///
  /// Returns:
  ///   - `List<int>`: A byte array representing the RistrettoPoint.
  ///
  /// Details:
  ///   - The method calculates intermediate values and applies encoding-specific
  ///     transformations to the point's coordinates in accordance with Ristretto
  ///     encoding rules. The result is a compact byte array representation.
  @override
  List<int> toBytes([EncodeType encodeType = EncodeType.comprossed]) {
    final primeP = Curves.curveEd25519.p;
    final pointCoords = getCoords();
    BigInt x = pointCoords[0];
    BigInt y = pointCoords[1];
    final BigInt z = pointCoords[2];
    final BigInt t = pointCoords[3];

    final u1 = RistrettoUtils.positiveMod(
        RistrettoUtils.positiveMod(z + y, primeP) *
            RistrettoUtils.positiveMod(z - y, primeP),
        primeP);
    final u2 = RistrettoUtils.positiveMod(x * y, primeP);

    final u2Squared = RistrettoUtils.positiveMod(u2 * u2, primeP);
    final invSqrt = RistrettoUtils.sqrtUV(
            BigInt.one, RistrettoUtils.positiveMod(u1 * u2Squared, primeP))
        .item2;
    final d1 = RistrettoUtils.positiveMod(invSqrt * u1, primeP);
    final d2 = RistrettoUtils.positiveMod(invSqrt * u2, primeP);
    final zInverse = RistrettoUtils.positiveMod(d1 * d2 * t, primeP);
    BigInt D;
    if (RistrettoUtils.isOdd(t * zInverse, primeP)) {
      final x2 = RistrettoUtils.positiveMod(y * RistrettoUtils.sqrtM1, primeP);
      final y2 = RistrettoUtils.positiveMod(x * RistrettoUtils.sqrtM1, primeP);
      x = x2;
      y = y2;
      D = RistrettoUtils.positiveMod(d1 * RistrettoUtils.invSqrt, primeP);
    } else {
      D = d2;
    }
    if (RistrettoUtils.isOdd(x * zInverse, primeP)) {
      y = RistrettoUtils.positiveMod(-y, primeP);
    }
    BigInt s = RistrettoUtils.positiveMod((z - y) * D, primeP);
    if (RistrettoUtils.isOdd(s, primeP)) {
      s = RistrettoUtils.positiveMod(-s, primeP);
    }
    return BigintUtils.toBytes(s, order: Endian.little, length: 32);
  }
}
