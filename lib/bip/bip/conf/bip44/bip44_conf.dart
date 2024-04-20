import 'package:blockchain_utils/bip/address/ada/ada_byron_addr.dart';
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
import 'package:blockchain_utils/bip/bip/conf/bip_bitcoin_cash_conf.dart';
import 'package:blockchain_utils/bip/bip/conf/bip_coin_conf.dart';
import 'package:blockchain_utils/bip/bip/conf/bip_conf_const.dart';
import 'package:blockchain_utils/bip/bip/conf/bip_litecoin_conf.dart';
import 'package:blockchain_utils/bip/coin_conf/coins_conf.dart';
import 'package:blockchain_utils/bip/ecc/curve/elliptic_curve_types.dart';
import 'package:blockchain_utils/bip/slip/slip44/slip44.dart';

/// A configuration class for BIP44 coins that defines the key network versions and
/// maps each supported BIP44Coin to its corresponding CoinConfig.
class Bip44Conf {
  /// The key network version for the mainnet of Bitcoin.
  static final Bip32KeyNetVersions bip44BtcKeyNetVerMain =
      Bip32Const.mainNetKeyNetVersions;

  /// The key network version for the testnet of Bitcoin.
  static final Bip32KeyNetVersions bip44BtcKeyNetVerTest =
      Bip32Const.testNetKeyNetVersions;

  /// Configuration for Akash Network
  static final CoinConfig akashNetwork = CoinConfig(
    coinNames: CoinsConf.akashNetwork.coinName,
    coinIdx: Slip44.atom,
    isTestnet: false,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder: ([dynamic kwargs]) => AtomAddrEncoder(),
    addrParams: {
      "hrp": CoinsConf.akashNetwork.params.addrHrp!,
    },
  );

