import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:test/test.dart';

import '../../utils.dart';

void utf8Test() {
  group('UTF8Encoder / UTF8Decoder round trip', () {
    const cases = {
      '': <int>[],
      'A': [0x41],
      'café': [0x63, 0x61, 0x66, 0xC3, 0xA9],
      '\u{1F600}': [0xF0, 0x9F, 0x98, 0x80], // 😀
      'a\u{1F600}b': [0x61, 0xF0, 0x9F, 0x98, 0x80, 0x62],
    };

    cases.forEach((str, bytes) {
      test('encode("$str") == $bytes', () {
        expect(UTF8Encoder.encode(str), equals(bytes));
      });

      test('inBytesLength("$str") == ${bytes.length}', () {
        expect(UTF8Encoder.inBytesLength(str), equals(bytes.length));
      });

      test('decode($bytes) == "$str"', () {
        expect(UTF8Decoder.decode(bytes), equals(str));
      });
    });

    test('a longer mixed string round trips', () {
      const s = 'Hello, \u4e16\u754c! caf\u00e9 \u{1F600}\u{1F601}';
      expect(UTF8Decoder.decode(UTF8Encoder.encode(s)), equals(s));
    });
  });

  group('UTF8Decoder BOM handling', () {
    test('a leading UTF-8 BOM is stripped, not decoded as a character', () {
      expect(UTF8Decoder.decode([0xEF, 0xBB, 0xBF, 0x41]), equals('A'));
    });

    test('no BOM present decodes normally', () {
      expect(UTF8Decoder.decode([0x41]), equals('A'));
    });
  });

  group('UTF8Decoder error handling', () {
    test('invalid lead byte throws by default', () {
      expect(() => UTF8Decoder.decode([0xFF]), throwsA(isA<BuError>()));
    });

    test('invalid lead byte is replaced with U+FFFD when allowMalformed', () {
      expect(
        UTF8Decoder.decode([0xFF], allowMalformed: true),
        equals('\u{FFFD}'),
      );
    });

    test('truncated sequence throws by default', () {
      expect(() => UTF8Decoder.decode([0xE0, 0x82]), throwsA(isA<BuError>()));
    });

    test('truncated sequence is replaced when allowMalformed', () {
      expect(
        UTF8Decoder.decode([0xE0, 0x82], allowMalformed: true),
        equals('\u{FFFD}'),
      );
    });

    test('invalid continuation byte throws by default', () {
      expect(
        () => UTF8Decoder.decode([0xE0, 0x41, 0x41]),
        throwsA(isA<BuError>()),
      );
    });

    test(
      'overlong encoding (3-byte sequence for a <=0x7FF value) is rejected',
      () {
        // 0xE0 0x82 0x80 decodes arithmetically to code point 0x80, which
        // must be encoded in 2 bytes, not 3 - the 3-byte form is invalid.
        expect(
          () => UTF8Decoder.decode([0xE0, 0x82, 0x80]),
          throwsA(isA<BuError>()),
        );
      },
    );

    test('a directly UTF-8-encoded surrogate value is rejected', () {
      // 0xED 0xA0 0x80 arithmetically decodes to U+D800, a UTF-16
      // surrogate half - never valid as a standalone UTF-8 code point.
      expect(
        () => UTF8Decoder.decode([0xED, 0xA0, 0x80]),
        throwsA(isA<BuError>()),
      );
    });
  });

  group('UTF8Encoder unpaired surrogate handling', () {
    test('an unpaired high surrogate encodes as U+FFFD', () {
      final s = String.fromCharCode(0xD800); // lone high surrogate
      expect(UTF8Encoder.encode(s), equals(UTF8Encoder.encode('\u{FFFD}')));
    });

    test('an unpaired low surrogate encodes as U+FFFD', () {
      final s = String.fromCharCode(0xDC00); // lone low surrogate
      expect(UTF8Encoder.encode(s), equals(UTF8Encoder.encode('\u{FFFD}')));
    });
  });

  group('ASCIIEncoder / ASCIIDecoder round trip', () {
    test('plain ASCII text round trips', () {
      const s = 'Hello, World! 123';
      expect(ASCIIDecoder.decode(ASCIIEncoder.encode(s)), equals(s));
    });

    test('empty string round trips', () {
      expect(ASCIIEncoder.encode(''), equals(<int>[]));
      expect(ASCIIDecoder.decode([]), equals(''));
    });

    test('every ASCII byte value 0..127 round trips', () {
      final bytes = List<int>.generate(128, (i) => i);
      final s = ASCIIDecoder.decode(bytes);
      expect(ASCIIEncoder.encode(s), equals(bytes));
    });
  });

  group('ASCIIEncoder / ASCIIDecoder error handling', () {
    test('encode throws on a non-ASCII character', () {
      expect(() => ASCIIEncoder.encode('caf\u00e9'), throwsA(isA<BuError>()));
    });

    test('decode throws on a non-ASCII byte by default', () {
      expect(() => ASCIIDecoder.decode([0x41, 0xFF]), throwsA(isA<BuError>()));
    });

    test(
      'decode replaces a non-ASCII byte with U+FFFD when allowMalformed',
      () {
        expect(
          ASCIIDecoder.decode([0x41, 0xFF], allowMalformed: true),
          equals('A\u{FFFD}'),
        );
      },
    );
  });
}

void main() {
  BlockchainUtilsTestApi.runTest(utf8Test, "Utf8");
}
