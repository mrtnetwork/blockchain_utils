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

/// Constants for scalar arithmetic operations
const scMinusOne = [
  236,
  211,
  245,
  92,
  26,
  99,
  18,
  88,
  214,
  156,
  247,
  162,
  222,
  249,
  222,
  20,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  16
];
const scOne = [
  1,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0
];
const scZero = [
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0
];

/// Loads a 3-byte integer from a list of integers and returns it as a BigInt.
///
/// This method takes a list of integers and interprets the first 3 integers as
/// little-endian bytes to form a 3-byte integer. It then converts this integer to
/// a BigInt and returns it.
///
/// Parameters:
///   - input: A list of integers representing the 3-byte integer.
///
/// Returns:
///   A BigInt representation of the loaded 3-byte integer.
///
BigInt _load3(List<int> input) {
  int r = input[0];
  r |= input[1] << 8;
  r |= input[2] << 16;
  return BigInt.from(r);
}

/// Loads a 4-byte integer from a list of integers and returns it as a BigInt.
///
/// This method takes a list of integers and interprets the first 4 integers as
/// little-endian bytes to form a 4-byte integer. It then converts this integer to
/// a BigInt and returns it.
///
/// Parameters:
///   - input: A list of integers representing the 4-byte integer.
///
/// Returns:
///   A BigInt representation of the loaded 4-byte integer.
///
BigInt _load4(List<int> input) {
  int r = input[0];
  r |= input[1] << 8;
  r |= input[2] << 16;
  r |= input[3] << 24;
  return BigInt.from(r);
}

/// Adds two scalar values represented as List<int>s and returns the result as a List<int>.
///
/// This method adds two scalar values, `scalar1` and `scalar2`, and stores the result in the `out` List<int>.
/// The addition is performed according to Ristretto255 scalar operations.
///
/// Parameters:
///   - scalar1: The first scalar value to add.
///   - scalar2: The second scalar value to add.
///
/// Returns:
///   A List<int> representing the result of the addition.
List<int> add(List<int> scalar1, List<int> scalar2) {
  final out = List<int>.filled(32, 0);
  _mulAdd(out, scOne, scalar1, scalar2);
  return BytesUtils.toBytes(out);
}

/// Subtracts one scalar value from another and returns the result as a List<int>.
///
/// This method subtracts `scalar2` from `scalar1` and stores the result in the `out` List<int>.
/// The subtraction is performed according to Ristretto255 scalar operations.
///
/// Parameters:
///   - scalar1: The scalar value to subtract from.
///   - scalar2: The scalar value to subtract.
///
/// Returns:
///   A List<int> representing the result of the subtraction.
List<int> sub(List<int> scalar1, List<int> scalar2) {
  final out = List<int>.filled(32, 0);
  _mulAdd(out, scMinusOne, scalar2, scalar1);
  return BytesUtils.toBytes(out);
}

/// Negates a scalar value and returns the result as a List<int>.
///
/// This method negates the given `scalar` and stores the result in the `out` List<int>.
/// The negation is performed according to Ristretto255 scalar operations.
///
/// Parameters:
///   - scalar: The scalar value to negate.
///
/// Returns:
///   A List<int> representing the negated scalar.
List<int> neg(List<int> scalar) {
  final out = List<int>.filled(32, 0);
  _mulAdd(out, scMinusOne, scalar, scZero);
  return BytesUtils.toBytes(out);
}

/// Multiplies two scalar values represented as List<int>s and returns the result as a List<int>.
///
/// This method multiplies two scalar values, `scalar1` and `scalar2`, and stores the result in the `out` List<int>.
/// The multiplication is performed according to Ristretto255 scalar operations.
///
/// Parameters:
///   - scalar1: The first scalar value to multiply.
///   - scalar2: The second scalar value to multiply.
///
/// Returns:
///   A List<int> representing the result of the multiplication.
List<int> mul(List<int> scalar1, List<int> scalar2) {
  final out = List<int>.filled(32, 0);
  _mulAdd(out, scalar1, scalar2, scZero);

  return BytesUtils.toBytes(out);
}

