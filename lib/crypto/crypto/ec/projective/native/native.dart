// "python-ecdsa" Copyright (c) 2010 Brian Warner

// Portions written in 2005 by Peter Pearson and placed in the public domain.

// Permission is hereby granted, free of charge, to any person
// obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use,
// copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following
// conditions:

// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
// OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
// HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
// WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.

import 'package:blockchain_utils/crypto/crypto/ec/curve/curve.dart';
import 'package:blockchain_utils/crypto/crypto/ec/core/point.dart';
import 'package:blockchain_utils/crypto/crypto/ec/projective/native/affine_native.dart';
import 'package:blockchain_utils/crypto/crypto/ec/utils/utils.dart';
import 'package:blockchain_utils/crypto/crypto/exception/exception.dart';
import 'package:blockchain_utils/utils/numbers/numbers.dart';

class _NativeProjectiveUtils {
  static (BigInt, BigInt) fromBytes(
    Curve curve,
    List<int> data, {
    EncodeType? encodeType,
  }) {
    final keyLen = data.length;
    final rawEncodingLength = 2 * BigintUtils.bitlengthInBytes(curve.p);
    if (encodeType == null) {
      if (keyLen == rawEncodingLength) {
        encodeType = EncodeType.raw;
      } else if (keyLen == rawEncodingLength + 1) {
        final prefix = data[0];
        if (prefix == 0x04) {
          encodeType = EncodeType.uncompressed;
        } else if (prefix == 0x06 || prefix == 0x07) {
          encodeType = EncodeType.hybrid;
        } else {
          throw const CryptoException("invalid key length");
        }
      } else if (keyLen == rawEncodingLength ~/ 2 + 1) {
        encodeType = EncodeType.comprossed;
      } else {
        throw const CryptoException("invalid key length");
      }
    }
    curve as CurveFp;
    switch (encodeType) {
      case EncodeType.comprossed:
        return _fromCompressed(data, curve);
      case EncodeType.uncompressed:
        return _fromRawEncoding(data.sublist(1), rawEncodingLength);
      case EncodeType.hybrid:
        return _fromHybrid(data, rawEncodingLength);
      default:
        return _fromRawEncoding(data, rawEncodingLength);
    }
  }

  /// Creates an elliptic curve point from a raw byte encoding.
  static (BigInt, BigInt) _fromRawEncoding(
    List<int> data,
    int rawEncodingLength,
  ) {
    assert(data.length == rawEncodingLength);

    final xs = data.sublist(0, rawEncodingLength ~/ 2);
    final ys = data.sublist(rawEncodingLength ~/ 2);

    assert(xs.length == rawEncodingLength ~/ 2);
    assert(ys.length == rawEncodingLength ~/ 2);

    final coordX = BigintUtils.fromBytes(xs);
    final coordY = BigintUtils.fromBytes(ys);

    return (coordX, coordY);
  }

  /// Creates an elliptic curve point from a compressed byte encoding.
  static (BigInt, BigInt) _fromCompressed(List<int> data, CurveFp curve) {
    if (data[0] != 0x02 && data[0] != 0x03) {
      throw const CryptoException('Malformed compressed point encoding');
    }

    final isEven = data[0] == 0x02;
    final x = BigintUtils.fromBytes(data.sublist(1));
    final p = curve.p;

    final alpha = (x.modPow(BigInt.from(3), p) + curve.a * x + curve.b) % p;

    final beta = ECDSAUtils.modularSquareRootPrime(alpha, p);
    final betaEven = (beta & BigInt.one == BigInt.zero) ? false : true;
    if (isEven == betaEven) {
      final y = p - beta;
      return (x, y);
    } else {
      return (x, beta);
    }
  }

  /// Creates an elliptic curve point from a hybrid byte encoding.
  static (BigInt, BigInt) _fromHybrid(List<int> data, int rawEncodingLength) {
    assert(data[0] == 0x06 || data[0] == 0x07);

    // Primarily use the uncompressed as it's easiest to handle
    final result = _fromRawEncoding(data.sublist(1), rawEncodingLength);
    final x = result.$1;
    final y = result.$2;
    final prefix = y & BigInt.one;
    // Validate if it's self-consistent if we're asked to do that
    if (((prefix == BigInt.one && data[0] != 0x07) ||
        (prefix == BigInt.zero && data[0] != 0x06))) {
      throw const CryptoException('Inconsistent hybrid point encoding');
    }

    return (x, y);
  }
}

