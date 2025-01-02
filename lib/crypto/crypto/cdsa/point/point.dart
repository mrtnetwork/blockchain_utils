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
import 'package:blockchain_utils/crypto/crypto/cdsa/point/ec_projective_point.dart';
import 'package:blockchain_utils/exception/exceptions.dart';

import 'base.dart';

/// Represents a point in affine coordinates on an elliptic curve.
class AffinePointt extends AbstractPoint {
  AffinePointt(this.curve, this.x, this.y, {this.order});

  /// Factory method to create an infinity point on the given curve.
  factory AffinePointt.infinity(CurveFp curve) {
    return AffinePointt(curve, BigInt.zero, BigInt.zero);
  }

  /// Represents the elliptic curve to which this point belongs.
  @override
  final CurveFp curve;

  /// Represents the x-coordinate of this point in affine coordinates.
  @override
  final BigInt x;

  /// Represents the y-coordinate of this point in affine coordinates.
  @override
  final BigInt y;

  /// Represents the order of this point, which is the number of times this point
  /// can be added to itself before reaching the infinity point.
  @override
  final BigInt? order;

  /// Overrides the equality operator (==) to compare this `AffinePointt` instance
  /// with another object. It returns `true` if the other object is also an
  /// `AffinePointt` and if the `curve`, `x`, and `y` coordinates match.
  @override
  bool operator ==(Object other) {
    if (other is AffinePointt) {
      return curve == other.curve && x == other.x && y == other.y;
    }
    return other == this;
  }

  /// Checks if this `AffinePointt` represents the point at infinity (O), which
  /// is defined by having x and y coordinates both equal to zero.
  @override
  bool get isInfinity => x == BigInt.zero && y == BigInt.zero;

  /// Negates this point and returns the result.
  AffinePointt operator -() {
    return AffinePointt(curve, x, curve.p - y, order: order);
  }

  /// Overrides the addition operator (+) to perform point addition between this
  /// `AffinePointt` and another `AbstractPoint`. The result is a new
  /// `AffinePointt`. If one of the points is the point at infinity, it returns
  /// the other point. If the x-coordinates of both points are equal, and the
  /// sum of their y-coordinates modulo `curve.p` equals zero, the result is the
  /// point at infinity. Otherwise, it computes the sum using the provided
  /// addition formula.
  ///
  /// Returns a new `AffinePointt` representing the result of the point addition.
  @override
  AbstractPoint operator +(AbstractPoint other) {
    if (other is! AffinePointt && other is! ProjectiveECCPoint) {
      throw ArgumentException("cannot add with ${other.runtimeType} point");
    }
    if (other is ProjectiveECCPoint) {
      return other + this;
    }
    other as AffinePointt;
    if (other.isInfinity) {
      return this;
    }
    if (isInfinity) {
      return other;
    }
    assert(curve == other.curve);
    if (x == other.x) {
      if ((y + other.y) % curve.p == BigInt.zero) {
        return AffinePointt(curve, BigInt.zero, BigInt.zero);
      } else {
        return doublePoint();
      }
    }

    final BigInt p = curve.p;
    final BigInt l = (other.y - y) * BigintUtils.inverseMod(other.x - x, p) % p;

    final BigInt x3 = (l * l - x - other.x) % p;
    final BigInt y3 = (l * (x - x3) - y) % p;

    return AffinePointt(curve, x3, y3, order: null);
  }

  /// Overrides the multiplication operator (*) to perform point scalar
  /// multiplication. It multiplies the `AffinePointt` instance by a scalar
  /// `other` and returns a new `AffinePointt` representing the result.
  ///
  /// Scalar multiplication is implemented using the double-and-add method, which
  /// efficiently computes `this * other` for positive `other`. It also handles
  /// the case where `other` is zero or a multiple of the group order.
  ///
  /// If `other` is zero or a multiple of the group order, the result is the point
  /// at infinity. For negative scalars, it negates the point before performing
  /// multiplication.
  ///
  /// Returns a new `AffinePointt` representing the result of the scalar
  /// multiplication.
  @override
  AffinePointt operator *(BigInt other) {
    BigInt leftmostBit(BigInt x) {
      assert(x > BigInt.zero);
      BigInt result = BigInt.one;
      while (result <= x) {
        result = BigInt.from(2) * result;
      }
      return result ~/ BigInt.from(2);
    }

    BigInt e = other;
    if (e == BigInt.zero || (order != null && e % order! == BigInt.zero)) {
      return AffinePointt(curve, BigInt.zero, BigInt.zero);
    }

    if (e < BigInt.zero) {
      return -this * -e;
    }

    e *= BigInt.from(3);
    final AffinePointt negativeSelf = AffinePointt(curve, x, -y, order: order);
    BigInt i = leftmostBit(e) ~/ BigInt.from(2);
    AffinePointt result = this;

    while (i > BigInt.one) {
      result = result.doublePoint();
      if ((e & i) != BigInt.zero && (other & i) == BigInt.zero) {
        result = (result + this) as AffinePointt;
      }
      if ((e & i) == BigInt.zero && (other & i) != BigInt.zero) {
        result = (result + negativeSelf) as AffinePointt;
      }
      i = i ~/ BigInt.from(2);
    }

    return result;
  }

  /// Doubles the `AffinePointt` by performing point doubling operation.
  /// It computes the new point representing the result of doubling this point
  /// on the elliptic curve. If `this` is the point at infinity, it returns
  /// the point at infinity.
  ///
  /// The doubling operation on the elliptic curve is used to efficiently
  /// calculate scalar multiplications. It computes the new coordinates (x, y)
  /// on the curve that results from doubling the given point.
  ///
  /// Returns a new `AffinePointt` representing the result of doubling this point.
  @override
  AffinePointt doublePoint() {
    if (isInfinity) {
      return AffinePointt(curve, BigInt.zero, BigInt.zero);
    }

    final BigInt p = curve.p;
    final BigInt a = curve.a;

    final BigInt l = (BigInt.from(3) * x * x + a) *
        BigintUtils.inverseMod(BigInt.from(2) * y, p) %
        p;

    final BigInt x3 = (l * l - BigInt.from(2) * x) % p;
    final BigInt y3 = (l * (x - x3) - y) % p;

    return AffinePointt(curve, x3, y3, order: null);
  }

  @override
  int get hashCode => x.hashCode ^ y.hashCode;
}
