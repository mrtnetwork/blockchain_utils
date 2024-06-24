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
class Bip44Coins implements CryptoCoins {
  // Named constants representing each coin
  const Bip44Coins._(this.name);

  final String name;

  /// Akash Network
  static const akashNetwork = Bip44Coins._('akashNetwork');

  /// Algorand
  static const algorand = Bip44Coins._('algorand');

  /// Aptos
  static const aptos = Bip44Coins._('aptos');

  /// Avalanche C-Chain
  static const avaxCChain = Bip44Coins._('avaxCChain');

  /// Avalanche P-Chain
  static const avaxPChain = Bip44Coins._('avaxPChain');

  /// Avalanche X-Chain
  static const avaxXChain = Bip44Coins._('avaxXChain');

  /// Axelar
  static const axelar = Bip44Coins._('axelar');

  /// Band Protocol
  static const bandProtocol = Bip44Coins._('bandProtocol');

  /// Binance Chain
  static const binanceChain = Bip44Coins._('binanceChain');

  /// Binance Smart Chain
  static const binanceSmartChain = Bip44Coins._('binanceSmartChain');

  /// Bitcoin
  static const bitcoin = Bip44Coins._('bitcoin');

  /// Bitcoin Cash
  static const bitcoinCash = Bip44Coins._('bitcoinCash');

  /// Bitcoin Cash SLP
  static const bitcoinCashSlp = Bip44Coins._('bitcoinCashSlp');

  /// Bitcoin SV
  static const bitcoinSv = Bip44Coins._('bitcoinSv');

  /// Cardano Byron Icarus
  static const cardanoByronIcarus = Bip44Coins._('cardanoByronIcarus');

  /// Cardano Byron Ledger
  static const cardanoByronLedger = Bip44Coins._('cardanoByronLedger');

  /// Cardano Byron Icarus
  static const cardanoByronIcarusTestnet =
      Bip44Coins._('cardanoByronIcarusTestnet');

  /// Cardano Byron Ledger
  static const cardanoByronLedgerTestnet =
      Bip44Coins._('cardanoByronLedgerTestnet');

  /// Celo
  static const celo = Bip44Coins._('celo');

  /// Certik
  static const certik = Bip44Coins._('certik');

  /// Chihuahua
  static const chihuahua = Bip44Coins._('chihuahua');

  /// Cosmos
  static const cosmos = Bip44Coins._('cosmos');

  /// Cosmos
  static const cosmosTestnet = Bip44Coins._('cosmosTestnet');

  /// Cosmos
  static const cosmosNist256p1 = Bip44Coins._('cosmosNist256p1');

  /// Cosmos
  static const cosmosTestnetNist256p1 = Bip44Coins._('cosmosTestnetNist256p1');

  /// Dash
  static const dash = Bip44Coins._('dash');

  /// Dogecoin
  static const dogecoin = Bip44Coins._('dogecoin');

  /// Pepecoin
  static const pepecoin = Bip44Coins._('pepecoin');

  /// eCash
  static const ecash = Bip44Coins._('ecash');

  /// Elrond
  static const elrond = Bip44Coins._('elrond');

  /// EOS
  static const eos = Bip44Coins._('eos');

  /// Ergo
  static const ergo = Bip44Coins._('ergo');

  /// Ethereum
  static const ethereum = Bip44Coins._('ethereum');

  /// Ethereum
  static const ethereumTestnet = Bip44Coins._('ethereumTestnet');

  /// Ethereum Classic
  static const ethereumClassic = Bip44Coins._('ethereumClassic');

  /// Fantom Opera
  static const fantomOpera = Bip44Coins._('fantomOpera');

  /// Filecoin
  static const filecoin = Bip44Coins._('filecoin');

  /// Harmony One Atom
  static const harmonyOneAtom = Bip44Coins._('harmonyOneAtom');

  /// Harmony One Eth
  static const harmonyOneEth = Bip44Coins._('harmonyOneEth');

  /// Harmony One Metamask
  static const harmonyOneMetamask = Bip44Coins._('harmonyOneMetamask');

  /// Huobi Chain
  static const huobiChain = Bip44Coins._('huobiChain');

  /// ICON
  static const icon = Bip44Coins._('icon');

  /// Injective
  static const injective = Bip44Coins._('injective');

  /// IrisNet
  static const irisNet = Bip44Coins._('irisNet');

