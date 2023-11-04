/// Bitcoin key net version for main net (same as BIP32)

import 'package:blockchain_utils/bip/address/ada_byron_addr.dart';
import 'package:blockchain_utils/bip/address/algo_addr.dart';
import 'package:blockchain_utils/bip/address/aptos_addr.dart';
import 'package:blockchain_utils/bip/address/atom_addr.dart';
import 'package:blockchain_utils/bip/address/avax_addr.dart';
import 'package:blockchain_utils/bip/address/egld_addr.dart';
import 'package:blockchain_utils/bip/address/eos_addr.dart';
import 'package:blockchain_utils/bip/address/ergo.dart';
import 'package:blockchain_utils/bip/address/eth_addr.dart';
import 'package:blockchain_utils/bip/address/fil_addr.dart';
import 'package:blockchain_utils/bip/address/icx_addr.dart';
import 'package:blockchain_utils/bip/address/inj_addr.dart';
import 'package:blockchain_utils/bip/address/nano_addr.dart';
import 'package:blockchain_utils/bip/address/near_addr.dart';
import 'package:blockchain_utils/bip/address/neo_addr.dart';
import 'package:blockchain_utils/bip/address/okex_addr.dart';
import 'package:blockchain_utils/bip/address/one_addr.dart';
import 'package:blockchain_utils/bip/address/p2pkh_addr.dart';
import 'package:blockchain_utils/bip/address/sol_addr.dart';
import 'package:blockchain_utils/bip/address/substrate_addr.dart';
import 'package:blockchain_utils/bip/address/trx_addr.dart';
import 'package:blockchain_utils/bip/address/xlm_addr.dart';
import 'package:blockchain_utils/bip/address/xmr_addr.dart';
import 'package:blockchain_utils/bip/address/xrp_addr.dart';
import 'package:blockchain_utils/bip/address/xtz_addr.dart';
import 'package:blockchain_utils/bip/address/zil_addr.dart';
import 'package:blockchain_utils/bip/bip/bip32/bip32_const.dart';
import 'package:blockchain_utils/bip/bip/bip32/bip32_key_net_ver.dart';
import 'package:blockchain_utils/bip/bip/conf/bip44/bip44_coins.dart';
import 'package:blockchain_utils/bip/bip/conf/bip_bitcoin_cash_conf.dart';
import 'package:blockchain_utils/bip/bip/conf/bip_coin_conf.dart';
import 'package:blockchain_utils/bip/bip/conf/bip_coins.dart';
import 'package:blockchain_utils/bip/bip/conf/bip_conf_const.dart';
import 'package:blockchain_utils/bip/bip/conf/bip_litecoin_conf.dart';
import 'package:blockchain_utils/bip/coin_conf/coins_conf.dart';
import 'package:blockchain_utils/bip/ecc/curve/elliptic_curve_types.dart';
import 'package:blockchain_utils/bip/slip/slip44/slip44.dart';

/// A configuration class for BIP44 coins that defines the key network versions and
/// maps each supported BIP44Coin to its corresponding BipCoinConf.
class Bip44Conf {
  /// The key network version for the mainnet of Bitcoin.
  static final Bip32KeyNetVersions bip44BtcKeyNetVerMain =
      Bip32Const.mainNetKeyNetVersions;

  /// The key network version for the testnet of Bitcoin.
  static final Bip32KeyNetVersions bip44BtcKeyNetVerTest =
      Bip32Const.testNetKeyNetVersions;

  /// Retrieves the BipCoinConf for the given BIP44Coin. If the provided coin
  /// is not an instance of Bip44Coins, an error is thrown.
  static BipCoinConf getCoin(BipCoins coin) {
    if (coin is! Bip44Coins) {
      throw ArgumentError("Coin type is not an enumerative of Bip44Coins");
    }

    return coinToConf[coin.value]!;
  }

