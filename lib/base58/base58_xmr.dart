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

import 'package:blockchain_utils/base58/base58.dart';
import 'package:blockchain_utils/helper/helper.dart';

/// Constants and data related to Base58 encoding used in Monero (XMR).
class Base58XmrConst {
  /// Retrieve the Base58 alphabet specific to Monero (XMR).
  static String get alphabet => Base58Const.alphabets[Base58Alphabets.bitcoin]!;

  /// Maximum byte length for decoding blocks in Monero Base58 encoding.
  static const int blockDecMaxByteLen = 8;

  /// Maximum byte length for encoding blocks in Monero Base58 encoding.
  static const int blockEncMaxByteLen = 11;

  /// List of byte lengths for encoding blocks in Monero Base58 encoding.
  static const List<int> blockEncByteLens = [0, 2, 3, 5, 6, 7, 9, 10, 11];
}

/// A utility class for encoding BytesData data into Monero Base58 format.
class Base58XmrEncoder {
  /// Encode the provided BytesData of dataBytes into a Monero Base58 encoded string.
  static String encode(List<int> dataBytes) {
    dataBytes = dataBytes.asImmutableBytes;
    String enc = '';

    /// Get lengths
    final dataLen = dataBytes.length;
    const blockDecLen = Base58XmrConst.blockDecMaxByteLen;

    /// Compute total block count and last block length
    final totBlockCnt = dataLen ~/ blockDecLen;
    final lastBlockEncLen = dataLen % blockDecLen;

    /// Encode each single block and pad
    for (var i = 0; i < totBlockCnt; i++) {
      final blockEnc = Base58Encoder.encode(
          dataBytes.sublist(i * blockDecLen, (i + 1) * blockDecLen));
      enc += _pad(blockEnc, Base58XmrConst.blockEncMaxByteLen);
    }

    /// Encode last block and pad
    if (lastBlockEncLen > 0) {
      final blockEnc = Base58Encoder.encode(dataBytes.sublist(
          totBlockCnt * blockDecLen,
          totBlockCnt * blockDecLen + lastBlockEncLen));
      enc += _pad(blockEnc, Base58XmrConst.blockEncByteLens[lastBlockEncLen]);
    }

    return enc;
  }

  static String _pad(String encStr, int padLen) {
    return encStr.padLeft(padLen, Base58XmrConst.alphabet[0]);
  }
}

/// A utility class for decoding Monero Base58 encoded strings into BytesData data.
class Base58XmrDecoder {
  /// Decode the provided Monero Base58 encoded [dataStr] into a BytesData of dataBytes.
  static List<int> decode(String dataStr) {
    List<int> dec = List.empty();

    /// Get lengths
    final dataLen = dataStr.length;
    const blockDecLen = Base58XmrConst.blockDecMaxByteLen;
    const blockEncLen = Base58XmrConst.blockEncMaxByteLen;

    /// Compute block count and last block length
    final totBlockCnt = dataLen ~/ blockEncLen;
    final lastBlockEncLen = dataLen % blockEncLen;

    /// Get last block decoded length
    final lastBlockDecLen =
        Base58XmrConst.blockEncByteLens.indexOf(lastBlockEncLen);

    /// Decode each single block and unpad
    for (var i = 0; i < totBlockCnt; i++) {
      final blockDec = Base58Decoder.decode(
          dataStr.substring(i * blockEncLen, (i + 1) * blockEncLen));
      dec = List<int>.from([...dec, ..._unPad(blockDec, blockDecLen)]);
    }

    /// Decode last block and unpad
    if (lastBlockEncLen > 0) {
      final blockDec = Base58Decoder.decode(dataStr.substring(
          totBlockCnt * blockEncLen,
          totBlockCnt * blockEncLen + lastBlockEncLen));
      dec = List<int>.from([...dec, ..._unPad(blockDec, lastBlockDecLen)]);
    }

    return dec;
  }

  static List<int> _unPad(List<int> decBytes, int unpadLen) {
    final start = decBytes.length - unpadLen;
    return decBytes.sublist(start);
  }
}
