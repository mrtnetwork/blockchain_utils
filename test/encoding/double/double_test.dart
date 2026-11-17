import 'dart:typed_data';
import 'package:blockchain_utils/blockchain_utils.dart';

import 'package:test/test.dart';

import '../../utils.dart';

void doubleTest() {
  group('DoubleCoder', () {
    test('f64 roundtrip', () {
      for (final v in [
        0.0,
        -0.0,
        1.0,
        -1.5,
        3.141592653589793,
        1.7976931348623157e308,
        5e-324,
        double.infinity,
        double.negativeInfinity,
      ]) {
        final decoded = DoubleCoder.fromBytes(DoubleCoder.toBytes(v));
        expect(decoded, v, reason: 'f64 $v');
      }
      expect(
        DoubleCoder.fromBytes(DoubleCoder.toBytes(double.nan)).isNaN,
        isTrue,
      );
    });

    test('f64 big-endian bytes', () {
      expect(DoubleCoder.toBytes(1.0).toList(), [0x3F, 0xF0, 0, 0, 0, 0, 0, 0]);
      expect(DoubleCoder.fromBytes([0x3F, 0xF0, 0, 0, 0, 0, 0, 0]), 1.0);
    });

    test('f64 endianness', () {
      final le = DoubleCoder.toBytes(1.5, byteOrder: Endian.little);
      final be = DoubleCoder.toBytes(1.5, byteOrder: Endian.big);
      expect(le.toList(), be.toList().reversed.toList());
      expect(DoubleCoder.fromBytes(le, byteOrder: Endian.little), 1.5);
    });

    test('f64 requires exactly 8 bytes', () {
      expect(() => DoubleCoder.fromBytes([1, 2, 3]), throwsA(isA<BuError>()));
      expect(
        () => DoubleCoder.fromBytes(List<int>.filled(7, 0)),
        throwsA(isA<BuError>()),
      );
      expect(
        () => DoubleCoder.fromBytes(List<int>.filled(9, 0)),
        throwsA(isA<BuError>()),
      );
      expect(() => DoubleCoder.fromBytes([]), throwsA(isA<BuError>()));
    });
  });

  group('FloatCoder', () {
    test('f32 roundtrip', () {
      for (final v in [0.0, 0.5, -2.25, 1.0]) {
        expect(FloatCoder.fromBytes(FloatCoder.toBytes(v)), v);
      }
      // f32 cannot represent pi exactly; check precision loss is bounded.
      final pi32 = FloatCoder.fromBytes(FloatCoder.toBytes(3.141592653589793));
      expect((pi32 - 3.141592653589793).abs() < 1e-7, isTrue);
    });

    test('f32 big-endian bytes', () {
      expect(FloatCoder.toBytes(0.5).toList(), [0x3F, 0, 0, 0]);
      expect(FloatCoder.fromBytes([0x3F, 0, 0, 0]), 0.5);
    });

    test('f32 endianness', () {
      final le = FloatCoder.toBytes(0.5, byteOrder: Endian.little);
      final be = FloatCoder.toBytes(0.5, byteOrder: Endian.big);
      expect(le.toList(), be.toList().reversed.toList());
    });

    test('f32 requires exactly 4 bytes', () {
      expect(() => FloatCoder.fromBytes([1, 2, 3]), throwsA(isA<BuError>()));
      expect(
        () => FloatCoder.fromBytes(List<int>.filled(5, 0)),
        throwsA(isA<BuError>()),
      );
      expect(() => FloatCoder.fromBytes([]), throwsA(isA<BuError>()));
    });
  });
}

void main() {
  BlockchainUtilsTestApi.runTest(doubleTest, "Double");
}
