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
import 'package:blockchain_utils/bip/bip/conf/bip44/bip44_conf.dart';
import 'package:blockchain_utils/bip/bip/conf/config/bip_coin_conf.dart';
import 'package:blockchain_utils/bip/bip/conf/core/coins.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';

enum Bip44Coins implements BipCoins {
  // Akash Network
  akashNetwork('akashNetwork', 1),

  // Algorand
  algorand('algorand', 2),

  // Aptos
  aptos('aptos', 3),
  aptosEd25519SingleKey('aptosEd25519SingleKey', 4),
  aptosSecp256k1SingleKey('aptosSecp256k1SingleKey', 5),

  // Sui
  sui('sui', 6),
  suiSecp256k1('suiSecp256k1', 7),
  suiSecp256r1('suiSecp256r1', 8),

  // Avalanche
  avaxCChain('avaxCChain', 9),
  avaxPChain('avaxPChain', 10),
  avaxXChain('avaxXChain', 11),

  // Axelar
  axelar('axelar', 12),

  // Band Protocol
  bandProtocol('bandProtocol', 13),

  // Binance
  binanceChain('binanceChain', 14),
  binanceSmartChain('binanceSmartChain', 15),

  // Bitcoin variants
  bitcoin('bitcoin', 16),
  bitcoinCash('bitcoinCash', 17),
  bitcoinCashSlp('bitcoinCashSlp', 18),
  bitcoinSv('bitcoinSv', 19),

  // Cardano
  cardanoByronIcarus('cardanoByronIcarus', 20),
  cardanoByronLedger('cardanoByronLedger', 21),
  cardanoByronIcarusTestnet('cardanoByronIcarusTestnet', 22),
  cardanoByronLedgerTestnet('cardanoByronLedgerTestnet', 23),

  // Celo
  celo('celo', 24),

  // Certik
  certik('certik', 25),

  // Chihuahua
  chihuahua('chihuahua', 26),

  // Cosmos (various)
  cosmos('cosmos', 27),
  cosmosTestnet('cosmosTestnet', 28),
  cosmosNist256p1('cosmosNist256p1', 29),
  cosmosTestnetNist256p1('cosmosTestnetNist256p1', 30),
  cosmosEd25519('cosmosEd25519', 31),
  cosmosTestnetEd25519('cosmosTestnetEd25519', 32),
  cosmosEthSecp256k1('cosmosEthSecp256k1', 33),
  cosmosTestnetEthSecp256k1('cosmosTestnetEthSecp256k1', 34),

  // Dash
  dash('dash', 35),

  // Dogecoin
  dogecoin('dogecoin', 36),

  // Pepecoin
  pepecoin('pepecoin', 37),

  // eCash
  ecash('ecash', 38),

  // Elrond
  elrond('elrond', 39),

  // EOS
  eos('eos', 40),

  // Ergo
  ergo('ergo', 41),

  // Ethereum
  ethereum('ethereum', 42),
  ethereumTestnet('ethereumTestnet', 43),
  ethereumClassic('ethereumClassic', 44),

  // Fantom
  fantomOpera('fantomOpera', 45),

  // Filecoin
  filecoin('filecoin', 46),

  // Harmony
  harmonyOneAtom('harmonyOneAtom', 47),
  harmonyOneEth('harmonyOneEth', 48),
  harmonyOneMetamask('harmonyOneMetamask', 49),

  // Huobi
  huobiChain('huobiChain', 50),

  // ICON
  icon('icon', 51),

  // Injective
  injective('injective', 52),

  // IrisNet
  irisNet('irisNet', 53),

  // Kava
  kava('kava', 54),

  // Kusama
  kusamaEd25519Slip('kusamaEd25519Slip', 55),
  kusamaTestnetEd25519Slip('kusamaTestnetEd25519Slip', 56),

  // Litecoin
  litecoin('litecoin', 57),

  // Monero
  moneroEd25519Slip('moneroEd25519Slip', 58),
  moneroSecp256k1('moneroSecp256k1', 59),

  // Nano
  nano('nano', 60),

  // Near
  nearProtocol('nearProtocol', 61),

  // NEO
  neo('neo', 62),

  // Nine Chronicles
  nineChroniclesGold('nineChroniclesGold', 63),

  // OKEx
  okexChainAtom('okexChainAtom', 64),
  okexChainAtomOld('okexChainAtomOld', 65),
  okexChainEth('okexChainEth', 66),

  // Ontology
  ontology('ontology', 67),

  // Osmosis
  osmosis('osmosis', 68),

  // Pi Network
  piNetwork('piNetwork', 69),

  // Polkadot
  polkadotEd25519Slip('polkadotEd25519Slip', 70),
  polkadotTestnetEd25519Slip('polkadotTestnetEd25519Slip', 71),

  // Polygon
  polygon('polygon', 72),

  // Ripple
  ripple('ripple', 73),
  rippleTestnet('rippleTestnet', 74),
  rippleEd25519('rippleED25519', 75),
  rippleTestnetED25519('rippleTestnetED25519', 76),

