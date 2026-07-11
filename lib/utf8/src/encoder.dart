import 'package:blockchain_utils/exception/exceptions.dart';

class UTF8Encoder {
  static int inBytesLength(String s) {
    final int length = s.length;
    int utf8Length = 0;
    for (int i = 0; i < length; i++) {
      int cu = s.codeUnitAt(i);

      if (cu >= 0xD800 && cu <= 0xDBFF) {
        if (i + 1 < length) {
          int c2 = s.codeUnitAt(i + 1);
          if (c2 >= 0xDC00 && c2 <= 0xDFFF) {
            cu = 0x10000 + ((cu - 0xD800) << 10) + (c2 - 0xDC00);
            i++;
          } else {
            cu = 0xFFFD; // replacement char
          }
        } else {
          cu = 0xFFFD; // lone high surrogate
        }
      } else if (cu >= 0xDC00 && cu <= 0xDFFF) {
        cu = 0xFFFD; // lone low surrogate
      }

      // Count UTF-8 bytes
      if (cu <= 0x7F) {
        utf8Length += 1;
      } else if (cu <= 0x7FF) {
        utf8Length += 2;
      } else if (cu <= 0xFFFF) {
        utf8Length += 3;
      } else {
        utf8Length += 4;
      }
    }
    return utf8Length;
  }

  static List<int> encode(String s) {
    final int length = s.length;

    int utf8Length = 0;

    for (int i = 0; i < length; i++) {
      int cu = s.codeUnitAt(i);

      if (cu >= 0xD800 && cu <= 0xDBFF) {
        if (i + 1 < length) {
          int c2 = s.codeUnitAt(i + 1);
          if (c2 >= 0xDC00 && c2 <= 0xDFFF) {
            cu = 0x10000 + ((cu - 0xD800) << 10) + (c2 - 0xDC00);
            i++;
          } else {
            cu = 0xFFFD; // replacement char
          }
        } else {
          cu = 0xFFFD; // lone high surrogate
        }
      } else if (cu >= 0xDC00 && cu <= 0xDFFF) {
        cu = 0xFFFD; // lone low surrogate
      }

      // Count UTF-8 bytes
      if (cu <= 0x7F) {
        utf8Length += 1;
      } else if (cu <= 0x7FF) {
        utf8Length += 2;
      } else if (cu <= 0xFFFF) {
        utf8Length += 3;
      } else {
        utf8Length += 4;
      }
    }

    // ---------- SECOND PASS: write bytes ----------
    final out = List<int>.filled(utf8Length, 0);
    int o = 0;

    for (int i = 0; i < length; i++) {
      int cu = s.codeUnitAt(i);

      // Same surrogate logic (MUST EXACTLY match first pass)
      if (cu >= 0xD800 && cu <= 0xDBFF) {
        if (i + 1 < length) {
          int c2 = s.codeUnitAt(i + 1);
          if (c2 >= 0xDC00 && c2 <= 0xDFFF) {
            cu = 0x10000 + ((cu - 0xD800) << 10) + (c2 - 0xDC00);
            i++;
          } else {
            cu = 0xFFFD;
          }
        } else {
          cu = 0xFFFD;
        }
      } else if (cu >= 0xDC00 && cu <= 0xDFFF) {
        cu = 0xFFFD;
      }

      // Encode
      if (cu <= 0x7F) {
        out[o++] = cu;
      } else if (cu <= 0x7FF) {
        out[o++] = 0xC0 | (cu >> 6);
        out[o++] = 0x80 | (cu & 0x3F);
      } else if (cu <= 0xFFFF) {
        out[o++] = 0xE0 | (cu >> 12);
        out[o++] = 0x80 | ((cu >> 6) & 0x3F);
        out[o++] = 0x80 | (cu & 0x3F);
      } else {
        out[o++] = 0xF0 | (cu >> 18);
        out[o++] = 0x80 | ((cu >> 12) & 0x3F);
        out[o++] = 0x80 | ((cu >> 6) & 0x3F);
        out[o++] = 0x80 | (cu & 0x3F);
      }
    }

    return out;
  }
}

class ASCIIEncoder {
  static List<int> encode(String str) {
    final bytes = <int>[];
    for (int i = 0; i < str.length; i++) {
      int codeUnit = str.codeUnitAt(i);
      if (codeUnit <= 0x7F) {
        bytes.add(codeUnit);
      } else {
        throw ArgumentException.invalidOperationArguments(
          "encode",
          name: "str",
          reason: "Invalid ascii string. ${str[i]}",
        );
      }
    }
    return bytes;
  }
}
