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
import 'package:blockchain_utils/bip/address/p2pkh_addr.dart';
import 'package:blockchain_utils/bip/ecc/keys/secp256k1_keys_ecdsa.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:blockchain_utils/exception/exception.dart';

/// Constants related to Wallet Import Format (WIF).
class WifConst {
  /// Suffix value indicating compressed public key mode in a WIF.
  static const comprPubKeySuffix = 0x01;
}

/// A class for encoding Wallet Import Format (WIF) private keys.
class WifEncoder {
  /// Encodes a private key into a WIF string.
  ///
  /// The [privKey] is the private key to be encoded, and [netVer] is an optional
  /// list of network version bytes. By default, it's an empty list.
  ///
  /// The [pubKeyMode] determines the mode of the associated public key, where
  /// [WifPubKeyModes.compressed] represents the compressed mode.
  ///
  /// Returns the WIF-encoded private key as a string.
  static String encode(List<int> privKey,
      {List<int> netVer = const [],
      PubKeyModes pubKeyMode = PubKeyModes.compressed}) {
    final prv = Secp256k1PrivateKeyEcdsa.fromBytes(privKey);

    List<int> privKeyBytes = prv.raw;

    if (pubKeyMode == PubKeyModes.compressed) {
      privKeyBytes =
          List<int>.from([...privKeyBytes, WifConst.comprPubKeySuffix]);
    }
    privKeyBytes = List<int>.from([...netVer, ...privKeyBytes]);

    return Base58Encoder.checkEncode(privKeyBytes);
  }
}

/// A class for decoding Wallet Import Format (WIF) private keys.
class WifDecoder {
  /// Decodes a WIF-encoded private key
  ///
  /// The [wif] is the WIF-encoded private key to be decoded, and [netVer] is an
  /// optional list of network version bytes. By default, it's an empty list.
  ///
  /// Returns a tuple containing the decoded private key as a `List<int>` and
  /// the associated [WifPubKeyModes] representing the public key mode, where
  /// [WifPubKeyModes.compressed] indicates the compressed mode.
  static Tuple<List<int>, PubKeyModes> decode(String wif,
      {List<int> netVer = const []}) {
    List<int> privKeyBytes = Base58Decoder.checkDecode(wif);
    if (netVer.isEmpty || privKeyBytes[0] != netVer[0]) {
      throw const ArgumentException('Invalid net version');
    }
    privKeyBytes = privKeyBytes.sublist(1);
    PubKeyModes pubKeyMode;
    if (Secp256k1PrivateKeyEcdsa.isValidBytes(
        privKeyBytes.sublist(0, privKeyBytes.length - 1))) {
      // Check the compressed public key suffix
      if (privKeyBytes[privKeyBytes.length - 1] != WifConst.comprPubKeySuffix) {
        throw const ArgumentException('Invalid compressed public key suffix');
      }
      privKeyBytes = privKeyBytes.sublist(0, privKeyBytes.length - 1);
      pubKeyMode = PubKeyModes.compressed;
    } else {
      if (!Secp256k1PrivateKeyEcdsa.isValidBytes(privKeyBytes)) {
        throw const ArgumentException('Invalid decoded key');
      }
      pubKeyMode = PubKeyModes.uncompressed;
    }

    return Tuple(privKeyBytes, pubKeyMode);
  }
}
