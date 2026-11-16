import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:test/test.dart';

import '../../utils.dart';

void hexTest() {
  group('encode', () {
    test('empty', () {
      expect(hex.encode([]), equals(''));
    });

    test('lowercase (default)', () {
      expect(hex.encode([0, 1, 255, 16, 171]), equals('0001ff10ab'));
    });

    test('uppercase', () {
      expect(
        hex.encode([0, 1, 255, 16, 171], lowerCase: false),
        equals('0001FF10AB'),
      );
    });

    test('every byte value 0..255 encodes correctly', () {
      for (var b = 0; b < 256; b++) {
        expect(hex.encode([b]), equals(b.toRadixString(16).padLeft(2, '0')));
      }
    });

    test('throws HexFormatError on an out-of-range byte', () {
      expect(() => hex.encode([256]), throwsA(isA<BuError>()));
      expect(() => hex.encode([-1]), throwsA(isA<BuError>()));
    });

    test('tryEncode returns null instead of throwing', () {
      expect(hex.tryEncode([256]), isNull);
      expect(hex.tryEncode([1, 2, 3]), equals('010203'));
    });
  });

  group('decode', () {
    test('empty', () {
      expect(hex.decode(''), equals([]));
    });

    test('lowercase input', () {
      expect(hex.decode('0001ff10ab'), equals([0, 1, 255, 16, 171]));
    });

    test('uppercase input', () {
      expect(hex.decode('0001FF10AB'), equals([0, 1, 255, 16, 171]));
    });

    test('mixed-case input', () {
      expect(hex.decode('Ff0aB1'), equals([0xFF, 0x0A, 0xB1]));
    });

    test('every byte value 0..255 round trips', () {
      for (var b = 0; b < 256; b++) {
        final encoded = hex.encode([b]);
        expect(hex.decode(encoded), equals([b]), reason: 'byte=$b');
      }
    });

    test('throws HexFormatError on odd length', () {
      expect(() => hex.decode('abc'), throwsA(isA<BuError>()));
    });

    test('throws HexFormatError on a non-hex character', () {
      expect(() => hex.decode('gg'), throwsA(isA<BuError>()));
      expect(() => hex.decode('0g'), throwsA(isA<BuError>()));
    });

    test('error message identifies the specific bad character and index', () {
      try {
        hex.decode('ab0xcd');
        fail('should have thrown');
      } on BuError catch (e) {
        expect(e.details?['reason'], contains('"x"'));
        expect(e.details?['reason'], contains('index 3'));
      }
    });

    test('tryDecode returns null instead of throwing', () {
      expect(hex.tryDecode('gg'), isNull);
      expect(hex.tryDecode('abc'), isNull);
      expect(hex.tryDecode('0102'), equals([1, 2]));
    });
  });

  group('round trip', () {
    test('a longer arbitrary byte sequence round trips, both cases', () {
      final bytes = List<int>.generate(97, (i) => (i * 37 + 5) % 256);
      expect(hex.decode(hex.encode(bytes)), equals(bytes));
      expect(hex.decode(hex.encode(bytes, lowerCase: false)), equals(bytes));
    });
  });
}

void main() {
  BlockchainUtilsTestApi.runTest(hexTest, "Hex");
}
