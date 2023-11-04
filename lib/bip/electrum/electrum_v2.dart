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

import 'package:blockchain_utils/bip/address/p2pkh_addr.dart';
import 'package:blockchain_utils/bip/address/p2wpkh_addr.dart';
import 'package:blockchain_utils/bip/bip/bip32/base/bip32_base.dart';
import 'package:blockchain_utils/bip/bip/bip32/bip32_keys.dart';
import 'package:blockchain_utils/bip/bip/bip32/slip10/bip32_slip10_secp256k1.dart';
import 'package:blockchain_utils/bip/coin_conf/coins_conf.dart';

/// An abstract base class for Electrum V2 implementations
abstract class ElectrumV2Base {
  final Bip32Slip10Secp256k1 bip32;

  ElectrumV2Base(this.bip32);
// Check if the instance contains only public keys (no private keys).
  bool get isPublicOnly {
    return bip32.isPublicOnly;
  }

  /// Get the master private key.
  Bip32PrivateKey get masterPrivateKey {
    return bip32.privateKey;
  }

  /// Get the master public key.
  Bip32PublicKey get masterPublicKey {
    return bip32.publicKey;
  }

  /// Get a specific private key based on change and address indexes.
  Bip32PrivateKey getPrivateKey(int changeIndex, int addressIndex);

  /// Get a specific public key based on change and address indexes.
  Bip32PublicKey getPublicKey(int changeIndex, int addressIndex);

  /// Get the address for a specific change and address index.
  String getAddress(int changeIndex, int addressIndex);
}

/// Implementation of Electrum V2 for the standard type wallet.
class ElectrumV2Standard extends ElectrumV2Base {
  ElectrumV2Standard(Bip32Slip10Secp256k1 bip32) : super(bip32);

  /// Factory method to create an instance from a seed.
  factory ElectrumV2Standard.fromSeed(List<int> seedBytes) {
    final bip = Bip32Slip10Secp256k1.fromSeed(seedBytes);
    return ElectrumV2Standard(bip);
  }

  /// Get a specific private key based on change and address indexes.
  @override
  Bip32PrivateKey getPrivateKey(int changeIndex, int addressIndex) {
    return _deriveKey(changeIndex, addressIndex).privateKey;
  }

  /// Get a specific public key based on change and address indexes.
  @override
  Bip32PublicKey getPublicKey(int changeIndex, int addressIndex) {
    return _deriveKey(changeIndex, addressIndex).publicKey;
  }

  /// Get the P2PKH (pay-to-pub-key-hash) address for a specific change and address index.
  @override
  String getAddress(int changeIndex, int addressIndex) {
    return P2PKHAddrEncoder().encodeKey(
        getPublicKey(changeIndex, addressIndex).compressed,
        {"net_ver": CoinsConf.bitcoinMainNet.getParam('p2pkh_net_ver')});
  }

  /// Derive a key for a specific change and address index.
  Bip32Base _deriveKey(int changeIndex, int addressIndex) {
    return bip32.derivePath('m/$changeIndex/$addressIndex');
  }
}

/// Implementation of Electrum V2 for the segwit type wallet.
class ElectrumV2Segwit extends ElectrumV2Base {
  final Bip32Base bip32Account;

  ElectrumV2Segwit(Bip32Slip10Secp256k1 bip32)
      : bip32Account = bip32.derivePath("m/0'"),
        super(bip32);

  /// Factory method to create an instance from a seed.
  factory ElectrumV2Segwit.fromSeed(List<int> seedBytes) {
    final bip = Bip32Slip10Secp256k1.fromSeed(seedBytes);
    return ElectrumV2Segwit(bip);
  }

  /// Get a specific private key based on change and address indexes.
  @override
  Bip32PrivateKey getPrivateKey(int changeIndex, int addressIndex) {
    return _deriveKey(changeIndex, addressIndex).privateKey;
  }

  /// Get a specific public key based on change and address indexes.
  @override
  Bip32PublicKey getPublicKey(int changeIndex, int addressIndex) {
    return _deriveKey(changeIndex, addressIndex).publicKey;
  }

  /// Get the P2WPKH (pay-to-witness-pub-key-hash) address for a specific change and address index.
  @override
  String getAddress(int changeIndex, int addressIndex) {
    return P2WPKHAddrEncoder()
        .encodeKey(getPublicKey(changeIndex, addressIndex).compressed, {
      "hrp": CoinsConf.bitcoinMainNet.getParam("p2wpkh_hrp"),
    });
  }

  /// Derive a key for a specific change and address index.
  Bip32Base _deriveKey(int changeIndex, int addressIndex) {
    return bip32Account.derivePath('$changeIndex/$addressIndex');
  }
}
