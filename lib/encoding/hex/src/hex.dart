/// Hex encoding/decoding. `hex` is a single const instance (not static
/// methods on a class) so call sites read as `hex.encode(...)` /
/// `hex.decode(...)` - kept as-is.
library;

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';


const HexCodec hex = HexCodec();

class HexCodec {
  const HexCodec();

  // Char *codes* (not Strings) for each hex digit, 0..15 - encode writes
  // directly into a List<int> and finishes with String.fromCharCodes,
  // rather than building a List<String> of one-character Strings and
  // .join()-ing them (each entry here used to be its own String object).
  static const List<int> _lowerCodes = [
    0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, // 0-7
    0x38, 0x39, 0x61, 0x62, 0x63, 0x64, 0x65, 0x66, // 8-9, a-f
  ];
  static const List<int> _upperCodes = [
    0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, // 0-7
    0x38, 0x39, 0x41, 0x42, 0x43, 0x44, 0x45, 0x46, // 8-9, A-F
  ];

  // Invalid character used in decoding to indicate that the character to
  // decode is out of range of the hex alphabet and cannot be decoded.
  static const _invalidHexNibble = 256;

  static const List<int> _nibbleLookupTable = [
    256, 256, 256, 256, 256, 256, 256, 256, 256, 256, 256, 256, 256, 256, 256,
    256, // 0-15
    256, 256, 256, 256, 256, 256, 256, 256, 256, 256, 256, 256, 256, 256, 256,
    256, // 16-31
    256, 256, 256, 256, 256, 256, 256, 256, 256, 256, 256, 256, 256, 256, 256,
    256, // 32-47
    0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 256, 256, 256, 256, 256, 256, // 48-63 (0-9)
    256, 10, 11, 12, 13, 14, 15, 256, 256, 256, 256, 256, 256, 256, 256,
    256, // 64-79 (A-F)
    256, 256, 256, 256, 256, 256, 256, 256, 256, 256, 256, 256, 256, 256, 256,
    256, // 80-95
    256, 10, 11, 12, 13, 14, 15, 256, 256, 256, 256, 256, 256, 256, 256,
    256, // 96-111 (a-f)
    256, 256, 256, 256, 256, 256, 256, 256, 256, 256, 256, 256, 256, 256, 256,
    256, // 112-127
    // the rest are all 256 by default
  ];

  int _decodeNibble(int charCode) {
    return charCode < 128 ? _nibbleLookupTable[charCode] : _invalidHexNibble;
  }

  /// Encodes [data] as a hex string.
  ///
  /// [lowerCase]: whether to use lowercase hex digits (default) or
  /// uppercase.
  ///
  /// Throws [HexFormatError] if any byte in [data] is outside 0..255.
  String encode(List<int> data, {bool lowerCase = true}) {
    final table = lowerCase ? _lowerCodes : _upperCodes;
    final length = data.length;
    final result = List<int>.filled(length * 2, 0);
    for (var i = 0; i < length; i++) {
      final byte = data[i];
      if (byte < 0 || byte > 0xFF) {
        throw BuError(DefaultErrorType.invalidArgument,
          'Invalid bytes.',
          details: {'reason': 'byte value $byte at index $i is outside 0..255'},
        );
      }
      result[i * 2] = table[byte >> 4];
      result[i * 2 + 1] = table[byte & 0x0F];
    }
    return String.fromCharCodes(result);
  }

  /// Decodes [hexStr] into bytes.
  ///
  /// Throws [HexFormatError] if [hexStr] has an odd length or contains a
  /// non-hex character.
  BuBytes decode(String hexStr) {
    if (hexStr.isEmpty) return BuBytes.empty();
    if (!hexStr.length.isEven) {
      throw BuError(DefaultErrorType.invalidLength,
        'Invalid hex string.',
        details: {'reason': 'odd length (${hexStr.length})'},
      );
    }

    final result = BuBytes.fill(hexStr.length ~/ 2, 0);
    // Tracks the first bad character's index without bailing out early -
    // keeps the loop branch-light (same trick the original used, just
    // extended to remember *where* rather than only *whether*), so a
    // caller gets a specific, actionable error instead of a generic one.
    var firstBadIndex = -1;
    for (var i = 0; i < hexStr.length; i += 2) {
      final v0 = _decodeNibble(hexStr.codeUnitAt(i));
      final v1 = _decodeNibble(hexStr.codeUnitAt(i + 1));
      result[i ~/ 2] = ((v0 << 4) | v1) & 0xFF;
      if (firstBadIndex == -1 &&
          (v0 == _invalidHexNibble || v1 == _invalidHexNibble)) {
        firstBadIndex = v0 == _invalidHexNibble ? i : i + 1;
      }
    }

    if (firstBadIndex != -1) {
      throw BuError(DefaultErrorType.badHex,
        'Invalid hex string.',
        details: {
          'reason':
              'invalid character "${hexStr[firstBadIndex]}" at index $firstBadIndex',
        },
      );
    }
    return result;
  }

  /// Like [decode], but returns null instead of throwing on invalid input.
  BuBytes? tryDecode(String hexStr) {
    try {
      return decode(hexStr);
    } catch (_) {
      return null;
    }
  }

  /// Like [encode], but returns null instead of throwing on invalid input.
  String? tryEncode(List<int> data, {bool lowerCase = true}) {
    try {
      return encode(data, lowerCase: lowerCase);
    } catch (_) {
      return null;
    }
  }
}