/// Represents a point in projective coordinates on an elliptic curve.
class ProjectiveECCPoint extends ProjectivePointNative {
  /// Constructs a [ProjectiveECCPoint] from the given coordinates and optional order and generator flag.
  /// The [curve] parameter specifies the elliptic curve.
  /// [x], [y], and [z] are the projective coordinates of the point.
  /// [order] is the order of the point, and [generator] indicates if the point is a generator.
  factory ProjectiveECCPoint({
    required CurveFp curve,
    required BigInt x,
    required BigInt y,
    required BigInt z,
    BigInt? order,
    bool generator = false,
  }) {
    final coords = [x, y, z];
    return ProjectiveECCPoint._(
      curve,
      coords,
      generator: generator,
      order: order,
    );
  }

  /// Constructs a special [ProjectiveECCPoint] representing infinity on the elliptic curve.
  /// The [curve] parameter specifies the elliptic curve.
  factory ProjectiveECCPoint.infinity(CurveFp curve) {
    return ProjectiveECCPoint._(
      curve,
      [BigInt.zero, BigInt.zero, BigInt.zero],
      generator: false,
      order: null,
    );
  }

  /// Constructs a [ProjectiveECCPoint] from a byte representation.
  /// The [curve] parameter specifies the elliptic curve, and [data] is the byte data.
  /// [order] is the order of the point.
  factory ProjectiveECCPoint.fromBytes({
    required CurveFp curve,
    required List<int> data,
    BigInt? order,
  }) {
    final coords = _NativeProjectiveUtils.fromBytes(curve, data);
    final x = coords.$1;
    final y = coords.$2;
    return ProjectiveECCPoint(
      curve: curve,
      x: x,
      y: y,
      z: BigInt.one,
      generator: false,
      order: order,
    );
  }

  ///  The elliptic curve associated with this point.
  @override
  final CurveFp curve;

  /// The order of the point (can be null if unknown).
  @override
  final BigInt? order;

  /// Indicates whether the point is a generator.
  final bool generator;

  /// List of precomputed values for point operations.
  List<List<BigInt>> _precompute;

  /// List of projective coordinates [x, y, z].
  List<BigInt> _coords;

  List<BigInt> getCoords() => List.from(_coords);

  /// check if point is infinity
  @override
  bool isZero() =>
      _coords.isEmpty ||
      (_coords[0] == BigInt.zero && _coords[1] == BigInt.zero);

  /// Private constructor for creating a [ProjectiveECCPoint].
  /// [curve] is the elliptic curve.
  /// [order] is the order of the point, and [generator] indicates if the point is a generator.
  /// [precompute] is a list of precomputed values for point operations.
  ProjectiveECCPoint._(
    this.curve,
    this._coords, {
    this.order,
    bool generator = false,
    List<List<BigInt>> precompute = const [],
  }) : _precompute = precompute,
       generator = generator && order != null;

  /// Precompute values for faster point operations if necessary.
  void _precomputeIfNeeded() {
    // If not a generator or precomputation is already done, return.
    if (!generator || _precompute.isNotEmpty) {
      return;
    }

    // Ensure the order is not null.
    assert(order != null);
    BigInt newOrder = order!;

    // Initialize a list to store precomputed values.
    final List<List<BigInt>> precomputedPoints = [];

    BigInt i = BigInt.one;
    newOrder *= BigInt.two;

    // Extract projective coordinates.
    final BigInt xCoord = _coords[0];
    final BigInt yCoord = _coords[1];
    final BigInt zCoord = _coords[2];

    // Create a projective point for doubling.
    ProjectiveECCPoint doubler = ProjectiveECCPoint._(curve, [
      xCoord,
      yCoord,
      zCoord,
    ], order: order);

    newOrder *= BigInt.two;
    precomputedPoints.add([doubler.x, doubler.y]);

    while (i < newOrder) {
      i *= BigInt.two;
      doubler = doubler.double().scale();
      precomputedPoints.add([doubler.x, doubler.y]);
    }

    // Update the precomputed values.
    _precompute = precomputedPoints;
  }

  @override
  ProjectiveECCPoint operator -() {
    final x = _coords[0];
    final y = _coords[1];
    final z = _coords[2];
    return ProjectiveECCPoint._(curve, [x, -y, z], order: order);
  }