  /// Kava
  static const kava = Bip44Coins._('kava');

  /// Kusama Ed25519 Slip
  static const kusamaEd25519Slip = Bip44Coins._('kusamaEd25519Slip');

  /// Litecoin
  static const litecoin = Bip44Coins._('litecoin');

  /// Monero Ed25519 Slip
  static const moneroEd25519Slip = Bip44Coins._('moneroEd25519Slip');

  /// Monero Secp256k1
  static const moneroSecp256k1 = Bip44Coins._('moneroSecp256k1');

  /// Nano
  static const nano = Bip44Coins._('nano');

  /// Near Protocol
  static const nearProtocol = Bip44Coins._('nearProtocol');

  /// NEO
  static const neo = Bip44Coins._('neo');

  /// Nine Chronicles Gold
  static const nineChroniclesGold = Bip44Coins._('nineChroniclesGold');

  /// OKEx Chain Atom
  static const okexChainAtom = Bip44Coins._('okexChainAtom');

  /// OKEx Chain Atom (Old)
  static const okexChainAtomOld = Bip44Coins._('okexChainAtomOld');

  /// OKEx Chain ETH
  static const okexChainEth = Bip44Coins._('okexChainEth');

  /// Ontology
  static const ontology = Bip44Coins._('ontology');

  /// Osmosis
  static const osmosis = Bip44Coins._('osmosis');

  /// Pi Network
  static const piNetwork = Bip44Coins._('piNetwork');

  /// Polkadot Ed25519 Slip
  static const polkadotEd25519Slip = Bip44Coins._('polkadotEd25519Slip');

  /// Polygon
  static const polygon = Bip44Coins._('polygon');

  /// Ripple
  static const ripple = Bip44Coins._('ripple');

  /// Ripple Testnet
  static const rippleTestnet = Bip44Coins._('rippleTestnet');

  /// Ripple
  static const rippleEd25519 = Bip44Coins._('rippleED25519');

  /// Ripple Testnet
  static const rippleTestnetED25519 = Bip44Coins._('rippleTestnetED25519');

  /// Secret Network (Old)
  static const secretNetworkOld = Bip44Coins._('secretNetworkOld');

  /// Secret Network (New)
  static const secretNetworkNew = Bip44Coins._('secretNetworkNew');

  /// Solana
  static const solana = Bip44Coins._('solana');

  /// Solana
  static const solanaTestnet = Bip44Coins._('solanaTestnet');

  /// Stellar
  static const stellar = Bip44Coins._('stellar');

  /// Terra
  static const terra = Bip44Coins._('terra');

  /// Tezos
  static const tezos = Bip44Coins._('tezos');

  /// Theta
  static const theta = Bip44Coins._('theta');

  /// Tron
  static const tron = Bip44Coins._('tron');

  /// Tron
  static const tronTestnet = Bip44Coins._('tronTestnet');

  /// VeChain
  static const vechain = Bip44Coins._('vechain');

  /// Verge
  static const verge = Bip44Coins._('verge');

  /// Zcash
  static const zcash = Bip44Coins._('zcash');

  /// Zilliqa
  static const zilliqa = Bip44Coins._('zilliqa');

  // Test nets

  /// Bitcoin Cash Testnet
  static const bitcoinCashTestnet = Bip44Coins._('bitcoinCashTestnet');

  /// Bitcoin Cash SLP Testnet
  static const bitcoinCashSlpTestnet = Bip44Coins._('bitcoinCashSlpTestnet');

  /// Bitcoin SV Testnet
  static const bitcoinSvTestnet = Bip44Coins._('bitcoinSvTestnet');

  /// Bitcoin Testnet
  static const bitcoinTestnet = Bip44Coins._('bitcoinTestnet');

  /// Dash Testnet
  static const dashTestnet = Bip44Coins._('dashTestnet');

  /// Dogecoin Testnet
  static const dogecoinTestnet = Bip44Coins._('dogecoinTestnet');

  /// Pepecoin Testnet
  static const pepecoinTestnet = Bip44Coins._('pepecoinTestnet');

  /// eCash Testnet
  static const ecashTestnet = Bip44Coins._('ecashTestnet');

  /// Ergo Testnet
  static const ergoTestnet = Bip44Coins._('ergoTestnet');

  /// Litecoin Testnet
  static const litecoinTestnet = Bip44Coins._('litecoinTestnet');

  /// Zcash Testnet
  static const zcashTestnet = Bip44Coins._('zcashTestnet');

