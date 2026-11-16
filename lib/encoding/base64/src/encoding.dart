/// Base64 encoding (RFC 4648), with optional URL-safe alphabet and
/// optional padding.
///
/// Single-pass, single-allocation implementation: output length is
/// computed exactly up front, so there's exactly one `List<int>` (of char
/// codes) allocated for the whole call - no per-3-byte-group buffers, no
/// list shifting, no post-hoc string surgery for the urlSafe/noPadding
/// options (both are handled by picking the right alphabet and output
/// length before the loop even starts, not by scanning/rewriting the
/// string afterward).
library;

class B64Encoder {
  // Char-code lists instead of the raw Strings for the hot loop below -
  // plain list indexing, no per-character UTF-16 handling.
  static const List<int> standardCodes = [
    65,
    66,
    67,
    68,
    69,
    70,
    71,
    72,
    73,
    74,
    75,
    76,
    77,
    78,
    79,
    80,
    81,
    82,
    83,
    84,
    85,
    86,
    87,
    88,
    89,
    90,
    97,
    98,
    99,
    100,
    101,
    102,
    103,
    104,
    105,
    106,
    107,
    108,
    109,
    110,
    111,
    112,
    113,
    114,
    115,
    116,
    117,
    118,
    119,
    120,
    121,
    122,
    48,
    49,
    50,
    51,
    52,
    53,
    54,
    55,
    56,
    57,
    43,
    47,
  ];
  static const List<int> urlSafeCodes = [
    65,
    66,
    67,
    68,
    69,
    70,
    71,
    72,
    73,
    74,
    75,
    76,
    77,
    78,
    79,
    80,
    81,
    82,
    83,
    84,
    85,
    86,
    87,
    88,
    89,
    90,
    97,
    98,
    99,
    100,
    101,
    102,
    103,
    104,
    105,
    106,
    107,
    108,
    109,
    110,
    111,
    112,
    113,
    114,
    115,
    116,
    117,
    118,
    119,
    120,
    121,
    122,
    48,
    49,
    50,
    51,
    52,
    53,
    54,
    55,
    56,
    57,
    45,
    95,
  ];

  static const int _equalsCode = 0x3D; // '='

  /// Encodes [data] to a Base64 string.
  ///
  /// [noPadding]: if true, omits the trailing `=` padding.
  /// [urlSafe]: if true, uses `-`/`_` in place of `+`/`/`.
  static String encode(
    List<int> data, {
    bool noPadding = false,
    bool urlSafe = false,
  }) {
    if (data.isEmpty) return '';

    final table = urlSafe ? urlSafeCodes : standardCodes;
    final fullGroups = data.length ~/ 3;
    final remainder = data.length % 3; // 0, 1, or 2 leftover bytes

    final outLen =
        noPadding
            ? fullGroups * 4 + (remainder == 0 ? 0 : remainder + 1)
            : (fullGroups + (remainder == 0 ? 0 : 1)) * 4;

    final out = List<int>.filled(outLen, 0);
    var o = 0;
    var i = 0;
    final fullEnd = fullGroups * 3;

    while (i < fullEnd) {
      final chunk =
          ((data[i] & 0xFF) << 16) |
          ((data[i + 1] & 0xFF) << 8) |
          (data[i + 2] & 0xFF);
      out[o++] = table[(chunk >> 18) & 0x3F];
      out[o++] = table[(chunk >> 12) & 0x3F];
      out[o++] = table[(chunk >> 6) & 0x3F];
      out[o++] = table[chunk & 0x3F];
      i += 3;
    }

    if (remainder == 1) {
      final chunk = (data[i] & 0xFF) << 16;
      out[o++] = table[(chunk >> 18) & 0x3F];
      out[o++] = table[(chunk >> 12) & 0x3F];
      if (!noPadding) {
        out[o++] = _equalsCode;
        out[o++] = _equalsCode;
      }
    } else if (remainder == 2) {
      final chunk = ((data[i] & 0xFF) << 16) | ((data[i + 1] & 0xFF) << 8);
      out[o++] = table[(chunk >> 18) & 0x3F];
      out[o++] = table[(chunk >> 12) & 0x3F];
      out[o++] = table[(chunk >> 6) & 0x3F];
      if (!noPadding) {
        out[o++] = _equalsCode;
      }
    }

    return String.fromCharCodes(out);
  }
}
