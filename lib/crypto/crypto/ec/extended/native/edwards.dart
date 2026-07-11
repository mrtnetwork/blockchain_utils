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

import 'dart:typed_data' show Endian;
import 'package:blockchain_utils/crypto/crypto/ec/core/point.dart';
import 'package:blockchain_utils/crypto/crypto/ec/utils/utils.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';

import 'package:blockchain_utils/crypto/crypto/ec/curve/curve.dart';
import 'package:blockchain_utils/utils/numbers/utils/bigint_utils.dart';

/// A class representing a point on an Edwards curve.
class EDPoint extends BaseExtendedPointNative {
  /// The Edwards curve associated with this point.
  @override
  final CurveED curve;

  /// The order of the point (null if not set).
  final BigInt? order;

  /// Indicates if this point is a generator point.
  final bool generator;

  /// List of precomputed values (for internal use).
  List<List<BigInt>> _precompute;

  /// List of coordinates representing the point.
  final List<BigInt> _coords;

  /// A factory constructor to create an infinity point on an Edwards curve.
  ///
  /// Parameters:
  /// - [curve]: The Edwards curve associated with the point.
  ///
  factory EDPoint.infinity({required CurveED curve}) {
    return EDPoint._(curve, [
      BigInt.zero,
      BigInt.zero,
      BigInt.zero,
      BigInt.zero,
    ]);
  }

  /// Private constructor for creating an [EDPoint] with specified curve, coordinates, and optional order.
  ///
  /// Parameters:
  /// - [curve]: The Edwards curve associated with the point.
  /// - [_coords]: List of coordinates representing the point.
  /// - [order]: The order of the point (optional).
  ///
  EDPoint._(this.curve, this._coords, {this.order})
    : _precompute = const [],
      generator = false;

  /// Constructor for creating an [EDPoint] with explicit coordinates and optional parameters.
  ///
  /// Parameters:
  /// - [curve]: The Edwards curve associated with the point.
  /// - [x]: The x-coordinate of the point.
  /// - [y]: The y-coordinate of the point.
  /// - [z]: The z-coordinate of the point.
  /// - [t]: The t-coordinate of the point.
  /// - [order]: The order of the point (optional).
  /// - [generator]: A flag indicating if this point is a generator point (default is `false`).
  ///
  EDPoint({
    required this.curve,
    required BigInt x,
    required BigInt y,
    required BigInt z,
    required BigInt t,
    this.order,
    this.generator = false,
  }) : _coords = [x, y, z, t],
       _precompute = const [];

  BigInt get t => _coords[3];

  BigInt get z => _coords[2];

  /// Factory constructor to create an [EDPoint] from a byte representation.
  ///
  /// Parameters:
  /// - [curve]: The Edwards curve associated with the point.
  /// - [data]: The byte array representing the point's coordinates.
  /// - [order]: The order of the point (optional).
  ///
  factory EDPoint.fromBytes({
    required CurveED curve,
    required List<int> data,
    BigInt? order,
  }) {
    data = data.clone();
    final p = curve.p;
    final expLen = (p.bitLength + 1 + 7) ~/ 8;

    if (data.length != expLen) {
      throw ArgumentException.invalidOperationArguments(
        "EDPoint",
        name: "data",
        reason: "Incorrect bytes length.",
      );
    }

    final x0 = (data[expLen - 1] & 0x80) >> 7;
    data[expLen - 1] &= 0x80 - 1;

    final y = BigintUtils.fromBytes(data, byteOrder: Endian.little);

    final x2 =
        (y * y - BigInt.from(1)) *
        BigintUtils.inverseMod(curve.d * y * y - curve.a, p) %
        p;
    BigInt x = ECDSAUtils.modularSquareRootPrime(x2, p);
    if (x.isOdd != (x0 == 1)) {
      x = (-x) % p;
    }
    final t = x * y;
    return EDPoint(
      curve: curve,
      x: x,
      y: y,
      z: BigInt.one,
      t: t,
      generator: false,
      order: order,
    );
  }

