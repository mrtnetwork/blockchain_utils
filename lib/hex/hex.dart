import 'package:blockchain_utils/utils/utils.dart';
import 'package:blockchain_utils/exception/exception.dart';

// ignore: library_private_types_in_public_api
const _Hex hex = _Hex();

class _Hex {
  const _Hex();
  static const _lookupTableLower = [
    '0',
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    'a',
    'b',
    'c',
    'd',
    'e',
    'f'
  ];
  static const _lookupTableUpper = [
    '0',
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    'A',
    'B',
    'C',
    'D',
    'E',
    'F'
  ];

// Invalid character used in decoding to indicate
// that the character to decode is out of range of
// the hex alphabet and cannot be decoded.
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

  /// Encode a bytes as a hex string.
  ///
  /// Input: data - the bytes to be encoded.
  ///        lowerCase - a flag indicating whether to use lowercase hexadecimal characters (default is true).
  /// Output: Returns a hex-encoded string.
  String encode(List<int> data, {bool lowerCase = true}) {
    BytesUtils.validateBytes(data, onError: "Invalid hex bytes");
    final table = lowerCase ? _lookupTableLower : _lookupTableUpper;
    final int length = data.length;
    final List<String> result = List<String>.filled(length * 2, '');
    for (int i = 0; i < length; i++) {
      final byte = data[i];
      result[i * 2] = table[byte >> 4];
      result[i * 2 + 1] = table[byte & 0x0F];
    }
    return result.join();
  }

  /// Decode a hex string into a bytes.
  ///
  /// Input: hex - the hex string to be decoded.
  /// Output: Returns a bytes with data decoded from the hex string.
  ///
  /// Throws an error if the hex string length is not divisible by 2 or contains non-hex characters.
  List<int> decode(String hex) {
    if (hex.isEmpty) {
      return List.empty();
    }
    if (!hex.length.isEven) {
      throw const ArgumentException(
          "Hex input string must be divisible by two");
    }
    final result = List<int>.filled(hex.length ~/ 2, 0);
    bool haveBad = false;
    for (int i = 0; i < hex.length; i += 2) {
      int v0 = _decodeNibble(hex.codeUnitAt(i));
      int v1 = _decodeNibble(hex.codeUnitAt(i + 1));
      result[i ~/ 2] = ((v0 << 4) | v1) & mask8;
      haveBad |= (v0 == _invalidHexNibble) | (v1 == _invalidHexNibble);
    }
    if (haveBad) {
      throw const ArgumentException("Incorrect characters for hex decoding");
    }
    return result;
  }
}