  /// equal operation
  @override
  bool operator ==(other) {
    if (other is! BaseProjectivePointNative) {
      return false;
    }
    // Extract coordinates for the current point.
    final BigInt x1 = _coords[0];
    final BigInt y1 = _coords[1];
    final BigInt z1 = _coords[2];

    // Get the prime field modulus from the curve.
    final p = curve.p;

    // Calculate the square of z1 modulo p.
    final zz1 = (z1 * z1) % p;

    // If 'other' represents an infinity point, check if this point is also at infinity.
    if (other.isZero()) {
      return y1 == BigInt.zero || z1 == BigInt.zero;
    }

    // Extract coordinates for 'other' point.
    BigInt x2;
    BigInt y2;
    BigInt z2;
    if (other is ProjectivAffinePoint) {
      x2 = other.x;
      y2 = other.y;
      z2 = BigInt.one;
    } else if (other is ProjectiveECCPoint) {
      x2 = other._coords[0];
      y2 = other._coords[1];
      z2 = other._coords[2];
    } else {
      return false;
    }

    // Ensure both points belong to the same curve.
    if (curve != other.curve) {
      return false;
    }

    // Calculate the square of z2 modulo p.
    final zz2 = (z2 * z2) % p;

    // Check if the points are equal in projective coordinates.
    return ((x1 * zz2 - x2 * zz1) % p == BigInt.zero) &&
        ((y1 * zz2 * z2 - y2 * zz1 * z1) % p == BigInt.zero);
  }

  /// Get the x-coordinate of this point in the projective elliptic curve coordinates.
  @override
  BigInt get x {
    /// Extract the x-coordinate and z-coordinate from the point's coordinates.
    final xCoordinate = _coords[0];
    final zCoordinate = _coords[2];

    /// If z-coordinate is one, return the x-coordinate as it is.
    if (zCoordinate == BigInt.one) {
      return xCoordinate;
    }

    /// Get the prime field modulus from the curve.
    final p = curve.p;

    /// Calculate the inverse of z-coordinate modulo p.
    final zInverse = BigintUtils.inverseMod(zCoordinate, p);

    /// Compute and return the x-coordinate in projective coordinates.
    final result = (xCoordinate * zInverse * zInverse) % p;
    return result;
  }

  /// Get the y-coordinate of this point in projective elliptic curve coordinates.
  @override
  BigInt get y {
    final yCoordinate = _coords[1];
    final zCoordinate = _coords[2];
    final primeField = curve.p;

    // Check if the z-coordinate is already one.
    if (zCoordinate == BigInt.one) {
      return yCoordinate;
    }

    // Calculate the modular inverse of z-coordinate.
    final zInverse = BigintUtils.inverseMod(zCoordinate, primeField);

    // Compute the normalized y-coordinate using the formula.
    final normalizedY =
        (yCoordinate * zInverse * zInverse * zInverse) % primeField;

    return normalizedY;
  }

  /// The coordinates are updated to the scaled values, and the scaled point is returned.
  ProjectiveECCPoint scale() {
    final currentZ = _coords[2];

    /// If the current z-coordinate is already one, no need to scale
    if (currentZ == BigInt.one) {
      return this;
    }
    final currentY = _coords[1];
    final currentX = _coords[0];

    /// Get the prime field value
    final primeField = curve.p;

    /// Calculate the modular inverse of z
    final zInverse = BigintUtils.inverseMod(currentZ, primeField);

    /// Calculate z-inverse squared
    final zInverseSquared = (zInverse * zInverse) % primeField;

    /// Scale the x and y coordinates
    final scaledX = (currentX * zInverseSquared) % primeField;
    final scaledY = (currentY * zInverseSquared * zInverse) % primeField;

    /// Update the coordinates to the scaled values
    _coords = [scaledX, scaledY, BigInt.one];

    return this;
  }

  /// Converts the projective point to an affine point.
  ProjectivAffinePoint toAffine() {
    ///  Current y-coordinate
    final y = _coords[1];

    ///  Current z-coordinate
    final z = _coords[2];

    if (y == BigInt.zero || z == BigInt.zero) {
      return ProjectivAffinePoint.zero(curve);
    }

    /// Scale the point to its affine form
    scale();

    /// Scaled x-coordinate
    final x = _coords[0];

    /// Affine y-coordinate
    final yAffine = y;

    return ProjectivAffinePoint(curve, x, yAffine, order: order);
  }

