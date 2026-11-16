import 'dart:typed_data';
import 'package:blockchain_utils/blockchain_utils.dart';

import 'package:blockchain_utils/encoding/cbor/utils/float_utils.dart';
import 'package:test/test.dart';

import '../../utils.dart';

void floatUtilsTest() {
  group('fit detection, verified against Python\'s struct module', () {
    // (value, fits float16, fits float32) - independently computed via
    // Python's struct.pack('>e'/'>f', v) round-trip, not derived from
    // this implementation.
    const cases = [
      (1.0, true, true),
      (0.5, true, true),
      (-2.0, true, true),
      (0.1, false, false),
      (65504.0, true, true), // float16's largest finite value
      (65520.0, false, true), // just past it - fits float32, not float16
      (100000.0, false, true),
      (3.14159265358979, false, false),
    ];

    for (final (value, fits16, fits32) in cases) {
      test('$value: isLessThan16=$fits16, isLessThan32=$fits32', () {
        final f = FloatUtils(value);
        expect(
          f.isLessThan16,
          equals(fits16),
          reason: 'isLessThan16 for $value',
        );
        expect(
          f.isLessThan32,
          equals(fits32),
          reason: 'isLessThan32 for $value',
        );
      });
    }

    test('type picks the smallest format that fits', () {
      expect(FloatUtils(1.0).type, equals(FloatLength.bytes16));
      expect(FloatUtils(65520.0).type, equals(FloatLength.bytes32));
      expect(FloatUtils(0.1).type, equals(FloatLength.bytes64));
    });
  });

  group('NaN / Infinity', () {
    test('NaN always fits (both flags true), even though NaN != NaN', () {
      final f = FloatUtils(double.nan);
      expect(f.isLessThan16, isTrue);
      expect(f.isLessThan32, isTrue);
      expect(f.type, equals(FloatLength.bytes16));
    });

    test('Infinity and -Infinity always fit', () {
      for (final v in [double.infinity, double.negativeInfinity]) {
        final f = FloatUtils(v);
        expect(f.isLessThan16, isTrue);
        expect(f.isLessThan32, isTrue);
      }
    });

    test('encoding/decoding NaN through float16 gives back a NaN', () {
      final (bytes, format) = FloatUtils(double.nan).toBytes(null);
      expect(format, equals(FloatLength.bytes16));
      expect(FloatUtils.floatFromBytes16(bytes).isNaN, isTrue);
    });

    test('encoding/decoding Infinity through float16 round trips exactly', () {
      final (bytes, format) = FloatUtils(double.infinity).toBytes(null);
      expect(format, equals(FloatLength.bytes16));
      expect(FloatUtils.floatFromBytes16(bytes), equals(double.infinity));
    });
  });

  group('float16 bit patterns, verified against Python', () {
    // bytes -> the value Python's struct says those bits decode to.
    const patterns = {0x3c00: 1.0, 0x3800: 0.5, 0xc000: -2.0, 0x7bff: 65504.0};

    patterns.forEach((bits, expected) {
      test('0x${bits.toRadixString(16)} decodes to $expected', () {
        final bytes = [(bits >> 8) & 0xFF, bits & 0xFF];
        expect(FloatUtils.floatFromBytes16(bytes), equals(expected));
      });
    });
  });

  group('toBytes', () {
    test(
      'auto format picks float16 when it fits and allowFloat16 is true (default)',
      () {
        final (bytes, format) = FloatUtils(1.0).toBytes(null);
        expect(format, equals(FloatLength.bytes16));
        expect(bytes.length, equals(2));
      },
    );

    test(
      'allowFloat16: false skips straight to float32 (or float64) even if float16 would fit',
      () {
        final (bytes, format) = FloatUtils(
          1.0,
        ).toBytes(null, allowFloat16: false);
        expect(format, equals(FloatLength.bytes32));
        expect(bytes.length, equals(4));
      },
    );

    test('explicit format that the value fits succeeds', () {
      final (bytes, format) = FloatUtils(65504.0).toBytes(FloatLength.bytes16);
      expect(format, equals(FloatLength.bytes16));
      expect(bytes.length, equals(2));
    });

    test(
      'explicit float16 that the value does NOT fit throws CborException',
      () {
        expect(
          () => FloatUtils(65520.0).toBytes(FloatLength.bytes16),
          throwsA(isA<BuError>()),
        );
      },
    );

    test(
      'explicit float32 that the value does NOT fit throws CborException',
      () {
        expect(
          () => FloatUtils(0.1).toBytes(FloatLength.bytes32),
          throwsA(isA<BuError>()),
        );
      },
    );

    test('float64 always succeeds regardless of fit', () {
      final (bytes, format) = FloatUtils(0.1).toBytes(FloatLength.bytes64);
      expect(format, equals(FloatLength.bytes64));
      expect(bytes.length, equals(8));
    });

    test('big-endian is the default byte order', () {
      final (bytesDefault, _) = FloatUtils(1.0).toBytes(FloatLength.bytes16);
      final (bytesBig, _) = FloatUtils(
        1.0,
      ).toBytes(FloatLength.bytes16, endianness: Endian.big);
      expect(bytesDefault, equals(bytesBig));
    });

    test('little-endian reverses the byte order', () {
      final (bytesBig, _) = FloatUtils(
        1.0,
      ).toBytes(FloatLength.bytes16, endianness: Endian.big);
      final (bytesLittle, _) = FloatUtils(
        1.0,
      ).toBytes(FloatLength.bytes16, endianness: Endian.little);
      expect(bytesLittle, equals(bytesBig.reversed.toList()));
    });
  });

  group('round trip through every format', () {
    test('float16-fitting values round trip via floatFromBytes16', () {
      for (final v in [1.0, 0.5, -2.0, 65504.0, 0.0, -0.0]) {
        final (bytes, format) = FloatUtils(v).toBytes(FloatLength.bytes16);
        expect(format, equals(FloatLength.bytes16));
        expect(
          FloatUtils.floatFromBytes16(bytes),
          equals(v),
          reason: 'value=$v',
        );
      }
    });

    test('a value needing float64 round trips through toBytes + ByteData', () {
      const v = 0.1;
      final (bytes, format) = FloatUtils(v).toBytes(null);
      expect(format, equals(FloatLength.bytes64));
      final decoded = ByteData.sublistView(
        Uint8List.fromList(bytes),
      ).getFloat64(0, Endian.big);
      expect(decoded, equals(v));
    });
  });

  group('static isLessThan', () {
    test('agrees with the instance getters for representative values', () {
      for (final v in [1.0, 0.1, 65504.0, 65520.0]) {
        expect(
          FloatUtils.isLessThan(v, FloatLength.bytes16),
          equals(FloatUtils(v).isLessThan16),
        );
        expect(
          FloatUtils.isLessThan(v, FloatLength.bytes32),
          equals(FloatUtils(v).isLessThan32),
        );
        expect(FloatUtils.isLessThan(v, FloatLength.bytes64), isTrue);
      }
    });
  });

  group('FloatLength', () {
    test('getByIndex returns the right values for valid indices', () {
      expect(FloatLength.getByIndex(0), equals(FloatLength.bytes16));
      expect(FloatLength.getByIndex(1), equals(FloatLength.bytes32));
      expect(FloatLength.getByIndex(2), equals(FloatLength.bytes64));
    });

    test('getByIndex throws CborException for an out-of-range index', () {
      expect(() => FloatLength.getByIndex(3), throwsA(isA<BuError>()));
      expect(() => FloatLength.getByIndex(-1), throwsA(isA<BuError>()));
    });

    test('exponentBias matches the well-known values for each format', () {
      expect(FloatLength.bytes16.exponentBias, equals(15));
      expect(FloatLength.bytes32.exponentBias, equals(127));
      expect(FloatLength.bytes64.exponentBias, equals(1023));
    });
  });
}

void main() {
  BlockchainUtilsTestApi.runTest(floatUtilsTest, "Float Utils");
}