/// A constant representing the value 2097151 as a BigInt.
///
/// This constant is used in various scalar operations in the Ristretto255 library.
///
final _b2097151 = BigInt.from(2097151);

/// A constant representing the value 666643 as a BigInt.
///
/// This constant is used in various scalar operations in the Ristretto255 library.
///
final _b666643 = BigInt.from(666643);

/// A constant representing the value 470296 as a BigInt.
///
/// This constant is used in various scalar operations in the Ristretto255 library.
///
final _b470296 = BigInt.from(470296);

/// A constant representing the value 654183 as a BigInt.
///
/// This constant is used in various scalar operations in the Ristretto255 library.
///
final _b654183 = BigInt.from(654183);

/// A constant representing the value 997805 as a BigInt.
///
/// This constant is used in various scalar operations in the Ristretto255 library.
///
final _b997805 = BigInt.from(997805);

/// A constant representing the value 136657 as a BigInt.
///
/// This constant is used in various scalar operations in the Ristretto255 library.
///
final _b136657 = BigInt.from(136657);

/// A constant representing the value 683901 as a BigInt.
///
/// This constant is used in various scalar operations in the Ristretto255 library.
final _b683901 = BigInt.from(683901);

void _mulAdd(List<int> s, List<int> a, List<int> b, List<int> c) {
  BigInt a0 = _b2097151 & _load3(a.sublist(0));
  BigInt a1 = _b2097151 & (_load4(a.sublist(2)) >> 5);
  BigInt a2 = _b2097151 & (_load3(a.sublist(5)) >> 2);
  BigInt a3 = _b2097151 & (_load4(a.sublist(7)) >> 7);
  BigInt a4 = _b2097151 & (_load4(a.sublist(10)) >> 4);
  BigInt a5 = _b2097151 & (_load3(a.sublist(13)) >> 1);
  BigInt a6 = _b2097151 & (_load4(a.sublist(15)) >> 6);
  BigInt a7 = _b2097151 & (_load3(a.sublist(18)) >> 3);
  BigInt a8 = _b2097151 & _load3(a.sublist(21));
  BigInt a9 = _b2097151 & (_load4(a.sublist(23)) >> 5);
  BigInt a10 = _b2097151 & (_load3(a.sublist(26)) >> 2);
  BigInt a11 = (_load4(a.sublist(28)) >> 7);

  BigInt b0 = _b2097151 & _load3(b.sublist(0));
  BigInt b1 = _b2097151 & (_load4(b.sublist(2)) >> 5);
  BigInt b2 = _b2097151 & (_load3(b.sublist(5)) >> 2);
  BigInt b3 = _b2097151 & (_load4(b.sublist(7)) >> 7);
  BigInt b4 = _b2097151 & (_load4(b.sublist(10)) >> 4);
  BigInt b5 = _b2097151 & (_load3(b.sublist(13)) >> 1);
  BigInt b6 = _b2097151 & (_load4(b.sublist(15)) >> 6);
  BigInt b7 = _b2097151 & (_load3(b.sublist(18)) >> 3);
  BigInt b8 = _b2097151 & _load3(b.sublist(21));
  BigInt b9 = _b2097151 & (_load4(b.sublist(23)) >> 5);
  BigInt b10 = _b2097151 & (_load3(b.sublist(26)) >> 2);
  BigInt b11 = (_load4(b.sublist(28)) >> 7);

  BigInt c0 = _b2097151 & _load3(c.sublist(0));
  BigInt c1 = _b2097151 & (_load4(c.sublist(2)) >> 5);
  BigInt c2 = _b2097151 & (_load3(c.sublist(5)) >> 2);
  BigInt c3 = _b2097151 & (_load4(c.sublist(7)) >> 7);
  BigInt c4 = _b2097151 & (_load4(c.sublist(10)) >> 4);
  BigInt c5 = _b2097151 & (_load3(c.sublist(13)) >> 1);
  BigInt c6 = _b2097151 & (_load4(c.sublist(15)) >> 6);
  BigInt c7 = _b2097151 & (_load3(c.sublist(18)) >> 3);
  BigInt c8 = _b2097151 & _load3(c.sublist(21));
  BigInt c9 = _b2097151 & (_load4(c.sublist(23)) >> 5);
  BigInt c10 = _b2097151 & (_load3(c.sublist(26)) >> 2);
  BigInt c11 = (_load4(c.sublist(28)) >> 7);
  List<BigInt> carry = List<BigInt>.filled(23, BigInt.zero);
  BigInt s0 = c0 + a0 * b0;
  BigInt s1 = c1 + a0 * b1 + a1 * b0;
  BigInt s2 = c2 + a0 * b2 + a1 * b1 + a2 * b0;
  BigInt s3 = c3 + a0 * b3 + a1 * b2 + a2 * b1 + a3 * b0;
  BigInt s4 = c4 + a0 * b4 + a1 * b3 + a2 * b2 + a3 * b1 + a4 * b0;
  BigInt s5 = c5 + a0 * b5 + a1 * b4 + a2 * b3 + a3 * b2 + a4 * b1 + a5 * b0;
  BigInt s6 =
      c6 + a0 * b6 + a1 * b5 + a2 * b4 + a3 * b3 + a4 * b2 + a5 * b1 + a6 * b0;
  BigInt s7 = c7 +
      a0 * b7 +
      a1 * b6 +
      a2 * b5 +
      a3 * b4 +
      a4 * b3 +
      a5 * b2 +
      a6 * b1 +
      a7 * b0;
  BigInt s8 = c8 +
      a0 * b8 +
      a1 * b7 +
      a2 * b6 +
      a3 * b5 +
      a4 * b4 +
      a5 * b3 +
      a6 * b2 +
      a7 * b1 +
      a8 * b0;
  BigInt s9 = c9 +
      a0 * b9 +
      a1 * b8 +
      a2 * b7 +
      a3 * b6 +
      a4 * b5 +
      a5 * b4 +
      a6 * b3 +
      a7 * b2 +
      a8 * b1 +
      a9 * b0;
  BigInt s10 = c10 +
      a0 * b10 +
      a1 * b9 +
      a2 * b8 +
      a3 * b7 +
      a4 * b6 +
      a5 * b5 +
      a6 * b4 +
      a7 * b3 +
      a8 * b2 +
      a9 * b1 +
      a10 * b0;
  BigInt s11 = c11 +
      a0 * b11 +
      a1 * b10 +
      a2 * b9 +
      a3 * b8 +
      a4 * b7 +
      a5 * b6 +
      a6 * b5 +
      a7 * b4 +
      a8 * b3 +
      a9 * b2 +
      a10 * b1 +
      a11 * b0;
  BigInt s12 = a1 * b11 +
      a2 * b10 +
      a3 * b9 +
      a4 * b8 +
      a5 * b7 +
      a6 * b6 +
      a7 * b5 +
      a8 * b4 +
      a9 * b3 +
      a10 * b2 +
      a11 * b1;
  BigInt s13 = a2 * b11 +
      a3 * b10 +
      a4 * b9 +
      a5 * b8 +
      a6 * b7 +
      a7 * b6 +
      a8 * b5 +
      a9 * b4 +
      a10 * b3 +
      a11 * b2;
  BigInt s14 = a3 * b11 +
      a4 * b10 +
      a5 * b9 +
      a6 * b8 +
      a7 * b7 +
      a8 * b6 +
      a9 * b5 +
      a10 * b4 +
      a11 * b3;
  BigInt s15 = a4 * b11 +
      a5 * b10 +
      a6 * b9 +
      a7 * b8 +
      a8 * b7 +
      a9 * b6 +
      a10 * b5 +
      a11 * b4;
  BigInt s16 =
      a5 * b11 + a6 * b10 + a7 * b9 + a8 * b8 + a9 * b7 + a10 * b6 + a11 * b5;
  BigInt s17 = a6 * b11 + a7 * b10 + a8 * b9 + a9 * b8 + a10 * b7 + a11 * b6;
  BigInt s18 = a7 * b11 + a8 * b10 + a9 * b9 + a10 * b8 + a11 * b7;
  BigInt s19 = a8 * b11 + a9 * b10 + a10 * b9 + a11 * b8;
  BigInt s20 = a9 * b11 + a10 * b10 + a11 * b9;
  BigInt s21 = a10 * b11 + a11 * b10;
  BigInt s22 = a11 * b11;
  BigInt s23 = BigInt.zero;
  carry[0] = (s0 + (BigInt.one << 20)) >> 21;
  s1 += carry[0];
  s0 -= carry[0] << 21;
  carry[2] = (s2 + (BigInt.one << 20)) >> 21;
  s3 += carry[2];
  s2 -= carry[2] << 21;
  carry[4] = (s4 + (BigInt.one << 20)) >> 21;
  s5 += carry[4];
  s4 -= carry[4] << 21;
  carry[6] = (s6 + (BigInt.one << 20)) >> 21;
  s7 += carry[6];
  s6 -= carry[6] << 21;
  carry[8] = (s8 + (BigInt.one << 20)) >> 21;
  s9 += carry[8];
  s8 -= carry[8] << 21;
  carry[10] = (s10 + (BigInt.one << 20)) >> 21;
  s11 += carry[10];
  s10 -= carry[10] << 21;
  carry[12] = (s12 + (BigInt.one << 20)) >> 21;
  s13 += carry[12];
  s12 -= carry[12] << 21;
  carry[14] = (s14 + (BigInt.one << 20)) >> 21;
  s15 += carry[14];
  s14 -= carry[14] << 21;
  carry[16] = (s16 + (BigInt.one << 20)) >> 21;
  s17 += carry[16];
  s16 -= carry[16] << 21;
  carry[18] = (s18 + (BigInt.one << 20)) >> 21;
  s19 += carry[18];
  s18 -= carry[18] << 21;
  carry[20] = (s20 + (BigInt.one << 20)) >> 21;
  s21 += carry[20];
  s20 -= carry[20] << 21;
  carry[22] = (s22 + (BigInt.one << 20)) >> 21;
  s23 += carry[22];
  s22 -= carry[22] << 21;
  //
  carry[1] = (s1 + (BigInt.one << 20)) >> 21;
  s2 += carry[1];
  s1 -= carry[1] << 21;
  carry[3] = (s3 + (BigInt.one << 20)) >> 21;
  s4 += carry[3];
  s3 -= carry[3] << 21;
  carry[5] = (s5 + (BigInt.one << 20)) >> 21;
  s6 += carry[5];
  s5 -= carry[5] << 21;
  carry[7] = (s7 + (BigInt.one << 20)) >> 21;
  s8 += carry[7];
  s7 -= carry[7] << 21;
  carry[9] = (s9 + (BigInt.one << 20)) >> 21;
  s10 += carry[9];
  s9 -= carry[9] << 21;
  carry[11] = (s11 + (BigInt.one << 20)) >> 21;
  s12 += carry[11];
  s11 -= carry[11] << 21;
  carry[13] = (s13 + (BigInt.one << 20)) >> 21;
  s14 += carry[13];
  s13 -= carry[13] << 21;
  carry[15] = (s15 + (BigInt.one << 20)) >> 21;
  s16 += carry[15];
  s15 -= carry[15] << 21;
  carry[17] = (s17 + (BigInt.one << 20)) >> 21;
  s18 += carry[17];
  s17 -= carry[17] << 21;
  carry[19] = (s19 + (BigInt.one << 20)) >> 21;
  s20 += carry[19];
  s19 -= carry[19] << 21;
  carry[21] = (s21 + (BigInt.one << 20)) >> 21;
  s22 += carry[21];
  s21 -= carry[21] << 21;

  s11 += s23 * _b666643;
  s12 += s23 * _b470296;
  s13 += s23 * _b654183;
  s14 -= s23 * _b997805;
  s15 += s23 * _b136657;
  s16 -= s23 * _b683901;
  s23 = BigInt.zero;

  s10 += s22 * _b666643;
  s11 += s22 * _b470296;
  s12 += s22 * _b654183;
  s13 -= s22 * _b997805;
  s14 += s22 * _b136657;
  s15 -= s22 * _b683901;
  s22 = BigInt.zero;

  s9 += s21 * _b666643;
  s10 += s21 * _b470296;
  s11 += s21 * _b654183;
  s12 -= s21 * _b997805;
  s13 += s21 * _b136657;
  s14 -= s21 * _b683901;
  s21 = BigInt.zero;

  s8 += s20 * _b666643;
  s9 += s20 * _b470296;
  s10 += s20 * _b654183;
  s11 -= s20 * _b997805;
  s12 += s20 * _b136657;
  s13 -= s20 * _b683901;
  s20 = BigInt.zero;

  s7 += s19 * _b666643;
  s8 += s19 * _b470296;
  s9 += s19 * _b654183;
  s10 -= s19 * _b997805;
  s11 += s19 * _b136657;
  s12 -= s19 * _b683901;
  s19 = BigInt.zero;

  s6 += s18 * _b666643;
  s7 += s18 * _b470296;
  s8 += s18 * _b654183;
  s9 -= s18 * _b997805;
  s10 += s18 * _b136657;
  s11 -= s18 * _b683901;
  s18 = BigInt.zero;

  carry[6] = (s6 + (BigInt.one << 20)) >> 21;
  s7 += carry[6];
  s6 -= carry[6] << 21;
  carry[8] = (s8 + (BigInt.one << 20)) >> 21;
  s9 += carry[8];
  s8 -= carry[8] << 21;
  carry[10] = (s10 + (BigInt.one << 20)) >> 21;
  s11 += carry[10];
  s10 -= carry[10] << 21;
  carry[12] = (s12 + (BigInt.one << 20)) >> 21;
  s13 += carry[12];
  s12 -= carry[12] << 21;
  carry[14] = (s14 + (BigInt.one << 20)) >> 21;
  s15 += carry[14];
  s14 -= carry[14] << 21;
  carry[16] = (s16 + (BigInt.one << 20)) >> 21;
  s17 += carry[16];
  s16 -= carry[16] << 21;

  carry[7] = (s7 + (BigInt.one << 20)) >> 21;
  s8 += carry[7];
  s7 -= carry[7] << 21;
  carry[9] = (s9 + (BigInt.one << 20)) >> 21;
  s10 += carry[9];
  s9 -= carry[9] << 21;
  carry[11] = (s11 + (BigInt.one << 20)) >> 21;
  s12 += carry[11];
  s11 -= carry[11] << 21;
  carry[13] = (s13 + (BigInt.one << 20)) >> 21;
  s14 += carry[13];
  s13 -= carry[13] << 21;
  carry[15] = (s15 + (BigInt.one << 20)) >> 21;
  s16 += carry[15];
  s15 -= carry[15] << 21;

  s5 += s17 * _b666643;
  s6 += s17 * _b470296;
  s7 += s17 * _b654183;
  s8 -= s17 * _b997805;
  s9 += s17 * _b136657;
  s10 -= s17 * _b683901;
  s17 = BigInt.zero;

  s4 += s16 * _b666643;
  s5 += s16 * _b470296;
  s6 += s16 * _b654183;
  s7 -= s16 * _b997805;
  s8 += s16 * _b136657;
  s9 -= s16 * _b683901;
  s16 = BigInt.zero;

  s3 += s15 * _b666643;
  s4 += s15 * _b470296;
  s5 += s15 * _b654183;
  s6 -= s15 * _b997805;
  s7 += s15 * _b136657;
  s8 -= s15 * _b683901;
  s15 = BigInt.zero;

  s2 += s14 * _b666643;
  s3 += s14 * _b470296;
  s4 += s14 * _b654183;
  s5 -= s14 * _b997805;
  s6 += s14 * _b136657;
  s7 -= s14 * _b683901;
  s14 = BigInt.zero;

  s1 += s13 * _b666643;
  s2 += s13 * _b470296;
  s3 += s13 * _b654183;
  s4 -= s13 * _b997805;
  s5 += s13 * _b136657;
  s6 -= s13 * _b683901;
  s13 = BigInt.zero;

  s0 += s12 * _b666643;
  s1 += s12 * _b470296;
  s2 += s12 * _b654183;
  s3 -= s12 * _b997805;
  s4 += s12 * _b136657;
  s5 -= s12 * _b683901;
  s12 = BigInt.zero;

  carry[0] = (s0 + (BigInt.one << 20)) >> 21;
  s1 += carry[0];
  s0 -= carry[0] << 21;
  carry[2] = (s2 + (BigInt.one << 20)) >> 21;
  s3 += carry[2];
  s2 -= carry[2] << 21;
  carry[4] = (s4 + (BigInt.one << 20)) >> 21;
  s5 += carry[4];
  s4 -= carry[4] << 21;
  carry[6] = (s6 + (BigInt.one << 20)) >> 21;
  s7 += carry[6];
  s6 -= carry[6] << 21;
  carry[8] = (s8 + (BigInt.one << 20)) >> 21;
  s9 += carry[8];
  s8 -= carry[8] << 21;
  carry[10] = (s10 + (BigInt.one << 20)) >> 21;
  s11 += carry[10];
  s10 -= carry[10] << 21;

  carry[1] = (s1 + (BigInt.one << 20)) >> 21;
  s2 += carry[1];
  s1 -= carry[1] << 21;
  carry[3] = (s3 + (BigInt.one << 20)) >> 21;
  s4 += carry[3];
  s3 -= carry[3] << 21;
  carry[5] = (s5 + (BigInt.one << 20)) >> 21;
  s6 += carry[5];
  s5 -= carry[5] << 21;
  carry[7] = (s7 + (BigInt.one << 20)) >> 21;
  s8 += carry[7];
  s7 -= carry[7] << 21;
  carry[9] = (s9 + (BigInt.one << 20)) >> 21;
  s10 += carry[9];
  s9 -= carry[9] << 21;
  carry[11] = (s11 + (BigInt.one << 20)) >> 21;
  s12 += carry[11];
  s11 -= carry[11] << 21;

  s0 += s12 * _b666643;
  s1 += s12 * _b470296;
  s2 += s12 * _b654183;
  s3 -= s12 * _b997805;
  s4 += s12 * _b136657;
  s5 -= s12 * _b683901;
  s12 = BigInt.zero;

  carry[0] = s0 >> 21;
  s1 += carry[0];
  s0 -= carry[0] << 21;
  carry[1] = s1 >> 21;
  s2 += carry[1];
  s1 -= carry[1] << 21;
  carry[2] = s2 >> 21;
  s3 += carry[2];
  s2 -= carry[2] << 21;
  carry[3] = s3 >> 21;
  s4 += carry[3];
  s3 -= carry[3] << 21;
  carry[4] = s4 >> 21;
  s5 += carry[4];
  s4 -= carry[4] << 21;
  carry[5] = s5 >> 21;
  s6 += carry[5];
  s5 -= carry[5] << 21;
  carry[6] = s6 >> 21;
  s7 += carry[6];
  s6 -= carry[6] << 21;
  carry[7] = s7 >> 21;
  s8 += carry[7];
  s7 -= carry[7] << 21;
  carry[8] = s8 >> 21;
  s9 += carry[8];
  s8 -= carry[8] << 21;
  carry[9] = s9 >> 21;
  s10 += carry[9];
  s9 -= carry[9] << 21;
  carry[10] = s10 >> 21;
  s11 += carry[10];
  s10 -= carry[10] << 21;
  carry[11] = s11 >> 21;
  s12 += carry[11];
  s11 -= carry[11] << 21;

  s0 += s12 * _b666643;
  s1 += s12 * _b470296;
  s2 += s12 * _b654183;
  s3 -= s12 * _b997805;
  s4 += s12 * _b136657;
  s5 -= s12 * _b683901;
  s12 = BigInt.zero;

  carry[0] = s0 >> 21;
  s1 += carry[0];
  s0 -= carry[0] << 21;
  carry[1] = s1 >> 21;
  s2 += carry[1];
  s1 -= carry[1] << 21;
  carry[2] = s2 >> 21;
  s3 += carry[2];
  s2 -= carry[2] << 21;
  carry[3] = s3 >> 21;
  s4 += carry[3];
  s3 -= carry[3] << 21;
  carry[4] = s4 >> 21;
  s5 += carry[4];
  s4 -= carry[4] << 21;
  carry[5] = s5 >> 21;
  s6 += carry[5];
  s5 -= carry[5] << 21;
  carry[6] = s6 >> 21;
  s7 += carry[6];
  s6 -= carry[6] << 21;
  carry[7] = s7 >> 21;
  s8 += carry[7];
  s7 -= carry[7] << 21;
  carry[8] = s8 >> 21;
  s9 += carry[8];
  s8 -= carry[8] << 21;
  carry[9] = s9 >> 21;
  s10 += carry[9];
  s9 -= carry[9] << 21;
  carry[10] = s10 >> 21;
  s11 += carry[10];
  s10 -= carry[10] << 21;

  s[0] = (s0 >> 0).toInt();
  s[1] = (s0 >> 8).toInt();
  s[2] = ((s0 >> 16) | (s1 << 5)).toInt();
  s[3] = (s1 >> 3).toInt();
  s[4] = (s1 >> 11).toInt();
  s[5] = ((s1 >> 19) | (s2 << 2)).toInt();
  s[6] = (s2 >> 6).toInt();
  s[7] = ((s2 >> 14) | (s3 << 7)).toInt();
  s[8] = (s3 >> 1).toInt();
  s[9] = (s3 >> 9).toInt();
  s[10] = ((s3 >> 17) | (s4 << 4)).toInt();
  s[11] = (s4 >> 4).toInt();
  s[12] = (s4 >> 12).toInt();
  s[13] = ((s4 >> 20) | (s5 << 1)).toInt();
  s[14] = (s5 >> 7).toInt();
  s[15] = ((s5 >> 15) | (s6 << 6)).toInt();
  s[16] = (s6 >> 2).toInt();
  s[17] = (s6 >> 10).toInt();
  s[18] = ((s6 >> 18) | (s7 << 3)).toInt();
  s[19] = (s7 >> 5).toInt();
  s[20] = (s7 >> 13).toInt();
  s[21] = (s8 >> 0).toInt();
  s[22] = (s8 >> 8).toInt();
  s[23] = ((s8 >> 16) | (s9 << 5)).toInt();
  s[24] = (s9 >> 3).toInt();
  s[25] = (s9 >> 11).toInt();
  s[26] = ((s9 >> 19) | (s10 << 2)).toInt();
  s[27] = (s10 >> 6).toInt();
  s[28] = ((s10 >> 14) | (s11 << 7)).toInt();
  s[29] = (s11 >> 1).toInt();
  s[30] = (s11 >> 9).toInt();
  s[31] = (s11 >> 17).toInt();
}