  /// Ton Testnet
  static const tonTestnet = Bip44Coins._('tonTestnet');

  /// Ton Testnet
  static const tonMainnet = Bip44Coins._('tonMainnet');

  // Fields and methods

  @override
  Bip44Coins get value {
    return this;
  }

  @override
  String get coinName {
    return name;
  }

  @override
  CoinConfig get conf => _coinToConf[this]!;

  static Bip44Coins? fromName(String name) {
    try {
      return _coinToConf.keys.firstWhere((element) => element.name == name);
    } on StateError {
      return null;
    }
  }

  static List<Bip44Coins> get values => _coinToConf.keys.toList();

  /// A mapping that associates each BIP44Coin (enum) with its corresponding
  /// CoinConfig configuration.
  static final Map<Bip44Coins, CoinConfig> _coinToConf = {
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
    Bip44Coins.cardanoByronIcarusTestnet: Bip44Conf.cardanoByronIcarusTestnet,
    Bip44Coins.cardanoByronLedgerTestnet: Bip44Conf.cardanoByronLedgerTestnet,
    Bip44Coins.celo: Bip44Conf.celo,
    Bip44Coins.certik: Bip44Conf.certik,
    Bip44Coins.chihuahua: Bip44Conf.chihuahua,
    Bip44Coins.cosmos: Bip44Conf.cosmos,
    Bip44Coins.cosmosTestnet: Bip44Conf.cosmosTestnet,
    Bip44Coins.cosmosNist256p1: Bip44Conf.cosmosNist256p1,
    Bip44Coins.cosmosTestnetNist256p1: Bip44Conf.cosmosTestnetNist256p1,
    Bip44Coins.dash: Bip44Conf.dashMainNet,
    Bip44Coins.dashTestnet: Bip44Conf.dashTestNet,
    Bip44Coins.dogecoin: Bip44Conf.dogecoinMainNet,
    Bip44Coins.dogecoinTestnet: Bip44Conf.dogecoinTestNet,
    Bip44Coins.pepecoin: Bip44Conf.pepeMainnet,
    Bip44Coins.pepecoinTestnet: Bip44Conf.pepeTestnet,
    Bip44Coins.ecash: Bip44Conf.ecashMainNet,
    Bip44Coins.ecashTestnet: Bip44Conf.ecashTestNet,
    Bip44Coins.elrond: Bip44Conf.elrond,
    Bip44Coins.eos: Bip44Conf.eos,
    Bip44Coins.ergo: Bip44Conf.ergoMainNet,
    Bip44Coins.ergoTestnet: Bip44Conf.ergoTestNet,
    Bip44Coins.ethereum: Bip44Conf.ethereum,
    Bip44Coins.ethereumTestnet: Bip44Conf.ethereumTestnet,
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
    Bip44Coins.rippleEd25519: Bip44Conf.rippleEd25519,
    Bip44Coins.rippleTestnetED25519: Bip44Conf.rippleTestnetEd25519,
    Bip44Coins.secretNetworkOld: Bip44Conf.secretNetworkOld,
    Bip44Coins.secretNetworkNew: Bip44Conf.secretNetworkNew,
    Bip44Coins.solana: Bip44Conf.solana,
    Bip44Coins.solanaTestnet: Bip44Conf.solanaTestnet,
    Bip44Coins.stellar: Bip44Conf.stellar,
    Bip44Coins.terra: Bip44Conf.terra,
    Bip44Coins.tezos: Bip44Conf.tezos,
    Bip44Coins.theta: Bip44Conf.theta,
    Bip44Coins.tron: Bip44Conf.tron,
    Bip44Coins.tronTestnet: Bip44Conf.tronTestnet,
    Bip44Coins.vechain: Bip44Conf.vechain,
    Bip44Coins.verge: Bip44Conf.verge,
    Bip44Coins.zcash: Bip44Conf.zcashMainNet,
    Bip44Coins.zcashTestnet: Bip44Conf.zcashTestNet,
    Bip44Coins.zilliqa: Bip44Conf.zilliqa,
    Bip44Coins.tonTestnet: Bip44Conf.tonTestnet,
    Bip44Coins.tonMainnet: Bip44Conf.tonMainnet,
  };
  @override
  BipProposal get proposal => BipProposal.bip44;

  @override
  String toString() {
    return "Bip44Coins.$name";
  }
}