  /// Constructs a [ProjectiveECCPoint] from an [BaseProjectivePointNative] in affine coordinates.
  factory ProjectiveECCPoint.fromAffine(
    BaseProjectivePointNative point, {
    bool generator = false,
  }) {
    return ProjectiveECCPoint._(
      point.curve,
      [point.x, point.y, BigInt.one],
      generator: generator,
      order: point.order,
    );
  }

  /// Doubles a point
  List<BigInt> _doubleWithZ1(BigInt x1, BigInt y1, BigInt p, BigInt a) {
    // Calculate x-coordinate squared
    final BigInt xSquared = (x1 * x1) % p;

    // Calculate y-coordinate squared
    final BigInt ySquared = (y1 * y1) % p;

    // Check if y-coordinate squared is zero
    if (ySquared == BigInt.zero) {
      // If y-coordinate squared is zero, return the point at infinity
      return [BigInt.zero, BigInt.zero, BigInt.one];
    }

    // Calculate y-coordinate squared squared
    final BigInt ySquaredSquared = (ySquared * ySquared) % p;

    // Calculate 's' value
    final BigInt s =
        (BigInt.two *
            ((x1 + ySquared) * (x1 + ySquared) - xSquared - ySquaredSquared)) %
        p;

    // Calculate 'm' value
    final BigInt m = (BigInt.from(3) * xSquared + a) % p;

    // Calculate 't' value
    final BigInt t = (m * m - BigInt.from(2) * s) % p;

    // Calculate y-coordinate of the result and update Z-coordinate
    final BigInt yResult = (m * (s - t) - BigInt.from(8) * ySquaredSquared) % p;
    final BigInt zResult = (BigInt.two * y1) % p;

    return [t, yResult, zResult];
  }

  /// Doubles a point in projective coordinates on an elliptic curve, returning the resulting point.
  List<BigInt> _double(BigInt x1, BigInt y1, BigInt z1, BigInt p, BigInt a) {
    if (z1 == BigInt.one) {
      // If z-coordinate is one, use an optimized version of the doubling operation
      return _doubleWithZ1(x1, y1, p, a);
    }

    if (y1 == BigInt.zero || z1 == BigInt.zero) {
      // If y-coordinate or z-coordinate is zero, return the point at infinity
      return [BigInt.zero, BigInt.zero, BigInt.one];
    }

    // Calculate x-coordinate squared
    final BigInt xSquared = (x1 * x1) % p;

    // Calculate y-coordinate squared
    final BigInt ySquared = (y1 * y1) % p;

    // Check if y-coordinate squared is zero
    if (ySquared == BigInt.zero) {
      // If y-coordinate squared is zero, return the point at infinity
      return [BigInt.zero, BigInt.zero, BigInt.one];
    }

    // Calculate y-coordinate squared squared
    final BigInt ySquaredSquared = (ySquared * ySquared) % p;

    // Calculate z-coordinate squared
    final BigInt zSquared = (z1 * z1) % p;

    // Calculate 's' value
    final BigInt s =
        (BigInt.two *
            ((x1 + ySquared) * (x1 + ySquared) - xSquared - ySquaredSquared)) %
        p;

    // Calculate 'm' value
    final BigInt m =
        ((BigInt.from(3) * xSquared + a * zSquared * zSquared) % p);

    // Calculate 't' value
    final BigInt t = (m * m - BigInt.from(2) * s) % p;

    // Calculate y-coordinate of the result
    final BigInt yResult = (m * (s - t) - BigInt.from(8) * ySquaredSquared) % p;

    // Calculate z-coordinate of the result
    final BigInt zResult = ((y1 + z1) * (y1 + z1) - ySquared - zSquared) % p;

    return [t, yResult, zResult];
  }

  /// Doubles a point in projective coordinates on an elliptic curve and returns the result.
  @override
  ProjectiveECCPoint double() {
    final BigInt x1 = _coords[0];
    final BigInt y1 = _coords[1];
    final BigInt z1 = _coords[2];

    if (y1 == BigInt.zero) {
      // If y-coordinate is zero, the result is the point at infinity
      return ProjectiveECCPoint.infinity(curve);
    }

    final BigInt primeField = curve.p;
    final BigInt curveA = curve.a;

    final List<BigInt> result = _double(x1, y1, z1, primeField, curveA);

    if (result[1] == BigInt.zero || result[2] == BigInt.zero) {
      // If the y-coordinate or z-coordinate of the result is zero, return the point at infinity
      return ProjectiveECCPoint.infinity(curve);
    }

    return ProjectiveECCPoint(
      curve: curve,
      x: result[0],
      y: result[1],
      z: result[2],
      order: order,
    );
  }