  // Secret Network
  secretNetworkOld('secretNetworkOld', 77),
  secretNetworkNew('secretNetworkNew', 78),

  // Solana
  solana('solana', 79),
  solanaTestnet('solanaTestnet', 80),

  // Stellar
  stellar('stellar', 81),
  stellarTestnet('stellarTestnet', 82),

  // Terra
  terra('terra', 83),

  // Tezos
  tezos('tezos', 84),

  // Theta
  theta('theta', 85),

  // Tron
  tron('tron', 86),
  tronTestnet('tronTestnet', 87),

  // VeChain
  vechain('vechain', 88),

  // Verge
  verge('verge', 89),

  // Zcash
  zcash('zcash', 90),

  // Zilliqa
  zilliqa('zilliqa', 91),

  // Electra
  electraProtocol('electraProtocol', 92),

  // -------- Testnets --------
  bitcoinCashTestnet('bitcoinCashTestnet', 93),
  bitcoinCashSlpTestnet('bitcoinCashSlpTestnet', 94),
  bitcoinSvTestnet('bitcoinSvTestnet', 95),
  bitcoinTestnet('bitcoinTestnet', 96),
  dashTestnet('dashTestnet', 97),
  dogecoinTestnet('dogecoinTestnet', 98),
  pepecoinTestnet('pepecoinTestnet', 99),
  ecashTestnet('ecashTestnet', 100),
  ergoTestnet('ergoTestnet', 101),
  litecoinTestnet('litecoinTestnet', 102),
  zcashTestnet('zcashTestnet', 103),
  zcashRegtest('zcashRegtest', 104),

  tonTestnet('tonTestnet', 105),
  tonMainnet('tonMainnet', 106),

  electraProtocolTestnet('electraProtocolTestnet', 107);

  final String name;
  @override
  final int identifier;

  const Bip44Coins(this.name, this.identifier);
  @override
  Bip44Coins get value {
    return this;
  }

  @override
  String get coinName {
    return name;
  }

