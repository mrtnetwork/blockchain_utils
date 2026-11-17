/// UTF-8 and ASCII decoding: bytes -> Dart String (UTF-16).
library;

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// Decodes UTF-8 bytes to a Dart String.
class UTF8Decoder {
  /// Decodes [bytes] as UTF-8. A leading UTF-8 BOM (`EF BB BF`), if
  /// present, is skipped rather than decoded as a character.
  ///
  /// [allowMalformed]: if true, invalid sequences are replaced with
  /// U+FFFD (the standard replacement character) instead of throwing.
  ///
  /// Throws [Utf8Exception] on malformed input when [allowMalformed] is
  /// false (the default) - an invalid lead byte, a truncated sequence, an
  /// invalid continuation byte, or a code point that's out of range,
  /// overlong, or a surrogate value (all of which are invalid to encode
  /// directly in UTF-8).
  static String decode(List<int> bytes, {bool allowMalformed = false}) {
    final out = <int>[];
    var i = 0;

    if (bytes.length >= 3 &&
        bytes[0] == 0xEF &&
        bytes[1] == 0xBB &&
        bytes[2] == 0xBF) {
      i = 3;
    }

    while (i < bytes.length) {
      final byte1 = bytes[i];

      if (byte1 <= 0x7F) {
        out.add(byte1);
        i++;
        continue;
      }

      int expectedLength;
      int codePoint;

      if (byte1 >= 0xC2 && byte1 <= 0xDF) {
        expectedLength = 2;
        codePoint = byte1 & 0x1F;
      } else if (byte1 >= 0xE0 && byte1 <= 0xEF) {
        expectedLength = 3;
        codePoint = byte1 & 0x0F;
      } else if (byte1 >= 0xF0 && byte1 <= 0xF4) {
        expectedLength = 4;
        codePoint = byte1 & 0x07;
      } else {
        if (!allowMalformed) {
          throw BuError(
            DefaultErrorType.badUtf8,
            'Invalid UTF-8 string.',
            details: {
              'reason':
                  'invalid lead byte 0x${byte1.toRadixString(16)} at index $i',
            },
          );
        }
        out.add(0xFFFD);
        i++;
        continue;
      }

      final remaining = bytes.length - i - 1;
      if (remaining < expectedLength - 1) {
        if (!allowMalformed) {
          throw BuError(
            DefaultErrorType.badUtf8,
            'Invalid UTF-8 string.',
            details: {'reason': 'truncated sequence at index $i'},
          );
        }
        out.add(0xFFFD);
        i += remaining + 1;
        continue;
      }

      var validContinuation = true;
      for (var j = 1; j < expectedLength; j++) {
        if ((bytes[i + j] & 0xC0) != 0x80) {
          validContinuation = false;
          break;
        }
      }

      if (!validContinuation) {
        if (!allowMalformed) {
          throw BuError(
            DefaultErrorType.badUtf8,
            'Invalid UTF-8 string.',
            details: {'reason': 'invalid continuation byte at index $i'},
          );
        }
        var consume = 1;
        while (i + consume < bytes.length &&
            (bytes[i + consume] & 0xC0) == 0x80) {
          consume++;
        }
        out.add(0xFFFD);
        i += consume;
        continue;
      }

      for (var j = 1; j < expectedLength; j++) {
        codePoint = (codePoint << 6) | (bytes[i + j] & 0x3F);
      }

      // Reject overlong encodings, out-of-range code points, and
      // surrogate values (0xD800..0xDFFF are UTF-16 surrogate halves and
      // are never valid as a standalone UTF-8 code point).
      final isOverlong =
          (expectedLength == 2 && codePoint <= 0x7F) ||
          (expectedLength == 3 && codePoint <= 0x7FF) ||
          (expectedLength == 4 && codePoint <= 0xFFFF);
      final isSurrogate = codePoint >= 0xD800 && codePoint <= 0xDFFF;
      if (codePoint > 0x10FFFF || isOverlong || isSurrogate) {
        if (!allowMalformed) {
          throw BuError(
            DefaultErrorType.badUtf8,
            'Invalid UTF-8 string.',
            details: {'reason': 'invalid code point $codePoint at index $i'},
          );
        }
        out.add(0xFFFD);
        i++;
        continue;
      }

      if (codePoint <= 0xFFFF) {
        out.add(codePoint);
      } else {
        // Encode as a UTF-16 surrogate pair, since Dart Strings are
        // UTF-16 and this code point needs two code units.
        final adjusted = codePoint - 0x10000;
        out.add(0xD800 + (adjusted >> 10));
        out.add(0xDC00 + (adjusted & 0x3FF));
      }

      i += expectedLength;
    }

    return String.fromCharCodes(out);
  }
}

/// Decodes ASCII bytes to a Dart String - one character per byte, since
/// every ASCII byte maps directly to a single UTF-16 code unit.
class ASCIIDecoder {
  /// Decodes [bytes] as ASCII.
  ///
  /// [allowMalformed]: if true, any byte outside the ASCII range is
  /// replaced with U+FFFD (the standard replacement character) instead of
  /// throwing.
  ///
  /// Throws [Utf8Exception] if [bytes] contains a byte outside the ASCII
  /// range (0x00..0x7F) and [allowMalformed] is false (the default).
  static String decode(List<int> bytes, {bool allowMalformed = false}) {
    // Output is always exactly one char per input byte - no need for a
    // separate first pass to count length before allocating (that count
    // is always just bytes.length; the original computed it anyway).
    final chars = List<int>.filled(bytes.length, 0);
    for (var i = 0; i < bytes.length; i++) {
      final b = bytes[i];
      if (b <= 0x7F) {
        chars[i] = b;
      } else if (allowMalformed) {
        chars[i] = 0xFFFD;
      } else {
        throw BuError(
          DefaultErrorType.badUtf8,
          'Invalid ASCII string.',
          details: {
            'reason':
                'byte 0x${b.toRadixString(16)} at index $i is outside the ASCII range',
          },
        );
      }
    }
    return String.fromCharCodes(chars);
  }
}
