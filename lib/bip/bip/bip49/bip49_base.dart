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

import 'package:blockchain_utils/bip/bip/bip32/base/bip32_base.dart';
import 'package:blockchain_utils/bip/bip/bip32/bip32_key_data.dart';
import 'package:blockchain_utils/bip/bip/bip44/base/bip44_base.dart';
import 'package:blockchain_utils/bip/bip/bip44/base/bip44_base_ex.dart';
import 'package:blockchain_utils/bip/bip/conf/bip49/bip49_coins.dart';
import 'package:blockchain_utils/bip/bip/conf/config/bip_coin_conf.dart';

/// Constants related to BIP-49 (Bitcoin Improvement Proposal 44).
class Bip49Const {
  /// The name of the BIP-49 specification.
  static const String specName = "BIP-0049";

  /// The purpose index for BIP-49, derived as a hardened index (49').
  static final Bip32KeyIndex purpose = Bip32KeyIndex.hardenIndex(49);
}

class Bip49 extends Bip44Base {
  /// private constractor
  Bip49._(Bip32Base bip32Obj, BipCoinConfig coinConf)
      : super(bip32Obj, coinConf);

  /// Constructor for creating a [Bip49] object from a seed and coin.
  Bip49.fromSeed(List<int> seedBytes, Bip49Coins coinType)
      : super.fromSeed(seedBytes, coinType.conf);

  /// Constructor for creating a [Bip49] object from a extended key and coin.
  Bip49.fromExtendedKey(String extendedKey, Bip49Coins coinType)
      : super.fromExtendedKey(extendedKey, coinType.conf);

  /// Constructor for creating a [Bip49] object from a private key and coin.
  Bip49.fromPrivateKey(List<int> privateKeyBytes, Bip49Coins coinType,
      {Bip32KeyData? keyData})
      : super.fromPrivateKey(privateKeyBytes, coinType.conf,
            keyData: keyData ?? Bip32KeyData());

  /// Constructor for creating a [Bip49] object from a public key and coin.
  Bip49.fromPublicKey(List<int> pubkeyBytes, Bip49Coins coinType,
      {Bip32KeyData? keyData})
      : super.fromPublicKey(pubkeyBytes, coinType.conf,
            keyData: keyData ??
                Bip32KeyData(depth: Bip32Depth(Bip44Levels.account.value)));

  /// derive purpose
  @override
  Bip49 get purpose {
    if (!isLevel(Bip44Levels.master)) {
      throw Bip44DepthError(
          "Current depth (${bip32.depth.toInt()}) is not suitable for deriving purpose");
    }
    return Bip49._(bip32.childKey(Bip49Const.purpose), coinConf);
  }

  /// derive coin
  @override
  Bip49 get coin {
    if (!isLevel(Bip44Levels.purpose)) {
      throw Bip44DepthError(
          "Current depth (${bip32.depth.toInt()}) is not suitable for deriving coin");
    }
    final coinIndex = coinConf.coinIdx;
    return Bip49._(
        bip32.childKey(Bip32KeyIndex.hardenIndex(coinIndex)), coinConf);
  }

  /// derive account with index
  @override
  Bip49 account(int accIndex) {
    if (!isLevel(Bip44Levels.coin)) {
      throw Bip44DepthError(
          "Current depth (${bip32.depth.toInt()}) is not suitable for deriving account");
    }
    return Bip49._(
        bip32.childKey(Bip32KeyIndex.hardenIndex(accIndex)), coinConf);
  }

  /// derive change with change type [Bip44Changes] internal or external
  @override
  Bip49 change(Bip44Changes changeType) {
    if (!isLevel(Bip44Levels.account)) {
      throw Bip44DepthError(
          "Current depth (${bip32.depth.toInt()}) is not suitable for deriving change");
    }
    Bip32KeyIndex changeIndex = Bip32KeyIndex(changeType.value);
    if (!bip32Object.isPublicDerivationSupported) {
      changeIndex = Bip32KeyIndex.hardenIndex(changeType.value);
    }
    return Bip49._(bip32.childKey(changeIndex), coinConf);
  }

  /// derive address with index
  @override
  Bip49 addressIndex(int addressIndex) {
    if (!isLevel(Bip44Levels.change)) {
      throw Bip44DepthError(
          "Current depth (${bip32.depth.toInt()}) is not suitable for deriving address");
    }
    Bip32KeyIndex changeIndex = Bip32KeyIndex(addressIndex);
    if (!bip32Object.isPublicDerivationSupported) {
      changeIndex = Bip32KeyIndex.hardenIndex(addressIndex);
    }
    return Bip49._(bip32.childKey(changeIndex), coinConf);
  }

  /// derive default path
  @override
  Bip49 get deriveDefaultPath {
    Bip44Base bipObj = purpose.coin;
    return Bip49._(bipObj.bip32.derivePath(bipObj.coinConf.defPath), coinConf);
  }

  /// Specification name
  @override
  String get specName {
    return Bip49Const.specName;
  }
}
