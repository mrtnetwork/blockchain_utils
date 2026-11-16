/// RFC 4648 Base32 encoding/decoding.
///
/// Independent implementation: bytes are pushed through a running bit
/// accumulator and drained 5 bits at a time (encode) or 8 bits at a time
/// (decode) - the standard technique for any base-2^n encoding, not tied
/// to any particular codebase's implementation.
library;

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';
import 'package:blockchain_utils/utils/string/string.dart';


class Base32Alphabet {
  static const String cidBase32Alphabet = 'abcdefghijklmnopqrstuvwxyz234567';
  static const String standardAlphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
}

const String _paddingChar = '=';
const int _bitsPerChar = 5;
const int _bitsPerByte = 8;

void _checkAlphabet(String alphabet) {
  if (alphabet.length != 32) {
    throw BuError(DefaultErrorType.invalidLength, "Invalid Base32 string.",
      details: {
        "reason":
            "Base32 alphabet must be exactly 32 characters, got ${alphabet.length}.",
      },
    );
  }
}

Map<String, int> _reverseLookup(String alphabet) {
  final map = <String, int>{};
  for (var i = 0; i < alphabet.length; i++) {
    map[alphabet[i]] = i;
  }
  return map;
}

/// Encodes [bytes] with [alphabet], no padding applied.
String _encodeRaw(List<int> bytes, String alphabet) {
  if (bytes.isEmpty) return '';
  final out = StringBuffer();
  var bitBuffer = 0;
  var bitCount = 0;
  for (final byte in bytes) {
    bitBuffer = (bitBuffer << _bitsPerByte) | (byte & 0xFF);
    bitCount += _bitsPerByte;
    while (bitCount >= _bitsPerChar) {
      bitCount -= _bitsPerChar;
      out.write(alphabet[(bitBuffer >> bitCount) & 0x1F]);
    }
  }
  if (bitCount > 0) {
    // Left-pad the leftover bits with zeros to fill out one more char.
    out.write(alphabet[(bitBuffer << (_bitsPerChar - bitCount)) & 0x1F]);
  }
  return out.toString();
}

String _addPadding(String data) {
  final remainder = data.length % 8;
  if (remainder == 0) return data;
  return data + (_paddingChar * (8 - remainder));
}

BuBytes _decodeRaw(String input, String alphabet) {
  final reverse = _reverseLookup(alphabet);

  // Locate where padding starts (if any), and make sure everything from
  // that point on actually is padding.
  var dataLen = input.length;
  for (var i = 0; i < input.length; i++) {
    if (input[i] == _paddingChar) {
      dataLen = i;
      break;
    }
  }
  for (var i = dataLen; i < input.length; i++) {
    if (input[i] != _paddingChar) {
      throw BuError(DefaultErrorType.badBase32, "Invalid Base32 string.",
        details: {
          "reason":
              'Unexpected character "${input[i]}" after padding at index $i.',
        },
      );
    }
  }

  // RFC 4648: a group's data-char count must be one of these -
  // anything else can't represent a whole number of bytes canonically.
  const validGroupRemainders = {0, 2, 4, 5, 7};
  if (!validGroupRemainders.contains(dataLen % 8)) {
    throw BuError(DefaultErrorType.invalidLength, "Invalid Base32 string.",
      details: {
        "reason":
            'Invalid Base32 length: $dataLen data character(s) does not form a valid group.',
      },
    );
  }

  final out = <int>[];
  var bitBuffer = 0;
  var bitCount = 0;
  for (var i = 0; i < dataLen; i++) {
    final char = input[i];
    final value = reverse[char];
    if (value == null) {
      throw BuError(DefaultErrorType.badBase32, "Invalid Base32 string.",
        details: {"reason": 'Invalid Base32 character "$char" at index $i.'},
      );
    }
    bitBuffer = (bitBuffer << _bitsPerChar) | value;
    bitCount += _bitsPerChar;
    if (bitCount >= _bitsPerByte) {
      bitCount -= _bitsPerByte;
      out.add((bitBuffer >> bitCount) & 0xFF);
    }
  }

  // Canonical check: any leftover bits (from the final, partial char group)
  // must be zero. Nonzero here means the input wasn't produced by a
  // canonical encoder and shouldn't silently round-trip to a "valid" value.
  if (bitCount > 0) {
    final leftoverMask = (1 << bitCount) - 1;
    if ((bitBuffer & leftoverMask) != 0) {
      throw BuError(DefaultErrorType.badBase32, "Invalid Base32 string.",
        details: {
          "reason": "Non-canonical Base32 encoding: nonzero padding bits.",
        },
      );
    }
  }

  return BuBytes(out);
}
// ---------------------------------------------------------------------------
// Public API - same class/method names and signatures as before
// ---------------------------------------------------------------------------

/// A utility class for decoding Base32 encoded strings into bytes.
class Base32Decoder {
  /// Decode the provided Base32 string into a List of bytes.
  /// Optionally, you can specify a custom alphabet for decoding.
  static BuBytes decode(String data, [String? customAlphabet]) {
    final alphabet = customAlphabet ?? Base32Alphabet.standardAlphabet;
    _checkAlphabet(alphabet);
    return _decodeRaw(data, alphabet);
  }
}

/// A utility class for encoding strings and bytes into Base32 format.
class Base32Encoder {
  /// Encode the provided string into a Base32 encoded string.
  /// Optionally, you can specify a custom alphabet for encoding.
  static String encode(String data, [String? customAlphabet]) {
    return encodeBytes(StringUtils.encode(data), customAlphabet);
  }

  /// Encode the provided List of bytes into a Base32 encoded string.
  /// Optionally, you can specify a custom alphabet for encoding.
  static String encodeBytes(List<int> data, [String? customAlphabet]) {
    final alphabet = customAlphabet ?? Base32Alphabet.standardAlphabet;
    _checkAlphabet(alphabet);
    return _addPadding(_encodeRaw(data, alphabet));
  }

  /// Encode the provided string into a Base32 encoded string without padding characters.
  /// Optionally, you can specify a custom alphabet for encoding.
  static String encodeNoPadding(String data, [String? customAlphabet]) {
    return encodeNoPaddingBytes(StringUtils.encode(data), customAlphabet);
  }

  /// Encode the provided List of bytes into a Base32 encoded string without padding characters.
  /// Optionally, you can specify a custom alphabet for encoding.
  static String encodeNoPaddingBytes(List<int> data, [String? customAlphabet]) {
    final alphabet = customAlphabet ?? Base32Alphabet.standardAlphabet;
    _checkAlphabet(alphabet);
    return _encodeRaw(data, alphabet);
  }
}
