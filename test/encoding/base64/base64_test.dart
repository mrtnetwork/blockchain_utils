import 'dart:convert';
import 'dart:math';

import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:test/test.dart';

import 'test_vector.dart';

import '../../utils.dart';

String generateRandomString(int length) {
  const String charset =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZ' // uppercase
      'abcdefghijklmnopqrstuvwxyz' // lowercase
      '0123456789' // digits
      ' !"#%&\'()*+,-./:;<=>?@[\\]^_`{|}~' // symbols, note escaped $
      '\t\n\r'; // whitespace chars

  final random = Random.secure(); // cryptographically strong RNG
  final buffer = StringBuffer();

  for (int i = 0; i < length; i++) {
    final idx = random.nextInt(charset.length);
    buffer.write(charset[idx]);
  }
  return buffer.toString();
}

void base64Test() {
  _testVector();
  _withConvertPackage();
  _special();
  _urlSafe();

  group('RFC 4648 §10 official test vectors', () {
    const vectors = {
      '': '',
      'f': 'Zg==',
      'fo': 'Zm8=',
      'foo': 'Zm9v',
      'foob': 'Zm9vYg==',
      'fooba': 'Zm9vYmE=',
      'foobar': 'Zm9vYmFy',
    };

    vectors.forEach((plain, encoded) {
      test('encode("$plain") == "$encoded"', () {
        expect(B64Encoder.encode(utf8.encode(plain)), equals(encoded));
      });

      test('decode("$encoded") == "$plain"', () {
        expect(utf8.decode(B64Decoder.decode(encoded)), equals(plain));
      });
    });
  });

  group('noPadding', () {
    test('strips trailing = from encode output', () {
      expect(
        B64Encoder.encode(utf8.encode('f'), noPadding: true),
        equals('Zg'),
      );
      expect(
        B64Encoder.encode(utf8.encode('fo'), noPadding: true),
        equals('Zm8'),
      );
      expect(
        B64Encoder.encode(utf8.encode('foo'), noPadding: true),
        equals('Zm9v'),
      );
    });

    test('decode with validatePadding:false accepts unpadded input', () {
      expect(
        B64Decoder.decode('Zg', validatePadding: false),
        equals(utf8.encode('f')),
      );
      expect(
        B64Decoder.decode('Zm8', validatePadding: false),
        equals(utf8.encode('fo')),
      );
    });

    test('decode with default validatePadding:true rejects unpadded input', () {
      expect(
        () => B64Decoder.decode('Zg'),
        throwsA(isA<BuError>()),
      );
    });
  });

  group('urlSafe', () {
    test('encode replaces + and / with - and _', () {
      // BuBytes chosen so the standard encoding actually contains both
      // '+' and '/' - byte values 0xFB../0xFF-ish ranges tend to produce
      // them; easiest is to just check known bytes.
      final bytes = [0xFB, 0xFF, 0xBF];
      final standard = B64Encoder.encode(bytes);
      final urlSafe = B64Encoder.encode(bytes, urlSafe: true);
      expect(standard, contains('+'));
      expect(standard, contains('/'));
      expect(urlSafe, isNot(contains('+')));
      expect(urlSafe, isNot(contains('/')));
      expect(urlSafe, contains('-'));
      expect(urlSafe, contains('_'));
    });

    test('decode accepts URL-safe characters by default', () {
      final bytes = [0xFB, 0xFF, 0xBF];
      final encoded = B64Encoder.encode(bytes, urlSafe: true);
      expect(B64Decoder.decode(encoded), equals(bytes));
    });

    test('decode rejects URL-safe characters when urlSafe:false', () {
      final bytes = [0xFB, 0xFF, 0xBF];
      final encoded = B64Encoder.encode(bytes, urlSafe: true);
      expect(
        () => B64Decoder.decode(encoded, urlSafe: false),
        throwsA(isA<BuError>()),
      );
    });

    test('decodeWithInfo reports isUrlSafe correctly', () {
      final bytes = [0xFB, 0xFF, 0xBF];
      final standardEncoded = B64Encoder.encode(bytes);
      final urlSafeEncoded = B64Encoder.encode(bytes, urlSafe: true);
      expect(B64Decoder.decodeWithInfo(standardEncoded).isUrlSafe, isFalse);
      expect(B64Decoder.decodeWithInfo(urlSafeEncoded).isUrlSafe, isTrue);
    });
  });

  group('round trip', () {
    test('empty', () {
      expect(B64Encoder.encode([]), equals(''));
      expect(B64Decoder.decode(''), equals([]));
    });

    test('every byte value 0..255 round trips individually', () {
      for (var b = 0; b < 256; b++) {
        final encoded = B64Encoder.encode([b]);
        expect(B64Decoder.decode(encoded), equals([b]), reason: 'byte=$b');
      }
    });

    test('all three remainder cases (0, 1, 2 leftover bytes) round trip', () {
      for (final len in [3, 4, 5, 6, 7, 8, 9]) {
        final bytes = List<int>.generate(len, (i) => (i * 41 + 3) % 256);
        expect(
          B64Decoder.decode(B64Encoder.encode(bytes)),
          equals(bytes),
          reason: 'len=$len',
        );
      }
    });

    test(
      'a large payload round trips correctly (exercises the O(n) path, not just small inputs)',
      () {
        final bytes = List<int>.generate(200000, (i) => (i * 2654435761) % 256);
        final encoded = B64Encoder.encode(bytes);
        expect(B64Decoder.decode(encoded), equals(bytes));
      },
    );
  });

  group('newline handling', () {
    test('embedded newlines are stripped before length/padding validation', () {
      final encoded = B64Encoder.encode(utf8.encode('foobar'));
      final wrapped = '${encoded.substring(0, 4)}\n${encoded.substring(4)}\r\n';
      expect(utf8.decode(B64Decoder.decode(wrapped)), equals('foobar'));
    });
  });

  group('error handling', () {
    test('invalid character throws B64ConverterException', () {
      expect(
        () => B64Decoder.decode('!!!!'),
        throwsA(isA<BuError>()),
      );
    });

    test('wrong length (not a multiple of 4, validatePadding:true) throws', () {
      expect(
        () => B64Decoder.decode('Zg', validatePadding: true),
        throwsA(isA<BuError>()),
      );
    });

    test('tryDecode returns null instead of throwing', () {
      expect(B64Decoder.tryDecode('!!!!'), isNull);
      expect(B64Decoder.tryDecode('Zm9vYmFy'), equals(utf8.encode('foobar')));
    });

    test(
      'a non-ASCII character is rejected cleanly, not with a raw RangeError',
      () {
        expect(
          () => B64Decoder.decode('Zg\u{1F600}='),
          throwsA(isA<BuError>()),
        );
      },
    );
  });
}

