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

import 'package:blockchain_utils/bip/bip/conf/bip/bip_coins.dart';
import 'package:blockchain_utils/bip/bip/conf/bip84/bip84_conf.dart';
import 'package:blockchain_utils/bip/bip/conf/config/bip_coin_conf.dart';

/// An enumeration of supported cryptocurrencies for BIP84. It includes both main
/// networks and test networks of various cryptocurrencies.
class Bip84Coins extends BipCoins {
  // Main nets
  static const Bip84Coins bitcoin = Bip84Coins._('bitcoin');
  static const Bip84Coins litecoin = Bip84Coins._('litecoin');

  // Test nets
  static const Bip84Coins bitcoinTestnet = Bip84Coins._('bitcoinTestnet');
  static const Bip84Coins litecoinTestnet = Bip84Coins._('litecoinTestnet');
  static const List<Bip84Coins> values = [
    bitcoin,
    litecoin,
    bitcoinTestnet,
    litecoinTestnet
  ];
  final String name;

  const Bip84Coins._(this.name);

  @override
  Bip84Coins get value => this;

  @override
  String get coinName => name;

  @override
  BipCoinConfig get conf => _coinToConf[this]!;

  static Bip84Coins? fromName(String name) {
    try {
      return _coinToConf.keys.firstWhere((element) => element.name == name);
    } on StateError {
      return null;
    }
  }

  /// A mapping that associates each BIP84Coin (enum) with its corresponding
  /// BipCoinConfig configuration.
  static final Map<Bip84Coins, BipCoinConfig> _coinToConf = {
    Bip84Coins.bitcoin: Bip84Conf.bitcoinMainNet,
    Bip84Coins.bitcoinTestnet: Bip84Conf.bitcoinTestNet,
    Bip84Coins.litecoin: Bip84Conf.litecoinMainNet,
    Bip84Coins.litecoinTestnet: Bip84Conf.litecoinTestNet,
  };

  @override
  BipProposal get proposal => BipProposal.bip84;
}