  List<BigInt> _addPointsWithZ1(
    BigInt x1,
    BigInt y1,
    BigInt x2,
    BigInt y2,
    BigInt p,
  ) {
    // Calculate the difference and its square
    final BigInt diff = x2 - x1;
    final BigInt diffSquare = diff * diff;

    // Calculate intermediate values I and J
    final BigInt I = (diffSquare * BigInt.from(4)) % p;
    final BigInt J = diff * I;

    // Calculate the y-coordinate difference scaled by 2
    final BigInt scaledYDifference = (y2 - y1) * BigInt.from(2);

    if (diff == BigInt.zero && scaledYDifference == BigInt.zero) {
      // If the difference and scaled y-coordinate difference are both zero,
      // perform a doubling operation
      return _doubleWithZ1(x1, y1, p, curve.a);
    }

    // Calculate intermediate value V
    final BigInt V = x1 * I;

    // Calculate the x, y, and z coordinates of the result
    final BigInt x3 =
        (scaledYDifference * scaledYDifference - J - V * BigInt.from(2)) % p;
    final BigInt y3 =
        (scaledYDifference * (V - x3) - y1 * J * BigInt.from(2)) % p;
    final BigInt z3 = diff * BigInt.from(2) % p;

    return [x3, y3, z3];
  }

  List<BigInt> _addPointsWithCommonZ(
    BigInt x1,
    BigInt y1,
    BigInt z1,
    BigInt x2,
    BigInt y2,
    BigInt p,
  ) {
    // Calculate intermediate values A, B, C, and D
    final BigInt A = (x2 - x1).modPow(BigInt.from(2), p);
    final BigInt B = (x1 * A) % p;
    final BigInt C = x2 * A;
    final BigInt D = (y2 - y1).modPow(BigInt.from(2), p);

    if (A == BigInt.zero && D == BigInt.zero) {
      // If A and D are both zero, perform a doubling operation
      return _double(x1, y1, z1, p, curve.a);
    }

    // Calculate the x, y, and z coordinates of the result
    final BigInt x3 = (D - B - C) % p;
    final BigInt y3 = ((y2 - y1) * (B - x3) - y1 * (C - B)) % p;
    final BigInt z3 = (z1 * (x2 - x1)) % p;

    return [x3, y3, z3];
  }

  List<BigInt> _addPointsWithZ2EqualOne(
    BigInt x1,
    BigInt y1,
    BigInt z1,
    BigInt x2,
    BigInt y2,
    BigInt p,
  ) {
    // Calculate Z1Z1, U2, and S2
    final BigInt z1z1 = (z1 * z1) % p;
    final BigInt u2 = (x2 * z1z1) % p;
    final BigInt s2 = (y2 * z1 * z1z1) % p;

    // Calculate H, HH, I, and J
    final BigInt h = (u2 - x1) % p;
    final BigInt hh = (h * h) % p;
    final BigInt i = (BigInt.from(4) * hh) % p;
    final BigInt j = (h * i) % p;
    final BigInt r = (BigInt.from(2) * (s2 - y1)) % p;

    if (r == BigInt.zero && h == BigInt.zero) {
      // If r and h are both zero, perform a doubling operation
      return _doubleWithZ1(x2, y2, p, curve.a);
    }

    // Calculate the x, y, and z coordinates of the result
    final BigInt v = (x1 * i) % p;
    final BigInt x3 = (r * r - j - BigInt.from(2) * v) % p;
    final BigInt y3 = (r * (v - x3) - BigInt.from(2) * y1 * j) % p;
    final BigInt z3 = (((z1 + h).modPow(BigInt.from(2), p) - z1z1) - hh) % p;

    return [x3, y3, z3];
  }

