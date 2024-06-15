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

import 'dart:typed_data';

import 'package:blockchain_utils/utils/utils.dart';

import 'bech32_utils.dart';
import 'package:blockchain_utils/exception/exception.dart';

/// A utility class containing constants used for Bitcoin Cash (BCH) Bech32 encoding and decoding.
class BchBech32Const {
  /// The separator used in a Bech32 encoded BCH address.
  static const String separator = ":";

  /// The length of the checksum in characters for a Bech32 encoded BCH address.
  static const int checksumStrLen = 8;
}

class _BchBech32Utils {
  static final _mask5 = BigInt.from(0x1f);
  static BigInt polyMod(List<int> values) {
    final List<List<BigInt>> generator = [
      [BigInt.from(0x01), BigInt.from(0x98f2bc8e61)],
      [BigInt.from(0x02), BigInt.from(0x79b76d99e2)],
      [BigInt.from(0x04), BigInt.from(0xf33e5fb3c4)],
      [BigInt.from(0x08), BigInt.from(0xae2eabe2a8)],
      [BigInt.from(0x10), BigInt.from(0x1e4f43e470)],
    ];

    // Compute modulus
    BigInt chk = BigInt.one;
    for (int value in values) {
      BigInt top = chk >> 35;
      final BigInt valueBig = BigInt.from(value);
      chk = ((chk & BigInt.from(0x07ffffffff)) << 5) ^ valueBig;

      for (List<BigInt> i in generator) {
        if ((top & i[0]) != BigInt.zero) {
          chk ^= i[1];
        }
      }
    }

    return (chk ^ BigInt.one);
  }

  static List<int> hrpExpand(String hrp) {
    List<int> expandedHrp = hrp.runes.map((int rune) {
      return rune & 0x1f;
    }).toList();
    expandedHrp.add(0);
    return expandedHrp;
  }

  static List<int> computeChecksum(String hrp, List<int> data) {
    List<int> values = hrpExpand(hrp) + data;
    BigInt polymod = polyMod(values + [0, 0, 0, 0, 0, 0, 0, 0]);
    return List<int>.generate(
      BchBech32Const.checksumStrLen,
      (i) => ((polymod >> (5 * (7 - i))) & _mask5).toInt(),
    );
  }

  static bool verifyChecksum(String hrp, List<int> data) {
    final polyMode = polyMod([...hrpExpand(hrp), ...data]);
    return polyMode == BigInt.zero;
  }
}

/// Encode data using the Bitcoin Cash (BCH) Bech32 encoding scheme.
///
/// Parameters:
/// - hrp: The Human-Readable Part (HRP) of the BCH address.
/// - netVar: A List<int> representing the network version bytes.
/// - data: A List<int> containing the data to be encoded.
///
/// Returns:
/// A Bech32 encoded BCH address string.
class BchBech32Encoder extends Bech32EncoderBase {
  /// Combine the network version bytes and data.
  static String encode(String hrp, List<int> netVar, List<int> data) {
    return Bech32EncoderBase.encodeBech32(
        hrp,
        Bech32BaseUtils.convertToBase32(List<int>.from([...netVar, ...data])),
        BchBech32Const.separator,
        _BchBech32Utils.computeChecksum);
  }
}

/// A utility class for decoding Bitcoin Cash (BCH) Bech32 encoded addresses.
class BchBech32Decoder extends Bech32DecoderBase {
  /// Decode a Bech32 encoded BCH address into its components: the Human-Readable Part (HRP),
  /// network version bytes, and data.
  ///
  /// Parameters:
  /// - hrp: The expected Human-Readable Part (HRP) of the BCH address.
  /// - address: The Bech32 encoded BCH address to be decoded.
  ///
  /// Returns:
  /// A tuple (pair) containing the network version bytes and data.
  ///
  /// Throws:
  /// - ArgumentException: If the decoded HRP does not match the expected HRP.
  static Tuple<List<int>, List<int>> decode(String hrp, String address) {
    final decode = Bech32DecoderBase.decodeBech32(
        address,
        BchBech32Const.separator,
        BchBech32Const.checksumStrLen,
        _BchBech32Utils.verifyChecksum);
    if (decode.item1 != hrp) {
      throw ArgumentException(
          "Invalid format (HRP not valid, expected $hrp, got ${decode.item2})");
    }
    final convData = Bech32BaseUtils.convertFromBase32(decode.item2);
    final ver = convData[0];
    return Tuple(
        IntUtils.toBytes(ver,
            length: IntUtils.bitlengthInBytes(ver), byteOrder: Endian.little),
        convData.sublist(1));
  }
}