void main() {
  BlockchainUtilsTestApi.runTest(base64Test, "Base64");
}

void _testVector() {
  test("base64 test vector", () {
    for (final i in base64TestMap.entries) {
      final bytes = StringUtils.encode(i.key);
      final b64 = B64Encoder.encode(bytes);
      expect(b64, i.value);
      final decode = B64Decoder.decode(b64);
      expect(decode, bytes);
    }
  });
}

void _urlSafe() {
  test("base64 test url safe with dart:convert", () {
    for (int i = 0; i < 100; i++) {
      final rand = QuickCrypto.generateRandom(length: i);
      final toB64 = B64Encoder.encode(rand, urlSafe: true);
      final cB64 = base64UrlEncode(rand);
      expect(toB64, cB64);
      final decode = B64Decoder.decode(toB64);
      final cB64s = base64Decode(cB64);
      expect(decode, rand);
      expect(cB64s, rand);
    }
  });
}

void _withConvertPackage() {
  test("base64 test with dart:convert", () {
    for (int i = 0; i < 100; i++) {
      final rand = QuickCrypto.generateRandom(length: i);
      final toB64 = B64Encoder.encode(rand);
      final cB64 = base64Encode(rand);
      expect(toB64, cB64);
      final decode = B64Decoder.decode(toB64);
      expect(decode, rand);
    }
  });
}

void _special() {
  test("base64 special bytes", () {
    for (final i in specialBase64Map.entries) {
      final toB64 = B64Encoder.encode(i.key);
      final cB64 = base64Encode(i.key);
      expect(toB64, cB64);
      expect(toB64, i.value);

      final decode = B64Decoder.decode(toB64);

      expect(decode, i.key);
    }
    for (final i in specialBase64Map.entries) {
      final toB64 = B64Decoder.decode(
        i.value.replaceAll("=", ''),
        validatePadding: false,
      );

      expect(toB64, i.key);
    }
  });
}
