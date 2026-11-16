/// UTF-8 and ASCII encoding: Dart `String` (UTF-16) -> bytes.
library;

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';


/// Encodes a Dart String (UTF-16) to UTF-8 bytes.
class UTF8Encoder {
  /// Resolves the UTF-16 code unit(s) at index [i] into a single Unicode
  /// code point - combining a surrogate pair into one code point, or
  /// substituting U+FFFD (the standard replacement character) for an
  /// unpaired high/low surrogate. Returns `(codePoint, nextIndex)`.
  ///
  /// This is the one place surrogate-pair resolution is implemented -
  /// both [inBytesLength] and [encode] call it, so there's no duplicated
  /// (and therefore driftable) copy of this logic to keep in sync.
  static (int codePoint, int nextIndex) _nextCodePoint(String s, int i) {
    final cu = s.codeUnitAt(i);

    if (cu >= 0xD800 && cu <= 0xDBFF) {
      // High surrogate - look for a following low surrogate to pair with.
      if (i + 1 < s.length) {
        final c2 = s.codeUnitAt(i + 1);
        if (c2 >= 0xDC00 && c2 <= 0xDFFF) {
          return (0x10000 + ((cu - 0xD800) << 10) + (c2 - 0xDC00), i + 2);
        }
      }
      return (0xFFFD, i + 1); // unpaired high surrogate
    }
    if (cu >= 0xDC00 && cu <= 0xDFFF) {
      return (0xFFFD, i + 1); // unpaired low surrogate
    }
    return (cu, i + 1);
  }

  static int _utf8ByteLengthFor(int codePoint) {
    if (codePoint <= 0x7F) return 1;
    if (codePoint <= 0x7FF) return 2;
    if (codePoint <= 0xFFFF) return 3;
    return 4;
  }

  /// The number of UTF-8 bytes [s] would encode to, without actually
  /// allocating/writing them - useful for sizing a buffer you're writing
  /// into yourself.
  static int inBytesLength(String s) {
    var length = 0;
    var i = 0;
    while (i < s.length) {
      final (codePoint, next) = _nextCodePoint(s, i);
      length += _utf8ByteLengthFor(codePoint);
      i = next;
    }
    return length;
  }

  /// Encodes [s] to UTF-8 bytes. Single pass: each code point is resolved
  /// once and its 1-4 UTF-8 bytes written immediately - no separate
  /// length-counting pass first.
  static BuBytes encode(String s) {
    final out = BuBytes.empty();
    var i = 0;
    while (i < s.length) {
      final (codePoint, next) = _nextCodePoint(s, i);
      i = next;

      if (codePoint <= 0x7F) {
        out.add(codePoint);
      } else if (codePoint <= 0x7FF) {
        out.add(0xC0 | (codePoint >> 6));
        out.add(0x80 | (codePoint & 0x3F));
      } else if (codePoint <= 0xFFFF) {
        out.add(0xE0 | (codePoint >> 12));
        out.add(0x80 | ((codePoint >> 6) & 0x3F));
        out.add(0x80 | (codePoint & 0x3F));
      } else {
        out.add(0xF0 | (codePoint >> 18));
        out.add(0x80 | ((codePoint >> 12) & 0x3F));
        out.add(0x80 | ((codePoint >> 6) & 0x3F));
        out.add(0x80 | (codePoint & 0x3F));
      }
    }
    return out;
  }
}

/// Encodes a Dart String to ASCII bytes - one byte per character, since
/// every valid ASCII character is already a single UTF-16 code unit
/// <= 0x7F.
class ASCIIEncoder {
  /// Encodes [str] to ASCII bytes.
  ///
  /// Throws [Utf8Exception] if [str] contains any character outside the
  /// ASCII range (0x00..0x7F).
  static BuBytes encode(String str) {
    // Output is always exactly one byte per input character - no
    // variable-length expansion like UTF-8 has - so the buffer can be
    // sized exactly up front instead of grown incrementally.
    final bytes = BuBytes.fill(str.length, 0);
    for (var i = 0; i < str.length; i++) {
      final codeUnit = str.codeUnitAt(i);
      if (codeUnit > 0x7F) {
        throw BuError(DefaultErrorType.badUtf8,
          'Invalid ASCII string.',
          details: {
            'reason':
                'character "${str[i]}" at index $i is outside the ASCII range',
          },
        );
      }
      bytes[i] = codeUnit;
    }
    return bytes;
  }
}
