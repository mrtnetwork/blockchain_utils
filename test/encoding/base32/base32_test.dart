// This file assumes it lives inside your blockchain_utils project (or
// anywhere with that package as a dependency) - it needs Base32FormatError,
// which extends BlockchainUtilsException. Adjust the import below to
// wherever you place base32.dart.
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:test/test.dart';

import '../../utils.dart';

void base32Test() {
  group('RFC 4648 §10 official test vectors', () {
    // https://www.rfc-editor.org/rfc/rfc4648#section-10
    const vectors = {
      '': '',
      'f': 'MY======',
      'fo': 'MZXQ====',
      'foo': 'MZXW6===',
      'foob': 'MZXW6YQ=',
      'fooba': 'MZXW6YTB',
      'foobar': 'MZXW6YTBOI======',
    };

    vectors.forEach((plain, encoded) {
      test('Base32Encoder.encode("$plain") == "$encoded"', () {
        expect(Base32Encoder.encode(plain), equals(encoded));
      });

      test('Base32Decoder.decode("$encoded") round trips to "$plain"', () {
        expect(Base32Decoder.decode(encoded), equals(plain.codeUnits));
      });
    });
  });

  group('no-padding variants', () {
    test('encodeNoPadding strips trailing =', () {
      expect(Base32Encoder.encodeNoPadding('f'), equals('MY'));
      expect(Base32Encoder.encodeNoPadding('foo'), equals('MZXW6'));
      expect(Base32Encoder.encodeNoPadding('foobar'), equals('MZXW6YTBOI'));
    });

    test('decode accepts input with no padding at all', () {
      expect(Base32Decoder.decode('MY'), equals('f'.codeUnits));
      expect(Base32Decoder.decode('MZXW6'), equals('foo'.codeUnits));
      expect(Base32Decoder.decode('MZXW6YTBOI'), equals('foobar'.codeUnits));
    });

    test('decode accepts either padded or unpadded input interchangeably', () {
      expect(
        Base32Decoder.decode('MZXW6YQ='),
        equals(Base32Decoder.decode('MZXW6YQ')),
      );
    });
  });

  group('bytes round trip', () {
    test('empty', () {
      expect(Base32Encoder.encodeBytes([]), equals(''));
      expect(Base32Decoder.decode(''), equals([]));
    });

    test('every byte value 0..255 round trips individually', () {
      for (var b = 0; b < 256; b++) {
        final encoded = Base32Encoder.encodeBytes([b]);
        expect(Base32Decoder.decode(encoded), equals([b]), reason: 'byte=$b');
      }
    });

    test('a longer arbitrary byte sequence round trips', () {
      final bytes = List<int>.generate(97, (i) => (i * 37 + 5) % 256);
      final encoded = Base32Encoder.encodeBytes(bytes);
      expect(Base32Decoder.decode(encoded), equals(bytes));
    });

    test('output length is always a multiple of 8 when padded', () {
      for (var len = 0; len <= 20; len++) {
        final bytes = List<int>.filled(len, 0xAB);
        expect(
          Base32Encoder.encodeBytes(bytes).length % 8,
          equals(0),
          reason: 'len=$len',
        );
      }
    });
  });

  group('custom alphabet', () {
    // A z-base-32-style alphabet (different symbol order, still 32 chars).
    const zAlphabet = 'ybndrfg8ejkmcpqxot1uwisza345h769';

    test('round trips with a custom alphabet', () {
      final bytes = [0, 1, 2, 253, 254, 255, 42, 128];
      final encoded = Base32Encoder.encodeBytes(bytes, zAlphabet);
      expect(Base32Decoder.decode(encoded, zAlphabet), equals(bytes));
    });

    test(
      'custom-alphabet output differs from the standard alphabet for the same bytes',
      () {
        final bytes = 'foobar'.codeUnits;
        final standard = Base32Encoder.encodeBytes(bytes);
        final custom = Base32Encoder.encodeBytes(bytes, zAlphabet);
        expect(custom, isNot(equals(standard)));
      },
    );

    test('rejects an alphabet that is not exactly 32 characters', () {
      expect(
        () => Base32Encoder.encodeBytes([1, 2, 3], 'TOOSHORT'),
        throwsA(isA<BuError>()),
      );
    });
  });

  group('error handling', () {
    test('invalid character throws Base32FormatError', () {
      expect(() => Base32Decoder.decode('MY0!'), throwsA(isA<BuError>()));
    });

    test('lowercase input (not in the standard alphabet) is rejected', () {
      // The standard RFC 4648 alphabet is uppercase-only; lowercase 'my'
      // isn't valid unless you explicitly pass a lowercase alphabet.
      expect(() => Base32Decoder.decode('my'), throwsA(isA<BuError>()));
    });
  });
}

void main() {
  BlockchainUtilsTestApi.runTest(base32Test, "Base32");
}
