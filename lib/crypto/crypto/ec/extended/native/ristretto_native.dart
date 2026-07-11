import 'dart:typed_data' show Endian;

import 'package:blockchain_utils/crypto/crypto/exception/exception.dart';
import 'package:blockchain_utils/exception/exceptions.dart';

import 'package:blockchain_utils/crypto/crypto/ec/curve/curve.dart';
import 'package:blockchain_utils/crypto/crypto/ec/curve/curves.dart';
import 'package:blockchain_utils/crypto/crypto/ec/extended/native/edwards.dart';
import 'package:blockchain_utils/helper/helper.dart';
import 'package:blockchain_utils/utils/numbers/utils/bigint_utils.dart';

/// A class representing a RistrettoPoint, a point on an elliptic curve
/// in the Ristretto255 group, derived from an Edwards curve point.
class RistrettoPoint extends EDPoint {
  RistrettoPoint._({
    required super.curve,
    required super.x,
    required super.y,
    required super.z,
    required super.t,
    bool generator = false,
    super.order,
  }) : super(generator: false);

  /// Calculates the positive remainder of two BigInt values.
  static BigInt positiveMod(BigInt a, BigInt b) {
    final result = a % b;
    return result >= BigInt.zero ? result : b + result;
  }

  /// Computes modular exponentiation for BigInt values.
  static BigInt _mExp(BigInt x, BigInt power, BigInt modulo) {
    BigInt res = x;
    while (power > BigInt.zero) {
      res *= res;
      res %= modulo;
      power -= BigInt.one;
    }
    return res;
  }

  /// Calculate values relevant to the Ed25519 elliptic curve for pow(2, 252 - 3).
  static BigInt _pow252(BigInt x) {
    final P = Curves.curveEd25519.p;
    final xSquared = (x * x) % P;
    final xCubed = (xSquared * x) % P;
    final xTo4th = (_mExp(xCubed, BigInt.two, P) * xCubed) % P;
    final xTo5th = (_mExp(xTo4th, BigInt.one, P) * x) % P;
    final xTo10th = (_mExp(xTo5th, BigInt.from(5), P) * xTo5th) % P;
    final xTo20th = (_mExp(xTo10th, BigInt.from(10), P) * xTo10th) % P;
    final xTo40th = (_mExp(xTo20th, BigInt.from(20), P) * xTo20th) % P;
    final xTo80th = (_mExp(xTo40th, BigInt.from(40), P) * xTo40th) % P;
    final xTo160th = (_mExp(xTo80th, BigInt.from(80), P) * xTo80th) % P;
    final xTo240th = (_mExp(xTo160th, BigInt.from(80), P) * xTo80th) % P;
    final xTo250th = (_mExp(xTo240th, BigInt.from(10), P) * xTo10th) % P;
    final result = (_mExp(xTo250th, BigInt.two, P) * x) % P;
    return result;
  }

  /// Check if a BigInt number is odd with respect to a given modulo.
  static bool isOdd(BigInt num, BigInt modulo) {
    return (positiveMod(num, modulo) & BigInt.one) == BigInt.one;
  }

  /// sqrt u/v
  static (bool, BigInt) sqrtUV(BigInt u, BigInt v) {
    final sqrtM1 = BigInt.parse(
      '19681161376707505956807079304988542015446066515923890162744021073123829784752',
    );

    final P = Curves.curveEd25519.p;
    final v3 = positiveMod(v * v * v, P);
    final v7 = positiveMod(v3 * v3 * v, P);
    final pow = _pow252(u * v7);
    var x = positiveMod(u * v3 * pow, P);
    final vx2 = positiveMod(v * x * x, P);
    final root1 = x;

    final root2 = positiveMod(x * sqrtM1, P);
    final useRoot1 = vx2 == u;
    final useRoot2 = vx2 == positiveMod(-u, P);
    final noRoot = vx2 == positiveMod(-u * sqrtM1, P);

    if (useRoot1) {
      x = root1;
    }
    if (useRoot2 || noRoot) {
      x = root2;
    }

    if (isOdd(x, P)) {
      x = positiveMod(-x, P);
    }
    return (useRoot1 || useRoot2, x);
  }

