// The MIT License (MIT)

// Copyright (c) 2021 Emanuele Bellocchia
// Copyright (c) 2023 Mohsen Haydari (MRTNETWORK)

// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
// of the Software, and to permit persons to whom the Software is furnished to do so,
// subject to the following conditions:

// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS," WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
// INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
// PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
// FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
// ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
// Note: This code has been adapted from its original Python version to Dart.

import 'package:blockchain_utils/helper/helper.dart';

import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/utils/binary/binary_operation.dart';
import 'package:blockchain_utils/utils/string/string.dart';

/// Constants and data structures used for Base32 encoding and decoding.
class _Base32Const {
  /// Base32 alphabet for encoding and decoding.
  static const String alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';

  /// Padding character used for Base32 encoding.
  static const String paddingChar = '=';
}

class _Base32Utils {
  /// Add padding to an encoded Base32 string.
  /// Used if the string was encoded with Base32Encoder.encodeNoPadding.
  static String addPadding(String data) {
    final lastBlockWidth = data.length % 8;
    if (lastBlockWidth != 0) {
      data += '=' * (8 - lastBlockWidth);
    }
    return data;
  }

  /// Translate the standard Base32 alphabet to a custom one.
  static String translateAlphabet(
    String data,
    String fromAlphabet,
    String toAlphabet,
  ) {
    final translationMap = Map<String, String>.fromIterable(
      fromAlphabet.codeUnits,
      key: (unit) => String.fromCharCode(unit),
      value: (unit) {
        final index = fromAlphabet.indexOf(String.fromCharCode(unit));
        return toAlphabet[index];
      },
    );

    final translatedData = data
        .split('')
        .map((char) {
          return translationMap[char] ?? char;
        })
        .join('');

    return translatedData;
  }

  static List<int> _b32decode(String alphabet, String base32) {
    Map<String, int> rev = {};
    for (var i = 0; i < alphabet.length; i++) {
      rev[alphabet[i]] = i;
    }
    int shift = 8;
    int carry = 0;
    final List<int> decoded = [];
    base32.split('').forEach((char) {
      if (char == '=') {
        return;
      }
      final symbol = (rev[char] ?? 0) & BinaryOps.mask8;
      shift -= 5;
      if (shift > 0) {
        carry |= (symbol << shift) & BinaryOps.mask8;
      } else if (shift < 0) {
        decoded.add(carry | (symbol >> -shift));
        shift += 8;
        carry = (symbol << shift) & BinaryOps.mask8;
      } else {
        decoded.add(carry | symbol);
        shift = 8;
        carry = 0;
      }
    });
    if (shift != 8 && carry != 0) {
      decoded.add(carry);
      shift = 8;
      carry = 0;
    }

    return decoded;
  }

  static List<int> _b32encode(String alphabet, List<int> s) {
    final leftover = s.length % 5;
    if (leftover != 0) {
      s = [...s, ...List.filled(5 - leftover, 0)];
    }
    int shift = 3;
    int carry = 0;
    final encoded = <int>[];
    for (final byte in s) {
      int symbol = carry | (byte >> shift);
      encoded.addAll(alphabet[symbol & 0x1f].codeUnits);
      if (shift > 5) {
        shift -= 5;
        symbol = byte >> shift;
        encoded.addAll(alphabet[symbol & 0x1f].codeUnits);
      }
      shift = 5 - shift;
      carry = byte << shift;
      shift = 8 - shift;
    }
    if (shift != 3) {
      encoded.addAll(alphabet[carry & 0x1f].codeUnits);
      shift = 3;
      carry = 0;
    }
    if (leftover == 1) {
      encoded.setAll(encoded.length - 6, [0x3d, 0x3d, 0x3d, 0x3d, 0x3d, 0x3d]);
    } else if (leftover == 2) {
      encoded.setAll(encoded.length - 4, [0x3d, 0x3d, 0x3d, 0x3d]);
    } else if (leftover == 3) {
      encoded.setAll(encoded.length - 3, [0x3d, 0x3d, 0x3d]);
    } else if (leftover == 4) {
      encoded.setAll(encoded.length - 1, [0x3d]);
    }
    return encoded;
  }
}

/// A utility class for decoding Base32 encoded strings into bytes.
class Base32Decoder {
  /// Decode the provided Base32 string into a List of bytes.
  /// Optionally, you can specify a custom alphabet for decoding.
  static List<int> decode(String data, [String? customAlphabet]) {
    try {
      /// Add padding characters to the input data as needed.
      data = _Base32Utils.addPadding(data);

      /// If a custom alphabet is specified, translate the input data to the standard Base32 alphabet.
      if (customAlphabet != null) {
        data = _Base32Utils.translateAlphabet(
          data,
          customAlphabet,
          _Base32Const.alphabet,
        );
      }

      /// Decode the Base32 string and obtain the decoded bytes.
      return _Base32Utils._b32decode(_Base32Const.alphabet, data);
    } catch (_) {
      /// Handle exceptions by throwing an error for invalid Base32 strings.
      throw ArgumentException.invalidOperationArguments(
        "decode",
        name: "data",
        reason: 'Invalid Base32 string',
      );
    }
  }
}

/// A utility class for encoding strings and bytes into Base32 format.
class Base32Encoder {
  /// Encode the provided string into a Base32 encoded string.
  /// Optionally, you can specify a custom alphabet for encoding.
  static String encode(String data, [String? customAlphabet]) {
    /// Convert the input string to UTF-8 encoded bytes and then encode it in Base32.
    String encoded = StringUtils.decode(
      _Base32Utils._b32encode(_Base32Const.alphabet, StringUtils.encode(data)),
    );

    /// If a custom alphabet is specified, translate the encoded string to the custom alphabet.
    if (customAlphabet != null) {
      encoded = _Base32Utils.translateAlphabet(
        encoded,
        _Base32Const.alphabet,
        customAlphabet,
      );
    }

    /// Return the Base32 encoded string.
    return encoded;
  }

  /// Encode the provided List of bytes into a Base32 encoded string.
  /// Optionally, you can specify a custom alphabet for encoding.
  static String encodeBytes(List<int> data, [String? customAlphabet]) {
    data = data.asImmutableBytes;

    /// Encode the input bytes in Base32.
    String encoded = StringUtils.decode(
      _Base32Utils._b32encode(_Base32Const.alphabet, data),
    );

    /// If a custom alphabet is specified, translate the encoded string to the custom alphabet.
    if (customAlphabet != null) {
      encoded = _Base32Utils.translateAlphabet(
        encoded,
        _Base32Const.alphabet,
        customAlphabet,
      );
    }

    /// Return the Base32 encoded string.
    return encoded;
  }

  /// Encode the provided string into a Base32 encoded string without padding characters.
  /// Optionally, you can specify a custom alphabet for encoding.
  static String encodeNoPadding(String data, [String? customAlphabet]) {
    // Encode the input data and then remove any padding characters.
    return encode(
      data,
      customAlphabet,
    ).replaceAll(_Base32Const.paddingChar, '');
  }

  /// Encode the provided List of bytes into a Base32 encoded string without padding characters.
  /// Optionally, you can specify a custom alphabet for encoding.
  static String encodeNoPaddingBytes(List<int> data, [String? customAlphabet]) {
    /// Encode the input bytes and then remove any padding characters.
    return encodeBytes(
      data,
      customAlphabet,
    ).replaceAll(_Base32Const.paddingChar, '');
  }
}
