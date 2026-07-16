import 'dart:math';

import 'package:blockchain_utils/numbers/src/u64.dart';
import 'package:test/test.dart';

void main() {
  test("Uint64", () {
    fuzzUint64();
    boundaryTests();
    identityTests();
    bitwiseTests();
    shiftTests();
    widenMulTests();
    oracleTest();
  });
}

void fuzzUint64() {
  final rnd = Random(123456);
  const int max32 = 0x100000000; // 2^32

  final mask64 = BigInt.parse("FFFFFFFFFFFFFFFF", radix: 16);

  for (int i = 0; i < 200000; i++) {
    final hiA = rnd.nextInt(max32);
    final loA = rnd.nextInt(max32);
    final hiB = rnd.nextInt(max32);
    final loB = rnd.nextInt(max32);

    final a = Uint64.fromParts(hiA, loA);
    final b = Uint64.fromParts(hiB, loB);

    final bigA = a.toBigInt();
    final bigB = b.toBigInt();

    // add
    expect((a + b).toBigInt(), (bigA + bigB) & mask64);

    // sub
    expect((a - b).toBigInt(), (bigA - bigB) & mask64);

    // mul
    expect((a * b).toBigInt(), (bigA * bigB) & mask64);

    // shifts
    final s = rnd.nextInt(64);
    expect((a << s).toBigInt(), (bigA << s) & mask64);
    expect((a >> s).toBigInt(), (bigA >> s) & mask64);

    // bitwise
    expect((a & b).toBigInt(), bigA & bigB);
    expect((a | b).toBigInt(), bigA | bigB);
    expect((a ^ b).toBigInt(), bigA ^ bigB);
  }
}

void boundaryTests() {
  final zero = Uint64.zero;
  final one = Uint64.one;
  final max = Uint64.max;

  // wrapping add: (2^64 - 1) + 1 = 0 mod 2^64
  expect((max + one).toBigInt(), BigInt.zero);

  // wrapping sub: 0 - 1 = 2^64 - 1
  expect((zero - one).toBigInt(), BigInt.parse("FFFFFFFFFFFFFFFF", radix: 16));

  // wrapping mul: (2^64 - 1)^2 = 1 mod 2^64
  expect((max * max).toBigInt(), BigInt.one);

  // shifts
  expect((one << 63).toBigInt(), BigInt.parse("8000000000000000", radix: 16));
  expect((max >> 63).toBigInt(), BigInt.one);
}

void identityTests() {
  final a = Uint64.parseHex("0x1234567890ABCDEF");
  final b = Uint64.parseHex("0x0FEDCBA098765432");

  // Valid identity for wrapping arithmetic
  expect(((a + b) - b).toBigInt(), a.toBigInt());

  // Valid shift identity
  expect(((a << 1) >> 1).toBigInt(), (a & Uint64.max).toBigInt());
}

void bitwiseTests() {
  final a = Uint64.parseHex("0xAAAAAAAAAAAAAAAA");
  final b = Uint64.parseHex("0x5555555555555555");

  expect((a & b).toHexString(), "0000000000000000");
  expect((a | b).toHexString().toUpperCase(), "FFFFFFFFFFFFFFFF");
  expect((a ^ b).toHexString().toUpperCase(), "FFFFFFFFFFFFFFFF");
  expect((~a).toHexString(), "5555555555555555");
}

void shiftTests() {
  final a = Uint64.parseHex("0x0000000000000001");

  expect((a << 63).toHexString(), "8000000000000000");
  expect((a << 64).toHexString(), "0000000000000001"); // masked shift
  expect((a >> 1).toHexString(), "0000000000000000");
}

void widenMulTests() {
  final a = Uint64.parseHex("0xFFFFFFFFFFFFFFFF");
  final b = Uint64.parseHex("0xFFFFFFFFFFFFFFFF");

  final (hi, lo) = Uint64.widenMul(a, b);

  final big = a.toBigInt() * b.toBigInt();
  expect(lo.toBigInt(), big & BigInt.parse("FFFFFFFFFFFFFFFF", radix: 16));
  expect(
    hi.toBigInt(),
    (big >> 64) & BigInt.parse("FFFFFFFFFFFFFFFF", radix: 16),
  );
}

void oracleTest() {
  for (int i = 0; i < 50000; i++) {
    final a = Uint64(i * 123456789);
    final b = Uint64(i * 987654321);

    final bigA = a.toBigInt();
    final bigB = b.toBigInt();

    expect(
      (a + b).toBigInt(),
      (bigA + bigB) & BigInt.parse("FFFFFFFFFFFFFFFF", radix: 16),
    );

    expect(
      (a * b).toBigInt(),
      (bigA * bigB) & BigInt.parse("FFFFFFFFFFFFFFFF", radix: 16),
    );
  }
}
