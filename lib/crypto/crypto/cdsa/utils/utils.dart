import 'package:blockchain_utils/crypto/crypto/cdsa/utils/exp.dart';
import 'package:blockchain_utils/exception/exception.dart';

class ECDSAUtils {
  /// Computes the modular exponentiation of a polynomial represented by [base]
  /// to the power of [exponent], using the specified [polymod] and modulus [p].
  ///
  /// This function efficiently calculates (base^exponent) % polymod, where
  /// base, polymod, and p are all polynomials with coefficients represented as
  /// BigInt. The result is also a polynomial with coefficients mod p.
  ///
  /// The function iteratively squares and multiplies the base polynomial using
  /// the exponent to achieve the modular exponentiation.
  ///
  /// - [base]: The base polynomial.
  /// - [exponent]: The non-negative exponent.
  /// - [polymod]: The modulus polynomial.
  /// - [p]: The modulus value.
  ///
  /// Returns the polynomial resulting from (base^exponent) % polymod.
  static List<BigInt> polynomialExponentiationMod(
      List<BigInt> base, BigInt exponent, List<BigInt> polymod, BigInt p) {
    assert(exponent < p);

    if (exponent == BigInt.zero) {
      return [BigInt.one];
    }

    List<BigInt> G = List.from(base);
    BigInt k = exponent;
    List<BigInt> s =
        (k % BigInt.two == BigInt.one) ? List.from(G) : [BigInt.one];

    while (k > BigInt.one) {
      k = k ~/ BigInt.two;
      G = polynomialMultiplyMod(G, G, polymod, p);
      if (k % BigInt.two == BigInt.one) {
        s = polynomialMultiplyMod(G, s, polymod, p);
      }
    }

    return s;
  }

  // Calculate the modular square root of 'a' modulo prime 'p' using algorithms from the Handbook of Applied Cryptography (3.34 to 3.39).
  // Preconditions: a should be in the range [0, p), and p should be a prime number.
  static BigInt modularSquareRootPrime(BigInt a, BigInt p) {
    assert(BigInt.zero <= a && a < p);
    assert(p > BigInt.one);

    if (a == BigInt.zero) {
      return BigInt.zero;
    }

    if (p == BigInt.two) {
      return a;
    }

    final jacobiSymbol = jacobi(a, p);

    if (jacobiSymbol == BigInt.from(-1)) {
      throw SquareRootError("$a has no square root modulo $p");
    }

    if (p % BigInt.from(4) == BigInt.from(3)) {
      return a.modPow((p + BigInt.one) ~/ BigInt.from(4), p);
    }

    if (p % BigInt.from(8) == BigInt.from(5)) {
      final d = a.modPow((p - BigInt.one) ~/ BigInt.from(4), p);
      if (d == BigInt.one) {
        return a.modPow((p + BigInt.from(3)) ~/ BigInt.from(8), p);
      }
      assert(d == p - BigInt.one);
      return (BigInt.from(2) *
              a *
              (BigInt.from(4) * a)
                  .modPow((p - BigInt.from(5)) ~/ BigInt.from(8), p)) %
          p;
    }

    for (BigInt b = BigInt.from(2); b < p; b += BigInt.one) {
      if (jacobi(b * b - BigInt.from(4) * a, p) == BigInt.from(-1)) {
        final quadraticForm = [a, -b, BigInt.one];
        final result = polynomialExponentiationMod([BigInt.zero, BigInt.one],
            (p + BigInt.one) ~/ BigInt.from(2), quadraticForm, p);
        if (result[1] != BigInt.zero) {
          throw const SquareRootError("p is not prime");
        }
        return result[0];
      }
    }

    throw const MessageException("No suitable 'b' found.");
  }

  /// Multiply two polynomials represented by lists 'm1' and 'm2', reducing modulo 'polymod' and prime 'p'.
  static List<BigInt> polynomialMultiplyMod(
      List<BigInt> m1, List<BigInt> m2, List<BigInt> polymod, BigInt p) {
    List<BigInt> prod = List.filled(m1.length + m2.length - 1, BigInt.zero);

    // Add together all the cross-terms:
    for (int i = 0; i < m1.length; i++) {
      for (int j = 0; j < m2.length; j++) {
        prod[i + j] = (prod[i + j] + m1[i] * m2[j]) % p;
      }
    }

    // Reduce the result modulo 'polymod':
    return polynomialReduceMod(prod, polymod, p);
  }

  /// Reduce a polynomial 'poly' modulo 'polymod' using prime 'p'.
  static List<BigInt> polynomialReduceMod(
      List<BigInt> poly, List<BigInt> polymod, BigInt p) {
    assert(polymod.last == BigInt.one);
    assert(polymod.length > 1);

    // Repeatedly reduce the polynomial while its degree is greater than or equal to 'polymod':
    while (poly.length >= polymod.length) {
      if (poly.last != BigInt.zero) {
        for (int i = 2; i <= polymod.length; i++) {
          poly[poly.length - i] = (poly[poly.length - i] -
                  poly.last * polymod[polymod.length - i]) %
              p;
        }
      }
      poly.removeLast();
    }

    return poly;
  }

  /// Calculates the Jacobi symbol (a/n) for given integers 'a' and 'n'.
  ///
  /// The Jacobi symbol is defined for an odd positive integer 'n' and any integer 'a'.
  ///
  /// Returns 0 if 'a' is congruent to 0 modulo 'n'.
  /// Returns 1 if 'a' is a quadratic residue modulo 'n'.
  /// Returns -1 if 'a' is a non-quadratic residue modulo 'n'.
  ///
  /// Throws a JacobiError if 'n' is not an odd integer greater than or equal to 3.
  ///
  static BigInt jacobi(BigInt a, BigInt n) {
    if (!(n >= BigInt.from(3))) {
      throw const JacobiError("n must be larger than 2");
    }
    if (!(n % BigInt.two == BigInt.one)) {
      throw const JacobiError("n must be odd");
    }

    a = a % n;
    if (a == BigInt.zero) {
      return BigInt.zero;
    }
    if (a == BigInt.one) {
      return BigInt.one;
    }

    BigInt a1 = a, e = BigInt.zero;
    while (a1 % BigInt.two == BigInt.zero) {
      a1 = a1 ~/ BigInt.two;
      e = e + BigInt.one;
    }

    BigInt s = BigInt.one;

    if (e % BigInt.two == BigInt.zero ||
        n % BigInt.from(8) == BigInt.one ||
        n % BigInt.from(8) == BigInt.from(7)) {
      // s remains 1
    } else {
      s = BigInt.from(-1);
    }

    if (a1 == BigInt.one) {
      return s;
    }

    if (n % BigInt.from(4) == BigInt.from(3) &&
        a1 % BigInt.from(4) == BigInt.from(3)) {
      s = -s;
    }

    return s * jacobi(n % a1, a1);
  }
}