  List<BigInt> _addPointsWithZNotEqual(
    BigInt x1,
    BigInt y1,
    BigInt z1,
    BigInt x2,
    BigInt y2,
    BigInt z2,
    BigInt p,
  ) {
    // Calculate Z1Z1, Z2Z2, U1, U2, S1, S2
    final BigInt z1z1 = (z1 * z1) % p;
    final BigInt z2z2 = (z2 * z2) % p;
    final BigInt u1 = (x1 * z2z2) % p;
    final BigInt u2 = (x2 * z1z1) % p;
    final BigInt s1 = (y1 * z2 * z2z2) % p;
    final BigInt s2 = (y2 * z1 * z1z1) % p;

    // Calculate H, I, J, and r
    final BigInt h = (u2 - u1) % p;
    final BigInt i = (BigInt.from(4) * h * h) % p;
    final BigInt j = (h * i) % p;
    final BigInt r = (BigInt.from(2) * (s2 - s1)) % p;

    if (h == BigInt.zero && r == BigInt.zero) {
      // If h and r are both zero, perform a doubling operation
      return _double(x1, y1, z1, p, curve.a);
    }

    // Calculate the x, y, and z coordinates of the result
    final BigInt v = (u1 * i) % p;
    final BigInt x3 = (r * r - j - BigInt.from(2) * v) % p;
    final BigInt y3 = (r * (v - x3) - BigInt.from(2) * s1 * j) % p;
    final BigInt z3 =
        (((z1 + z2).modPow(BigInt.from(2), p) - z1z1 - z2z2) * h) % p;

    return [x3, y3, z3];
  }

  /// Adds two points in projective coordinates on an elliptic curve and returns the result.
  List<BigInt> _addPoints(
    BigInt x1,
    BigInt y1,
    BigInt z1,
    BigInt x2,
    BigInt y2,
    BigInt z2,
    BigInt p,
  ) {
    if (y1 == BigInt.zero || z1 == BigInt.zero) {
      // If the first point is at infinity, return the second point
      return [x2, y2, z2];
    }
    if (y2 == BigInt.zero || z2 == BigInt.zero) {
      // If the second point is at infinity, return the first point
      return [x1, y1, z1];
    }
    if (z1 == z2) {
      if (z1 == BigInt.one) {
        // If both points have z equal to one, perform the addition
        return _addPointsWithZ1(x1, y1, x2, y2, p);
      }
      // If z-coordinates are equal but not one, perform the addition
      return _addPointsWithCommonZ(x1, y1, z1, x2, y2, p);
    }
    if (z1 == BigInt.one) {
      // If the first point has z equal to one, perform the addition
      return _addPointsWithZ2EqualOne(x2, y2, z2, x1, y1, p);
    }
    if (z2 == BigInt.one) {
      // If the second point has z equal to one, perform the addition
      return _addPointsWithZ2EqualOne(x1, y1, z1, x2, y2, p);
    }
    // If none of the special cases apply, perform the addition with different z-coordinates
    return _addPointsWithZNotEqual(x1, y1, z1, x2, y2, z2, p);
  }

  @override
  BaseProjectivePointNative operator +(BaseProjectivePointNative other) {
    if (isZero()) {
      return other;
    }
    if (other.isZero()) {
      return this;
    }
    final point = switch (other) {
      final ProjectiveECCPoint point => point,
      _ => ProjectiveECCPoint.fromAffine(other),
    };
    // Get the prime field value
    final BigInt primeField = curve.p;

    // Extract coordinates of the first point
    final BigInt x1 = _coords[0];
    final BigInt y1 = _coords[1];
    final BigInt z1 = _coords[2];

    // Extract coordinates of the second point
    final BigInt x2 = point._coords[0];
    final BigInt y2 = point._coords[1];
    final BigInt z2 = point._coords[2];

    // Perform point addition
    final List<BigInt> result = _addPoints(x1, y1, z1, x2, y2, z2, primeField);

    final BigInt x3 = result[0];
    final BigInt y3 = result[1];
    final BigInt z3 = result[2];

    if (y3 == BigInt.zero || z3 == BigInt.zero) {
      return ProjectiveECCPoint.infinity(curve);
    }

    return ProjectiveECCPoint._(curve, [x3, y3, z3], order: order);
  }