  /// A mapping that associates each BIP44Coin (enum) with its corresponding
  /// BipCoinConf configuration.
  static Map<Bip44Coins, BipCoinConf> coinToConf = {
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

  /// Configuration for Akash Network
  static final BipCoinConf akashNetwork = BipCoinConf(
    coinNames: CoinsConf.akashNetwork.coinName,
    coinIdx: Slip44.atom,
    isTestnet: false,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder: ([dynamic kwargs]) => AtomAddrEncoder(),
    addrParams: {
      "hrp": CoinsConf.akashNetwork.getParam("addr_hrp"),
    },
  );

  /// Configuration for Algorand
  static final BipCoinConf algorand = BipCoinConf(
    coinNames: CoinsConf.algorand.coinName,
    addressEncoder: ([dynamic kwargs]) => AlgoAddrEncoder(),
    coinIdx: Slip44.algorand,
    isTestnet: false,
    defPath: derPathHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.ed25519,
    addrParams: {},
  );

  /// Configuration for Aptos
  static final BipCoinConf aptos = BipCoinConf(
    coinNames: CoinsConf.aptos.coinName,
    coinIdx: Slip44.aptos,
    isTestnet: false,
    defPath: derPathHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.ed25519,
    addressEncoder: ([dynamic kwargs]) => AptosAddrEncoder(),
    addrParams: {},
  );

  /// Configuration for Avax C-Chain
  static final BipCoinConf avaxCChain = BipCoinConf(
    coinNames: CoinsConf.avaxCChain.coinName,
    coinIdx: Slip44.ethereum,
    isTestnet: false,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder: ([dynamic kwargs]) => EthAddrEncoder(),
    addrParams: {},
  );

  /// Configuration for Avax P-Chain
  static final BipCoinConf avaxPChain = BipCoinConf(
    coinNames: CoinsConf.avaxPChain.coinName,
    coinIdx: Slip44.avalanche,
    isTestnet: false,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder: ([dynamic kwargs]) => AvaxPChainAddrEncoder(),
    addrParams: {},
  );

  /// Configuration for Avax X-Chain
  static final BipCoinConf avaxXChain = BipCoinConf(
    coinNames: CoinsConf.avaxXChain.coinName,
    coinIdx: Slip44.avalanche,
    isTestnet: false,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder: ([dynamic kwargs]) => AvaxXChainAddrEncoder(),
    addrParams: {},
  );

  /// Configuration for Axelar
  static final BipCoinConf axelar = BipCoinConf(
    coinNames: CoinsConf.axelar.coinName,
    coinIdx: Slip44.atom,
    isTestnet: false,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder: ([dynamic kwargs]) => AtomAddrEncoder(),
    addrParams: {
      "hrp": CoinsConf.axelar.getParam("addr_hrp"),
    },
  );

  /// Configuration for Band Protocol
  static final BipCoinConf bandProtocol = BipCoinConf(
    coinNames: CoinsConf.bandProtocol.coinName,
    coinIdx: Slip44.bandProtocol,
    isTestnet: false,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder: ([dynamic kwargs]) => AtomAddrEncoder(),
    addrParams: {
      "hrp": CoinsConf.bandProtocol.getParam("addr_hrp"),
    },
  );

  /// Configuration for Binance Chain
  static final BipCoinConf binanceChain = BipCoinConf(
    coinNames: CoinsConf.binanceChain.coinName,
    coinIdx: Slip44.binanceChain,
    isTestnet: false,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder: ([dynamic kwargs]) => AtomAddrEncoder(),
    addrParams: {
      "hrp": CoinsConf.binanceChain.getParam("addr_hrp"),
    },
  );

  /// Configuration for Binance Smart Chain
  static final BipCoinConf binanceSmartChain = BipCoinConf(
    coinNames: CoinsConf.binanceSmartChain.coinName,
    coinIdx: Slip44.ethereum,
    isTestnet: false,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder: ([dynamic kwargs]) => EthAddrEncoder(),
    addrParams: {},
  );

  /// Configuration for Bitcoin main net
  static final BipCoinConf bitcoinMainNet = BipCoinConf(
    coinNames: CoinsConf.bitcoinMainNet.coinName,
    coinIdx: Slip44.bitcoin,
    isTestnet: false,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: CoinsConf.bitcoinMainNet.getParam("wif_net_ver"),
    type: EllipticCurveTypes.secp256k1,
    addressEncoder: ([dynamic kwargs]) => P2PKHAddrEncoder(),
    addrParams: {
      "net_ver": CoinsConf.bitcoinMainNet.getParam("p2pkh_net_ver"),
    },
  );

  /// Configuration for Bitcoin test net
  static final BipCoinConf bitcoinTestNet = BipCoinConf(
    coinNames: CoinsConf.bitcoinTestNet.coinName,
    coinIdx: Slip44.testnet,
    isTestnet: true,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerTest,
    wifNetVer: CoinsConf.bitcoinTestNet.getParam("wif_net_ver"),
    type: EllipticCurveTypes.secp256k1,
    addressEncoder: ([dynamic kwargs]) => P2PKHAddrEncoder(),
    addrParams: {
      "net_ver": CoinsConf.bitcoinTestNet.getParam("p2pkh_net_ver"),
    },
  );

  /// Configuration for Bitcoin Cash main net
  static final BipBitcoinCashConf bitcoinCashMainNet = BipBitcoinCashConf(
    coinNames: CoinsConf.bitcoinCashMainNet.coinName,
    coinIdx: Slip44.bitcoinCash,
    isTestnet: false,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: CoinsConf.bitcoinCashMainNet.getParam("wif_net_ver"),
    type: EllipticCurveTypes.secp256k1,
    addressEncoder: ([dynamic legacy]) {
      if (legacy == true) {
        return P2PKHAddrEncoder();
      }
      return BchP2PKHAddrEncoder();
    },
    addrParams: {
      "std": {
        "net_ver": CoinsConf.bitcoinCashMainNet.getParam("p2pkh_std_net_ver"),
        "hrp": CoinsConf.bitcoinCashMainNet.getParam("p2pkh_std_hrp"),
      },
      "legacy": {
        "net_ver":
            CoinsConf.bitcoinCashMainNet.getParam("p2pkh_legacy_net_ver"),
      }
    },
  );

  /// Configuration for Bitcoin Cash test net
  static final BipBitcoinCashConf bitcoinCashTestNet = BipBitcoinCashConf(
    coinNames: CoinsConf.bitcoinCashTestNet.coinName,
    coinIdx: Slip44.testnet,
    isTestnet: true,
    defPath: derPathNonHardenedFull,
    addressEncoder: ([dynamic legacy]) {
      if (legacy == true) {
        return P2PKHAddrEncoder();
      }
      return BchP2PKHAddrEncoder();
    },
    keyNetVer: bip44BtcKeyNetVerTest,
    wifNetVer: CoinsConf.bitcoinCashTestNet.getParam("wif_net_ver"),
    type: EllipticCurveTypes.secp256k1,
    addrParams: {
      "std": {
        "net_ver": CoinsConf.bitcoinCashTestNet.getParam("p2pkh_std_net_ver"),
        "hrp": CoinsConf.bitcoinCashTestNet.getParam("p2pkh_std_hrp"),
      },
      "legacy": {
        "net_ver":
            CoinsConf.bitcoinCashTestNet.getParam("p2pkh_legacy_net_ver"),
      }
    },
  );

  /// Configuration for Bitcoin Cash Simple Ledger Protocol main net
  static final BipBitcoinCashConf bitcoinCashSlpMainNet = BipBitcoinCashConf(
    coinNames: CoinsConf.bitcoinCashSlpMainNet.coinName,
    coinIdx: Slip44.bitcoinCash,
    isTestnet: false,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: CoinsConf.bitcoinCashSlpMainNet.getParam("wif_net_ver"),
    type: EllipticCurveTypes.secp256k1,
    addressEncoder: ([dynamic legacy]) {
      if (legacy == true) {
        return P2PKHAddrEncoder();
      }
      return BchP2PKHAddrEncoder();
    },
    addrParams: {
      "std": {
        "net_ver":
            CoinsConf.bitcoinCashSlpMainNet.getParam("p2pkh_std_net_ver"),
        "hrp": CoinsConf.bitcoinCashSlpMainNet.getParam("p2pkh_std_hrp"),
      },
      "legacy": {
        "net_ver":
            CoinsConf.bitcoinCashSlpMainNet.getParam("p2pkh_legacy_net_ver"),
      }
    },
  );

  /// Configuration for Bitcoin Cash Simple Ledger Protocol test net
  static final BipBitcoinCashConf bitcoinCashSlpTestNet = BipBitcoinCashConf(
    coinNames: CoinsConf.bitcoinCashSlpTestNet.coinName,
    coinIdx: Slip44.testnet,
    isTestnet: true,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerTest,
    wifNetVer: CoinsConf.bitcoinCashSlpTestNet.getParam("wif_net_ver"),
    type: EllipticCurveTypes.secp256k1,
    addressEncoder: ([dynamic legacy]) {
      if (legacy == true) {
        return P2PKHAddrEncoder();
      }
      return BchP2PKHAddrEncoder();
    },
    addrParams: {
      "std": {
        "net_ver":
            CoinsConf.bitcoinCashSlpTestNet.getParam("p2pkh_std_net_ver"),
        "hrp": CoinsConf.bitcoinCashSlpTestNet.getParam("p2pkh_std_hrp"),
      },
      "legacy": {
        "net_ver":
            CoinsConf.bitcoinCashSlpTestNet.getParam("p2pkh_legacy_net_ver"),
      }
    },
  );

  /// Configuration for BitcoinSV main net
  static final BipCoinConf bitcoinSvMainNet = BipCoinConf(
    coinNames: CoinsConf.bitcoinSvMainNet.coinName,
    coinIdx: Slip44.bitcoinSv,
    isTestnet: false,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: CoinsConf.bitcoinSvMainNet.getParam("wif_net_ver"),
    type: EllipticCurveTypes.secp256k1,
    addressEncoder: ([dynamic legacy]) {
      return P2PKHAddrEncoder();
    },
    addrParams: {
      "net_ver": CoinsConf.bitcoinSvMainNet.getParam("p2pkh_net_ver"),
    },
  );

  /// Configuration for BitcoinSV test net
  static final BipCoinConf bitcoinSvTestNet = BipCoinConf(
    coinNames: CoinsConf.bitcoinSvTestNet.coinName,
    coinIdx: Slip44.testnet,
    isTestnet: true,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerTest,
    wifNetVer: CoinsConf.bitcoinSvTestNet.getParam("wif_net_ver"),
    type: EllipticCurveTypes.secp256k1,
    addressEncoder: ([dynamic kwargs]) => P2PKHAddrEncoder(),
    addrParams: {
      "net_ver": CoinsConf.bitcoinSvTestNet.getParam("p2pkh_net_ver"),
    },
  );

  static final BipCoinConf cardanoByronIcarus = BipCoinConf(
    coinNames: CoinsConf.cardanoMainNet.coinName,
    coinIdx: Slip44.cardano,
    isTestnet: false,
    defPath: derPathNonHardenedFull,
    keyNetVer: Bip32Const.kholawKeyNetVersions,
    wifNetVer: null,
    type: EllipticCurveTypes.ed25519Kholaw,
    addressEncoder: ([dynamic kwargs]) => AdaByronIcarusAddrEncoder(),
    addrParams: {
      "chain_code": true,
      "is_icarus": true,
    },
  );

  /// Configuration for Cardano Byron (Ledger)
  static final BipCoinConf cardanoByronLedger = BipCoinConf(
    coinNames: CoinsConf.cardanoMainNet.coinName,
    coinIdx: Slip44.cardano,
    isTestnet: false,
    defPath: derPathNonHardenedFull,
    keyNetVer: Bip32Const.kholawKeyNetVersions,
    wifNetVer: null,
    type: EllipticCurveTypes.ed25519Kholaw,
    addressEncoder: ([dynamic kwargs]) => AdaByronIcarusAddrEncoder(),
    addrParams: {
      "chain_code": true,
    },
  );

  /// Configuration for Celo
  static final BipCoinConf celo = BipCoinConf(
    coinNames: CoinsConf.celo.coinName,
    coinIdx: Slip44.celo,
    isTestnet: false,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder: ([dynamic kwargs]) => EthAddrEncoder(),
    addrParams: {},
  );

  /// Configuration for Certik
  static final BipCoinConf certik = BipCoinConf(
    coinNames: CoinsConf.certik.coinName,
    coinIdx: Slip44.atom,
    isTestnet: false,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder: ([dynamic kwargs]) => AtomAddrEncoder(),
    addrParams: {
      "hrp": CoinsConf.certik.getParam("addr_hrp"),
    },
  );

  /// Configuration for Chihuahua
  static final BipCoinConf chihuahua = BipCoinConf(
    coinNames: CoinsConf.chihuahua.coinName,
    coinIdx: Slip44.atom,
    isTestnet: false,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder: ([dynamic kwargs]) => AtomAddrEncoder(),
    addrParams: {
      "hrp": CoinsConf.chihuahua.getParam("addr_hrp"),
    },
  );

  /// Configuration for Cosmos
  static final BipCoinConf cosmos = BipCoinConf(
    coinNames: CoinsConf.cosmos.coinName,
    coinIdx: Slip44.atom,
    isTestnet: false,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder: ([dynamic kwargs]) => AtomAddrEncoder(),
    addrParams: {
      "hrp": CoinsConf.cosmos.getParam("addr_hrp"),
    },
  );

  /// Configuration for Dash main net
  static final BipCoinConf dashMainNet = BipCoinConf(
    coinNames: CoinsConf.dashMainNet.coinName,
    coinIdx: Slip44.dash,
    isTestnet: false,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: CoinsConf.dashMainNet.getParam("wif_net_ver"),
    type: EllipticCurveTypes.secp256k1,
    addressEncoder: ([dynamic kwargs]) => P2PKHAddrEncoder(),
    addrParams: {
      "net_ver": CoinsConf.dashMainNet.getParam("p2pkh_net_ver"),
    },
  );

  /// Configuration for Dash test net
  static final BipCoinConf dashTestNet = BipCoinConf(
    coinNames: CoinsConf.dashTestNet.coinName,
    coinIdx: Slip44.testnet,
    isTestnet: true,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerTest,
    wifNetVer: CoinsConf.dashTestNet.getParam("wif_net_ver"),
    type: EllipticCurveTypes.secp256k1,
    addressEncoder: ([dynamic kwargs]) => P2PKHAddrEncoder(),
    addrParams: {
      "net_ver": CoinsConf.dashTestNet.getParam("p2pkh_net_ver"),
    },
  );

  /// Configuration for Dogecoin main net
  static final BipCoinConf dogecoinMainNet = BipCoinConf(
    coinNames: CoinsConf.dogecoinMainNet.coinName,
    coinIdx: Slip44.dogecoin,
    isTestnet: false,
    defPath: derPathNonHardenedFull,
    keyNetVer: Bip32KeyNetVersions(List<int>.from([0x02, 0xfa, 0xca, 0xfd]),
        List<int>.from([0x02, 0xfa, 0xc3, 0x98])),
    wifNetVer: CoinsConf.dogecoinMainNet.getParam("wif_net_ver"),
    type: EllipticCurveTypes.secp256k1,
    addressEncoder: ([dynamic kwargs]) => P2PKHAddrEncoder(),
    addrParams: {
      "net_ver": CoinsConf.dogecoinMainNet.getParam("p2pkh_net_ver"),
    },
  );

  /// Configuration for Dogecoin test net
  static final BipCoinConf dogecoinTestNet = BipCoinConf(
    coinNames: CoinsConf.dogecoinTestNet.coinName,
    coinIdx: Slip44.testnet,
    isTestnet: true,
    defPath: derPathNonHardenedFull,
    keyNetVer: Bip32KeyNetVersions(List<int>.from([0x04, 0x32, 0xa9, 0xa8]),
        List<int>.from([0x04, 0x32, 0xa2, 0x43])),
    wifNetVer: CoinsConf.dogecoinTestNet.getParam("wif_net_ver"),
    type: EllipticCurveTypes.secp256k1,
    addressEncoder: ([dynamic kwargs]) => P2PKHAddrEncoder(),
    addrParams: {
      "net_ver": CoinsConf.dogecoinTestNet.getParam("p2pkh_net_ver"),
    },
  );

  /// Configuration for eCash main net
  static final BipBitcoinCashConf ecashMainNet = BipBitcoinCashConf(
    coinNames: CoinsConf.ecashMainNet.coinName,
    coinIdx: Slip44.bitcoinCash,
    isTestnet: false,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: CoinsConf.ecashMainNet.getParam("wif_net_ver"),
    type: EllipticCurveTypes.secp256k1,
    addressEncoder: ([dynamic legacy]) {
      if (legacy == true) {
        return P2PKHAddrEncoder();
      }
      return BchP2PKHAddrEncoder();
    },
    addrParams: {
      "std": {
        "net_ver": CoinsConf.ecashMainNet.getParam("p2pkh_std_net_ver"),
        "hrp": CoinsConf.ecashMainNet.getParam("p2pkh_std_hrp"),
      },
      "legacy": {
        "net_ver": CoinsConf.ecashMainNet.getParam("p2pkh_legacy_net_ver"),
      },
    },
  );

  /// Configuration for eCash test net
  static final BipBitcoinCashConf ecashTestNet = BipBitcoinCashConf(
    coinNames: CoinsConf.ecashTestNet.coinName,
    coinIdx: Slip44.testnet,
    isTestnet: true,
    addressEncoder: ([dynamic legacy]) {
      if (legacy == true) {
        return P2PKHAddrEncoder();
      }
      return BchP2PKHAddrEncoder();
    },
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerTest,
    wifNetVer: CoinsConf.ecashTestNet.getParam("wif_net_ver"),
    type: EllipticCurveTypes.secp256k1,
    addrParams: {
      "std": {
        "net_ver": CoinsConf.ecashTestNet.getParam("p2pkh_std_net_ver"),
        "hrp": CoinsConf.ecashTestNet.getParam("p2pkh_std_hrp"),
      },
      "legacy": {
        "net_ver": CoinsConf.ecashTestNet.getParam("p2pkh_legacy_net_ver"),
      },
    },

    /// addrClsLegacy: P2PKHAddrEncoder,
  );

  /// Configuration for Elrond
  static final BipCoinConf elrond = BipCoinConf(
    coinNames: CoinsConf.elrond.coinName,
    coinIdx: Slip44.elrond,
    isTestnet: false,
    defPath: derPathHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.ed25519,
    addressEncoder: ([dynamic kwargs]) => EgldAddrEncoder(),
    addrParams: {},
  );

  /// Configuration for Eos
  static final BipCoinConf eos = BipCoinConf(
    coinNames: CoinsConf.eos.coinName,
    coinIdx: Slip44.eos,
    isTestnet: false,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.secp256k1,
    addrParams: {},
    addressEncoder: ([dynamic kwargs]) => EosAddrEncoder(),
  );

  /// Configuration for Ergo main net
  static final BipCoinConf ergoMainNet = BipCoinConf(
    coinNames: CoinsConf.ergoMainNet.coinName,
    coinIdx: Slip44.ergo,
    isTestnet: false,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder: ([dynamic kwargs]) => ErgoP2PKHAddrEncoder(),
    addrParams: {
      "net_type": ErgoNetworkTypes.mainnet,
    },
  );

  /// Configuration for Ergo test net
  static final BipCoinConf ergoTestNet = BipCoinConf(
    coinNames: CoinsConf.ergoTestNet.coinName,
    coinIdx: Slip44.ergo,
    isTestnet: true,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerTest,
    wifNetVer: null,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder: ([dynamic kwargs]) => ErgoP2PKHAddrEncoder(),
    addrParams: {
      "net_type": ErgoNetworkTypes.testnet,
    },
  );

  /// Configuration for Ethereum
  static final BipCoinConf ethereum = BipCoinConf(
    coinNames: CoinsConf.ethereum.coinName,
    coinIdx: Slip44.ethereum,
    isTestnet: false,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder: ([dynamic kwargs]) => EthAddrEncoder(),
    addrParams: {},
  );

  /// Configuration for Ethereum Classic
  static final BipCoinConf ethereumClassic = BipCoinConf(
    coinNames: CoinsConf.ethereumClassic.coinName,
    coinIdx: Slip44.ethereumClassic,
    isTestnet: false,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder: ([dynamic kwargs]) => EthAddrEncoder(),
    addrParams: {},
  );

  /// Configuration for Fantom Opera
  static final BipCoinConf fantomOpera = BipCoinConf(
    coinNames: CoinsConf.fantomOpera.coinName,
    coinIdx: Slip44.ethereum,
    isTestnet: false,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder: ([dynamic kwargs]) => EthAddrEncoder(),
    addrParams: {},
  );

  /// Configuration for Filecoin
  static final BipCoinConf filecoin = BipCoinConf(
    coinNames: CoinsConf.filecoin.coinName,
    coinIdx: Slip44.filecoin,
    isTestnet: false,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder: ([dynamic kwargs]) => FilSecp256k1AddrEncoder(),
    addrParams: {},
  );

  /// Configuration for Harmony One (Metamask address)
  static final BipCoinConf harmonyOneMetamask = BipCoinConf(
    coinNames: CoinsConf.harmonyOne.coinName,
    coinIdx: Slip44.ethereum,
    isTestnet: false,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder: ([dynamic kwargs]) => EthAddrEncoder(),
    addrParams: {},
  );

  /// Configuration for Harmony One (Ethereum address)
  static final BipCoinConf harmonyOneEth = BipCoinConf(
    coinNames: CoinsConf.harmonyOne.coinName,
    coinIdx: Slip44.harmonyOne,
    isTestnet: false,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder: ([dynamic kwargs]) => EthAddrEncoder(),
    addrParams: {},
  );

  /// Configuration for Harmony One (Atom address)
  static final BipCoinConf harmonyOneAtom = BipCoinConf(
    coinNames: CoinsConf.harmonyOne.coinName,
    coinIdx: Slip44.harmonyOne,
    isTestnet: false,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder: ([dynamic kwargs]) => OneAddrEncoder(),
    addrParams: {},
  );

  /// Configuration for Huobi Chain
  static final BipCoinConf huobiChain = BipCoinConf(
    coinNames: CoinsConf.huobiChain.coinName,
    coinIdx: Slip44.ethereum,
    isTestnet: false,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder: ([dynamic kwargs]) => EthAddrEncoder(),
    addrParams: {},
  );

  /// Configuration for Icon
  static final BipCoinConf icon = BipCoinConf(
    coinNames: CoinsConf.icon.coinName,
    coinIdx: Slip44.icon,
    isTestnet: false,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder: ([dynamic kwargs]) => IcxAddrEncoder(),
    addrParams: {},
  );

  /// Configuration for Injective
  static final BipCoinConf injective = BipCoinConf(
    coinNames: CoinsConf.injective.coinName,
    coinIdx: Slip44.ethereum,
    isTestnet: false,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder: ([dynamic kwargs]) => InjAddrEncoder(),
    addrParams: {},
  );

  /// Configuration for IRISnet
  static final BipCoinConf irisNet = BipCoinConf(
    coinNames: CoinsConf.irisNet.coinName,
    coinIdx: Slip44.atom,
    isTestnet: false,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder: ([dynamic kwargs]) => AtomAddrEncoder(),
    addrParams: {
      "hrp": CoinsConf.irisNet.getParam("addr_hrp"),
    },
  );

  /// Configuration for Kava
  static final BipCoinConf kava = BipCoinConf(
    coinNames: CoinsConf.kava.coinName,
    coinIdx: Slip44.kava,
    isTestnet: false,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder: ([dynamic kwargs]) => AtomAddrEncoder(),
    addrParams: {
      "hrp": CoinsConf.kava.getParam("addr_hrp"),
    },
  );

  /// Configuration for Kusama (ed25519 SLIP-0010)
  static final BipCoinConf kusamaEd25519Slip = BipCoinConf(
    coinNames: CoinsConf.kusama.coinName,
    coinIdx: Slip44.kusama,
    isTestnet: false,
    defPath: derPathHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.ed25519,
    addressEncoder: ([dynamic kwargs]) => SubstrateEd25519AddrEncoder(),
    addrParams: {
      "ss58_format": CoinsConf.kusama.getParam("addr_ss58_format"),
    },
  );

  /// Configuration for Litecoin main net
  static final BipLitecoinConf litecoinMainNet = BipLitecoinConf(
    coinNames: CoinsConf.litecoinMainNet.coinName,
    coinIdx: Slip44.litecoin,
    isTestnet: false,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    addressEncoder: ([dynamic kwargs]) => P2PKHAddrEncoder(),
    altKeyNetVer: Bip32KeyNetVersions(
      List<int>.from([0x01, 0x9d, 0xa4, 0x62]),
      List<int>.from([0x01, 0x9d, 0x9c, 0xfe]),
    ),
    wifNetVer: CoinsConf.litecoinMainNet.getParam("wif_net_ver"),
    type: EllipticCurveTypes.secp256k1,
    addrParams: {
      "std_net_ver": CoinsConf.litecoinMainNet.getParam("p2pkh_std_net_ver"),
      "depr_net_ver": CoinsConf.litecoinMainNet.getParam("p2pkh_depr_net_ver"),
    },
  );

  /// Configuration for Litecoin test net
  static final BipLitecoinConf litecoinTestNet = BipLitecoinConf(
    coinNames: CoinsConf.litecoinTestNet.coinName,
    coinIdx: Slip44.testnet,
    isTestnet: true,
    defPath: derPathNonHardenedFull,
    keyNetVer: Bip32KeyNetVersions(
      List<int>.from([0x04, 0x36, 0xf6, 0xe1]),
      List<int>.from([0x04, 0x36, 0xef, 0x7d]),
    ),
    altKeyNetVer: Bip32KeyNetVersions(
      List<int>.from([0x04, 0x36, 0xf6, 0xe1]),
      List<int>.from([0x04, 0x36, 0xef, 0x7d]),
    ),
    wifNetVer: CoinsConf.litecoinTestNet.getParam("wif_net_ver"),
    type: EllipticCurveTypes.secp256k1,
    addressEncoder: ([dynamic kwargs]) => P2PKHAddrEncoder(),
    addrParams: {
      "std_net_ver": CoinsConf.litecoinTestNet.getParam("p2pkh_std_net_ver"),
      "depr_net_ver": CoinsConf.litecoinTestNet.getParam("p2pkh_depr_net_ver"),
    },
  );

  /// Configuration for Monero (ed25519 SLIP-0010)
  static final BipCoinConf moneroEd25519Slip = BipCoinConf(
    coinNames: CoinsConf.moneroMainNet.coinName,
    coinIdx: Slip44.monero,
    isTestnet: false,
    defPath: derPathHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.ed25519,
    addressEncoder: ([dynamic kwargs]) => XmrAddrEncoder(),
    addrParams: {},
  );

  /// Configuration for Monero (secp256k1)
  static final BipCoinConf moneroSecp256k1 = BipCoinConf(
    coinNames: CoinsConf.moneroMainNet.coinName,
    coinIdx: Slip44.monero,
    isTestnet: false,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder: ([dynamic kwargs]) => XmrAddrEncoder(),
    addrParams: {},
  );

  /// Configuration for Nano
  static final BipCoinConf nano = BipCoinConf(
    coinNames: CoinsConf.nano.coinName,
    coinIdx: Slip44.nano,
    isTestnet: false,
    defPath: derPathHardenedShort,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.ed25519Blake2b,
    addressEncoder: ([dynamic kwargs]) => NanoAddrEncoder(),
    addrParams: {},
  );

  /// Configuration for Near Protocol
  static final BipCoinConf nearProtocol = BipCoinConf(
    coinNames: CoinsConf.nearProtocol.coinName,
    coinIdx: Slip44.nearProtocol,
    isTestnet: false,
    defPath: derPathHardenedShort,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.ed25519,
    addressEncoder: ([dynamic kwargs]) => NearAddrEncoder(),
    addrParams: {},
  );

  /// Configuration for Neo
  static final BipCoinConf neo = BipCoinConf(
    coinNames: CoinsConf.neo.coinName,
    coinIdx: Slip44.neo,
    isTestnet: false,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.nist256p1,
    addressEncoder: ([dynamic kwargs]) => NeoAddrEncoder(),
    addrParams: {
      "ver": CoinsConf.neo.getParam("addr_ver"),
    },
  );

  /// Configuration for Nine Chronicles Gold
  static final BipCoinConf nineChroniclesGold = BipCoinConf(
    coinNames: CoinsConf.nineChroniclesGold.coinName,
    coinIdx: Slip44.nineChronicles,
    isTestnet: false,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder: ([dynamic kwargs]) => EthAddrEncoder(),
    addrParams: {},
  );

  /// Configuration for OKEx Chain (Ethereum address)
  static final BipCoinConf okexChainEth = BipCoinConf(
    coinNames: CoinsConf.okexChain.coinName,
    coinIdx: Slip44.ethereum,
    isTestnet: false,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder: ([dynamic kwargs]) => EthAddrEncoder(),
    addrParams: {},
  );

  /// Configuration for OKEx Chain (Atom address)
  static final BipCoinConf okexChainAtom = BipCoinConf(
    coinNames: CoinsConf.okexChain.coinName,
    coinIdx: Slip44.ethereum,
    isTestnet: false,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder: ([dynamic kwargs]) => OkexAddrEncoder(),
    addrParams: {},
  );

  /// Configuration for OKEx Chain (old Atom address)
  static final BipCoinConf okexChainAtomOld = BipCoinConf(
    coinNames: CoinsConf.okexChain.coinName,
    coinIdx: Slip44.okexChain,
    isTestnet: false,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder: ([dynamic kwargs]) => OkexAddrEncoder(),
    addrParams: {},
  );

  /// Configuration for Ontology
  static final BipCoinConf ontology = BipCoinConf(
    coinNames: CoinsConf.ontology.coinName,
    coinIdx: Slip44.ontology,
    isTestnet: false,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.nist256p1,
    addressEncoder: ([dynamic kwargs]) => NeoAddrEncoder(),
    addrParams: {
      "ver": CoinsConf.ontology.getParam("addr_ver"),
    },
  );

  /// Configuration for Osmosis
  static final BipCoinConf osmosis = BipCoinConf(
    coinNames: CoinsConf.osmosis.coinName,
    coinIdx: Slip44.atom,
    isTestnet: false,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder: ([dynamic kwargs]) => AtomAddrEncoder(),
    addrParams: {
      "hrp": CoinsConf.osmosis.getParam("addr_hrp"),
    },
  );

  /// Configuration for Pi Network
  static final BipCoinConf piNetwork = BipCoinConf(
    coinNames: CoinsConf.piNetwork.coinName,
    coinIdx: Slip44.piNetwork,
    isTestnet: false,
    defPath: derPathHardenedShort,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.ed25519,
    addressEncoder: ([dynamic kwargs]) => XlmAddrEncoder(),
    addrParams: {"addr_type": XlmAddrTypes.pubKey},
  );

  /// Configuration for Polkadot (ed25519 SLIP-0010)
  static final BipCoinConf polkadotEd25519Slip = BipCoinConf(
    coinNames: CoinsConf.polkadot.coinName,
    coinIdx: Slip44.polkadot,
    isTestnet: false,
    defPath: derPathHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.ed25519,
    addressEncoder: ([dynamic kwargs]) => SubstrateEd25519AddrEncoder(),
    addrParams: {
      "ss58_format": CoinsConf.polkadot.getParam("addr_ss58_format"),
    },
  );

  /// Configuration for Polygon
  static final BipCoinConf polygon = BipCoinConf(
    coinNames: CoinsConf.polygon.coinName,
    coinIdx: Slip44.ethereum,
    isTestnet: false,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder: ([dynamic kwargs]) => EthAddrEncoder(),
    addrParams: {},
  );

  /// Configuration for Ripple
  static final BipCoinConf ripple = BipCoinConf(
    coinNames: CoinsConf.ripple.coinName,
    coinIdx: Slip44.ripple,
    isTestnet: false,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder: ([dynamic kwargs]) => XrpAddrEncoder(),
    addrParams: {},
  );

  /// Configuration for Secret Network (old path)
  static final BipCoinConf secretNetworkOld = BipCoinConf(
    coinNames: CoinsConf.secretNetwork.coinName,
    coinIdx: Slip44.atom,
    isTestnet: false,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder: ([dynamic kwargs]) => AtomAddrEncoder(),
    addrParams: {
      "hrp": CoinsConf.secretNetwork.getParam("addr_hrp"),
    },
  );

  /// Configuration for Secret Network (new path)
  static final BipCoinConf secretNetworkNew = BipCoinConf(
    coinNames: CoinsConf.secretNetwork.coinName,
    coinIdx: Slip44.secretNetwork,
    isTestnet: false,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder: ([dynamic kwargs]) => AtomAddrEncoder(),
    addrParams: {
      "hrp": CoinsConf.secretNetwork.getParam("addr_hrp"),
    },
  );

  /// Configuration for Solana
  static final BipCoinConf solana = BipCoinConf(
    coinNames: CoinsConf.solana.coinName,
    coinIdx: Slip44.solana,
    isTestnet: false,
    defPath: derPathHardenedShort,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.ed25519,
    addressEncoder: ([dynamic kwargs]) => SolAddrEncoder(),
    addrParams: {},
  );

  /// Configuration for Stellar
  static final BipCoinConf stellar = BipCoinConf(
    coinNames: CoinsConf.stellar.coinName,
    coinIdx: Slip44.stellar,
    isTestnet: false,
    defPath: derPathHardenedShort,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.ed25519,
    addressEncoder: ([dynamic kwargs]) => XlmAddrEncoder(),
    addrParams: {"addr_type": XlmAddrTypes.pubKey},
  );

  /// Configuration for Terra
  static final BipCoinConf terra = BipCoinConf(
    coinNames: CoinsConf.terra.coinName,
    coinIdx: Slip44.terra,
    isTestnet: false,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder: ([dynamic kwargs]) => AtomAddrEncoder(),
    addrParams: {
      "hrp": CoinsConf.terra.getParam("addr_hrp"),
    },
  );

  /// Configuration for Tezos
  static final BipCoinConf tezos = BipCoinConf(
    coinNames: CoinsConf.tezos.coinName,
    coinIdx: Slip44.tezos,
    isTestnet: false,
    defPath: "0'/0'",
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.ed25519,
    addressEncoder: ([dynamic kwargs]) => XtzAddrEncoder(),
    addrParams: {"prefix": XtzAddrPrefixes.tz1},
  );

  /// Configuration for Theta
  static final BipCoinConf theta = BipCoinConf(
    coinNames: CoinsConf.theta.coinName,
    coinIdx: Slip44.theta,
    isTestnet: false,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder: ([dynamic kwargs]) => EthAddrEncoder(),
    addrParams: {},
  );

  /// Configuration for Tron
  static final BipCoinConf tron = BipCoinConf(
    coinNames: CoinsConf.tron.coinName,
    coinIdx: Slip44.tron,
    isTestnet: false,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder: ([dynamic kwargs]) => TrxAddrEncoder(),
    addrParams: {},
  );

  /// Configuration for VeChain
  static final BipCoinConf vechain = BipCoinConf(
    coinNames: CoinsConf.veChain.coinName,
    coinIdx: Slip44.vechain,
    isTestnet: false,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder: ([dynamic kwargs]) => EthAddrEncoder(),
    addrParams: {},
  );

  /// Configuration for Verge
  static final BipCoinConf verge = BipCoinConf(
    coinNames: CoinsConf.verge.coinName,
    coinIdx: Slip44.verge,
    isTestnet: false,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: CoinsConf.verge.getParam("wif_net_ver"),
    type: EllipticCurveTypes.secp256k1,
    addressEncoder: ([dynamic kwargs]) => P2PKHAddrEncoder(),
    addrParams: {
      "net_ver": CoinsConf.verge.getParam("p2pkh_net_ver"),
    },
  );

  /// Configuration for Zcash main net
  static final BipCoinConf zcashMainNet = BipCoinConf(
    coinNames: CoinsConf.zcashMainNet.coinName,
    coinIdx: Slip44.zcash,
    isTestnet: false,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: CoinsConf.zcashMainNet.getParam("wif_net_ver"),
    type: EllipticCurveTypes.secp256k1,
    addressEncoder: ([dynamic kwargs]) => P2PKHAddrEncoder(),
    addrParams: {
      "net_ver": CoinsConf.zcashMainNet.getParam("p2pkh_net_ver"),
    },
  );

  /// Configuration for Zcash test net
  static final BipCoinConf zcashTestNet = BipCoinConf(
    coinNames: CoinsConf.zcashTestNet.coinName,
    coinIdx: Slip44.testnet,
    isTestnet: true,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerTest,
    wifNetVer: CoinsConf.zcashTestNet.getParam("wif_net_ver"),
    type: EllipticCurveTypes.secp256k1,
    addressEncoder: ([dynamic kwargs]) => P2PKHAddrEncoder(),
    addrParams: {
      "net_ver": CoinsConf.zcashTestNet.getParam("p2pkh_net_ver"),
    },
  );

  /// Configuration for Zilliqa
  static final BipCoinConf zilliqa = BipCoinConf(
    coinNames: CoinsConf.zilliqa.coinName,
    coinIdx: Slip44.zilliqa,
    isTestnet: false,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder: ([dynamic kwargs]) => ZilAddrEncoder(),
    addrParams: {},
  );
}
