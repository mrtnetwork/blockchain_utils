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

import 'package:blockchain_utils/utils/utils.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/curve/curve.dart';
import 'base.dart';
import 'package:blockchain_utils/exception/exceptions.dart';

/// A class representing a point on an Edwards curve, extending the abstract [AbstractPoint] class.
class EDPoint extends AbstractPoint {
  /// The Edwards curve associated with this point.
  @override
  CurveED curve;

  /// The order of the point (null if not set).
  @override
  BigInt? order;

  /// Indicates if this point is a generator point.
  bool generator;

  /// List of precomputed values (for internal use).
  List<List<BigInt>> _precompute;

  /// List of coordinates representing the point.
  List<BigInt> _coords;

  /// A factory constructor to create an infinity point on an Edwards curve.
  ///
  /// This factory method creates a special point at infinity for the given Edwards curve.
  /// It's a static method and doesn't require explicit point coordinates.
  ///
  /// Parameters:
  /// - [curve]: The Edwards curve associated with the point.
  ///
  /// Returns:
  /// - An instance of [EDPoint] representing the point at infinity.
  factory EDPoint.infinity({required CurveED curve}) {
    return EDPoint._(
        curve, [BigInt.zero, BigInt.zero, BigInt.zero, BigInt.zero]);
  }

  /// Private constructor for creating an [EDPoint] with specified curve, coordinates, and optional order.
  ///
  /// This constructor is used internally to create Edwards curve points.
  ///
  /// Parameters:
  /// - [curve]: The Edwards curve associated with the point.
  /// - [_coords]: List of coordinates representing the point.
  /// - [order]: The order of the point (optional).
  ///
  /// Additional Information:
  /// - The [_precompute] list is initialized as an empty constant list.
  /// - The [generator] flag is set to `false` by default.
  EDPoint._(this.curve, this._coords, {this.order})
      : _precompute = const [],
        generator = false;

  /// Constructor for creating an [EDPoint] with explicit coordinates and optional parameters.
  ///
  /// This constructor creates an Edwards curve point with the specified curve and coordinates.
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
  /// Additional Information:
  /// - The [_coords] list is initialized with the provided coordinates [x, y, z, t].
  /// - The [_precompute] list is initialized as an empty constant list.
  EDPoint(
      {required this.curve,
      required BigInt x,
      required BigInt y,
      required BigInt z,
      required BigInt t,
      this.order,
      this.generator = false})
      : _coords = [x, y, z, t],
        _precompute = const [];

  /// Factory constructor to create an [EDPoint] from a byte representation.
  ///
  /// This factory method constructs an Edwards curve point from its byte representation.
  ///
  /// Parameters:
  /// - [curve]: The Edwards curve associated with the point.
  /// - [data]: The byte array representing the point's coordinates.
  /// - [order]: The order of the point (optional).
  ///
  /// Returns:
  /// - An instance of [EDPoint] with the specified curve, coordinates, and optional order.
  factory EDPoint.fromBytes(
      {required CurveED curve, required List<int> data, BigInt? order}) {
    final coords = AbstractPoint.fromBytes(curve, data);
    final x = coords.item1;
    final y = coords.item2;
    final t = x * y;
    return EDPoint(
        curve: curve,
        x: x,
        y: y,
        z: BigInt.one,
        t: t,
        generator: false,
        order: order);
  }

  /// Internal method for performing point precomputation when required.
  ///
  /// This method is responsible for performing precomputation on the point, specifically for generator points.
  /// It precomputes a set of values that can be used to accelerate point multiplication operations.
  ///
  /// Precomputation is only performed if the point is a generator point and precomputed values are not already available.
  ///
  /// The precomputed values are stored in the [_precompute] list.
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
      doubler = doubler.doublePoint();