  /// Create a RistrettoPoint from an EdwardsPoint.
  ///
  /// Parameters:
  ///   - [point]: An EdwardsPoint to derive the RistrettoPoint from.
  ///
  factory RistrettoPoint.fromEdwardsPoint(EDPoint point) {
    final coords = point.getCoords();
    return RistrettoPoint._(
      curve: point.curve,
      x: coords[0],
      y: coords[1],
      z: coords[2],
      t: coords[3],
      generator: point.generator,
      order: point.order,
    );
  }

  factory RistrettoPoint.fromEdwardBytes(List<int> bytes) {
    return RistrettoPoint.fromEdwardsPoint(
      EDPoint.fromBytes(curve: Curves.curveEd25519, data: bytes),
    );
  }

  /// Factory method to create a RistrettoPoint from a byte representation.
  ///
  /// Parameters:
  ///   - [bytes]: The byte representation of the RistrettoPoint.
  ///   - [curveEdTw]: An optional parameter specifying the curve (default is Ed25519).
  ///
  /// Throws:
  ///   - [ArgumentException]: If the input bytes result in an invalid RistrettoPoint.
  ///   - [CryptoException]: If the RistrettoPoint creation fails any validity checks.
  ///
  factory RistrettoPoint.fromBytes(List<int> bytes, {CurveED? curveEdTw}) {
    final c = curveEdTw ?? Curves.curveEd25519;
    final a = c.a;
    final d = c.d;
    final P = c.p;
    final s = BigintUtils.fromBytes(bytes, byteOrder: Endian.little);
    if (isOdd(s, P)) {
      throw ArgumentException.invalidOperationArguments(
        "RistrettoPoint",
        name: "bytes",
        reason: "Invalid point bytes.",
      );
    }
    final s2 = positiveMod(s * s, P);
    final u1 = positiveMod(BigInt.one + a * s2, P);
    final u2 = positiveMod(BigInt.one - a * s2, P);
    final u1_2 = positiveMod(u1 * u1, P);
    final u2_2 = positiveMod(u2 * u2, P);
    final v = positiveMod(a * d * u1_2 - u2_2, P);
    final invSqrt = sqrtUV(BigInt.one, positiveMod(v * u2_2, P));
    final x2 = positiveMod(invSqrt.$2 * u2, P);
    final y2 = positiveMod(invSqrt.$2 * x2 * v, P);

    BigInt x = positiveMod((s + s) * x2, P);
    if (isOdd(x, P)) {
      x = positiveMod(-x, P);
    }

    final y = positiveMod(u1 * y2, P);
    final t = positiveMod(x * y, P);
    if (!invSqrt.$1 || isOdd(t, P) || y == BigInt.zero) {
      throw ArgumentException.invalidOperationArguments(
        "RistrettoPoint",
        reason: "Invalid ristretto point encoding bytes.",
      );
    }
    return RistrettoPoint.fromEdwardsPoint(
      EDPoint(curve: c, x: x, y: y, z: BigInt.one, t: t),
    );
  }

  /// Maps a BigInt 'r0' to an Edwards curve point (EDPoint).
  static EDPoint mapToPoint(BigInt r0) {
    final sqrtM1 = BigInt.parse(
      '19681161376707505956807079304988542015446066515923890162744021073123829784752',
    );

    /// The square of -1 in the Ristretto255 curve field.
    final minusOneSq = BigInt.parse(
      '40440834346308536858101042469323190826248399146238708352240133220865137265952',
    );

    /// The value 1 - d^2 in the Ristretto255 curve field.
    final oneMinusDSq = BigInt.parse(
      '1159843021668779879193775521855586647937357759715417654439879720876111806838',
    );

    /// The value (a*d) - 1 in the Ristretto255 curve field.
    final sqrtAdMinusOne = BigInt.parse(
      '25063068953384623474111414158702152701244531502492656460079210482610430750235',
    );
    final curveD = Curves.generatorED25519.curve.d;
    final primeP = Curves.curveEd25519.p;

    final rSquared = positiveMod(sqrtM1 * r0 * r0, primeP);
    final numeratorS = positiveMod(
      (rSquared + BigInt.one) * oneMinusDSq,
      primeP,
    );

    var c = BigInt.from(-1);

    final D = positiveMod(
      (c - curveD * rSquared) * positiveMod(rSquared + curveD, primeP),
      primeP,
    );

    final uvRatio = sqrtUV(numeratorS, D);

    final useSecondRoot = uvRatio.$1;
    BigInt sValue = uvRatio.$2;

    BigInt sComputed = positiveMod(sValue * r0, primeP);

    if (!isOdd(sComputed, primeP)) {
      sComputed = positiveMod(-sComputed, primeP);
    }

    if (!useSecondRoot) {
      sValue = sComputed;
    }

    if (!useSecondRoot) {
      c = rSquared;
    }

    final ntValue = positiveMod(
      c * (rSquared - BigInt.one) * minusOneSq - D,
      primeP,
    );

    final sSquared = sValue * sValue;
    final w0 = positiveMod((sValue + sValue) * D, primeP);
    final w1 = positiveMod(ntValue * sqrtAdMinusOne, primeP);
    final w2 = positiveMod(BigInt.one - sSquared, primeP);
    final w3 = positiveMod(BigInt.one + sSquared, primeP);

    return EDPoint(
      curve: Curves.curveEd25519,
      x: positiveMod(w0 * w3, primeP),
      y: positiveMod(w2 * w1, primeP),
      z: positiveMod(w1 * w3, primeP),
      t: positiveMod(w0 * w2, primeP),
    );
  }

