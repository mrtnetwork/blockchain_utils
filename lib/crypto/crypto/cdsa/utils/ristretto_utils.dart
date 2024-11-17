import 'package:blockchain_utils/utils/utils.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/curve/curves.dart';

/// Helper methods for Ristretto255 operations.
/// The square root of -1 in the Ristretto255 curve field.
final sqrtM1 = BigInt.parse(
    '19681161376707505956807079304988542015446066515923890162744021073123829784752');

/// The square of -1 in the Ristretto255 curve field.
final minusOneSq = BigInt.parse(
    '40440834346308536858101042469323190826248399146238708352240133220865137265952');

/// The value 1 - d^2 in the Ristretto255 curve field.
final oneMinusDSq = BigInt.parse(
    '1159843021668779879193775521855586647937357759715417654439879720876111806838');

/// The value (a*d) - 1 in the Ristretto255 curve field.
final sqrtAdMinusOne = BigInt.parse(
    '25063068953384623474111414158702152701244531502492656460079210482610430750235');

/// The modular inverse of the square root (1/sqrt(a*d)) in the Ristretto255 curve field.
final invSqrt = BigInt.parse(
    '54469307008909316920995813868745141605393597292927456921205312896311721017578');

/// A mask for the least significant 255 bits, used for bitwise operations.
final mask255 = BigInt.parse(
    "7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff",
    radix: 16);

/// Calculates the positive remainder of two BigInt values.
///
/// This function takes two BigInt values, `a` and `b`, and computes `a % b`.
/// If the result is greater than or equal to zero, it returns the result.
/// If the result is negative, it adds `b` to the result to make it positive.
///
/// Parameters:
///   a (BigInt): The dividend.
///   b (BigInt): The divisor.
///
/// Returns:
///   BigInt: The positive remainder of `a` when divided by `b`.
BigInt positiveMod(BigInt a, BigInt b) {
  final result = a % b;
  return result >= BigInt.zero ? result : b + result;
}

/// Computes modular exponentiation for BigInt values.
///
/// This function calculates 'x' raised to the power 'power', modulo 'modulo'.
/// It uses a modular exponentiation algorithm to efficiently compute
/// large powers while keeping the result within the range of 'modulo'.
///
/// Parameters:
///   x (BigInt): The base value.
///   power (BigInt): The exponent to which 'x' is raised.
///   modulo (BigInt): The modulus value.
///
/// Returns:
///   BigInt: The result of 'x' raised to the 'power', modulo 'modulo'.
BigInt _mExp(BigInt x, BigInt power, BigInt modulo) {
  BigInt res = x;
  while (power > BigInt.zero) {
    res *= res;
    res %= modulo;
    power -= BigInt.one;
  }
  return res;
}

/// Calculate values relevant to the Ed25519 elliptic curve for pow(2, 252 - 3).
///
/// This function takes a BigInt value 'x' and computes various intermediate values
/// necessary for the Ed25519 elliptic curve, specifically for pow(2, 252 - 3).
/// It involves several modular exponentiations and modular multiplications.
///
/// Parameters:
///   x (BigInt): The input value.
///
/// Returns:
///   Tuple of BigInt: A tuple containing two BigInt values:
///     - The result of pow(2, 252 - 3) modulo the Ed25519 curve prime 'P'.
///     - An intermediate value 'b2' used in the calculations.
///
BigInt _pow252(BigInt x) {
  // CryptoOps.geDoubleScalarMultBaseVartime(r, a, gA, b)
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
///
/// This function determines whether a BigInt 'num' is an odd number
/// when computed within the modular arithmetic defined by 'modulo'.
/// It calculates the remainder of 'num' when divided by 'modulo' and checks
/// if the least significant bit is set to 1 (i.e., it's an odd number).
///
/// Parameters:
///   num (BigInt): The number to be checked for oddness.
///   modulo (BigInt): The modulus used for the modular arithmetic.
///
/// Returns:
///   bool: 'true' if 'num' is an odd number within the given modulo, 'false' otherwise.
bool isOdd(BigInt num, BigInt modulo) {
  return (positiveMod(num, modulo) & BigInt.one) == BigInt.one;
}

/// sqrt u/v
Tuple<bool, BigInt> sqrtUV(BigInt u, BigInt v) {
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
  return Tuple(useRoot1 || useRoot2, x);
}