      compute.add([coordsList[0], coordsList[1], coordsList[3]]);
    }

    /// Set the precomputed values in the [_precompute] list.
    _precompute = compute;
  }

  List<BigInt> getCoords() {
    return List.from(_coords);
  }

  /// Get the x-coordinate of the Edwards curve point.
  ///
  /// This getter method computes and returns the x-coordinate of the Edwards curve point
  /// using the stored coordinates, considering the base field element modulo the curve's prime value (p).
  ///
  /// Returns:
  /// - The x-coordinate of the point.
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
  ///
  /// This getter method computes and returns the y-coordinate of the Edwards curve point
  /// using the stored coordinates, considering the base field element modulo the curve's prime value (p).
  ///
  /// Returns:
  /// - The y-coordinate of the point.
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
  ///
  /// This method scales the point by converting it to projective coordinates (if not already),
  /// performing the scaling operation, and then converting it back to extended coordinates.
  ///
  /// Returns:
  /// - A reference to the scaled Edwards curve point.
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
  ///
  /// This method checks if the current Edwards curve point is equal to another point by comparing their coordinates.
  ///
  /// Parameters:
  /// - [other]: The object to compare with.
  ///
  /// Returns:
  /// - `true` if the points are equal, `false` otherwise.
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
      if (other.isInfinity) {
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

  /// Perform addition of two Edwards curve points.
  ///
  /// This method computes the sum of two Edwards curve points in extended coordinates. It takes the coordinates of both points, the prime value (p) of the curve, and the curve's parameter 'a' as input.
  ///
  /// Parameters:
  /// - [x1]: x-coordinate of the first point.
  /// - [y1]: y-coordinate of the first point.
  /// - [z1]: z-coordinate of the first point.
  /// - [t1]: t-coordinate of the first point.
  /// - [x2]: x-coordinate of the second point.
  /// - [y2]: y-coordinate of the second point.
  /// - [z2]: z-coordinate of the second point.
  /// - [t2]: t-coordinate of the second point.
  /// - [p]: The prime value (p) of the curve.
  /// - [a]: The 'a' parameter of the curve.
  ///
  /// Returns:
  /// - A list of BigInt values representing the coordinates of the resulting Edwards curve point [x3, y3, z3, t3].
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
  ///
  /// This operator performs point addition on the Edwards curve.
  /// It checks if the points are on the same curve and not at infinity,
  /// then calculates the result of the addition operation and returns a new Edwards curve point.
  ///
  /// Parameters:
  /// - [other]: The other Edwards curve point to add to this point.
  ///
  /// Returns:
  /// - A new Edwards curve point representing the result of the addition.
  ///
  /// Throws:
  /// - ArgumentException: If the 'other' point is on a different curve or at infinity.
  @override
  EDPoint operator +(AbstractPoint other) {
    if (other is! EDPoint || curve != other.curve) {
      throw const ArgumentException("The other point is on a different curve.");
    }
    if (other.isInfinity) {
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
    if (result[0] == BigInt.zero || result[3] == BigInt.zero) {
      return EDPoint.infinity(curve: curve);
    }

    return EDPoint(
        curve: curve,
        x: result[0],
        y: result[1],
        z: result[2],
        t: result[3],
        order: order);
  }

  /// Negation operator for an Edwards curve point.
  ///
  /// This operator computes the negation (negate y-coordinate) of the Edwards curve point and returns a new Edwards curve point representing the negated point.
  ///
  /// Returns:
  /// - A new Edwards curve point representing the negation of this point.
  EDPoint operator -() {
    final BigInt x1 = _coords[0];
    final BigInt y1 = _coords[1];
    final BigInt t1 = _coords[3];
    final BigInt p = curve.p;

    return EDPoint._(curve, [x1, (p - y1) % p, _coords[2], (p - t1) % p],
        order: order);
  }

  List<BigInt> _double(
      BigInt x1, BigInt y1, BigInt z1, BigInt t1, BigInt p, BigInt a) {
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
  ///
  /// This method computes the result of doubling an Edwards curve point on the same curve.
  /// It calculates the new coordinates and returns them as a list.
  ///
  /// Parameters:
  /// - [x1]: x-coordinate of the point.
  /// - [y1]: y-coordinate of the point.
  /// - [z1]: z-coordinate of the point.
  /// - [t1]: t-coordinate of the point.
  /// - [p]: The prime modulus of the curve.
  /// - [a]: The 'a' parameter of the curve equation.
  ///
  /// Returns:
  /// - A list of BigInt values representing the new coordinates [x3, y3, z3, t3] after doubling the point.
  @override
  EDPoint doublePoint() {
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
  ///
  /// This method multiplies an Edwards curve point by a scalar using precomputed data.
  /// It efficiently performs the multiplication using the precomputed values and returns the result as a new Edwards curve point.
  ///
  /// Parameters:
  /// - [other]: The scalar value to multiply the point by.
  ///
  /// Returns:
  /// - A new Edwards curve point resulting from the multiplication.
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
  ///
  /// This method multiplies an Edwards curve point by a scalar
  /// value using an efficient multiplication algorithm. The scalar value is provided as a [BigInt],
  ///  and the result is returned as a new Edwards curve point.
  ///
  /// Parameters:
  /// - [other]: The scalar value to multiply the point by.
  ///
  /// Returns:
  /// - A new Edwards curve point resulting from the multiplication.
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

    final nf = BigintUtils.computeNAF(other).reversed.toList();
    for (final i in nf) {
      final List<BigInt> resultCoords =
          _double(x3, y3, z3, t3, curve.p, curve.a);
      x3 = resultCoords[0];
      y3 = resultCoords[1];
      z3 = resultCoords[2];
      t3 = resultCoords[3];

      if (i < BigInt.zero) {
        final List<BigInt> doubleCoords =
            _add(x3, y3, z3, t3, -x2, y2, z2, -t2, curve.p, curve.a);
        x3 = doubleCoords[0];
        y3 = doubleCoords[1];
        z3 = doubleCoords[2];
        t3 = doubleCoords[3];
      } else if (i > BigInt.zero) {
        final List<BigInt> doubleCoords =
            _add(x3, y3, z3, t3, x2, y2, z2, t2, curve.p, curve.a);
        x3 = doubleCoords[0];
        y3 = doubleCoords[1];
        z3 = doubleCoords[2];
        t3 = doubleCoords[3];
      }
    }

    return EDPoint._(curve, [x3, y3, z3, t3], order: order);
  }

  /// Calculates the hash code for the Edwards curve point.
  ///
  /// This method calculates a hash code for the Edwards curve point based on its x and y coordinates, as well as the order of the point.
  ///
  /// Returns:
  /// - An integer representing the hash code of the Edwards curve point.
  @override
  int get hashCode => x.hashCode ^ y.hashCode ^ order.hashCode;

  /// Checks if the Edwards curve point represents the point at infinity.
  ///
  /// This method checks whether the Edwards curve point represents the point at infinity, which is defined as either an empty set of coordinates or having both x and y coordinates equal to zero.
  ///
  /// Returns:
  /// - `true` if the point is the point at infinity, `false` otherwise.
  @override
  bool get isInfinity =>
      _coords.isEmpty ||
      (_coords[0] == BigInt.zero || _coords[3] == BigInt.zero);
}