  /// Factory method to create a RistrettoPoint from a uniform byte representation.
  ///
  /// Parameters:
  ///   - [hash]: The uniform byte value to be converted.
  ///
  factory RistrettoPoint.fromUniform(List<int> hash) {
    final mask255 = BigInt.parse(
      "7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff",
      radix: 16,
    );

    final rB =
        BigintUtils.fromBytes(hash.sublist(0, 32), byteOrder: Endian.little) &
        mask255;
    final rPoint = mapToPoint(rB);

    final lB =
        BigintUtils.fromBytes(hash.sublist(32, 64), byteOrder: Endian.little) &
        mask255;
    final lPoint = mapToPoint(lB);

    final sumPoint = rPoint + lPoint;
    return RistrettoPoint.fromEdwardsPoint(sumPoint);
  }

  /// Converts the RistrettoPoint to a byte array in Edwards curve encoding.
  List<int> toEdwardBytes() {
    return super.toBytes();
  }

  /// multiply a RistrettoPoint by another edward point.
  @override
  RistrettoPoint operator *(other) {
    final mul = super * other;
    return RistrettoPoint.fromEdwardsPoint(mul);
  }

  /// add a RistrettoPoint to another edward point.
  @override
  RistrettoPoint operator +(other) {
    final add = super + other;
    return RistrettoPoint.fromEdwardsPoint(add);
  }

  /// negate a RistrettoPoint.
  @override
  RistrettoPoint operator -() {
    final neg = -super;
    return RistrettoPoint.fromEdwardsPoint(neg);
  }

  /// convert the RistrettoPoint to a byte array.
  @override
  List<int> toBytes() {
    final sqrtM1 = BigInt.parse(
      '19681161376707505956807079304988542015446066515923890162744021073123829784752',
    );

    final invSqrt = BigInt.parse(
      '54469307008909316920995813868745141605393597292927456921205312896311721017578',
    );
    final primeP = Curves.curveEd25519.p;
    final pointCoords = getCoords();
    BigInt x = pointCoords[0];
    BigInt y = pointCoords[1];
    final BigInt z = pointCoords[2];
    final BigInt t = pointCoords[3];

    final u1 = positiveMod(
      positiveMod(z + y, primeP) * positiveMod(z - y, primeP),
      primeP,
    );
    final u2 = positiveMod(x * y, primeP);

    final u2Squared = positiveMod(u2 * u2, primeP);
    final invS = sqrtUV(BigInt.one, positiveMod(u1 * u2Squared, primeP)).$2;
    final d1 = positiveMod(invS * u1, primeP);
    final d2 = positiveMod(invS * u2, primeP);
    final zInverse = positiveMod(d1 * d2 * t, primeP);
    BigInt D;
    if (isOdd(t * zInverse, primeP)) {
      final x2 = positiveMod(y * sqrtM1, primeP);
      final y2 = positiveMod(x * sqrtM1, primeP);
      x = x2;
      y = y2;
      D = positiveMod(d1 * invSqrt, primeP);
    } else {
      D = d2;
    }
    if (isOdd(x * zInverse, primeP)) {
      y = positiveMod(-y, primeP);
    }
    BigInt s = positiveMod((z - y) * D, primeP);
    if (isOdd(s, primeP)) {
      s = positiveMod(-s, primeP);
    }
    return s.toLeBytes(length: 32);
  }
}
