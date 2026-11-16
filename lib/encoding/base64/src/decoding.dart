/// Base64 decoding (RFC 4648), with optional URL-safe alphabet handling
/// and optional padding validation.
///
/// Single-pass, single-allocation implementation. The character->value
/// reverse-lookup table is built exactly once (a `static final`, computed
/// on first use and cached forever after) rather than being rebuilt for
/// every group of input characters, and the whole input is decoded in one
/// pass into a single pre-sized output list - no repeated substring
/// slicing, no list-shifting.
library;

import 'package:blockchain_utils/helper/extensions/extensions.dart';

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

class B64Decoder {
  static const int _equalsCode = 0x3D; // '='

  /// Maps an ASCII code unit to its Base64 value (0..63), or -1 if it
  /// isn't a Base64 character. Sized to 128 (not 256) since every valid
  /// Base64 character is ASCII - this also means any code unit >= 128
  /// (e.g. genuine multi-byte Unicode) is rejected by a simple range
  /// check up front, rather than risking an out-of-range list access.
  /// Built once and reused for every decode() call.
  static const List<int> reverseTable = [
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    62,
    -1,
    62,
    -1,
    63,
    52,
    53,
    54,
    55,
    56,
    57,
    58,
    59,
    60,
    61,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    0,
    1,
    2,
    3,
    4,
    5,
    6,
    7,
    8,
    9,
    10,
    11,
    12,
    13,
    14,
    15,
    16,
    17,
    18,
    19,
    20,
    21,
    22,
    23,
    24,
    25,
    -1,
    -1,
    -1,
    -1,
    63,
    -1,
    26,
    27,
    28,
    29,
    30,
    31,
    32,
    33,
    34,
    35,
    36,
    37,
    38,
    39,
    40,
    41,
    42,
    43,
    44,
    45,
    46,
    47,
    48,
    49,
    50,
    51,
    -1,
    -1,
    -1,
    -1,
    -1,
  ];

  static int _valueAt(String data, int index) {
    final code = data.codeUnitAt(index);
    final value = code < 128 ? reverseTable[code] : -1;
    if (value == -1) {
      throw BuError(DefaultErrorType.badBase64, "Invalid Base64 string.",
        details: {"reason": 'Invalid Base64 character at index $index.'},
      );
    }
    return value;
  }

  /// Decodes the [normalized] string - already whitespace-stripped and a
  /// multiple of 4 in length (padded with '=' if necessary) by the caller.
  static BuBytes _decode(String normalized) {
    var len = normalized.length;
    if (len == 0) return BuBytes.empty();

    // Trailing '=' padding (0, 1, or 2 characters) carries no data.
    while (len > 0 && normalized.codeUnitAt(len - 1) == _equalsCode) {
      len--;
    }

    final fullGroups = len ~/ 4;
    final remainder =
        len % 4; // 0, 2, or 3 - a lone leftover char (1) is invalid

    if (remainder == 1) {
      throw const BuError(DefaultErrorType.invalidLength, "Invalid Base64 string.",
        details: {"reason": 'Truncated Base64 group.'},
      );
    }

    final outLen = fullGroups * 3 + (remainder == 0 ? 0 : remainder - 1);
    final out = BuBytes.zero(outLen);

    var o = 0;
    var i = 0;
    final fullEnd = fullGroups * 4;
    while (i < fullEnd) {
      final chunk =
          (_valueAt(normalized, i) << 18) |
          (_valueAt(normalized, i + 1) << 12) |
          (_valueAt(normalized, i + 2) << 6) |
          _valueAt(normalized, i + 3);
      out[o++] = (chunk >> 16) & 0xFF;
      out[o++] = (chunk >> 8) & 0xFF;
      out[o++] = chunk & 0xFF;
      i += 4;
    }

    if (remainder == 2) {
      final chunk =
          (_valueAt(normalized, i) << 18) | (_valueAt(normalized, i + 1) << 12);
      out[o++] = (chunk >> 16) & 0xFF;
    } else if (remainder == 3) {
      final chunk =
          (_valueAt(normalized, i) << 18) |
          (_valueAt(normalized, i + 1) << 12) |
          (_valueAt(normalized, i + 2) << 6);
      out[o++] = (chunk >> 16) & 0xFF;
      out[o++] = (chunk >> 8) & 0xFF;
    }

    return out;
  }

  /// Decodes a Base64 [data] string into bytes.
  ///
  /// [validatePadding]: if true (default), requires input length to
  /// already be a multiple of 4. If false, '=' padding is added
  /// automatically to fix the length.
  ///
  /// [urlSafe]: if true (default), treats input as URL-safe Base64,
  /// accepting `-`/`_` in place of `+`/`/`. If false, throws if URL-safe
  /// characters are present.
  ///
  /// Throws [B64ConverterException] on invalid input or length.
  static BuBytes decode(
    String data, {
    bool validatePadding = true,
    bool urlSafe = true,
  }) {
    return decodeWithInfo(
      data,
      validatePadding: validatePadding,
      urlSafe: urlSafe,
    ).data;
  }

  static B64DecodingInfo decodeWithInfo(
    String data, {
    bool validatePadding = true,
    bool urlSafe = true,
  }) {
    // Strip embedded newlines *before* measuring length, so line-wrapped
    // input doesn't throw off the padding/length checks below (the
    // original checked length first, so a line-wrapped-but-otherwise-valid
    // string could fail padding validation purely because of newlines).
    if (data.contains('\n') || data.contains('\r')) {
      data = data.replaceAll('\n', '').replaceAll('\r', '');
    }

    final isPadded = data.length % 4 == 0;
    final isUrlSafeInput = data.contains('-') || data.contains('_');
    if (isUrlSafeInput && !urlSafe) {
      throw const BuError(DefaultErrorType.badBase64, "Invalid Base64 string.");
    }

    if (validatePadding) {
      if (!isPadded) throw const BuError(DefaultErrorType.badBase64, "Invalid Base64 string.");
    } else if (!isPadded) {
      final missing = (4 - data.length % 4) % 4;
      data = data.padRight(data.length + missing, '=');
    }

    return B64DecodingInfo(
      isUrlSafe: isUrlSafeInput,
      isPadded: isPadded,
      data: _decode(data),
    );
  }

  /// Tries to decode a Base64 string, returning null if decoding fails.
  ///
  /// Same parameters as [decode], but catches exceptions and returns null
  /// on error.
  static BuBytes? tryDecode(
    String data, {
    bool validatePadding = true,
    bool urlSafe = true,
  }) {
    try {
      return decode(data, urlSafe: urlSafe, validatePadding: validatePadding);
    } catch (_) {
      return null;
    }
  }
}

class B64DecodingInfo {
  final bool isUrlSafe;
  final bool isPadded;
  final BuBytes data;
  B64DecodingInfo({
    required this.isUrlSafe,
    required this.isPadded,
    required List<int> data,
  }) : data = data.asImmutableBytes;
}