  /// Multiplies this point by a scalar using precomputed values.
  ProjectiveECCPoint _multiplyWithPrecompute(BigInt scalar) {
    BigInt resultX = BigInt.zero,
        resultY = BigInt.zero,
        resultZ = BigInt.one,
        primeField = curve.p;
    final List<List<BigInt>> precompute = List.from(_precompute);

    for (int i = 0; i < precompute.length; i++) {
      final BigInt x2 = precompute[i][0];
      final BigInt y2 = precompute[i][1];

      if (scalar.isOdd) {
        final flag = scalar % BigInt.from(4);
        if (flag >= BigInt.two) {
          scalar = (scalar + BigInt.one) ~/ BigInt.two;
          final List<BigInt> addResult = _addPoints(
            resultX,
            resultY,
            resultZ,
            x2,
            -y2,
            BigInt.one,
            primeField,
          );
          resultX = addResult[0];
          resultY = addResult[1];
          resultZ = addResult[2];
        } else {
          scalar = (scalar - BigInt.one) ~/ BigInt.two;
          final List<BigInt> addResult = _addPoints(
            resultX,
            resultY,
            resultZ,
            x2,
            y2,
            BigInt.one,
            primeField,
          );
          resultX = addResult[0];
          resultY = addResult[1];
          resultZ = addResult[2];
        }
      } else {
        scalar ~/= BigInt.two;
      }
    }

    if (resultY == BigInt.zero || resultZ == BigInt.zero) {
      return ProjectiveECCPoint.infinity(curve);
    }

    return ProjectiveECCPoint._(curve, [
      resultX,
      resultY,
      resultZ,
    ], order: order);
  }

  /// Multiplies this point by a scalar value.
  @override
  ProjectiveECCPoint operator *(BigInt scalar) {
    if (_coords[1] == BigInt.zero || scalar == BigInt.zero) {
      return ProjectiveECCPoint.infinity(curve);
    }
    if (scalar == BigInt.one) {
      return this;
    }
    if (order != null) {
      // Perform modulo operation for scalar if an order is defined
      // order*2 as a protection for Minerva
      scalar = scalar % (order! * BigInt.two);
    }

    _precomputeIfNeeded();
    if (_precompute.isNotEmpty) {
      return _multiplyWithPrecompute(scalar);
    }

    scale();

    // Initialize point coordinates
    final BigInt x2 = _coords[0];
    final BigInt y2 = _coords[1];

    BigInt x3 = BigInt.zero;
    BigInt y3 = BigInt.zero;
    BigInt z3 = BigInt.one;

    final BigInt primeField = curve.p;
    final BigInt curveA = curve.a;

    // Since adding points when at least one of them is scaled
    // is quicker, reverse the NAF order
    final List<BigInt> nafList = ECDSAUtils.computeNAF(scalar);
    for (int i = nafList.length - 1; i >= 0; i--) {
      final List<BigInt> double = _double(x3, y3, z3, primeField, curveA);
      x3 = double[0];
      y3 = double[1];
      z3 = double[2];
      if (nafList[i] < BigInt.zero) {
        final add = _addPoints(x3, y3, z3, x2, -y2, BigInt.one, primeField);
        x3 = add[0];
        y3 = add[1];
        z3 = add[2];
      } else if (nafList[i] > BigInt.zero) {
        final add = _addPoints(x3, y3, z3, x2, y2, BigInt.one, primeField);
        x3 = add[0];
        y3 = add[1];
        z3 = add[2];
      }
    }

    if (y3 == BigInt.zero || z3 == BigInt.zero) {
      return ProjectiveECCPoint.infinity(curve);
    }

    return ProjectiveECCPoint._(curve, [x3, y3, z3], order: order);
  }