  /// Configuration for Algorand
  static final CoinConfig algorand = CoinConfig(
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
  static final CoinConfig aptos = CoinConfig(
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
  static final CoinConfig avaxCChain = CoinConfig(
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
  static final CoinConfig avaxPChain = CoinConfig(
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
  static final CoinConfig avaxXChain = CoinConfig(
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
  static final CoinConfig axelar = CoinConfig(
    coinNames: CoinsConf.axelar.coinName,
    coinIdx: Slip44.atom,
    isTestnet: false,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder: ([dynamic kwargs]) => AtomAddrEncoder(),
    addrParams: {
      "hrp": CoinsConf.axelar.params.addrHrp!,
    },
  );

  /// Configuration for Band Protocol
  static final CoinConfig bandProtocol = CoinConfig(
    coinNames: CoinsConf.bandProtocol.coinName,
    coinIdx: Slip44.bandProtocol,
    isTestnet: false,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder: ([dynamic kwargs]) => AtomAddrEncoder(),
    addrParams: {
      "hrp": CoinsConf.bandProtocol.params.addrHrp!,
    },
  );

  /// Configuration for Binance Chain
  static final CoinConfig binanceChain = CoinConfig(
    coinNames: CoinsConf.binanceChain.coinName,
    coinIdx: Slip44.binanceChain,
    isTestnet: false,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder: ([dynamic kwargs]) => AtomAddrEncoder(),
    addrParams: {
      "hrp": CoinsConf.binanceChain.params.addrHrp!,
    },
  );

  /// Configuration for Binance Smart Chain
  static final CoinConfig binanceSmartChain = CoinConfig(
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
  static final CoinConfig bitcoinMainNet = CoinConfig(
    coinNames: CoinsConf.bitcoinMainNet.coinName,
    coinIdx: Slip44.bitcoin,
    isTestnet: false,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: CoinsConf.bitcoinMainNet.params.wifNetVer,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder: ([dynamic kwargs]) => P2PKHAddrEncoder(),
    addrParams: {
      "net_ver": CoinsConf.bitcoinMainNet.params.p2pkhNetVer!,
    },
  );

  /// Configuration for Bitcoin test net
  static final CoinConfig bitcoinTestNet = CoinConfig(
    coinNames: CoinsConf.bitcoinTestNet.coinName,
    coinIdx: Slip44.testnet,
    isTestnet: true,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerTest,
    wifNetVer: CoinsConf.bitcoinTestNet.params.wifNetVer,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder: ([dynamic kwargs]) => P2PKHAddrEncoder(),
    addrParams: {
      "net_ver": CoinsConf.bitcoinTestNet.params.p2pkhNetVer,
    },
  );

  /// Configuration for Bitcoin Cash main net
  static final BipBitcoinCashConf bitcoinCashMainNet = BipBitcoinCashConf(
    coinNames: CoinsConf.bitcoinCashMainNet.coinName,
    coinIdx: Slip44.bitcoinCash,
    isTestnet: false,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: CoinsConf.bitcoinCashMainNet.params.wifNetVer,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder: ([dynamic legacy]) {
      if (legacy == true) {
        return P2PKHAddrEncoder();
      }
      return BchP2PKHAddrEncoder();
    },
    addrParams: {
      "std": {
        "net_ver": CoinsConf.bitcoinCashMainNet.params.p2pkhStdNetVer!,
        "hrp": CoinsConf.bitcoinCashMainNet.params.p2pkhStdHrp!,
      },
      "legacy": {
        "net_ver": CoinsConf.bitcoinCashMainNet.params.p2pkhLegacyNetVer!,
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
    wifNetVer: CoinsConf.bitcoinCashTestNet.params.wifNetVer,
    type: EllipticCurveTypes.secp256k1,
    addrParams: {
      "std": {
        "net_ver": CoinsConf.bitcoinCashTestNet.params.p2pkhStdNetVer!,
        "hrp": CoinsConf.bitcoinCashTestNet.params.p2pkhStdHrp!,
      },
      "legacy": {
        "net_ver": CoinsConf.bitcoinCashTestNet.params.p2pkhLegacyNetVer!,
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
    wifNetVer: CoinsConf.bitcoinCashSlpMainNet.params.wifNetVer,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder: ([dynamic legacy]) {
      if (legacy == true) {
        return P2PKHAddrEncoder();
      }
      return BchP2PKHAddrEncoder();
    },
    addrParams: {
      "std": {
        "net_ver": CoinsConf.bitcoinCashSlpMainNet.params.p2pkhStdNetVer,
        "hrp": CoinsConf.bitcoinCashSlpMainNet.params.p2pkhStdHrp,
      },
      "legacy": {
        "net_ver": CoinsConf.bitcoinCashSlpMainNet.params.p2pkhLegacyNetVer!,
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
    wifNetVer: CoinsConf.bitcoinCashSlpTestNet.params.wifNetVer,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder: ([dynamic legacy]) {
      if (legacy == true) {
        return P2PKHAddrEncoder();
      }
      return BchP2PKHAddrEncoder();
    },
    addrParams: {
      "std": {
        "net_ver": CoinsConf.bitcoinCashSlpTestNet.params.p2pkhStdNetVer!,
        "hrp": CoinsConf.bitcoinCashSlpTestNet.params.p2pkhStdHrp!,
      },
      "legacy": {
        "net_ver": CoinsConf.bitcoinCashSlpTestNet.params.p2pkhLegacyNetVer!,
      }
    },
  );

  /// Configuration for BitcoinSV main net
  static final CoinConfig bitcoinSvMainNet = CoinConfig(
    coinNames: CoinsConf.bitcoinSvMainNet.coinName,
    coinIdx: Slip44.bitcoinSv,
    isTestnet: false,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: CoinsConf.bitcoinSvMainNet.params.wifNetVer,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder: ([dynamic legacy]) {
      return P2PKHAddrEncoder();
    },
    addrParams: {
      "net_ver": CoinsConf.bitcoinSvMainNet.params.p2pkhNetVer!,
    },
  );

  /// Configuration for BitcoinSV test net
  static final CoinConfig bitcoinSvTestNet = CoinConfig(
    coinNames: CoinsConf.bitcoinSvTestNet.coinName,
    coinIdx: Slip44.testnet,
    isTestnet: true,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerTest,
    wifNetVer: CoinsConf.bitcoinSvTestNet.params.wifNetVer,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder: ([dynamic kwargs]) => P2PKHAddrEncoder(),
    addrParams: {
      "net_ver": CoinsConf.bitcoinSvTestNet.params.p2pkhNetVer!,
    },
  );

  static final CoinConfig cardanoByronIcarus = CoinConfig(
    coinNames: CoinsConf.cardanoMainNet.coinName,
    coinIdx: Slip44.cardano,
    isTestnet: false,
    defPath: derPathNonHardenedFull,
    keyNetVer: Bip32Const.kholawKeyNetVersions,
    wifNetVer: null,
    type: EllipticCurveTypes.ed25519Kholaw,
    addressEncoder: ([dynamic kwargs]) => AdaByronIcarusAddrEncoder(),
    addrParams: {"chain_code": true, "is_icarus": true},
  );

  /// Configuration for Cardano Byron (Ledger)
  static final CoinConfig cardanoByronLedger = CoinConfig(
    coinNames: CoinsConf.cardanoMainNet.coinName,
    coinIdx: Slip44.cardano,
    isTestnet: false,
    defPath: derPathNonHardenedFull,
    keyNetVer: Bip32Const.kholawKeyNetVersions,
    wifNetVer: null,
    type: EllipticCurveTypes.ed25519Kholaw,
    addressEncoder: ([dynamic kwargs]) => AdaByronIcarusAddrEncoder(),
    addrParams: {"chain_code": true},
  );
  static final CoinConfig cardanoByronIcarusTestnet = CoinConfig(
    coinNames: CoinsConf.cardanoMainNet.coinName,
    coinIdx: Slip44.testnet,
    isTestnet: true,
    defPath: derPathNonHardenedFull,
    keyNetVer: Bip32Const.kholawKeyNetVersions,
    wifNetVer: null,
    type: EllipticCurveTypes.ed25519Kholaw,
    addressEncoder: ([dynamic kwargs]) => AdaByronIcarusAddrEncoder(),
    addrParams: {"chain_code": true, "is_icarus": true},
  );

  /// Configuration for Cardano Byron (Ledger)
  static final CoinConfig cardanoByronLedgerTestnet = CoinConfig(
    coinNames: CoinsConf.cardanoMainNet.coinName,
    coinIdx: Slip44.testnet,
    isTestnet: true,
    defPath: derPathNonHardenedFull,
    keyNetVer: Bip32Const.kholawKeyNetVersions,
    wifNetVer: null,
    type: EllipticCurveTypes.ed25519Kholaw,
    addressEncoder: ([dynamic kwargs]) => AdaByronIcarusAddrEncoder(),
    addrParams: {"chain_code": true},
  );

  /// Configuration for Celo
  static final CoinConfig celo = CoinConfig(
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
  static final CoinConfig certik = CoinConfig(
    coinNames: CoinsConf.certik.coinName,
    coinIdx: Slip44.atom,
    isTestnet: false,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder: ([dynamic kwargs]) => AtomAddrEncoder(),
    addrParams: {
      "hrp": CoinsConf.certik.params.addrHrp!,
    },
  );

  /// Configuration for Chihuahua
  static final CoinConfig chihuahua = CoinConfig(
    coinNames: CoinsConf.chihuahua.coinName,
    coinIdx: Slip44.atom,
    isTestnet: false,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder: ([dynamic kwargs]) => AtomAddrEncoder(),
    addrParams: {
      "hrp": CoinsConf.chihuahua.params.addrHrp!,
    },
  );

  /// Configuration for Cosmos
  static final CoinConfig cosmos = CoinConfig(
    coinNames: CoinsConf.cosmos.coinName,
    coinIdx: Slip44.atom,
    isTestnet: false,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder: ([dynamic kwargs]) => AtomAddrEncoder(),
    addrParams: {
      "hrp": CoinsConf.cosmos.params.addrHrp!,
    },
  );
  static final CoinConfig cosmosTestnet = CoinConfig(
    coinNames: CoinsConf.cosmos.coinName,
    coinIdx: Slip44.testnet,
    isTestnet: false,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder: ([dynamic kwargs]) => AtomAddrEncoder(),
    addrParams: {
      "hrp": CoinsConf.cosmos.params.addrHrp!,
    },
  );

  /// Configuration for Cosmos
  static final CoinConfig cosmosNist256p1 = CoinConfig(
    coinNames: CoinsConf.cosmos.coinName,
    coinIdx: Slip44.atom,
    isTestnet: false,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.nist256p1,
    addressEncoder: ([dynamic kwargs]) => AtomNist256P1AddrEncoder(),
    addrParams: {
      "hrp": CoinsConf.cosmos.params.addrHrp!,
    },
  );
  static final CoinConfig cosmosTestnetNist256p1 = CoinConfig(
    coinNames: CoinsConf.cosmos.coinName,
    coinIdx: Slip44.testnet,
    isTestnet: false,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.nist256p1,
    addressEncoder: ([dynamic kwargs]) => AtomNist256P1AddrEncoder(),
    addrParams: {
      "hrp": CoinsConf.cosmos.params.addrHrp!,
    },
  );

  /// Configuration for Dash main net
  static final CoinConfig dashMainNet = CoinConfig(
    coinNames: CoinsConf.dashMainNet.coinName,
    coinIdx: Slip44.dash,
    isTestnet: false,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: CoinsConf.dashMainNet.params.wifNetVer,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder: ([dynamic kwargs]) => P2PKHAddrEncoder(),
    addrParams: {
      "net_ver": CoinsConf.dashMainNet.params.p2pkhNetVer!,
    },
  );

  /// Configuration for Dash test net
  static final CoinConfig dashTestNet = CoinConfig(
    coinNames: CoinsConf.dashTestNet.coinName,
    coinIdx: Slip44.testnet,
    isTestnet: true,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerTest,
    wifNetVer: CoinsConf.dashTestNet.params.wifNetVer,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder: ([dynamic kwargs]) => P2PKHAddrEncoder(),
    addrParams: {
      "net_ver": CoinsConf.dashTestNet.params.p2pkhNetVer!,
    },
  );

  /// Configuration for Dogecoin main net
  static final CoinConfig dogecoinMainNet = CoinConfig(
    coinNames: CoinsConf.dogecoinMainNet.coinName,
    coinIdx: Slip44.dogecoin,
    isTestnet: false,
    defPath: derPathNonHardenedFull,
    keyNetVer: Bip32KeyNetVersions(List<int>.from([0x02, 0xfa, 0xca, 0xfd]),
        List<int>.from([0x02, 0xfa, 0xc3, 0x98])),
    wifNetVer: CoinsConf.dogecoinMainNet.params.wifNetVer,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder: ([dynamic kwargs]) => P2PKHAddrEncoder(),
    addrParams: {
      "net_ver": CoinsConf.dogecoinMainNet.params.p2pkhNetVer!,
    },
  );

  /// Configuration for Dogecoin test net
  static final CoinConfig dogecoinTestNet = CoinConfig(
    coinNames: CoinsConf.dogecoinTestNet.coinName,
    coinIdx: Slip44.testnet,
    isTestnet: true,
    defPath: derPathNonHardenedFull,
    keyNetVer: Bip32KeyNetVersions(List<int>.from([0x04, 0x32, 0xa9, 0xa8]),
        List<int>.from([0x04, 0x32, 0xa2, 0x43])),
    wifNetVer: CoinsConf.dogecoinTestNet.params.wifNetVer,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder: ([dynamic kwargs]) => P2PKHAddrEncoder(),
    addrParams: {
      "net_ver": CoinsConf.dogecoinTestNet.params.p2pkhNetVer!,
    },
  );

  /// Configuration for eCash main net
  static final BipBitcoinCashConf ecashMainNet = BipBitcoinCashConf(
    coinNames: CoinsConf.ecashMainNet.coinName,
    coinIdx: Slip44.bitcoinCash,
    isTestnet: false,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: CoinsConf.ecashMainNet.params.wifNetVer,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder: ([dynamic legacy]) {
      if (legacy == true) {
        return P2PKHAddrEncoder();
      }
      return BchP2PKHAddrEncoder();
    },
    addrParams: {
      "std": {
        "net_ver": CoinsConf.ecashMainNet.params.p2pkhStdNetVer!,
        "hrp": CoinsConf.ecashMainNet.params.p2pkhStdHrp!,
      },
      "legacy": {
        "net_ver": CoinsConf.ecashMainNet.params.p2pkhLegacyNetVer!,
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
    wifNetVer: CoinsConf.ecashTestNet.params.wifNetVer,
    type: EllipticCurveTypes.secp256k1,
    addrParams: {
      "std": {
        "net_ver": CoinsConf.ecashTestNet.params.p2pkhStdNetVer!,
        "hrp": CoinsConf.ecashTestNet.params.p2pkhStdHrp!,
      },
      "legacy": {
        "net_ver": CoinsConf.ecashTestNet.params.p2pkhLegacyNetVer!,
      },
    },

    /// addrClsLegacy: P2PKHAddrEncoder,
  );

  /// Configuration for Elrond
  static final CoinConfig elrond = CoinConfig(
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
  static final CoinConfig eos = CoinConfig(
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
  static final CoinConfig ergoMainNet = CoinConfig(
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
  static final CoinConfig ergoTestNet = CoinConfig(
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
  static final CoinConfig ethereum = CoinConfig(
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

  /// Configuration for EthereumTestnet
  static final CoinConfig ethereumTestnet = CoinConfig(
    coinNames: CoinsConf.ethereum.coinName,
    coinIdx: Slip44.testnet,
    isTestnet: true,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder: ([dynamic kwargs]) => EthAddrEncoder(),
    addrParams: {},
  );

  /// Configuration for Ethereum Classic
  static final CoinConfig ethereumClassic = CoinConfig(
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
  static final CoinConfig fantomOpera = CoinConfig(
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
  static final CoinConfig filecoin = CoinConfig(
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
  static final CoinConfig harmonyOneMetamask = CoinConfig(
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
  static final CoinConfig harmonyOneEth = CoinConfig(
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
  static final CoinConfig harmonyOneAtom = CoinConfig(
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
  static final CoinConfig huobiChain = CoinConfig(
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
  static final CoinConfig icon = CoinConfig(
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
  static final CoinConfig injective = CoinConfig(
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
  static final CoinConfig irisNet = CoinConfig(
    coinNames: CoinsConf.irisNet.coinName,
    coinIdx: Slip44.atom,
    isTestnet: false,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder: ([dynamic kwargs]) => AtomAddrEncoder(),
    addrParams: {
      "hrp": CoinsConf.irisNet.params.addrHrp!,
    },
  );

  /// Configuration for Kava
  static final CoinConfig kava = CoinConfig(
    coinNames: CoinsConf.kava.coinName,
    coinIdx: Slip44.kava,
    isTestnet: false,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder: ([dynamic kwargs]) => AtomAddrEncoder(),
    addrParams: {
      "hrp": CoinsConf.kava.params.addrHrp!,
    },
  );

  /// Configuration for Kusama (ed25519 SLIP-0010)
  static final CoinConfig kusamaEd25519Slip = CoinConfig(
    coinNames: CoinsConf.kusama.coinName,
    coinIdx: Slip44.kusama,
    isTestnet: false,
    defPath: derPathHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.ed25519,
    addressEncoder: ([dynamic kwargs]) => SubstrateEd25519AddrEncoder(),
    addrParams: {
      "ss58_format": CoinsConf.kusama.params.addrSs58Format,
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
    wifNetVer: CoinsConf.litecoinMainNet.params.wifNetVer,
    type: EllipticCurveTypes.secp256k1,
    addrParams: {
      "std_net_ver": CoinsConf.litecoinMainNet.params.p2pkhStdNetVer!,
      "depr_net_ver": CoinsConf.litecoinMainNet.params.p2pkhDeprNetVer,
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
    wifNetVer: CoinsConf.litecoinTestNet.params.wifNetVer,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder: ([dynamic kwargs]) => P2PKHAddrEncoder(),
    addrParams: {
      "std_net_ver": CoinsConf.litecoinTestNet.params.p2pkhStdNetVer!,
      "depr_net_ver": CoinsConf.litecoinTestNet.params.p2pkhDeprNetVer!,
    },
  );

  /// Configuration for Monero (ed25519 SLIP-0010)
  static final CoinConfig moneroEd25519Slip = CoinConfig(
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
  static final CoinConfig moneroSecp256k1 = CoinConfig(
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
  static final CoinConfig nano = CoinConfig(
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
  static final CoinConfig nearProtocol = CoinConfig(
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
  static final CoinConfig neo = CoinConfig(
    coinNames: CoinsConf.neo.coinName,
    coinIdx: Slip44.neo,
    isTestnet: false,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.nist256p1,
    addressEncoder: ([dynamic kwargs]) => NeoAddrEncoder(),
    addrParams: {
      "ver": CoinsConf.neo.params.addrVer!,
    },
  );

  /// Configuration for Nine Chronicles Gold
  static final CoinConfig nineChroniclesGold = CoinConfig(
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
  static final CoinConfig okexChainEth = CoinConfig(
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
  static final CoinConfig okexChainAtom = CoinConfig(
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
  static final CoinConfig okexChainAtomOld = CoinConfig(
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
  static final CoinConfig ontology = CoinConfig(
    coinNames: CoinsConf.ontology.coinName,
    coinIdx: Slip44.ontology,
    isTestnet: false,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.nist256p1,
    addressEncoder: ([dynamic kwargs]) => NeoAddrEncoder(),
    addrParams: {
      "ver": CoinsConf.ontology.params.addrVer!,
    },
  );

  /// Configuration for Osmosis
  static final CoinConfig osmosis = CoinConfig(
    coinNames: CoinsConf.osmosis.coinName,
    coinIdx: Slip44.atom,
    isTestnet: false,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder: ([dynamic kwargs]) => AtomAddrEncoder(),
    addrParams: {
      "hrp": CoinsConf.osmosis.params.addrHrp!,
    },
  );

  /// Configuration for Pi Network
  static final CoinConfig piNetwork = CoinConfig(
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
  static final CoinConfig polkadotEd25519Slip = CoinConfig(
    coinNames: CoinsConf.polkadot.coinName,
    coinIdx: Slip44.polkadot,
    isTestnet: false,
    defPath: derPathHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.ed25519,
    addressEncoder: ([dynamic kwargs]) => SubstrateEd25519AddrEncoder(),
    addrParams: {
      "ss58_format": CoinsConf.polkadot.params.addrSs58Format!,
    },
  );

  /// Configuration for Polygon
  static final CoinConfig polygon = CoinConfig(
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
  static final CoinConfig ripple = CoinConfig(
    coinNames: CoinsConf.ripple.coinName,
    coinIdx: Slip44.ripple,
    isTestnet: false,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder: ([dynamic kwargs]) => XrpAddrEncoder(),
    addrParams: {"prefix": CoinsConf.ripple.params.addrNetVer!},
  );

  /// Configuration for Ripple testnet
  static final CoinConfig rippleTestnet = CoinConfig(
    coinNames: CoinsConf.ripple.coinName,
    coinIdx: Slip44.testnet,
    isTestnet: true,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder: ([dynamic kwargs]) => XrpAddrEncoder(),
    addrParams: {"prefix": CoinsConf.rippleTestNet.params.addrNetVer!},
  );

  /// Configuration for Ripple
  static final CoinConfig rippleEd25519 = CoinConfig(
    coinNames: CoinsConf.ripple.coinName,
    coinIdx: Slip44.ripple,
    isTestnet: false,
    defPath: derPathHardenedShort,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.ed25519,
    addressEncoder: ([dynamic kwargs]) => XrpAddrEncoder(),
    addrParams: {
      "prefix": CoinsConf.ripple.params.addrNetVer!,
      "curve_type": EllipticCurveTypes.ed25519
    },
  );

  /// Configuration for Ripple testnet
  static final CoinConfig rippleTestnetEd25519 = CoinConfig(
    coinNames: CoinsConf.ripple.coinName,
    coinIdx: Slip44.testnet,
    isTestnet: true,
    defPath: derPathHardenedShort,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.ed25519,
    addressEncoder: ([dynamic kwargs]) => XrpAddrEncoder(),
    addrParams: {
      "prefix": CoinsConf.rippleTestNet.params.addrNetVer!,
      "curve_type": EllipticCurveTypes.ed25519
    },
  );
  static final CoinConfig secretNetworkOld = CoinConfig(
    coinNames: CoinsConf.secretNetwork.coinName,
    coinIdx: Slip44.atom,
    isTestnet: false,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder: ([dynamic kwargs]) => AtomAddrEncoder(),
    addrParams: {
      "hrp": CoinsConf.secretNetwork.params.addrHrp!,
    },
  );

  /// Configuration for Secret Network (new path)
  static final CoinConfig secretNetworkNew = CoinConfig(
    coinNames: CoinsConf.secretNetwork.coinName,
    coinIdx: Slip44.secretNetwork,
    isTestnet: false,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder: ([dynamic kwargs]) => AtomAddrEncoder(),
    addrParams: {
      "hrp": CoinsConf.secretNetwork.params.addrHrp!,
    },
  );

  /// Configuration for Solana
  static final CoinConfig solana = CoinConfig(
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

  /// Configuration for Solana
  static final CoinConfig solanaTestnet = CoinConfig(
    coinNames: CoinsConf.solana.coinName,
    coinIdx: Slip44.testnet,
    isTestnet: true,
    defPath: derPathHardenedShort,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.ed25519,
    addressEncoder: ([dynamic kwargs]) => SolAddrEncoder(),
    addrParams: {},
  );

  /// Configuration for Stellar
  static final CoinConfig stellar = CoinConfig(
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
  static final CoinConfig terra = CoinConfig(
    coinNames: CoinsConf.terra.coinName,
    coinIdx: Slip44.terra,
    isTestnet: false,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder: ([dynamic kwargs]) => AtomAddrEncoder(),
    addrParams: {
      "hrp": CoinsConf.terra.params.addrHrp!,
    },
  );

  /// Configuration for Tezos
  static final CoinConfig tezos = CoinConfig(
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
  static final CoinConfig theta = CoinConfig(
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
  static final CoinConfig tron = CoinConfig(
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

  /// Configuration for Tron testnet
  static final CoinConfig tronTestnet = CoinConfig(
    coinNames: CoinsConf.tron.coinName,
    coinIdx: Slip44.testnet,
    isTestnet: true,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder: ([dynamic kwargs]) => TrxAddrEncoder(),
    addrParams: {},
  );

  /// Configuration for VeChain
  static final CoinConfig vechain = CoinConfig(
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
  static final CoinConfig verge = CoinConfig(
    coinNames: CoinsConf.verge.coinName,
    coinIdx: Slip44.verge,
    isTestnet: false,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: CoinsConf.verge.params.wifNetVer,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder: ([dynamic kwargs]) => P2PKHAddrEncoder(),
    addrParams: {
      "net_ver": CoinsConf.verge.params.p2pkhNetVer!,
    },
  );

  /// Configuration for Zcash main net
  static final CoinConfig zcashMainNet = CoinConfig(
    coinNames: CoinsConf.zcashMainNet.coinName,
    coinIdx: Slip44.zcash,
    isTestnet: false,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: CoinsConf.zcashMainNet.params.wifNetVer,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder: ([dynamic kwargs]) => P2PKHAddrEncoder(),
    addrParams: {
      "net_ver": CoinsConf.zcashMainNet.params.p2pkhNetVer!,
    },
  );

  /// Configuration for Zcash test net
  static final CoinConfig zcashTestNet = CoinConfig(
    coinNames: CoinsConf.zcashTestNet.coinName,
    coinIdx: Slip44.testnet,
    isTestnet: true,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerTest,
    wifNetVer: CoinsConf.zcashTestNet.params.wifNetVer,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder: ([dynamic kwargs]) => P2PKHAddrEncoder(),
    addrParams: {
      "net_ver": CoinsConf.zcashTestNet.params.p2pkhNetVer!,
    },
  );

  /// Configuration for Zilliqa
  static final CoinConfig zilliqa = CoinConfig(
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
