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

import 'package:blockchain_utils/base32/base32.dart';
import 'package:blockchain_utils/bip/address/addr_dec_utils.dart';
import 'package:blockchain_utils/bip/address/addr_key_validator.dart';
import 'package:blockchain_utils/bip/address/decoder.dart';
import 'package:blockchain_utils/bip/address/encoder.dart';
import 'package:blockchain_utils/bip/ecc/keys/ed25519_keys.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';

/// Constants related to Algorand (Algo) blockchain addresses.
class AlgoAddrConst {
  /// The length in bytes of the checksum portion in Algo addresses.
  static const int checksumByteLen = 4;
}

/// Utility methods for working with Algorand (Algo) blockchain addresses.
class _AlgoAddrUtils {
  /// Compute the checksum for an Algorand (Algo) blockchain address.
  static List<int> computeChecksum(List<int> pubKeyBytes) {
    final digest = QuickCrypto.sha512256Hash(pubKeyBytes);
    final startIndex = digest.length - AlgoAddrConst.checksumByteLen;

    return digest.sublist(startIndex);
  }
}

/// Implementation of the [BlockchainAddressDecoder] for Algorand (Algo) address.
class AlgoAddrDecoder implements BlockchainAddressDecoder<List<int>> {
  /// Decode an Algorand (Algo) blockchain address to its corresponding public key bytes.
  @override
  List<int> decodeAddr(String addr) {
    final addrDecBytes = Base32Decoder.decode(addr);
    const expectedLength =
        Ed25519KeysConst.pubKeyByteLen + AlgoAddrConst.checksumByteLen;
    AddrDecUtils.validateBytesLength(addrDecBytes, expectedLength);
    final parts = AddrDecUtils.splitPartsByChecksum(
      addrDecBytes,
      AlgoAddrConst.checksumByteLen,
    );
    final pubKeyBytes = parts.$1;
    final checksumBytes = parts.$2;
    AddrDecUtils.validateChecksum(
      pubKeyBytes,
      checksumBytes,
      _AlgoAddrUtils.computeChecksum,
    );
    return pubKeyBytes;
  }
}

/// Implementation of the [BlockchainAddressEncoder] for Algorand (Algo) address.
class AlgoAddrEncoder implements BlockchainAddressEncoder {
  /// Encode a public key into an Algorand (Algo) blockchain address.
  @override
  String encodeKey(List<int> pubKey) {
    final pubkeyBytes = AddrKeyValidator.validateAndGetEd25519Key(
      pubKey,
    ).compressed.sublist(1);
    final checksumBytes = _AlgoAddrUtils.computeChecksum(pubkeyBytes);
    final encodedAddress = Base32Encoder.encodeNoPaddingBytes([
      ...pubkeyBytes,
      ...checksumBytes,
    ]);
    return encodedAddress;
  }
}