  /// Multiplies this point by a scalar value `selfMul` and adds another point
  /// `otherPoint` multiplied by `otherMul`.
  ///
  /// Parameters:
  /// - `selfMul`: Scalar value to multiply this point by.
  /// - `otherPoint`: The other point to multiply.
  /// - `otherMul`: Scalar value to multiply the `otherPoint` by.
  ///
  /// Returns:
  /// - A new [ProjectiveECCPoint] representing the result of the operation.
  ProjectiveECCPoint mulAdd(
    BigInt selfMul,
    ProjectivePointNative otherPoint,
    BigInt otherMul,
  ) {
    if (otherPoint.isZero() || otherMul == BigInt.zero) {
      return this * selfMul;
    }
    if (selfMul == BigInt.zero) {
      return (otherPoint * otherMul).cast<ProjectiveECCPoint>();
    }
    final other = switch (otherPoint) {
      final ProjectiveECCPoint point => point,
      _ => ProjectiveECCPoint.fromAffine(otherPoint),
    };
    _precomputeIfNeeded();
    other._precomputeIfNeeded();
    if (_precompute.isNotEmpty && other._precompute.isNotEmpty) {
      return (this * selfMul + other * otherMul).cast<ProjectiveECCPoint>();
    }
    final order = this.order;
    if (order != null) {
      selfMul = selfMul % order;
      otherMul = otherMul % order;
    }

    BigInt x3 = BigInt.zero;
    BigInt y3 = BigInt.zero;
    BigInt z3 = BigInt.one;
    final BigInt p = curve.p;
    final BigInt a = curve.a;

    scale();
    final BigInt x1 = _coords[0];
    final BigInt y1 = _coords[1];
    final BigInt z1 = _coords[2];
    other.scale();
    final BigInt x2 = other._coords[0];
    final BigInt y2 = other._coords[1];
    final BigInt z2 = other._coords[2];

    // with NAF we have 3 options: no add, subtract, add
    // so with 2 points, we have 9 combinations:
    // 0, -A, +A, -B, -A-B, +A-B, +B, -A+B, +A+B
    // so we need 4 combined points:
    final List<BigInt> mAmB = _addPoints(x1, -y1, z1, x2, -y2, z2, p);

    final List<BigInt> pAmB = _addPoints(x1, y1, z1, x2, -y2, z2, p);

    final List<BigInt> mApB = [pAmB[0], -pAmB[1], pAmB[2]];
    final List<BigInt> pApB = [mAmB[0], -mAmB[1], mAmB[2]];

    if (pApB[1] == BigInt.zero || pApB[2] == BigInt.zero) {
      return (this * selfMul + other * otherMul) as ProjectiveECCPoint;
    }

    List<BigInt> selfNaf = ECDSAUtils.computeNAF(selfMul).reversed.toList();
    List<BigInt> otherNaf = ECDSAUtils.computeNAF(otherMul).reversed.toList();

    if (selfNaf.length < otherNaf.length) {
      selfNaf =
          List.filled(otherNaf.length - selfNaf.length, BigInt.zero) + selfNaf;
    } else if (selfNaf.length > otherNaf.length) {
      otherNaf =
          List.filled(selfNaf.length - otherNaf.length, BigInt.zero) + otherNaf;
    }

    for (int i = 0; i < selfNaf.length; i++) {
      final BigInt A = selfNaf[i];
      final BigInt B = otherNaf[i];

      List<BigInt> result = _double(x3, y3, z3, p, a);

      // conditions ordered from most to least likely
      if (A == BigInt.zero) {
        if (B == BigInt.zero) {
          // Do nothing.
        } else if (B < BigInt.zero) {
          result = _addPoints(result[0], result[1], result[2], x2, -y2, z2, p);
        } else {
          assert(B > BigInt.zero);
          result = _addPoints(result[0], result[1], result[2], x2, y2, z2, p);
        }
      } else if (A < BigInt.zero) {
        if (B == BigInt.zero) {
          result = _addPoints(result[0], result[1], result[2], x1, -y1, z1, p);
        } else if (B < BigInt.zero) {
          result = _addPoints(
            result[0],
            result[1],
            result[2],
            mAmB[0],
            mAmB[1],
            mAmB[2],
            p,
          );
        } else {
          assert(B > BigInt.zero);
          result = _addPoints(
            result[0],
            result[1],
            result[2],
            mApB[0],
            mApB[1],
            mApB[2],
            p,
          );
        }
      } else {
        assert(A > BigInt.zero);
        if (B == BigInt.zero) {
          result = _addPoints(result[0], result[1], result[2], x1, y1, z1, p);
        } else if (B < BigInt.zero) {
          result = _addPoints(
            result[0],
            result[1],
            result[2],
            pAmB[0],
            pAmB[1],
            pAmB[2],
            p,
          );
        } else {
          assert(B > BigInt.zero);
          result = _addPoints(
            result[0],
            result[1],
            result[2],
            pApB[0],
            pApB[1],
            pApB[2],
            p,
          );
        }
      }

      x3 = result[0];
      y3 = result[1];
      z3 = result[2];
    }

    if (y3 == BigInt.zero || z3 == BigInt.zero) {
      return ProjectiveECCPoint.infinity(curve);
    }

    return ProjectiveECCPoint._(curve, [x3, y3, z3], order: order);
  }

  @override
  int get hashCode => curve.hashCode ^ x.hashCode ^ y.hashCode;

  bool get isOdd => y.isOdd;
  bool get isEven => y.isEven;
  List<int> toXonly() {
    return toBytes().sublist(1);
  }

  @override
  BigInt get z => _coords[2];
}
