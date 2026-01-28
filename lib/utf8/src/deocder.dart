import 'package:blockchain_utils/exception/exception/exception.dart';

class UTF8Decoder {
  static String decode(List<int> bytes, {bool allowMalformed = false}) {
    final c = <int>[];
    int i = 0;

    // Skip BOM if present at the start
    if (bytes.length >= 3 &&
        bytes[0] == 0xEF &&
        bytes[1] == 0xBB &&
        bytes[2] == 0xBF) {
      i = 3;
    }

    while (i < bytes.length) {
      int byte1 = bytes[i];

      // ASCII
      if (byte1 <= 0x7F) {
        c.add(byte1);
        i++;
        continue;
      }

      int expectedLength;
      int codePoint;

      // Determine sequence length and initial bits
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
        if (allowMalformed) {
          c.add(0xFFFD);
          i++;
        } else {
          throw ArgumentException.invalidOperationArguments(
            "Invalid UTF-8 bytes.",
            name: "bytes",
            reason: "Invalid UTF-8 lead byte at position $i: $byte1",
          );
        }
        continue;
      }

      int remaining = bytes.length - i - 1;
      if (remaining < expectedLength - 1) {
        if (allowMalformed) {
          c.add(0xFFFD);
          i += remaining + 1;
        } else {
          throw ArgumentException.invalidOperationArguments(
            "Invalid UTF-8 bytes.",
            name: "bytes",
            reason: "Truncated UTF-8 sequence at position $i",
          );
        }
        continue;
      }

      // Validate continuation bytes
      bool valid = true;
      for (int j = 1; j < expectedLength; j++) {
        if ((bytes[i + j] & 0xC0) != 0x80) {
          valid = false;
          break;
        }
      }

      if (!valid) {
        if (allowMalformed) {
          int consume = 1;
          while (i + consume < bytes.length &&
              (bytes[i + consume] & 0xC0) == 0x80) {
            consume++;
          }
          c.add(0xFFFD);
          i += consume;
        } else {
          throw ArgumentException.invalidOperationArguments(
            "Invalid UTF-8 bytes.",
            name: "bytes",
            reason: "Invalid UTF-8 continuation bytes at position $i",
          );
        }
        continue;
      }

      for (int j = 1; j < expectedLength; j++) {
        codePoint = (codePoint << 6) | (bytes[i + j] & 0x3F);
      }

      if (codePoint > 0x10FFFF ||
          (expectedLength == 2 && codePoint <= 0x7F) ||
          (expectedLength == 3 && codePoint <= 0x7FF) ||
          (expectedLength == 4 && codePoint <= 0xFFFF) ||
          (codePoint >= 0xD800 && codePoint <= 0xDFFF)) {
        if (allowMalformed) {
          c.add(0xFFFD);
          i++;
        } else {
          throw ArgumentException.invalidOperationArguments(
            "Invalid UTF-8 bytes.",
            name: "bytes",
            reason: "Invalid UTF-8 code point at position $i: $codePoint",
          );
        }
        continue;
      }

      if (codePoint <= 0xFFFF) {
        c.add(codePoint);
      } else {
        codePoint -= 0x10000;
        c.add(0xD800 + (codePoint >> 10));
        c.add(0xDC00 + (codePoint & 0x3FF));
      }

      i += expectedLength;
    }

    return String.fromCharCodes(c);
  }
}

class ASCIIDecoder {
  static String decode(List<int> bytes, {bool allowMalformed = false}) {
    int outLen = 0;
    for (int b in bytes) {
      if (b <= 0x7F) {
        outLen++;
      } else {
        if (!allowMalformed) {
          throw ArgumentException.invalidOperationArguments(
            "Invalid ASCII bytes.",
            name: "bytes",
            reason: "Invalid ASCII byte: $b",
          );
        }
        outLen++; // will insert U+FFFD
      }
    }

    final chars = List<int>.filled(outLen, 0, growable: false);

    int i = 0;
    for (int b in bytes) {
      if (b <= 0x7F) {
        chars[i++] = b;
      } else {
        chars[i++] =
            allowMalformed
                ? 0xFFFD
                : throw ArgumentException.invalidOperationArguments(
                  "Invalid ASCII bytes.",
                  name: "bytes",
                  reason: "Invalid ASCII byte: $b",
                );
      }
    }

    return String.fromCharCodes(chars);
  }
}
