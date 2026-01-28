import 'package:blockchain_utils/crypto/crypto/ec/curve/curve.dart';
import 'package:blockchain_utils/crypto/crypto/ec/core/point.dart';
import 'package:blockchain_utils/utils/numbers/utils/bigint_utils.dart';

/// Represents a point in affine coordinates on an elliptic curve.
class ProjectivAffinePoint extends BaseProjectivePointNative {
  ProjectivAffinePoint(this.curve, this.x, this.y, {this.order});

  factory ProjectivAffinePoint.zero(CurveFp curve) {
    return ProjectivAffinePoint(curve, BigInt.zero, BigInt.zero);
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

  @override
  bool operator ==(Object other) {
    if (other is ProjectivAffinePoint) {
      return curve == other.curve && x == other.x && y == other.y;
    }
    return other == this;
  }

  /// Checks if this `ProjectivAffinePoint` represents the point at infinity (O)
  @override
  bool isZero() => x == BigInt.zero && y == BigInt.zero;

  /// Overrides the addition operator (+) to perform point addition between this
  /// `ProjectivAffinePoint` and another `AbstractPoint`.
  @override
  BaseProjectivePointNative operator +(BaseProjectivePointNative other) {
    if (other is! ProjectivAffinePoint) {
      return other + this;
    }
    if (other.isZero()) {
      return this;
    }
    if (isZero()) {
      return other;
    }
    assert(curve == other.curve);
    if (x == other.x) {
      if ((y + other.y) % curve.p == BigInt.zero) {
        return ProjectivAffinePoint(curve, BigInt.zero, BigInt.zero);
      } else {
        return double();
      }
    }

    final BigInt p = curve.p;
    final BigInt l = (other.y - y) * BigintUtils.inverseMod(other.x - x, p) % p;

    final BigInt x3 = (l * l - x - other.x) % p;
    final BigInt y3 = (l * (x - x3) - y) % p;

    return ProjectivAffinePoint(curve, x3, y3, order: null);
  }

  /// Overrides the multiplication operator (*) to perform point scalar
  /// multiplication.
  @override
  ProjectivAffinePoint operator *(BigInt other) {
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
      return ProjectivAffinePoint(curve, BigInt.zero, BigInt.zero);
    }

    if (e < BigInt.zero) {
      return -this * -e;
    }

    e *= BigInt.from(3);
    final ProjectivAffinePoint negativeSelf = ProjectivAffinePoint(
      curve,
      x,
      -y,
      order: order,
    );
    BigInt i = leftmostBit(e) ~/ BigInt.from(2);
    ProjectivAffinePoint result = this;

    while (i > BigInt.one) {
      result = result.double();
      if ((e & i) != BigInt.zero && (other & i) == BigInt.zero) {
        result = (result + this) as ProjectivAffinePoint;
      }
      if ((e & i) == BigInt.zero && (other & i) != BigInt.zero) {
        result = (result + negativeSelf) as ProjectivAffinePoint;
      }
      i = i ~/ BigInt.from(2);
    }

    return result;
  }

  /// Doubles the `ProjectivAffinePoint` by performing point doubling operation.
  ProjectivAffinePoint double() {
    if (isZero()) {
      return ProjectivAffinePoint(curve, BigInt.zero, BigInt.zero);
    }

    final BigInt p = curve.p;
    final BigInt a = curve.a;

    final BigInt l =
        (BigInt.from(3) * x * x + a) *
        BigintUtils.inverseMod(BigInt.from(2) * y, p) %
        p;

    final BigInt x3 = (l * l - BigInt.from(2) * x) % p;
    final BigInt y3 = (l * (x - x3) - y) % p;

    return ProjectivAffinePoint(curve, x3, y3, order: null);
  }

  @override
  int get hashCode => x.hashCode ^ y.hashCode;

  /// Negates this point and returns the result.
  @override
  ProjectivAffinePoint operator -() {
    return ProjectivAffinePoint(curve, x, curve.p - y, order: order);
  }
}