  void _maybePrecompute() {
    /// Precomputation is only needed for generator points, and it should not be recomputed if already available.
    if (!generator || _precompute.isNotEmpty) {
      return;
    }
    BigInt newOrder = order!;

    /// Initialize a list to store computed values.
    final List<List<BigInt>> compute = [];
    BigInt i = BigInt.one;
    newOrder *= BigInt.from(2);
    final List<BigInt> coordsList = getCoords();

    /// Create a temporary point for doubling.
    EDPoint doubler = EDPoint._(curve, getCoords(), order: newOrder);

    newOrder *= BigInt.from(4);

    /// Iterate through point doubling and store computed values in the list.
    while (i < newOrder) {
      doubler = doubler.scale();
      coordsList[0] = doubler._coords[0];
      coordsList[1] = doubler._coords[1];
      coordsList[3] = doubler._coords[3];

      i *= BigInt.two;
      doubler = doubler.double();

      compute.add([coordsList[0], coordsList[1], coordsList[3]]);
    }

    /// Set the precomputed values in the [_precompute] list.
    _precompute = compute;
  }

  List<BigInt> getCoords() {
    return List.from(_coords);
  }

  /// Get the x-coordinate of the Edwards curve point.
  @override
  BigInt get x {
    final BigInt x1 = _coords[0];
    final BigInt z1 = _coords[2];

    /// If the z-coordinate is 1, return x1 directly.
    if (z1 == BigInt.one) {
      return x1;
    }

    /// Retrieve the prime value (p) of the curve.
    final BigInt p = curve.p;

    /// Compute the inverse of z1 modulo p.
    final BigInt zInv = BigintUtils.inverseMod(z1, p);

    /// Calculate and return the x-coordinate modulo p.
    return (x1 * zInv) % p;
  }

  /// Get the y-coordinate of the Edwards curve point.
  @override
  BigInt get y {
    /// Create a new list to avoid modifying the original coordinates.

    final BigInt y1 = _coords[1];
    final BigInt z1 = _coords[2];

    /// If the z-coordinate is 1, return y1 directly.
    if (z1 == BigInt.one) {
      return y1;
    }

    /// Retrieve the prime value (p) of the curve.
    final BigInt p = curve.p;

    /// Compute the inverse of z1 modulo p.
    final BigInt zInv = BigintUtils.inverseMod(z1, p);

    /// Calculate and return the y-coordinate modulo p.
    return (y1 * zInv) % p;
  }

  /// Scale the Edwards curve point.
  EDPoint scale() {
    final BigInt z1 = _coords[2];

    /// If the z-coordinate is already 1, the point is already in projective form, and no scaling is required.
    if (z1 == BigInt.one) {
      return this;
    }
    final BigInt x1 = _coords[0];
    final BigInt y1 = _coords[1];

    /// Retrieve the prime value (p) of the curve.
    final BigInt p = curve.p;

    /// Compute the inverse of z1 modulo p.
    final BigInt zInv = BigintUtils.inverseMod(z1, p);
    final BigInt x = (x1 * zInv) % p;
    final BigInt y = (y1 * zInv) % p;
    final BigInt t = (x * y) % p;

    /// Update the coordinates to their scaled values and set z-coordinate to 1 (projective form).
    _coords[0] = x;
    _coords[1] = y;
    _coords[2] = BigInt.one;
    _coords[3] = t;

    return this;
  }

  /// Equality operator for comparing two Edwards curve points.
  @override
  bool operator ==(Object other) {
    if (other is EDPoint) {
      /// Create new coordinate lists to avoid modifying the original coordinates.

      final List<BigInt> otherCoords = other.getCoords();

      /// Extract coordinates of the current point.
      final BigInt x1 = _coords[0];
      final BigInt y1 = _coords[1];
      final BigInt z1 = _coords[2];
      final BigInt t1 = _coords[3];

      ///  Extract coordinates of the other point.
      final BigInt x2 = otherCoords[0];
      final BigInt y2 = otherCoords[1];
      final BigInt z2 = otherCoords[2];

      /// If the other point is infinity, check specific conditions.
      if (other.isZero()) {
        return x1 == BigInt.zero || t1 == BigInt.zero;
      }

      /// Check if the curve of the two points is the same.
      if (curve != other.curve) {
        return false;
      }

      /// Retrieve the prime value (p) of the curve.
      final BigInt p = curve.p;

      /// Calculate the normalized coordinates of both points.
      final BigInt xn1 = (x1 * z2) % p;
      final BigInt xn2 = (x2 * z1) % p;
      final BigInt yn1 = (y1 * z2) % p;
      final BigInt yn2 = (y2 * z1) % p;

      /// Check if the normalized coordinates are equal.
      return xn1 == xn2 && yn1 == yn2;
    }

    return false;
  }

