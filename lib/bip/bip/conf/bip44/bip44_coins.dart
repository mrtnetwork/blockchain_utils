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

import 'package:blockchain_utils/bip/bip/conf/bip44/bip44_conf.dart';
import 'package:blockchain_utils/bip/bip/conf/bip_coin_conf.dart';
import 'package:blockchain_utils/bip/bip/conf/bip_coins.dart';

/// An enumeration of supported cryptocurrencies for BIP44. It includes both main
/// networks and test networks of various cryptocurrencies.
enum Bip44Coins implements CryptoCoins {
  akashNetwork,
  algorand,
  aptos,
  avaxCChain,
  avaxPChain,
  avaxXChain,
  axelar,
  bandProtocol,
  binanceChain,
  binanceSmartChain,
  bitcoin,
  bitcoinCash,
  bitcoinCashSlp,
  bitcoinSv,
  cardanoByronIcarus,
  cardanoByronLedger,
  celo,
  certik,
  chihuahua,
  cosmos,
  dash,
  dogecoin,
  ecash,
  elrond,
  eos,
  ergo,
  ethereum,
  ethereumClassic,
  fantomOpera,
  filecoin,
  harmonyOneAtom,
  harmonyOneEth,
  harmonyOneMetamask,
  huobiChain,
  icon,
  injective,
  irisNet,
  kava,
  kusamaEd25519Slip,
  litecoin,
  moneroEd25519Slip,
  moneroSecp256k1,
  nano,
  nearProtocol,
  neo,
  nineChroniclesGold,
  okexChainAtom,
  okexChainAtomOld,
  okexChainEth,
  ontology,
  osmosis,
  piNetwork,
  polkadotEd25519Slip,
  polygon,
  ripple,
  rippleTestnet,
  secretNetworkOld,
  secretNetworkNew,
  solana,
  stellar,
  terra,
  tezos,
  theta,
  tron,
  vechain,
  verge,
  zcash,
  zilliqa,
  // Test nets
  bitcoinCashTestnet,
  bitcoinCashSlpTestnet,
  bitcoinSvTestnet,
  bitcoinTestnet,
  dashTestnet,
  dogecoinTestnet,
  ecashTestnet,
  ergoTestnet,
  litecoinTestnet,
  zcashTestnet;

  @override
  Bip44Coins get value {
    return this;
  }

  String get coinName {
    return this.name;
  }

  CoinConfig get conf => _coinToConf[this]!;

  static Bip44Coins? fromName(String name) {
    try {
      return values.firstWhere((element) => element.name == name);
    } on StateError {
      return null;
    }
  }

