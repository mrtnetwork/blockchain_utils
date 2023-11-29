// Copyright (C) 2016 Dmitry Chestnykh
// MIT License. See LICENSE file for details.

import 'package:blockchain_utils/binary/binary_operation.dart';
import 'package:blockchain_utils/exception/exception.dart';

// ignore: library_private_types_in_public_api
const _Hex hex = _Hex();

class _Hex {
  const _Hex();

  /// Encode a single nibble (4 bits) to a hexadecimal character.
  ///
  /// Input: b - an integer representing a nibble (0-15).
  /// Output: Returns a string with the hexadecimal representation of the nibble.
  String _encodeNibble(int b) {
    // b >= 0
    int result = b + 48;
    // b > 9
    result += ((9 - b) >> 8) & (-48 + 65 - 10);

    return String.fromCharCode(result);
  }

  /// Encode a single nibble (4 bits) to a lowercase hexadecimal character.
  ///
  /// Input: b - an integer representing a nibble (0-15).
  /// Output: Returns a string with the lowercase hexadecimal representation of the nibble.
  String _encodeNibbleLower(int b) {
    int result = b + 48;
    // b > 9
    result += ((9 - b) >> 8) & (-48 + 97 - 10);

    return String.fromCharCode(result);
  }

// Invalid character used in decoding to indicate
// that the character to decode is out of range of
// the hex alphabet and cannot be decoded.
  static const _invalidHexNibble = 256;

  /// Decode a hexadecimal character to its integer value.
  ///
  /// Input: c - an integer representing the ASCII code of the character.
  /// Output: Returns the integer value of the hexadecimal character, or INVALID_HEX_NIBBLE for invalid characters.
  int _decodeNibble(int c) {
    int result = _invalidHexNibble;

    result += (((47 - c) & (c - 58)) >> 8) & (-_invalidHexNibble + c - 48);
    // A-F: c > 64 and c < 71
    result += (((64 - c) & (c - 71)) >> 8) & (-_invalidHexNibble + c - 65 + 10);
    // a-f: c > 96 and c < 103
    result +=
        (((96 - c) & (c - 103)) >> 8) & (-_invalidHexNibble + c - 97 + 10);

    return result;
  }

  /// Encode a bytes as a hex string.
  ///
  /// Input: data - the bytes to be encoded.
  ///        lowerCase - a flag indicating whether to use lowercase hexadecimal characters (default is true).
  /// Output: Returns a hex-encoded string.
  String encode(List<int> data, [bool lowerCase = true]) {
    final enc = lowerCase ? _encodeNibbleLower : _encodeNibble;
    String s = "";
    for (int i = 0; i < data.length; i++) {
      final byte = data[i];
      if (byte < 0 || byte > mask8) {
        throw ArgumentException("invalid byte ${byte.abs().toRadixString(16)}");
      }
      s += enc(data[i] >> 4);
      s += enc(data[i] & 0x0F);
    }
    return s;
  }

  /// Decode a hex string into a Uint8Array.
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
    int haveBad = 0;
    for (int i = 0; i < hex.length; i += 2) {
      int v0 = _decodeNibble(hex.codeUnitAt(i));
      int v1 = _decodeNibble(hex.codeUnitAt(i + 1));
      result[i ~/ 2] = ((v0 << 4) | v1) & mask8;
      haveBad |= v0 & _invalidHexNibble;
      haveBad |= v1 & _invalidHexNibble;
    }
    if (haveBad != 0) {
      throw const ArgumentException("Incorrect characters for hex decoding");
    }
    return result;
  }
}