  List<BigInt> _add(
    BigInt x1,
    BigInt y1,
    BigInt z1,
    BigInt t1,
    BigInt x2,
    BigInt y2,
    BigInt z2,
    BigInt t2,
    BigInt p,
    BigInt a,
  ) {
    /// Compute intermediate values for addition.
    final BigInt A = (x1 * x2) % p;
    final BigInt b = (y1 * y2) % p;
    final BigInt c = (z1 * t2) % p;
    final BigInt d = (t1 * z2) % p;
    final BigInt e = d + c;
    final BigInt f = (((x1 - y1) * (x2 + y2)) + b - A) % p;
    final BigInt g = b + (a * A);
    final BigInt h = d - c;

    /// Check if the value of 'h' is zero; if so, perform a doubling operation instead.
    if (h == BigInt.zero) {
      return _double(x1, y1, z1, t1, p, a);
    }

    /// Calculate the coordinates of the resulting point after addition.
    final BigInt x3 = (e * f) % p;
    final BigInt y3 = (g * h) % p;
    final BigInt t3 = (e * h) % p;
    final BigInt z3 = (f * g) % p;

    /// Return the resulting coordinates as a list.
    return [x3, y3, z3, t3];
  }

  /// Addition operator for two Edwards curve points.
  @override
  EDPoint operator +(BaseExtendedPointNative other) {
    if (curve != other.curve) {
      throw ArgumentException.invalidOperationArguments(
        "Addition",
        reason: "The other point is on a different curve.",
      );
    }
    if (other is! EDPoint) {
      throw ArgumentException.invalidOperationArguments(
        "Addition",
        reason: "The other point has different type.",
      );
    }
    if (other.isZero()) {
      return this;
    }
    final BigInt p = curve.p;
    final BigInt a = curve.a;

    final BigInt x1 = _coords[0];
    final BigInt y1 = _coords[1];
    final BigInt z1 = _coords[2];
    final BigInt t1 = _coords[3];

    final BigInt x2 = other._coords[0];
    final BigInt y2 = other._coords[1];
    final BigInt z2 = other._coords[2];
    final BigInt t2 = other._coords[3];

    final List<BigInt> result = _add(x1, y1, z1, t1, x2, y2, z2, t2, p, a);

    return EDPoint(
      curve: curve,
      x: result[0],
      y: result[1],
      z: result[2],
      t: result[3],
      order: order,
    );
  }

  List<BigInt> _double(
    BigInt x1,
    BigInt y1,
    BigInt z1,
    BigInt t1,
    BigInt p,
    BigInt a,
  ) {
    final BigInt A = (x1 * x1) % p;
    final BigInt B = (y1 * y1) % p;
    final BigInt C = (z1 * z1 * BigInt.two) % p;
    final BigInt D = (a * A) % p;
    final BigInt E = (((x1 + y1) * (x1 + y1)) - A - B) % p;
    final BigInt G = D + B;
    final BigInt F = G - C;
    final BigInt H = D - B;
    final BigInt x3 = (E * F) % p;
    final BigInt y3 = (G * H) % p;
    final BigInt t3 = (E * H) % p;
    final BigInt z3 = (F * G) % p;

    return [x3, y3, z3, t3];
  }

  /// Double an Edwards curve point.
  EDPoint double() {
    final BigInt x1 = _coords[0];
    final BigInt t1 = _coords[3];
    final BigInt p = curve.p;
    final BigInt a = curve.a;

    if (x1 == BigInt.zero || t1 == BigInt.zero) {
      return EDPoint.infinity(curve: curve);
    }

    final newCoords = _double(x1, _coords[1], _coords[2], t1, p, a);
    if (newCoords[0] == BigInt.zero || newCoords[3] == BigInt.zero) {
      return EDPoint.infinity(curve: curve);
    }

    return EDPoint._(curve, newCoords, order: order);
  }