  @override
  BaseBipCoinConfig get conf {
    final config = Bip44Conf();
    return switch (this) {
      Bip44Coins.akashNetwork => config.akashNetwork,
      Bip44Coins.algorand => config.algorand,
      Bip44Coins.aptos => config.aptos,
      Bip44Coins.aptosEd25519SingleKey => config.aptosSingleKeyEd25519,
      Bip44Coins.aptosSecp256k1SingleKey => config.aptosSingleKeySecp256k1,
      Bip44Coins.sui => config.suiEd25519,
      Bip44Coins.suiSecp256k1 => config.suiSecp256k1,
      Bip44Coins.suiSecp256r1 => config.suiSecp256r1,
      Bip44Coins.avaxCChain => config.avaxCChain,
      Bip44Coins.avaxPChain => config.avaxPChain,
      Bip44Coins.avaxXChain => config.avaxXChain,
      Bip44Coins.axelar => config.axelar,
      Bip44Coins.bandProtocol => config.bandProtocol,
      Bip44Coins.binanceChain => config.binanceChain,
      Bip44Coins.binanceSmartChain => config.binanceSmartChain,
      Bip44Coins.bitcoin => config.bitcoinMainNet,
      Bip44Coins.bitcoinTestnet => config.bitcoinTestNet,
      Bip44Coins.bitcoinCash => config.bitcoinCashMainNet,
      Bip44Coins.bitcoinCashTestnet => config.bitcoinCashTestNet,
      Bip44Coins.bitcoinCashSlp => config.bitcoinCashSlpMainNet,
      Bip44Coins.bitcoinCashSlpTestnet => config.bitcoinCashSlpTestNet,
      Bip44Coins.bitcoinSv => config.bitcoinSvMainNet,
      Bip44Coins.bitcoinSvTestnet => config.bitcoinSvTestNet,
      Bip44Coins.cardanoByronIcarus => config.cardanoByronIcarus,
      Bip44Coins.cardanoByronLedger => config.cardanoByronLedger,
      Bip44Coins.cardanoByronIcarusTestnet => config.cardanoByronIcarusTestnet,
      Bip44Coins.cardanoByronLedgerTestnet => config.cardanoByronLedgerTestnet,
      Bip44Coins.celo => config.celo,
      Bip44Coins.certik => config.certik,
      Bip44Coins.chihuahua => config.chihuahua,
      Bip44Coins.cosmos => config.cosmos,
      Bip44Coins.cosmosTestnet => config.cosmosTestnet,
      Bip44Coins.cosmosNist256p1 => config.cosmosNist256p1,
      Bip44Coins.cosmosTestnetNist256p1 => config.cosmosTestnetNist256p1,
      Bip44Coins.cosmosEd25519 => config.cosmosEd25519,
      Bip44Coins.cosmosTestnetEd25519 => config.cosmosTestnetEd25519,
      Bip44Coins.cosmosEthSecp256k1 => config.cosmosEthSecp256k1,
      Bip44Coins.cosmosTestnetEthSecp256k1 => config.cosmosTestnetEthSecp256k1,
      Bip44Coins.dash => config.dashMainNet,
      Bip44Coins.dashTestnet => config.dashTestNet,
      Bip44Coins.dogecoin => config.dogecoinMainNet,
      Bip44Coins.dogecoinTestnet => config.dogecoinTestNet,
      Bip44Coins.pepecoin => config.pepeMainnet,
      Bip44Coins.pepecoinTestnet => config.pepeTestnet,
      Bip44Coins.ecash => config.ecashMainNet,
      Bip44Coins.ecashTestnet => config.ecashTestNet,
      Bip44Coins.elrond => config.elrond,
      Bip44Coins.eos => config.eos,
      Bip44Coins.ergo => config.ergoMainNet,
      Bip44Coins.ergoTestnet => config.ergoTestNet,
      Bip44Coins.ethereum => config.ethereum,
      Bip44Coins.ethereumTestnet => config.ethereumTestnet,
      Bip44Coins.ethereumClassic => config.ethereumClassic,
      Bip44Coins.fantomOpera => config.fantomOpera,
      Bip44Coins.filecoin => config.filecoin,
      Bip44Coins.harmonyOneAtom => config.harmonyOneAtom,
      Bip44Coins.harmonyOneEth => config.harmonyOneEth,
      Bip44Coins.harmonyOneMetamask => config.harmonyOneMetamask,
      Bip44Coins.huobiChain => config.huobiChain,
      Bip44Coins.icon => config.icon,
      Bip44Coins.injective => config.injective,
      Bip44Coins.irisNet => config.irisNet,
      Bip44Coins.kava => config.kava,
      Bip44Coins.kusamaEd25519Slip => config.kusamaEd25519Slip,
      Bip44Coins.kusamaTestnetEd25519Slip => config.kusamaTestnetEd25519Slip,
      Bip44Coins.litecoin => config.litecoinMainNet,
      Bip44Coins.litecoinTestnet => config.litecoinTestNet,
      Bip44Coins.moneroEd25519Slip => config.moneroEd25519Slip,
      Bip44Coins.moneroSecp256k1 => config.moneroSecp256k1,
      Bip44Coins.nano => config.nano,
      Bip44Coins.nearProtocol => config.nearProtocol,
      Bip44Coins.neo => config.neo,
      Bip44Coins.nineChroniclesGold => config.nineChroniclesGold,
      Bip44Coins.okexChainAtom => config.okexChainAtom,
      Bip44Coins.okexChainAtomOld => config.okexChainAtomOld,
      Bip44Coins.okexChainEth => config.okexChainEth,
      Bip44Coins.ontology => config.ontology,
      Bip44Coins.osmosis => config.osmosis,
      Bip44Coins.piNetwork => config.piNetwork,
      Bip44Coins.polkadotEd25519Slip => config.polkadotEd25519Slip,
      Bip44Coins.polkadotTestnetEd25519Slip =>
        config.polkadotTestnetEd25519Slip,
      Bip44Coins.polygon => config.polygon,
      Bip44Coins.ripple => config.ripple,
      Bip44Coins.rippleTestnet => config.rippleTestnet,
      Bip44Coins.rippleEd25519 => config.rippleEd25519,
      Bip44Coins.rippleTestnetED25519 => config.rippleTestnetEd25519,
      Bip44Coins.secretNetworkOld => config.secretNetworkOld,
      Bip44Coins.secretNetworkNew => config.secretNetworkNew,
      Bip44Coins.solana => config.solana,
      Bip44Coins.solanaTestnet => config.solanaTestnet,
      Bip44Coins.stellar => config.stellar,
      Bip44Coins.stellarTestnet => config.stellarTestnet,
      Bip44Coins.terra => config.terra,
      Bip44Coins.tezos => config.tezos,
      Bip44Coins.theta => config.theta,
      Bip44Coins.tron => config.tron,
      Bip44Coins.tronTestnet => config.tronTestnet,
      Bip44Coins.vechain => config.vechain,
      Bip44Coins.verge => config.verge,
      Bip44Coins.zcash => config.zcashMainNet,
      Bip44Coins.zcashTestnet => config.zcashTestNet,
      Bip44Coins.zcashRegtest => config.zcashRegtest,
      Bip44Coins.zilliqa => config.zilliqa,
      Bip44Coins.tonTestnet => config.tonTestnet,
      Bip44Coins.tonMainnet => config.tonMainnet,
      Bip44Coins.electraProtocol => config.electraProtocolMainNet,
      Bip44Coins.electraProtocolTestnet => config.electraProtocolTestNet,
    };
  }

  static Bip44Coins? fromName(String name) {
    return values.firstWhereNullable((element) => element.name == name);
  }

  @override
  CoinProposal get proposal => CoinProposal.bip44;

  @override
  String toString() {
    return "Bip44Coins.$name";
  }
}
