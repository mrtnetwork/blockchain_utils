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

import 'package:blockchain_utils/bip/address/p2tr_addr.dart';
import 'package:blockchain_utils/bip/bip/bip32/bip32_const.dart';
import 'package:blockchain_utils/bip/bip/conf/bip86/bip86_coins.dart';
import 'package:blockchain_utils/bip/bip/conf/bip_coin_conf.dart';
import 'package:blockchain_utils/bip/bip/conf/bip_coins.dart';
import 'package:blockchain_utils/bip/bip/conf/bip_conf_const.dart';
import 'package:blockchain_utils/bip/coin_conf/coins_conf.dart';
import 'package:blockchain_utils/bip/ecc/curve/elliptic_curve_types.dart';
import 'package:blockchain_utils/bip/slip/slip44/slip44.dart';

/// A configuration class for BIP86 that defines the key network versions and
/// maps each supported BIP86Coin to its corresponding BipCoinConf.
class Bip86Conf {
  /// The key network version for the mainnet of Bitcoin.
  static final bip86BtcKeyNetVer = Bip32Const.mainNetKeyNetVersions;

  /// The key network version for the testnet of Bitcoin.
  static final bip86BtcKeyNetVerTest = Bip32Const.testNetKeyNetVersions;

  /// A mapping that associates each BIP86Coin (enum) with its corresponding
  /// BipCoinConf configuration.
  static final Map<Bip86Coins, BipCoinConf> coinToConf = {
    Bip86Coins.bitcoin: Bip86Conf.bitcoinMainNet,
    Bip86Coins.bitcoinTestnet: Bip86Conf.bitcoinTestNet,
  };

  /// Retrieves the BipCoinConf for the given BIP86Coin. If the provided coin
  /// is not an instance of Bip86Coins, an error is thrown.
  static BipCoinConf getCoin(BipCoins coin) {
    if (coin is! Bip86Coins) {
      throw ArgumentError("Coin type is not an enumerative of Bip86Coins");
    }
    return coinToConf[coin.value]!;
  }

  /// Configuration for Bitcoin main net
  static BipCoinConf bitcoinMainNet = BipCoinConf(
    coinNames: CoinsConf.bitcoinMainNet.coinName,
    coinIdx: Slip44.bitcoin,
    isTestnet: false,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip86BtcKeyNetVer,
    wifNetVer: CoinsConf.bitcoinMainNet.getParam("wif_net_ver"),
    addressEncoder: ([dynamic kwargs]) => P2TRAddrEncoder(),
    type: EllipticCurveTypes.secp256k1,
    addrParams: {
      "hrp": CoinsConf.bitcoinMainNet.getParam("p2tr_hrp"),
    },
  );

  /// Configuration for Bitcoin test net
  static BipCoinConf bitcoinTestNet = BipCoinConf(
    coinNames: CoinsConf.bitcoinTestNet.coinName,
    coinIdx: Slip44.testnet,
    isTestnet: true,
    defPath: derPathNonHardenedFull,
    addressEncoder: ([dynamic kwargs]) => P2TRAddrEncoder(),
    keyNetVer: bip86BtcKeyNetVerTest,
    wifNetVer: CoinsConf.bitcoinTestNet.getParam("wif_net_ver"),
    type: EllipticCurveTypes.secp256k1,
    addrParams: {
      "hrp": CoinsConf.bitcoinTestNet.getParam("p2tr_hrp"),
    },
  );
}