  /// Multiply an Edwards curve point using precomputed data.
  EDPoint _mulPrecompute(BigInt other) {
    BigInt x3 = BigInt.zero, y3 = BigInt.one, z3 = BigInt.one, t3 = BigInt.zero;
    final p = curve.p;
    final a = curve.a;

    for (final tuple in _precompute) {
      final x2 = tuple[0];
      final y2 = tuple[1];
      final t2 = tuple[2];
      final rem = other % BigInt.from(4);
      if (rem == BigInt.zero || rem == BigInt.from(2)) {
        other ~/= BigInt.from(2);
      } else if (rem == BigInt.from(3)) {
        other = (other + BigInt.one) ~/ BigInt.two;
        final result = _add(x3, y3, z3, t3, -x2, y2, BigInt.one, -t2, p, a);

        x3 = result[0];
        y3 = result[1];
        z3 = result[2];
        t3 = result[3];
      } else {
        assert(rem == BigInt.one);
        other = (other - BigInt.one) ~/ BigInt.two;
        final result = _add(x3, y3, z3, t3, x2, y2, BigInt.one, t2, p, a);
        x3 = result[0];
        y3 = result[1];
        z3 = result[2];
        t3 = result[3];
      }
    }
    if (x3 == BigInt.zero || t3 == BigInt.zero) {
      return EDPoint.infinity(curve: curve);
    }

    return EDPoint(curve: curve, x: x3, y: y3, z: z3, t: t3, order: order);
  }

  /// Multiply an Edwards curve point by a scalar.
  @override
  EDPoint operator *(BigInt other) {
    final BigInt x2 = _coords[0];
    final BigInt t2 = _coords[3];
    final BigInt y2 = _coords[1];
    final BigInt z2 = _coords[2];
    if (other == BigInt.zero) {
      return EDPoint.infinity(curve: curve);
    }

    if (order != null) {
      other %= (order! * BigInt.two);
    }
    _maybePrecompute();

    if (_precompute.isNotEmpty) {
      return _mulPrecompute(other);
    }

    BigInt x3 = BigInt.zero;
    BigInt y3 = BigInt.one;
    BigInt z3 = BigInt.one;
    BigInt t3 = BigInt.one;

    final nf = ECDSAUtils.computeNAF(other).reversed.toList();
    for (final i in nf) {
      final List<BigInt> resultCoords = _double(
        x3,
        y3,
        z3,
        t3,
        curve.p,
        curve.a,
      );
      x3 = resultCoords[0];
      y3 = resultCoords[1];
      z3 = resultCoords[2];
      t3 = resultCoords[3];

      if (i < BigInt.zero) {
        final List<BigInt> doubleCoords = _add(
          x3,
          y3,
          z3,
          t3,
          -x2,
          y2,
          z2,
          -t2,
          curve.p,
          curve.a,
        );
        x3 = doubleCoords[0];
        y3 = doubleCoords[1];
        z3 = doubleCoords[2];
        t3 = doubleCoords[3];
      } else if (i > BigInt.zero) {
        final List<BigInt> doubleCoords = _add(
          x3,
          y3,
          z3,
          t3,
          x2,
          y2,
          z2,
          t2,
          curve.p,
          curve.a,
        );
        x3 = doubleCoords[0];
        y3 = doubleCoords[1];
        z3 = doubleCoords[2];
        t3 = doubleCoords[3];
      }
    }

    return EDPoint._(curve, [x3, y3, z3, t3], order: order);
  }

  /// Checks if the Edwards curve point represents the point at infinity.
  bool isZero() =>
      _coords.isEmpty ||
      (_coords[0] == BigInt.zero || _coords[3] == BigInt.zero);

  @override
  List<int> toBytes() {
    scale();
    final encLen = (curve.p.bitLength + 1 + 7) ~/ 8;
    final yStr = y.toLeBytes(length: encLen);
    if (x % BigInt.two == BigInt.one) {
      yStr[yStr.length - 1] |= 0x80;
    }
    return yStr;
  }

  @override
  EDPoint operator -() {
    final BigInt x1 = _coords[0];
    final BigInt y1 = _coords[1];
    final BigInt z1 = _coords[2];
    final BigInt t1 = _coords[3];
    final BigInt p = curve.p;
    return EDPoint._(curve, [(p - x1) % p, y1, z1, (p - t1) % p], order: order);
  }

  /// Calculates the hash code for the Edwards curve point.
  @override
  int get hashCode => x.hashCode ^ y.hashCode ^ order.hashCode;
}
