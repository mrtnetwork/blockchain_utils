import 'dart:convert';
import 'dart:math';

import 'package:blockchain_utils/base64/converter/decoding.dart';
import 'package:blockchain_utils/base64/converter/encoding.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:test/test.dart';

import 'test_vector.dart';

String generateRandomString(int length) {
  const String charset = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ' // uppercase
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

void main() {
  _testVector();
  _withConvertPackage();
  _special();
  _urlSafe();
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
      final rand = QuickCrypto.generateRandom(i);
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
      final rand = QuickCrypto.generateRandom(i);
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
      final toB64 = B64Decoder.decode(i.value.replaceAll("=", ''),
          validatePadding: false);

      expect(toB64, i.key);
    }
  });
}