  /// A mapping that associates each BIP44Coin (enum) with its corresponding
  /// CoinConfig configuration.
  static Map<Bip44Coins, CoinConfig> _coinToConf = {
    Bip44Coins.akashNetwork: Bip44Conf.akashNetwork,
    Bip44Coins.algorand: Bip44Conf.algorand,
    Bip44Coins.aptos: Bip44Conf.aptos,
    Bip44Coins.avaxCChain: Bip44Conf.avaxCChain,
    Bip44Coins.avaxPChain: Bip44Conf.avaxPChain,
    Bip44Coins.avaxXChain: Bip44Conf.avaxXChain,
    Bip44Coins.axelar: Bip44Conf.axelar,
    Bip44Coins.bandProtocol: Bip44Conf.bandProtocol,
    Bip44Coins.binanceChain: Bip44Conf.binanceChain,
    Bip44Coins.binanceSmartChain: Bip44Conf.binanceSmartChain,
    Bip44Coins.bitcoin: Bip44Conf.bitcoinMainNet,
    Bip44Coins.bitcoinTestnet: Bip44Conf.bitcoinTestNet,
    Bip44Coins.bitcoinCash: Bip44Conf.bitcoinCashMainNet,
    Bip44Coins.bitcoinCashTestnet: Bip44Conf.bitcoinCashTestNet,
    Bip44Coins.bitcoinCashSlp: Bip44Conf.bitcoinCashSlpMainNet,
    Bip44Coins.bitcoinCashSlpTestnet: Bip44Conf.bitcoinCashSlpTestNet,
    Bip44Coins.bitcoinSv: Bip44Conf.bitcoinSvMainNet,
    Bip44Coins.bitcoinSvTestnet: Bip44Conf.bitcoinSvTestNet,
    Bip44Coins.cardanoByronIcarus: Bip44Conf.cardanoByronIcarus,
    Bip44Coins.cardanoByronLedger: Bip44Conf.cardanoByronLedger,
    Bip44Coins.celo: Bip44Conf.celo,
    Bip44Coins.certik: Bip44Conf.certik,
    Bip44Coins.chihuahua: Bip44Conf.chihuahua,
    Bip44Coins.cosmos: Bip44Conf.cosmos,
    Bip44Coins.dash: Bip44Conf.dashMainNet,
    Bip44Coins.dashTestnet: Bip44Conf.dashTestNet,
    Bip44Coins.dogecoin: Bip44Conf.dogecoinMainNet,
    Bip44Coins.dogecoinTestnet: Bip44Conf.dogecoinTestNet,
    Bip44Coins.ecash: Bip44Conf.ecashMainNet,
    Bip44Coins.ecashTestnet: Bip44Conf.ecashTestNet,
    Bip44Coins.elrond: Bip44Conf.elrond,
    Bip44Coins.eos: Bip44Conf.eos,
    Bip44Coins.ergo: Bip44Conf.ergoMainNet,
    Bip44Coins.ergoTestnet: Bip44Conf.ergoTestNet,
    Bip44Coins.ethereum: Bip44Conf.ethereum,
    Bip44Coins.ethereumClassic: Bip44Conf.ethereumClassic,
    Bip44Coins.fantomOpera: Bip44Conf.fantomOpera,
    Bip44Coins.filecoin: Bip44Conf.filecoin,
    Bip44Coins.harmonyOneAtom: Bip44Conf.harmonyOneAtom,
    Bip44Coins.harmonyOneEth: Bip44Conf.harmonyOneEth,
    Bip44Coins.harmonyOneMetamask: Bip44Conf.harmonyOneMetamask,
    Bip44Coins.huobiChain: Bip44Conf.huobiChain,
    Bip44Coins.icon: Bip44Conf.icon,
    Bip44Coins.injective: Bip44Conf.injective,
    Bip44Coins.irisNet: Bip44Conf.irisNet,
    Bip44Coins.kava: Bip44Conf.kava,
    Bip44Coins.kusamaEd25519Slip: Bip44Conf.kusamaEd25519Slip,
    Bip44Coins.litecoin: Bip44Conf.litecoinMainNet,
    Bip44Coins.litecoinTestnet: Bip44Conf.litecoinTestNet,
    Bip44Coins.moneroEd25519Slip: Bip44Conf.moneroEd25519Slip,
    Bip44Coins.moneroSecp256k1: Bip44Conf.moneroSecp256k1,
    Bip44Coins.nano: Bip44Conf.nano,
    Bip44Coins.nearProtocol: Bip44Conf.nearProtocol,
    Bip44Coins.neo: Bip44Conf.neo,
    Bip44Coins.nineChroniclesGold: Bip44Conf.nineChroniclesGold,
    Bip44Coins.okexChainAtom: Bip44Conf.okexChainAtom,
    Bip44Coins.okexChainAtomOld: Bip44Conf.okexChainAtomOld,
    Bip44Coins.okexChainEth: Bip44Conf.okexChainEth,
    Bip44Coins.ontology: Bip44Conf.ontology,
    Bip44Coins.osmosis: Bip44Conf.osmosis,
    Bip44Coins.piNetwork: Bip44Conf.piNetwork,
    Bip44Coins.polkadotEd25519Slip: Bip44Conf.polkadotEd25519Slip,
    Bip44Coins.polygon: Bip44Conf.polygon,
    Bip44Coins.ripple: Bip44Conf.ripple,
    Bip44Coins.rippleTestnet: Bip44Conf.rippleTestnet,
    Bip44Coins.secretNetworkOld: Bip44Conf.secretNetworkOld,
    Bip44Coins.secretNetworkNew: Bip44Conf.secretNetworkNew,
    Bip44Coins.solana: Bip44Conf.solana,
    Bip44Coins.stellar: Bip44Conf.stellar,
    Bip44Coins.terra: Bip44Conf.terra,
    Bip44Coins.tezos: Bip44Conf.tezos,
    Bip44Coins.theta: Bip44Conf.theta,
    Bip44Coins.tron: Bip44Conf.tron,
    Bip44Coins.vechain: Bip44Conf.vechain,
    Bip44Coins.verge: Bip44Conf.verge,
    Bip44Coins.zcash: Bip44Conf.zcashMainNet,
    Bip44Coins.zcashTestnet: Bip44Conf.zcashTestNet,
    Bip44Coins.zilliqa: Bip44Conf.zilliqa,
  };
  BipProposal get proposal => BipProposal.bip44;
}
