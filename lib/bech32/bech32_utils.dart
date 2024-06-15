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

import 'package:blockchain_utils/bech32/bech32_ex.dart';
import 'package:blockchain_utils/exception/exception.dart';
import 'package:blockchain_utils/utils/utils.dart';

/// A utility class containing constants for Bech32 encoding and decoding.
class Bech32BaseConst {
  /// The character set used for Bech32 encoding and decoding.
  static const String charset = "qpzry9x8gf2tvdw0s3jn54khce6mua7l";
}

/// A utility class containing methods for converting data to and from bech32 encoding.
class Bech32BaseUtils {
  /// Converts the input data to base32 encoding.
  ///
  /// Parameters:
  /// - data: The input data to be converted to base32.
  ///
  /// Returns:
  /// A List<int> containing the data in base32 encoding.
  ///
  /// Throws:
  /// - ArgumentException: If the data cannot be converted to base32.
  static List<int> convertToBase32(List<int> data) {
    List<int>? convData = _convertBits(data, 8, 5);
    if (convData == null) {
      throw const ArgumentException(
          'Invalid data, cannot perform conversion to base32');
    }

    return convData;
  }

  /// Converts the input data from base32 encoding.
  ///
  /// Parameters:
  /// - data: A List of integers representing the data in base32 encoding.
  ///
  /// Returns:
  /// A List<int> containing the data converted from base32 encoding.
  ///
  /// Throws:
  /// - ArgumentException: If the data cannot be converted from base32.
  static List<int> convertFromBase32(List<int> data) {
    List<int>? convData = _convertBits(data, 5, 8, pad: false);
    if (convData == null) {
      throw const ArgumentException(
          'Invalid data, cannot perform conversion from base32');
    }

    return convData;
  }

  static List<int>? _convertBits(
    List<int> data,
    int fromBits,
    int toBits, {
    bool pad = true,
  }) {
    /// Perform bit conversion.

    final int maxOutVal = (1 << toBits) - 1;
    final int maxAcc = (1 << (fromBits + toBits - 1)) - 1;

    int acc = 0;
    int bits = 0;
    final List<int> ret = <int>[];

    for (final int value in data) {
      // Value shall not be less than zero or greater than 2^fromBits
      if (value < 0 || (value >> fromBits) != 0) {
        return null;
      }
      // Continue accumulating until greater than toBits
      acc = ((acc << fromBits) | value) & maxAcc;
      bits += fromBits;
      while (bits >= toBits) {
        bits -= toBits;
        ret.add((acc >> bits) & maxOutVal);
      }
    }
    if (pad) {
      if (bits > 0) {
        // Pad the value with zeros to reach toBits
        ret.add((acc << (toBits - bits)) & maxOutVal);
      }
    } else if (bits >= fromBits ||
        ((acc << (toBits - bits)) & maxOutVal) != 0) {
      return null;
    }

    return List<int>.from(ret);
  }
}

/// An abstract base class for Bech32 encoding implementations.
abstract class Bech32EncoderBase {
  /// Encodes data into a Bech32 string.
  ///
  /// Parameters:
  /// - hrp: The Human-Readable Part (prefix) of the Bech32 string.
  /// - data: The data to be encoded as a List<int>.
  /// - sep: The separator character used in the Bech32 string.
  /// - computeChecksum: A function that computes the checksum for the Bech32 string.
  ///
  /// Returns:
  /// A Bech32-encoded string representing the provided data with a checksum.
  static String encodeBech32(String hrp, List<int> data, String sep,
      List<int> Function(String hrp, List<int> data) computeChecksum) {
    final checksum = computeChecksum(hrp, data);

    data = List<int>.from([...data, ...checksum]);

    final encodedData =
        hrp + sep + data.map((e) => Bech32BaseConst.charset[e]).join();

    return encodedData;
  }
}

/// An abstract base class for Bech32 decoding implementations.
abstract class Bech32DecoderBase {
  /// Decodes a Bech32-encoded string into its components.
  ///
  /// Parameters:
  /// - bechStr: The Bech32-encoded string to decode.
  /// - sep: The separator character used in the Bech32 string.
  /// - checksumLen: The length of the checksum in the Bech32 string.
  /// - verifyChecksum: A function that verifies the checksum of the Bech32 string.
  ///
  /// Returns:
  /// A tuple containing the Human-Readable Part (HRP) and the data part of the Bech32-encoded string.
  ///
  /// Throws:
  /// - ArgumentException: If the input string is mixed case, lacks a separator, HRP is invalid, or the checksum is invalid.
  ///
  static Tuple<String, List<int>> decodeBech32(
      String bechStr,
      String sep,
      int checksumLen,
      bool Function(String hrp, List<int> data) verifyChecksum) {
    if (_isStringMixed(bechStr)) {
      throw const ArgumentException(
          'Invalid bech32 format (string is mixed case)');
    }

    bechStr = bechStr.toLowerCase();

    final sepPos = bechStr.lastIndexOf(sep);
    if (sepPos == -1) {
      throw const ArgumentException(
          'Invalid bech32 format (no separator found)');
    }

    final hrp = bechStr.substring(0, sepPos);
    if (hrp.isEmpty || hrp.codeUnits.any((x) => x < 33 || x > 126)) {
      throw ArgumentException('Invalid bech32 format (HRP not valid: $hrp)');
    }

    final dataPart = bechStr.substring(sepPos + 1);

    if (dataPart.length < checksumLen + 1 ||
        dataPart.codeUnits.any(
            (x) => !Bech32BaseConst.charset.contains(String.fromCharCode(x)))) {
      throw const ArgumentException(
          'Invalid bech32 format (data part not valid)');
    }

    final intData = dataPart.codeUnits
        .map((x) => Bech32BaseConst.charset.indexOf(String.fromCharCode(x)))
        .toList();
    if (!verifyChecksum(hrp, intData)) {
      throw const Bech32ChecksumError('Invalid bech32 checksum');
    }

    return Tuple(
        hrp, List<int>.from(intData.sublist(0, intData.length - checksumLen)));
  }

  static bool _isStringMixed(String str) {
    final hasLowerCase = str.contains(RegExp(r'[a-z]'));
    final hasUpperCase = str.contains(RegExp(r'[A-Z]'));
    return hasLowerCase && hasUpperCase;
  }
}
