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

import 'package:blockchain_utils/bip/address/ada/ada_byron_addr.dart';
import 'package:blockchain_utils/bip/bip/bip32/base/bip32_base.dart';
import 'package:blockchain_utils/bip/bip/bip32/bip32_key_data.dart';
import 'package:blockchain_utils/bip/bip/bip32/bip32_keys.dart';
import 'package:blockchain_utils/bip/bip/bip32/bip32_path.dart';
import 'package:blockchain_utils/bip/cardano/bip32/cardano_byron_legacy_bip32.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/utils/utils.dart';

/// A class that holds constants related to the Cardano Byron legacy key derivation process.
class CardanoByronLegacyConst {
  /// The salt used for PBKDF2 when deriving keys along the HD path.
  static const String hdPathKeyPbkdf2Salt = 'address-hashing';

  /// The number of rounds for PBKDF2 key derivation along the HD path.
  static const int hdPathKeyPbkdf2Rounds = 500;

  /// The length of the output bytes from PBKDF2 key derivation along the HD path.
  static const int hdPathKeyPbkdf2OutByteLen = 32;
}

/// A class that represents a Cardano Byron Legacy wallet.
class CardanoByronLegacy {
  final Bip32Base bip32;

  /// CardanoByronLegacy

  /// Constructor to create a Cardano Byron Legacy wallet from a seed.
  ///
  /// Initializes the wallet's hierarchical deterministic (HD) structure using the
  /// provided seed bytes.
  ///
  /// Parameters:
  /// - `seedBytes`: The seed bytes used for wallet initialization.
  CardanoByronLegacy.fromSeed(List<int> seedBytes)
      : bip32 = CardanoByronLegacyBip32.fromSeed(seedBytes);

  CardanoByronLegacy.fromBip32(this.bip32);

  /// Computes and returns the HD path key for Cardano Byron Legacy wallet.
  ///
  /// The HD path key is derived using the PBKDF2 key derivation function based on
  /// the wallet's public key (compressed), chain code, and specified parameters.
  ///
  /// Returns:
  /// - A List<int> containing the derived HD path key.
  List<int> get hdPathKey {
    final hdPath = QuickCrypto.pbkdf2DeriveKey(
        password: List<int>.from([
          ...bip32.publicKey.compressed.sublist(1),
          ...bip32.chainCode.toBytes()
        ]),
        salt: StringUtils.encode(CardanoByronLegacyConst.hdPathKeyPbkdf2Salt),
        dklen: CardanoByronLegacyConst.hdPathKeyPbkdf2OutByteLen,
        iterations: CardanoByronLegacyConst.hdPathKeyPbkdf2Rounds);
    return hdPath;
  }

  /// Decodes and retrieves the BIP32 HD path from a Cardano Byron Legacy address.
  ///
  /// This method takes a Cardano Byron Legacy address, decodes it, and decrypts
  /// the embedded HD path using the provided `hdPathKey`.
  ///
  /// Parameters:
  /// - `address`: The Cardano Byron Legacy address to decode and extract the HD path from.
  ///
  /// Returns:
  /// - A BIP32Path object representing the hierarchical deterministic (HD) path.
  Bip32Path hdPathFromAddress(String address) {
    final addrDecBytes = AdaByronAddrDecoder().decodeAddr(address);
    final hdPathDecBytes = AdaByronAddrDecoder.decryptHdPath(
      AdaByronAddrDecoder.splitDecodedBytes(addrDecBytes).item2,
      hdPathKey,
    );
    return hdPathDecBytes;
  }

  /// master private key
  Bip32PrivateKey get masterPrivateKey {
    return bip32.privateKey;
  }

  /// master public key
  Bip32PublicKey get masterPublicKey {
    return bip32.publicKey;
  }

  /// Derives and returns a BIP32 base key based on two key indices, 'firstIndex' and 'secondIndex'.
  Bip32Base deriveKey(Bip32KeyIndex firstIndex, Bip32KeyIndex secondIndex) {
    return _deriveKey(firstIndex, secondIndex);
  }

  /// Retrieves and returns the public key associated with the specified key indices.
  ///
  /// Parameters:
  /// - 'firstIndex': The first key index for key derivation.
  /// - 'secondIndex': The second key index for key derivation.
  Bip32PublicKey getPublicKey(
      {required Bip32KeyIndex firstIndex, required Bip32KeyIndex secondIndex}) {
    final derive = deriveKey(firstIndex, secondIndex);
    return derive.publicKey;
  }

  /// Retrieves and returns the private key associated with the specified key indices.
  ///
  /// Parameters:
  /// - 'firstIndex': The first key index for key derivation.
  /// - 'secondIndex': The second key index for key derivation.
  Bip32PrivateKey getPrivateKey(
      {required Bip32KeyIndex firstIndex, required Bip32KeyIndex secondIndex}) {
    final derive = deriveKey(firstIndex, secondIndex);
    return derive.privateKey;
  }

  /// Computes and returns a Cardano Byron Legacy address based on two key indices, 'firstIndex' and 'secondIndex'.
  ///
  /// Parameters:
  /// - 'firstIndex': The first key index for address derivation.
  /// - 'secondIndex': The second key index for address derivation.
  String getAddress(Bip32KeyIndex firstIndex, Bip32KeyIndex secondIndex) {
    final pubKey =
        getPublicKey(firstIndex: firstIndex, secondIndex: secondIndex);
    final hdPath = _getDerivationPath(firstIndex, secondIndex);
    return AdaByronLegacyAddrEncoder().encodeKey(pubKey.key.compressed, {
      "chain_code": pubKey.chainCode.toBytes(),
      "hd_path": hdPath,
      "hd_path_key": hdPathKey,
    });
  }

  /// Derives and returns a BIP32 base key based on two key indices, 'firstIndex' and 'secondIndex'.
  ///
  /// Parameters:
  /// - 'firstIndex': The first key index for key derivation.
  /// - 'secondIndex': The second key index for key derivation.
  Bip32Base _deriveKey(Bip32KeyIndex firstIndex, Bip32KeyIndex secondIndex) {
    return bip32.derivePath(_getDerivationPath(firstIndex, secondIndex));
  }

  /// Generates the hierarchical derivation path based on two key indices.
  ///
  /// Parameters:
  /// - 'firstIndex': The first key index.
  /// - 'secondIndex': The second key index.
  String _getDerivationPath(
      Bip32KeyIndex firstIndex, Bip32KeyIndex secondIndex) {
    return 'm/${firstIndex.toInt()}\'/${secondIndex.toInt()}\'';
  }
}
