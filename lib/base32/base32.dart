/*
  The MIT License (MIT)
  
  Copyright (c) 2021 Emanuele Bellocchia

  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
  of the Software, and to permit persons to whom the Software is furnished to do so,
  subject to the following conditions:

  The above copyright notice and this permission notice shall be included in all
  copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS," WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
  INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
  PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
  FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
  ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
  
  Note: This code has been adapted from its original Python version to Dart.
*/

/*
  The 3-Clause BSD License
  
  Copyright (c) 2023 Mohsen Haydari (MRTNETWORK)
  All rights reserved.
  
  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions are met:
  
  1. Redistributions of source code must retain the above copyright notice, this
     list of conditions, and the following disclaimer.
  2. Redistributions in binary form must reproduce the above copyright notice, this
     list of conditions, and the following disclaimer in the documentation and/or
     other materials provided with the distribution.
  3. Neither the name of the [organization] nor the names of its contributors may be
     used to endorse or promote products derived from this software without
     specific prior written permission.
  
  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
  IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
  INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
  BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
  OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
  OF THE POSSIBILITY OF SUCH DAMAGE.
*/

import 'package:blockchain_utils/utils/utils.dart';
import 'package:blockchain_utils/exception/exception.dart';

/// Constants and data structures used for Base32 encoding and decoding.
class _Base32Const {
  /// Base32 alphabet for encoding and decoding.
  static const String alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';

  /// Padding character used for Base32 encoding.
  static const String paddingChar = '=';

  /// Internal data structures used for Base32 encoding and decoding.
  // static final Map<String, dynamic> _b32tab2 = {};

  /// Reverse mapping for Base32 decoding.
  static final Map<String, Map<String, int>> _b32rev = {}; // (private)
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
      String data, String fromAlphabet, String toAlphabet) {
    final translationMap = Map<String, String>.fromIterable(
      fromAlphabet.codeUnits,
      key: (unit) => String.fromCharCode(unit),
      value: (unit) {
        final index = fromAlphabet.indexOf(String.fromCharCode(unit));
        return toAlphabet[index];
      },
    );

    final translatedData = data.split('').map((char) {
      return translationMap[char] ?? char;
    }).join('');

    return translatedData;
  }

  static List<int> _b32decode(
    String alphabet,
    String base32,
  ) {
    if (!_Base32Const._b32rev.containsKey(alphabet)) {
      _Base32Const._b32rev[alphabet] = {};
      for (var i = 0; i < alphabet.length; i++) {
        _Base32Const._b32rev[alphabet]![alphabet[i]] = i;
      }
    }
    int shift = 8;
    int carry = 0;
    List<int> decoded = [];
    base32.split('').forEach((char) {
      if (char == '=') {
        return;
      }
      final symbol = (_Base32Const._b32rev[alphabet]![char] ?? 0) & 0xff;
      shift -= 5;
      if (shift > 0) {
        carry |= (symbol << shift) & 0xff;
      } else if (shift < 0) {
        decoded.add(carry | (symbol >> -shift));
        shift += 8;
        carry = (symbol << shift) & 0xff;
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
      final padding = List.filled(5 - leftover, 0);
      s = List<int>.from([...s, ...padding]);
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
    return List<int>.from(encoded);
  }
}

/// A utility class for decoding Base32 encoded strings into bytes.
class Base32Decoder {
  /// Decode the provided Base32 string into a List<int> of bytes.
  /// Optionally, you can specify a custom alphabet for decoding.
  static List<int> decode(String data, [String? customAlphabet]) {
    try {
      /// Add padding characters to the input data as needed.
      data = _Base32Utils.addPadding(data);

      /// If a custom alphabet is specified, translate the input data to the standard Base32 alphabet.
      if (customAlphabet != null) {
        data = _Base32Utils.translateAlphabet(
            data, customAlphabet, _Base32Const.alphabet);
      }

      /// Decode the Base32 string and obtain the decoded bytes.
      final decodedBytes = _Base32Utils._b32decode(_Base32Const.alphabet, data);

      /// Return the decoded bytes as a List<int>.
      return List<int>.from(decodedBytes);
    } catch (ex) {
      /// Handle exceptions by throwing an error for invalid Base32 strings.
      throw const ArgumentException('Invalid Base32 string');
    }
  }
}

/// A utility class for encoding strings and bytes into Base32 format.
class Base32Encoder {
  /// Encode the provided string into a Base32 encoded string.
  /// Optionally, you can specify a custom alphabet for encoding.
  static String encode(String data, [String? customAlphabet]) {
    /// Convert the input string to UTF-8 encoded bytes and then encode it in Base32.
    String encoded = StringUtils.decode(_Base32Utils._b32encode(
        _Base32Const.alphabet, StringUtils.encode(data)));

    /// If a custom alphabet is specified, translate the encoded string to the custom alphabet.
    if (customAlphabet != null) {
      encoded = _Base32Utils.translateAlphabet(
          encoded, _Base32Const.alphabet, customAlphabet);
    }

    /// Return the Base32 encoded string.
    return encoded;
  }

  /// Encode the provided List<int> of bytes into a Base32 encoded string.
  /// Optionally, you can specify a custom alphabet for encoding.
  static String encodeBytes(List<int> data, [String? customAlphabet]) {
    /// Encode the input bytes in Base32.
    String encoded = StringUtils.decode(
        _Base32Utils._b32encode(_Base32Const.alphabet, data));

    /// If a custom alphabet is specified, translate the encoded string to the custom alphabet.
    if (customAlphabet != null) {
      encoded = _Base32Utils.translateAlphabet(
          encoded, _Base32Const.alphabet, customAlphabet);
    }

    /// Return the Base32 encoded string.
    return encoded;
  }

  /// Encode the provided string into a Base32 encoded string without padding characters.
  /// Optionally, you can specify a custom alphabet for encoding.
  static String encodeNoPadding(String data, [String? customAlphabet]) {
    // Encode the input data and then remove any padding characters.
    return encode(data, customAlphabet)
        .replaceAll(_Base32Const.paddingChar, '');
  }

  /// Encode the provided List<int> of bytes into a Base32 encoded string without padding characters.
  /// Optionally, you can specify a custom alphabet for encoding.
  static String encodeNoPaddingBytes(List<int> data, [String? customAlphabet]) {
    /// Encode the input bytes and then remove any padding characters.
    return encodeBytes(data, customAlphabet)
        .replaceAll(_Base32Const.paddingChar, '');
  }
}
