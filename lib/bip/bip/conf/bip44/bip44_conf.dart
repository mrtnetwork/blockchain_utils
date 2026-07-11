import 'package:blockchain_utils/bip/address/encoders.dart';
import 'package:blockchain_utils/bip/bip/bip32/bip32_const.dart';
import 'package:blockchain_utils/bip/bip/bip32/bip32_key_data.dart';
import 'package:blockchain_utils/bip/bip/bip32/bip32_key_net_ver.dart';
import 'package:blockchain_utils/bip/bip/conf/config/bip_bitcoin_cash_conf.dart';
import 'package:blockchain_utils/bip/bip/conf/config/bip_coin_conf.dart';
import 'package:blockchain_utils/bip/bip/conf/const/bip_conf_const.dart';
import 'package:blockchain_utils/bip/bip/conf/config/bip_litecoin_conf.dart';
import 'package:blockchain_utils/bip/bip/conf/core/coin_conf.dart';
import 'package:blockchain_utils/bip/coin_conf/constant/coins_conf.dart';
import 'package:blockchain_utils/bip/ecc/curve/elliptic_curve_types.dart';
import 'package:blockchain_utils/bip/slip/slip44/slip44.dart';

/// A configuration class for BIP44 coins that defines the key network versions and
/// maps each supported BIP44Coin to its corresponding BipCoinConfig.
class Bip44Conf {
  /// The key network version for the mainnet of Bitcoin.
  static const Bip32KeyNetVersions bip44BtcKeyNetVerMain =
      Bip32Const.mainNetKeyNetVersions;

  /// The key network version for the testnet of Bitcoin.
  static const Bip32KeyNetVersions bip44BtcKeyNetVerTest =
      Bip32Const.testNetKeyNetVersions;

  /// Configuration for Akash Network
  final BipCoinConfig akashNetwork = BipCoinConfig(
    coinNames: CoinsConf.akashNetwork.coinName,
    coinIdx: Slip44.atom,
    chainType: ChainType.mainnet,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder:
        (params, config) => AtomAddrEncoder().encodeKey(
          params.pubKey,
          hrp: CoinsConf.akashNetwork.params.addrHrp,
        ),
  );

  /// Configuration for Algorand
  final BipCoinConfig algorand = BipCoinConfig(
    coinNames: CoinsConf.algorand.coinName,
    addressEncoder:
        (params, config) => AlgoAddrEncoder().encodeKey(params.pubKey),
    coinIdx: Slip44.algorand,
    chainType: ChainType.mainnet,
    defPath: derPathHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.ed25519,
  );

  /// Configuration for Aptos
  final BipCoinConfig aptos = BipCoinConfig(
    coinNames: CoinsConf.aptos.coinName,
    coinIdx: Slip44.aptos,
    chainType: ChainType.mainnet,
    defPath: derPathHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.ed25519,
    addressEncoder:
        (params, config) => AptosAddrEncoder().encodeKey(params.pubKey),
  );

  /// Configuration for Aptos (Secp256k1) SingleKey Address
  final BipCoinConfig aptosSingleKeySecp256k1 = BipCoinConfig(
    coinNames: CoinsConf.aptos.coinName,
    coinIdx: Slip44.aptos,
    chainType: ChainType.mainnet,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder:
        (params, config) =>
            AptosSingleKeySecp256k1AddrEncoder().encodeKey(params.pubKey),
  );

  /// Configuration for Aptos (Ed25519) SingleKey Address
  final BipCoinConfig aptosSingleKeyEd25519 = BipCoinConfig(
    coinNames: CoinsConf.aptos.coinName,
    coinIdx: Slip44.aptos,
    chainType: ChainType.mainnet,
    defPath: derPathHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.ed25519,
    addressEncoder:
        (params, config) =>
            AptosSingleKeyEd25519AddrEncoder().encodeKey(params.pubKey),
  );

  /// Configuration for Avax C-Chain
  final BipCoinConfig avaxCChain = BipCoinConfig(
    coinNames: CoinsConf.avaxCChain.coinName,
    coinIdx: Slip44.ethereum,
    chainType: ChainType.mainnet,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder:
        (params, config) => EthAddrEncoder().encodeKey(params.pubKey),
  );

  /// Configuration for Avax P-Chain
  final BipCoinConfig avaxPChain = BipCoinConfig(
    coinNames: CoinsConf.avaxPChain.coinName,
    coinIdx: Slip44.avalanche,
    chainType: ChainType.mainnet,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder:
        (params, config) => AvaxPChainAddrEncoder().encodeKey(params.pubKey),
  );

  /// Configuration for Avax X-Chain
  final BipCoinConfig avaxXChain = BipCoinConfig(
    coinNames: CoinsConf.avaxXChain.coinName,
    coinIdx: Slip44.avalanche,
    chainType: ChainType.mainnet,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder:
        (params, config) => AvaxXChainAddrEncoder().encodeKey(params.pubKey),
  );

  /// Configuration for Axelar
  final BipCoinConfig axelar = BipCoinConfig(
    coinNames: CoinsConf.axelar.coinName,
    coinIdx: Slip44.atom,
    chainType: ChainType.mainnet,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder:
        (params, config) => AtomAddrEncoder().encodeKey(
          params.pubKey,
          hrp: CoinsConf.axelar.params.addrHrp,
        ),
  );

  /// Configuration for Band Protocol
  final BipCoinConfig bandProtocol = BipCoinConfig(
    coinNames: CoinsConf.bandProtocol.coinName,
    coinIdx: Slip44.bandProtocol,
    chainType: ChainType.mainnet,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder:
        (params, config) => AtomAddrEncoder().encodeKey(
          params.pubKey,
          hrp: CoinsConf.bandProtocol.params.addrHrp,
        ),
  );

  /// Configuration for Binance Chain
  final BipCoinConfig binanceChain = BipCoinConfig(
    coinNames: CoinsConf.binanceChain.coinName,
    coinIdx: Slip44.binanceChain,
    chainType: ChainType.mainnet,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder:
        (params, config) => AtomAddrEncoder().encodeKey(
          params.pubKey,
          hrp: CoinsConf.binanceChain.params.addrHrp,
        ),
  );

  /// Configuration for Binance Smart Chain
  final BipCoinConfig binanceSmartChain = BipCoinConfig(
    coinNames: CoinsConf.binanceSmartChain.coinName,
    coinIdx: Slip44.ethereum,
    chainType: ChainType.mainnet,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder:
        (params, config) => EthAddrEncoder().encodeKey(params.pubKey),
  );

  /// Configuration for Bitcoin main net
  final BipCoinConfig bitcoinMainNet = BipCoinConfig(
    coinNames: CoinsConf.bitcoinMainNet.coinName,
    coinIdx: Slip44.bitcoin,
    chainType: ChainType.mainnet,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: CoinsConf.bitcoinMainNet.params.wifNetVer,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder:
        (params, config) => P2PKHAddrEncoder().encodeKey(
          params.pubKey,
          netVersion: CoinsConf.bitcoinMainNet.params.p2pkhNetVer,
        ),
  );

  /// Configuration for Bitcoin test net
  final BipCoinConfig bitcoinTestNet = BipCoinConfig(
    coinNames: CoinsConf.bitcoinTestNet.coinName,
    coinIdx: Slip44.testnet,
    chainType: ChainType.testnet,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerTest,
    wifNetVer: CoinsConf.bitcoinTestNet.params.wifNetVer,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder:
        (params, config) => P2PKHAddrEncoder().encodeKey(
          params.pubKey,
          netVersion: CoinsConf.bitcoinTestNet.params.p2pkhNetVer,
        ),
  );

  /// Configuration for Bitcoin Cash main net
  final BipBitcoinCashConf bitcoinCashMainNet = BipBitcoinCashConf(
    coinNames: CoinsConf.bitcoinCashMainNet.coinName,
    coinIdx: Slip44.bitcoinCash,
    chainType: ChainType.mainnet,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: CoinsConf.bitcoinCashMainNet.params.wifNetVer,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder: (params, config) {
      if (config.useLagacyAdder) {
        return P2PKHAddrEncoder().encodeKey(
          params.pubKey,
          netVersion: CoinsConf.bitcoinCashMainNet.params.p2pkhLegacyNetVer,
        );
      }
      return BchP2PKHAddrEncoder().encodeKey(
        params.pubKey,
        hrp: CoinsConf.bitcoinCashMainNet.params.p2pkhStdHrp,
        netVersion: CoinsConf.bitcoinCashMainNet.params.p2pkhStdNetVer,
      );
    },
  );

  /// Configuration for Bitcoin Cash test net
  final BipBitcoinCashConf bitcoinCashTestNet = BipBitcoinCashConf(
    coinNames: CoinsConf.bitcoinCashTestNet.coinName,
    coinIdx: Slip44.testnet,
    chainType: ChainType.testnet,
    defPath: derPathNonHardenedFull,
    addressEncoder: (params, config) {
      if (config.useLagacyAdder) {
        return P2PKHAddrEncoder().encodeKey(
          params.pubKey,
          netVersion: CoinsConf.bitcoinCashTestNet.params.p2pkhLegacyNetVer,
        );
      }
      return BchP2PKHAddrEncoder().encodeKey(
        params.pubKey,
        hrp: CoinsConf.bitcoinCashTestNet.params.p2pkhStdHrp,
        netVersion: CoinsConf.bitcoinCashTestNet.params.p2pkhStdNetVer,
      );
    },
    keyNetVer: bip44BtcKeyNetVerTest,
    wifNetVer: CoinsConf.bitcoinCashTestNet.params.wifNetVer,
    type: EllipticCurveTypes.secp256k1,
  );

  /// Configuration for Bitcoin Cash Simple Ledger Protocol main net
  final BipBitcoinCashConf bitcoinCashSlpMainNet = BipBitcoinCashConf(
    coinNames: CoinsConf.bitcoinCashSlpMainNet.coinName,
    coinIdx: Slip44.bitcoinCash,
    chainType: ChainType.mainnet,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: CoinsConf.bitcoinCashSlpMainNet.params.wifNetVer,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder: (params, config) {
      if (config.useLagacyAdder) {
        return P2PKHAddrEncoder().encodeKey(
          params.pubKey,
          netVersion: CoinsConf.bitcoinCashSlpMainNet.params.p2pkhLegacyNetVer,
        );
      }
      return BchP2PKHAddrEncoder().encodeKey(
        params.pubKey,
        hrp: CoinsConf.bitcoinCashSlpMainNet.params.p2pkhStdHrp,
        netVersion: CoinsConf.bitcoinCashSlpMainNet.params.p2pkhStdNetVer,
      );
    },
  );

  /// Configuration for Bitcoin Cash Simple Ledger Protocol test net
  final BipBitcoinCashConf bitcoinCashSlpTestNet = BipBitcoinCashConf(
    coinNames: CoinsConf.bitcoinCashSlpTestNet.coinName,
    coinIdx: Slip44.testnet,
    chainType: ChainType.testnet,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerTest,
    wifNetVer: CoinsConf.bitcoinCashSlpTestNet.params.wifNetVer,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder: (params, config) {
      if (config.useLagacyAdder) {
        return P2PKHAddrEncoder().encodeKey(
          params.pubKey,
          netVersion: CoinsConf.bitcoinCashSlpTestNet.params.p2pkhLegacyNetVer,
        );
      }
      return BchP2PKHAddrEncoder().encodeKey(
        params.pubKey,
        hrp: CoinsConf.bitcoinCashSlpTestNet.params.p2pkhStdHrp,
        netVersion: CoinsConf.bitcoinCashSlpTestNet.params.p2pkhStdNetVer,
      );
    },
  );

  /// Configuration for BitcoinSV main net
  final BipCoinConfig bitcoinSvMainNet = BipCoinConfig(
    coinNames: CoinsConf.bitcoinSvMainNet.coinName,
    coinIdx: Slip44.bitcoinSv,
    chainType: ChainType.mainnet,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: CoinsConf.bitcoinSvMainNet.params.wifNetVer,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder: (params, config) {
      return P2PKHAddrEncoder().encodeKey(
        params.pubKey,
        netVersion: CoinsConf.bitcoinSvMainNet.params.p2pkhNetVer,
      );
    },
  );

  /// Configuration for BitcoinSV test net
  final BipCoinConfig bitcoinSvTestNet = BipCoinConfig(
    coinNames: CoinsConf.bitcoinSvTestNet.coinName,
    coinIdx: Slip44.testnet,
    chainType: ChainType.testnet,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerTest,
    wifNetVer: CoinsConf.bitcoinSvTestNet.params.wifNetVer,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder:
        (params, config) => P2PKHAddrEncoder().encodeKey(
          params.pubKey,
          netVersion: CoinsConf.bitcoinSvTestNet.params.p2pkhNetVer,
        ),
  );

  final BipCoinConfig cardanoByronIcarus = BipCoinConfig(
    coinNames: CoinsConf.cardanoMainNet.coinName,
    coinIdx: Slip44.cardano,
    chainType: ChainType.mainnet,
    defPath: derPathNonHardenedFull,
    keyNetVer: Bip32Const.kholawKeyNetVersions,
    wifNetVer: null,
    type: EllipticCurveTypes.ed25519Kholaw,
    defaultHdKeyDerivator: DefaultHdKeyDerivator.icarus,
    addressEncoder:
        (params, config) => AdaByronIcarusAddrEncoder().encodeKey(
          params.pubKey,
          chainCode: params.chainCode,
        ),
  );

  /// Configuration for Cardano Byron (Ledger)
  final BipCoinConfig cardanoByronLedger = BipCoinConfig(
    coinNames: CoinsConf.cardanoMainNet.coinName,
    coinIdx: Slip44.cardano,
    chainType: ChainType.mainnet,
    defPath: derPathNonHardenedFull,
    keyNetVer: Bip32Const.kholawKeyNetVersions,
    wifNetVer: null,
    type: EllipticCurveTypes.ed25519Kholaw,
    addressEncoder:
        (params, config) => AdaByronIcarusAddrEncoder().encodeKey(
          params.pubKey,
          chainCode: params.chainCode,
        ),
  );
  final BipCoinConfig cardanoByronIcarusTestnet = BipCoinConfig(
    coinNames: CoinsConf.cardanoMainNet.coinName,
    coinIdx: Slip44.testnet,
    chainType: ChainType.testnet,
    defPath: derPathNonHardenedFull,
    keyNetVer: Bip32Const.kholawKeyNetVersions,
    wifNetVer: null,
    type: EllipticCurveTypes.ed25519Kholaw,
    defaultHdKeyDerivator: DefaultHdKeyDerivator.icarus,
    addressEncoder:
        (params, config) => AdaByronIcarusAddrEncoder().encodeKey(
          params.pubKey,
          chainCode: params.chainCode,
        ),
  );

  /// Configuration for Cardano Byron (Ledger)
  final BipCoinConfig cardanoByronLedgerTestnet = BipCoinConfig(
    coinNames: CoinsConf.cardanoMainNet.coinName,
    coinIdx: Slip44.testnet,
    chainType: ChainType.testnet,
    defPath: derPathNonHardenedFull,
    keyNetVer: Bip32Const.kholawKeyNetVersions,
    wifNetVer: null,
    type: EllipticCurveTypes.ed25519Kholaw,
    addressEncoder:
        (params, config) => AdaByronIcarusAddrEncoder().encodeKey(
          params.pubKey,
          chainCode: params.chainCode,
        ),
  );

  /// Configuration for Celo
  final BipCoinConfig celo = BipCoinConfig(
    coinNames: CoinsConf.celo.coinName,
    coinIdx: Slip44.celo,
    chainType: ChainType.mainnet,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder:
        (params, config) => EthAddrEncoder().encodeKey(params.pubKey),
  );

  /// Configuration for Certik
  final BipCoinConfig certik = BipCoinConfig(
    coinNames: CoinsConf.certik.coinName,
    coinIdx: Slip44.atom,
    chainType: ChainType.mainnet,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder:
        (params, config) => AtomAddrEncoder().encodeKey(
          params.pubKey,
          hrp: CoinsConf.certik.params.addrHrp,
        ),
  );

  /// Configuration for Chihuahua
  final BipCoinConfig chihuahua = BipCoinConfig(
    coinNames: CoinsConf.chihuahua.coinName,
    coinIdx: Slip44.atom,
    chainType: ChainType.mainnet,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder:
        (params, config) => AtomAddrEncoder().encodeKey(
          params.pubKey,
          hrp: CoinsConf.chihuahua.params.addrHrp,
        ),
  );

  /// Configuration for Cosmos
  final BipCoinConfig cosmos = BipCoinConfig(
    coinNames: CoinsConf.cosmos.coinName,
    coinIdx: Slip44.atom,
    chainType: ChainType.mainnet,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder:
        (params, config) => AtomAddrEncoder().encodeKey(
          params.pubKey,
          hrp: CoinsConf.cosmos.params.addrHrp,
        ),
  );
  final BipCoinConfig cosmosTestnet = BipCoinConfig(
    coinNames: CoinsConf.cosmos.coinName,
    coinIdx: Slip44.testnet,
    chainType: ChainType.testnet,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder:
        (params, config) => AtomAddrEncoder().encodeKey(
          params.pubKey,
          hrp: CoinsConf.cosmos.params.addrHrp,
        ),
  );

  final BipCoinConfig cosmosEthSecp256k1 = BipCoinConfig(
    coinNames: CoinsConf.cosmos.coinName,
    coinIdx: Slip44.atom,
    chainType: ChainType.mainnet,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder:
        (params, config) => AtomEthSecp256k1AddrEncoder().encodeKey(
          params.pubKey,
          hrp: CoinsConf.cosmos.params.addrHrp,
        ),
  );
  final BipCoinConfig cosmosTestnetEthSecp256k1 = BipCoinConfig(
    coinNames: CoinsConf.cosmos.coinName,
    coinIdx: Slip44.testnet,
    chainType: ChainType.testnet,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder:
        (params, config) => AtomEthSecp256k1AddrEncoder().encodeKey(
          params.pubKey,
          hrp: CoinsConf.cosmos.params.addrHrp,
        ),
  );

  /// Configuration for Cosmos
  final BipCoinConfig cosmosNist256p1 = BipCoinConfig(
    coinNames: CoinsConf.cosmos.coinName,
    coinIdx: Slip44.atom,
    chainType: ChainType.mainnet,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.nist256p1,
    addressEncoder:
        (params, config) => AtomNist256P1AddrEncoder().encodeKey(
          params.pubKey,
          hrp: CoinsConf.cosmos.params.addrHrp,
        ),
  );
  final BipCoinConfig cosmosTestnetNist256p1 = BipCoinConfig(
    coinNames: CoinsConf.cosmos.coinName,
    coinIdx: Slip44.testnet,
    chainType: ChainType.testnet,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.nist256p1,
    addressEncoder:
        (params, config) => AtomNist256P1AddrEncoder().encodeKey(
          params.pubKey,
          hrp: CoinsConf.cosmos.params.addrHrp,
        ),
  );

  /// Configuration for Cosmos
  final BipCoinConfig cosmosEd25519 = BipCoinConfig(
    coinNames: CoinsConf.cosmos.coinName,
    coinIdx: Slip44.atom,
    chainType: ChainType.mainnet,
    defPath: derPathHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.ed25519,
    addressEncoder:
        (params, config) => AtomEd25519AddrEncoder().encodeKey(
          params.pubKey,
          hrp: CoinsConf.cosmos.params.addrHrp,
        ),
  );
  final BipCoinConfig cosmosTestnetEd25519 = BipCoinConfig(
    coinNames: CoinsConf.cosmos.coinName,
    coinIdx: Slip44.testnet,
    chainType: ChainType.testnet,
    defPath: derPathHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.ed25519,
    addressEncoder:
        (params, config) => AtomEd25519AddrEncoder().encodeKey(
          params.pubKey,
          hrp: CoinsConf.cosmos.params.addrHrp,
        ),
  );

  /// Configuration for Dash main net
  final BipCoinConfig dashMainNet = BipCoinConfig(
    coinNames: CoinsConf.dashMainNet.coinName,
    coinIdx: Slip44.dash,
    chainType: ChainType.mainnet,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: CoinsConf.dashMainNet.params.wifNetVer,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder:
        (params, config) => P2PKHAddrEncoder().encodeKey(
          params.pubKey,
          netVersion: CoinsConf.dashMainNet.params.p2pkhNetVer,
        ),
  );

  /// Configuration for Dash test net
  final BipCoinConfig dashTestNet = BipCoinConfig(
    coinNames: CoinsConf.dashTestNet.coinName,
    coinIdx: Slip44.testnet,
    chainType: ChainType.testnet,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerTest,
    wifNetVer: CoinsConf.dashTestNet.params.wifNetVer,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder:
        (params, config) => P2PKHAddrEncoder().encodeKey(
          params.pubKey,
          netVersion: CoinsConf.dashTestNet.params.p2pkhNetVer,
        ),
  );

  /// Configuration for Dogecoin main net
  final BipCoinConfig dogecoinMainNet = BipCoinConfig(
    coinNames: CoinsConf.dogecoinMainNet.coinName,
    coinIdx: Slip44.dogecoin,
    chainType: ChainType.mainnet,
    defPath: derPathNonHardenedFull,
    keyNetVer: Bip32KeyNetVersions(
      [0x02, 0xfa, 0xca, 0xfd],
      [0x02, 0xfa, 0xc3, 0x98],
    ),
    wifNetVer: CoinsConf.dogecoinMainNet.params.wifNetVer,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder:
        (params, config) => P2PKHAddrEncoder().encodeKey(
          params.pubKey,
          netVersion: CoinsConf.dogecoinMainNet.params.p2pkhNetVer,
        ),
  );

  /// Configuration for Dogecoin test net
  final BipCoinConfig dogecoinTestNet = BipCoinConfig(
    coinNames: CoinsConf.dogecoinTestNet.coinName,
    coinIdx: Slip44.testnet,
    chainType: ChainType.testnet,
    defPath: derPathNonHardenedFull,
    keyNetVer: Bip32KeyNetVersions(
      [0x04, 0x32, 0xa9, 0xa8],
      [0x04, 0x32, 0xa2, 0x43],
    ),
    wifNetVer: CoinsConf.dogecoinTestNet.params.wifNetVer,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder:
        (params, config) => P2PKHAddrEncoder().encodeKey(
          params.pubKey,
          netVersion: CoinsConf.dogecoinTestNet.params.p2pkhNetVer,
        ),
  );

  /// Configuration for Pepecoin main net
  final BipCoinConfig pepeMainnet = BipCoinConfig(
    coinNames: CoinsConf.pepeMainnet.coinName,
    coinIdx: Slip44.pepecoin,
    chainType: ChainType.mainnet,
    defPath: derPathNonHardenedFull,
    keyNetVer: Bip32KeyNetVersions(
      [0x02, 0xfa, 0xca, 0xfd],
      [0x02, 0xfa, 0xc3, 0x98],
    ),
    wifNetVer: CoinsConf.pepeMainnet.params.wifNetVer,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder:
        (params, config) => P2PKHAddrEncoder().encodeKey(
          params.pubKey,
          netVersion: CoinsConf.pepeMainnet.params.p2pkhNetVer,
        ),
  );

  /// Configuration for Pepecoin test net
  final BipCoinConfig pepeTestnet = BipCoinConfig(
    coinNames: CoinsConf.pepeTestnet.coinName,
    coinIdx: Slip44.testnet,
    chainType: ChainType.testnet,
    defPath: derPathNonHardenedFull,
    keyNetVer: Bip32KeyNetVersions(
      [0x04, 0x32, 0xa9, 0xa8],
      [0x04, 0x32, 0xa2, 0x43],
    ),
    wifNetVer: CoinsConf.pepeTestnet.params.wifNetVer,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder:
        (params, config) => P2PKHAddrEncoder().encodeKey(
          params.pubKey,
          netVersion: CoinsConf.pepeTestnet.params.p2pkhNetVer,
        ),
  );

  /// Configuration for eCash main net
  final BipBitcoinCashConf ecashMainNet = BipBitcoinCashConf(
    coinNames: CoinsConf.ecashMainNet.coinName,
    coinIdx: Slip44.bitcoinCash,
    chainType: ChainType.mainnet,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: CoinsConf.ecashMainNet.params.wifNetVer,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder: (params, config) {
      if (config.useLagacyAdder) {
        return P2PKHAddrEncoder().encodeKey(
          params.pubKey,
          netVersion: CoinsConf.ecashMainNet.params.p2pkhLegacyNetVer,
        );
      }
      return BchP2PKHAddrEncoder().encodeKey(
        params.pubKey,
        hrp: CoinsConf.ecashMainNet.params.p2pkhStdHrp,
        netVersion: CoinsConf.ecashMainNet.params.p2pkhStdNetVer,
      );
    },
  );

  /// Configuration for eCash test net
  final BipBitcoinCashConf ecashTestNet = BipBitcoinCashConf(
    coinNames: CoinsConf.ecashTestNet.coinName,
    coinIdx: Slip44.testnet,
    chainType: ChainType.testnet,
    addressEncoder: (params, config) {
      if (config.useLagacyAdder) {
        return P2PKHAddrEncoder().encodeKey(
          params.pubKey,
          netVersion: CoinsConf.ecashTestNet.params.p2pkhLegacyNetVer,
        );
      }
      return BchP2PKHAddrEncoder().encodeKey(
        params.pubKey,
        netVersion: CoinsConf.ecashTestNet.params.p2pkhStdNetVer,
        hrp: CoinsConf.ecashTestNet.params.p2pkhStdHrp,
      );
    },
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerTest,
    wifNetVer: CoinsConf.ecashTestNet.params.wifNetVer,
    type: EllipticCurveTypes.secp256k1,

    /// addrClsLegacy: P2PKHAddrEncoder,
  );

  /// Configuration for Elrond
  final BipCoinConfig elrond = BipCoinConfig(
    coinNames: CoinsConf.elrond.coinName,
    coinIdx: Slip44.elrond,
    chainType: ChainType.mainnet,
    defPath: derPathHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.ed25519,
    addressEncoder:
        (params, config) => EgldAddrEncoder().encodeKey(params.pubKey),
  );

  /// Configuration for Eos
  final BipCoinConfig eos = BipCoinConfig(
    coinNames: CoinsConf.eos.coinName,
    coinIdx: Slip44.eos,
    chainType: ChainType.mainnet,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder:
        (params, config) => EosAddrEncoder().encodeKey(params.pubKey),
  );

  /// Configuration for Ergo main net
  final BipCoinConfig ergoMainNet = BipCoinConfig(
    coinNames: CoinsConf.ergoMainNet.coinName,
    coinIdx: Slip44.ergo,
    chainType: ChainType.mainnet,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder:
        (params, config) => ErgoP2PKHAddrEncoder().encodeKey(
          params.pubKey,
          netType: ErgoNetworkTypes.mainnet,
        ),
  );

  /// Configuration for Ergo test net
  final BipCoinConfig ergoTestNet = BipCoinConfig(
    coinNames: CoinsConf.ergoTestNet.coinName,
    coinIdx: Slip44.ergo,
    chainType: ChainType.testnet,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerTest,
    wifNetVer: null,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder:
        (params, config) => ErgoP2PKHAddrEncoder().encodeKey(
          params.pubKey,
          netType: ErgoNetworkTypes.testnet,
        ),
  );

  /// Configuration for Ethereum
  final BipCoinConfig ethereum = BipCoinConfig(
    coinNames: CoinsConf.ethereum.coinName,
    coinIdx: Slip44.ethereum,
    chainType: ChainType.mainnet,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder:
        (params, config) => EthAddrEncoder().encodeKey(params.pubKey),
  );

  /// Configuration for EthereumTestnet
  final BipCoinConfig ethereumTestnet = BipCoinConfig(
    coinNames: CoinsConf.ethereum.coinName,
    coinIdx: Slip44.testnet,
    chainType: ChainType.testnet,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder:
        (params, config) => EthAddrEncoder().encodeKey(params.pubKey),
  );

  /// Configuration for Ethereum Classic
  final BipCoinConfig ethereumClassic = BipCoinConfig(
    coinNames: CoinsConf.ethereumClassic.coinName,
    coinIdx: Slip44.ethereumClassic,
    chainType: ChainType.mainnet,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder:
        (params, config) => EthAddrEncoder().encodeKey(params.pubKey),
  );

  /// Configuration for Fantom Opera
  final BipCoinConfig fantomOpera = BipCoinConfig(
    coinNames: CoinsConf.fantomOpera.coinName,
    coinIdx: Slip44.ethereum,
    chainType: ChainType.mainnet,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder:
        (params, config) => EthAddrEncoder().encodeKey(params.pubKey),
  );

  /// Configuration for Filecoin
  final BipCoinConfig filecoin = BipCoinConfig(
    coinNames: CoinsConf.filecoin.coinName,
    coinIdx: Slip44.filecoin,
    chainType: ChainType.mainnet,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder:
        (params, config) => FilSecp256k1AddrEncoder().encodeKey(params.pubKey),
  );

  /// Configuration for Harmony One (Metamask address)
  final BipCoinConfig harmonyOneMetamask = BipCoinConfig(
    coinNames: CoinsConf.harmonyOne.coinName,
    coinIdx: Slip44.ethereum,
    chainType: ChainType.mainnet,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder:
        (params, config) => EthAddrEncoder().encodeKey(params.pubKey),
  );

  /// Configuration for Harmony One (Ethereum address)
  final BipCoinConfig harmonyOneEth = BipCoinConfig(
    coinNames: CoinsConf.harmonyOne.coinName,
    coinIdx: Slip44.harmonyOne,
    chainType: ChainType.mainnet,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder:
        (params, config) => EthAddrEncoder().encodeKey(params.pubKey),
  );

  /// Configuration for Harmony One (Atom address)
  final BipCoinConfig harmonyOneAtom = BipCoinConfig(
    coinNames: CoinsConf.harmonyOne.coinName,
    coinIdx: Slip44.harmonyOne,
    chainType: ChainType.mainnet,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder:
        (params, config) => OneAddrEncoder().encodeKey(params.pubKey),
  );

  /// Configuration for Huobi Chain
  final BipCoinConfig huobiChain = BipCoinConfig(
    coinNames: CoinsConf.huobiChain.coinName,
    coinIdx: Slip44.ethereum,
    chainType: ChainType.mainnet,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder:
        (params, config) => EthAddrEncoder().encodeKey(params.pubKey),
  );

  /// Configuration for Icon
  final BipCoinConfig icon = BipCoinConfig(
    coinNames: CoinsConf.icon.coinName,
    coinIdx: Slip44.icon,
    chainType: ChainType.mainnet,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder:
        (params, config) => IcxAddrEncoder().encodeKey(params.pubKey),
  );

  /// Configuration for Injective
  final BipCoinConfig injective = BipCoinConfig(
    coinNames: CoinsConf.injective.coinName,
    coinIdx: Slip44.ethereum,
    chainType: ChainType.mainnet,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder:
        (params, config) => InjAddrEncoder().encodeKey(params.pubKey),
  );

  /// Configuration for IRISnet
  final BipCoinConfig irisNet = BipCoinConfig(
    coinNames: CoinsConf.irisNet.coinName,
    coinIdx: Slip44.atom,
    chainType: ChainType.mainnet,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder:
        (params, config) => AtomAddrEncoder().encodeKey(
          params.pubKey,
          hrp: CoinsConf.irisNet.params.addrHrp,
        ),
  );

  /// Configuration for Kava
  final BipCoinConfig kava = BipCoinConfig(
    coinNames: CoinsConf.kava.coinName,
    coinIdx: Slip44.kava,
    chainType: ChainType.mainnet,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder:
        (params, config) => AtomAddrEncoder().encodeKey(
          params.pubKey,
          hrp: CoinsConf.kava.params.addrHrp,
        ),
  );

  /// Configuration for Kusama (ed25519 SLIP-0010)
  final BipCoinConfig kusamaEd25519Slip = BipCoinConfig(
    coinNames: CoinsConf.kusama.coinName,
    coinIdx: Slip44.kusama,
    chainType: ChainType.mainnet,
    defPath: derPathHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.ed25519,
    addressEncoder:
        (params, config) => SubstrateEd25519AddrEncoder().encodeKey(
          params.pubKey,
          ss58Format: CoinsConf.kusama.params.addrSs58Format,
        ),
  );

  /// Configuration for KusamaTestnet (ed25519 SLIP-0010)
  final BipCoinConfig kusamaTestnetEd25519Slip = BipCoinConfig(
    coinNames: CoinsConf.kusama.coinName,
    coinIdx: Slip44.testnet,
    chainType: ChainType.mainnet,
    defPath: derPathHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.ed25519,
    addressEncoder:
        (params, config) => SubstrateEd25519AddrEncoder().encodeKey(
          params.pubKey,
          ss58Format: CoinsConf.kusama.params.addrSs58Format,
        ),
  );

  /// Configuration for Litecoin main net
  final BipLitecoinConf litecoinMainNet = BipLitecoinConf(
    coinNames: CoinsConf.litecoinMainNet.coinName,
    coinIdx: Slip44.litecoin,
    chainType: ChainType.mainnet,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    addressEncoder: (params, config) {
      return P2PKHAddrEncoder().encodeKey(
        params.pubKey,
        netVersion: switch (config.useDeprAddress) {
          false => CoinsConf.litecoinMainNet.params.p2pkhStdNetVer,
          true => CoinsConf.litecoinMainNet.params.p2pkhDeprNetVer,
        },
      );
    },
    altKeyNetVer: Bip32KeyNetVersions(
      [0x01, 0x9d, 0xa4, 0x62],
      [0x01, 0x9d, 0x9c, 0xfe],
    ),
    wifNetVer: CoinsConf.litecoinMainNet.params.wifNetVer,
    type: EllipticCurveTypes.secp256k1,
  );

  /// Configuration for Litecoin test net
  final BipLitecoinConf litecoinTestNet = BipLitecoinConf(
    coinNames: CoinsConf.litecoinTestNet.coinName,
    coinIdx: Slip44.testnet,
    chainType: ChainType.testnet,
    defPath: derPathNonHardenedFull,
    keyNetVer: Bip32KeyNetVersions(
      [0x04, 0x36, 0xf6, 0xe1],
      [0x04, 0x36, 0xef, 0x7d],
    ),
    altKeyNetVer: Bip32KeyNetVersions(
      [0x04, 0x36, 0xf6, 0xe1],
      [0x04, 0x36, 0xef, 0x7d],
    ),
    wifNetVer: CoinsConf.litecoinTestNet.params.wifNetVer,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder:
        (params, config) => P2PKHAddrEncoder().encodeKey(
          params.pubKey,
          netVersion: switch (config.useDeprAddress) {
            false => CoinsConf.litecoinTestNet.params.p2pkhStdNetVer,
            true => CoinsConf.litecoinTestNet.params.p2pkhDeprNetVer,
          },
        ),
  );

  /// Configuration for Monero (ed25519 SLIP-0010)
  final BipCoinConfig moneroEd25519Slip = BipCoinConfig(
    coinNames: CoinsConf.moneroMainNet.coinName,
    coinIdx: Slip44.monero,
    chainType: ChainType.mainnet,
    defPath: derPathHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.ed25519,
    addressEncoder:
        (params, config) =>
            throw AddressConverterException(
              "Address derivation is not supported using coinConfig. Please use the Monero class instead.",
            ),
  );

  /// Configuration for Monero (secp256k1)
  final BipCoinConfig moneroSecp256k1 = BipCoinConfig(
    coinNames: CoinsConf.moneroMainNet.coinName,
    coinIdx: Slip44.monero,
    chainType: ChainType.mainnet,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder:
        (params, config) =>
            throw AddressConverterException(
              "Address derivation is not supported using coinConfig. Please use the Monero class instead.",
            ),
  );

  /// Configuration for Nano
  final BipCoinConfig nano = BipCoinConfig(
    coinNames: CoinsConf.nano.coinName,
    coinIdx: Slip44.nano,
    chainType: ChainType.mainnet,
    defPath: derPathHardenedShort,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.ed25519Blake2b,
    addressEncoder:
        (params, config) => NanoAddrEncoder().encodeKey(params.pubKey),
  );

  /// Configuration for Near Protocol
  final BipCoinConfig nearProtocol = BipCoinConfig(
    coinNames: CoinsConf.nearProtocol.coinName,
    coinIdx: Slip44.nearProtocol,
    chainType: ChainType.mainnet,
    defPath: derPathHardenedShort,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.ed25519,
    addressEncoder:
        (params, config) => NearAddrEncoder().encodeKey(params.pubKey),
  );

  /// Configuration for Neo
  final BipCoinConfig neo = BipCoinConfig(
    coinNames: CoinsConf.neo.coinName,
    coinIdx: Slip44.neo,
    chainType: ChainType.mainnet,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.nist256p1,
    addressEncoder:
        (params, config) => NeoAddrEncoder().encodeKey(
          params.pubKey,
          versionBytes: CoinsConf.neo.params.addrVer,
        ),
  );

  /// Configuration for Nine Chronicles Gold
  final BipCoinConfig nineChroniclesGold = BipCoinConfig(
    coinNames: CoinsConf.nineChroniclesGold.coinName,
    coinIdx: Slip44.nineChronicles,
    chainType: ChainType.mainnet,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder:
        (params, config) => EthAddrEncoder().encodeKey(params.pubKey),
  );

  /// Configuration for OKEx Chain (Ethereum address)
  final BipCoinConfig okexChainEth = BipCoinConfig(
    coinNames: CoinsConf.okexChain.coinName,
    coinIdx: Slip44.ethereum,
    chainType: ChainType.mainnet,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder:
        (params, config) => EthAddrEncoder().encodeKey(params.pubKey),
  );

  /// Configuration for OKEx Chain (Atom address)
  final BipCoinConfig okexChainAtom = BipCoinConfig(
    coinNames: CoinsConf.okexChain.coinName,
    coinIdx: Slip44.ethereum,
    chainType: ChainType.mainnet,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder:
        (params, config) => OkexAddrEncoder().encodeKey(params.pubKey),
  );

  /// Configuration for OKEx Chain (old Atom address)
  final BipCoinConfig okexChainAtomOld = BipCoinConfig(
    coinNames: CoinsConf.okexChain.coinName,
    coinIdx: Slip44.okexChain,
    chainType: ChainType.mainnet,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder:
        (params, config) => OkexAddrEncoder().encodeKey(params.pubKey),
  );

  /// Configuration for Ontology
  final BipCoinConfig ontology = BipCoinConfig(
    coinNames: CoinsConf.ontology.coinName,
    coinIdx: Slip44.ontology,
    chainType: ChainType.mainnet,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.nist256p1,
    addressEncoder:
        (params, config) => NeoAddrEncoder().encodeKey(
          params.pubKey,
          versionBytes: CoinsConf.ontology.params.addrVer,
        ),
  );

  /// Configuration for Osmosis
  final BipCoinConfig osmosis = BipCoinConfig(
    coinNames: CoinsConf.osmosis.coinName,
    coinIdx: Slip44.atom,
    chainType: ChainType.mainnet,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder:
        (params, config) => AtomAddrEncoder().encodeKey(
          params.pubKey,
          hrp: CoinsConf.osmosis.params.addrHrp,
        ),
  );

  /// Configuration for Pi Network
  final BipCoinConfig piNetwork = BipCoinConfig(
    coinNames: CoinsConf.piNetwork.coinName,
    coinIdx: Slip44.piNetwork,
    chainType: ChainType.mainnet,
    defPath: derPathHardenedShort,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.ed25519,
    addressEncoder:
        (params, config) => XlmAddrEncoder().encodeKey(
          params.pubKey,
          addrType: XlmAddrTypes.pubKey,
        ),
  );

  /// Configuration for Polkadot (ed25519 SLIP-0010)
  final BipCoinConfig polkadotEd25519Slip = BipCoinConfig(
    coinNames: CoinsConf.polkadot.coinName,
    coinIdx: Slip44.polkadot,
    chainType: ChainType.mainnet,
    defPath: derPathHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.ed25519,
    addressEncoder:
        (params, config) => SubstrateEd25519AddrEncoder().encodeKey(
          params.pubKey,
          ss58Format: CoinsConf.polkadot.params.addrSs58Format,
        ),
  );
  final BipCoinConfig polkadotTestnetEd25519Slip = BipCoinConfig(
    coinNames: CoinsConf.polkadot.coinName,
    coinIdx: Slip44.testnet,
    chainType: ChainType.testnet,
    defPath: derPathHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.ed25519,
    addressEncoder:
        (params, config) => SubstrateEd25519AddrEncoder().encodeKey(
          params.pubKey,
          ss58Format: CoinsConf.genericSubstrate.params.addrSs58Format,
        ),
  );

  /// Configuration for Polygon
  final BipCoinConfig polygon = BipCoinConfig(
    coinNames: CoinsConf.polygon.coinName,
    coinIdx: Slip44.ethereum,
    chainType: ChainType.mainnet,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder:
        (params, config) => EthAddrEncoder().encodeKey(params.pubKey),
  );

  final BipCoinConfig ripple = BipCoinConfig(
    coinNames: CoinsConf.ripple.coinName,
    coinIdx: Slip44.ripple,
    chainType: ChainType.mainnet,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder:
        (params, config) => XrpAddrEncoder().encodeKey(params.pubKey),
  );

  /// Configuration for Ripple testnet
  final BipCoinConfig rippleTestnet = BipCoinConfig(
    coinNames: CoinsConf.ripple.coinName,
    coinIdx: Slip44.testnet,
    chainType: ChainType.testnet,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder:
        (params, config) => XrpAddrEncoder().encodeKey(params.pubKey),
  );

  /// Configuration for Ripple
  final BipCoinConfig rippleEd25519 = BipCoinConfig(
    coinNames: CoinsConf.ripple.coinName,
    coinIdx: Slip44.ripple,
    chainType: ChainType.mainnet,
    defPath: derPathHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.ed25519,
    addressEncoder:
        (params, config) => XrpAddrEncoder().encodeKey(
          params.pubKey,
          pubKeyType: EllipticCurveTypes.ed25519,
        ),
  );

  /// Configuration for Ripple testnet
  final BipCoinConfig rippleTestnetEd25519 = BipCoinConfig(
    coinNames: CoinsConf.ripple.coinName,
    coinIdx: Slip44.testnet,
    chainType: ChainType.testnet,
    defPath: derPathHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.ed25519,
    addressEncoder:
        (params, config) => XrpAddrEncoder().encodeKey(
          params.pubKey,
          pubKeyType: EllipticCurveTypes.ed25519,
        ),
  );
  final BipCoinConfig secretNetworkOld = BipCoinConfig(
    coinNames: CoinsConf.secretNetwork.coinName,
    coinIdx: Slip44.atom,
    chainType: ChainType.mainnet,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder:
        (params, config) => AtomAddrEncoder().encodeKey(
          params.pubKey,
          hrp: CoinsConf.secretNetwork.params.addrHrp,
        ),
  );

  /// Configuration for Secret Network (new path)
  final BipCoinConfig secretNetworkNew = BipCoinConfig(
    coinNames: CoinsConf.secretNetwork.coinName,
    coinIdx: Slip44.secretNetwork,
    chainType: ChainType.mainnet,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder:
        (params, config) => AtomAddrEncoder().encodeKey(
          params.pubKey,
          hrp: CoinsConf.secretNetwork.params.addrHrp,
        ),
  );

  /// Configuration for Solana
  final BipCoinConfig solana = BipCoinConfig(
    coinNames: CoinsConf.solana.coinName,
    coinIdx: Slip44.solana,
    chainType: ChainType.mainnet,
    defPath: derPathHardenedShort,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.ed25519,
    addressEncoder:
        (params, config) => SolAddrEncoder().encodeKey(params.pubKey),
  );

  /// Configuration for Solana
  final BipCoinConfig solanaTestnet = BipCoinConfig(
    coinNames: CoinsConf.solana.coinName,
    coinIdx: Slip44.testnet,
    chainType: ChainType.testnet,
    defPath: derPathHardenedShort,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.ed25519,
    addressEncoder:
        (params, config) => SolAddrEncoder().encodeKey(params.pubKey),
  );

  /// Configuration for Stellar
  final BipCoinConfig stellar = BipCoinConfig(
    coinNames: CoinsConf.stellar.coinName,
    coinIdx: Slip44.stellar,
    chainType: ChainType.mainnet,
    defPath: derPathHardenedShort,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.ed25519,
    addressEncoder:
        (params, config) => XlmAddrEncoder().encodeKey(
          params.pubKey,
          addrType: XlmAddrTypes.pubKey,
        ),
  );

  /// Configuration for Stellar testnet
  final BipCoinConfig stellarTestnet = BipCoinConfig(
    coinNames: CoinsConf.stellar.coinName,
    coinIdx: Slip44.testnet,
    chainType: ChainType.testnet,
    defPath: derPathHardenedShort,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.ed25519,
    addressEncoder:
        (params, config) => XlmAddrEncoder().encodeKey(
          params.pubKey,
          addrType: XlmAddrTypes.pubKey,
        ),
  );

  /// Configuration for Terra
  final BipCoinConfig terra = BipCoinConfig(
    coinNames: CoinsConf.terra.coinName,
    coinIdx: Slip44.terra,
    chainType: ChainType.mainnet,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder:
        (params, config) => AtomAddrEncoder().encodeKey(
          params.pubKey,
          hrp: CoinsConf.terra.params.addrHrp,
        ),
  );

  /// Configuration for Tezos
  final BipCoinConfig tezos = BipCoinConfig(
    coinNames: CoinsConf.tezos.coinName,
    coinIdx: Slip44.tezos,
    chainType: ChainType.mainnet,
    defPath: "0'/0'",
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.ed25519,
    addressEncoder:
        (params, config) => XtzAddrEncoder().encodeKey(
          params.pubKey,
          addressPrefix: XtzAddrPrefixes.tz1,
        ),
  );

  /// Configuration for Theta
  final BipCoinConfig theta = BipCoinConfig(
    coinNames: CoinsConf.theta.coinName,
    coinIdx: Slip44.theta,
    chainType: ChainType.mainnet,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder:
        (params, config) => EthAddrEncoder().encodeKey(params.pubKey),
  );

  /// Configuration for Tron
  final BipCoinConfig tron = BipCoinConfig(
    coinNames: CoinsConf.tron.coinName,
    coinIdx: Slip44.tron,
    chainType: ChainType.mainnet,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder:
        (params, config) => TrxAddrEncoder().encodeKey(params.pubKey),
  );

  /// Configuration for Tron testnet
  final BipCoinConfig tronTestnet = BipCoinConfig(
    coinNames: CoinsConf.tron.coinName,
    coinIdx: Slip44.testnet,
    chainType: ChainType.testnet,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder:
        (params, config) => TrxAddrEncoder().encodeKey(params.pubKey),
  );

  /// Configuration for VeChain
  final BipCoinConfig vechain = BipCoinConfig(
    coinNames: CoinsConf.veChain.coinName,
    coinIdx: Slip44.vechain,
    chainType: ChainType.mainnet,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder:
        (params, config) => EthAddrEncoder().encodeKey(params.pubKey),
  );

  /// Configuration for Verge
  final BipCoinConfig verge = BipCoinConfig(
    coinNames: CoinsConf.verge.coinName,
    coinIdx: Slip44.verge,
    chainType: ChainType.mainnet,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: CoinsConf.verge.params.wifNetVer,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder:
        (params, config) => P2PKHAddrEncoder().encodeKey(
          params.pubKey,
          netVersion: CoinsConf.verge.params.p2pkhNetVer,
        ),
  );

  /// Configuration for Zcash main net
  final BipCoinConfig zcashMainNet = BipCoinConfig(
    coinNames: CoinsConf.zcashTransparentMainNet.coinName,
    coinIdx: Slip44.zcash,
    chainType: ChainType.mainnet,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: CoinsConf.zcashTransparentMainNet.params.wifNetVer,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder:
        (params, config) => P2PKHAddrEncoder().encodeKey(
          params.pubKey,
          netVersion: CoinsConf.zcashTransparentMainNet.params.p2pkhNetVer,
        ),
  );

  /// Configuration for Zcash test net
  final BipCoinConfig zcashTestNet = BipCoinConfig(
    coinNames: CoinsConf.zcashTransparentTestNet.coinName,
    coinIdx: Slip44.testnet,
    chainType: ChainType.testnet,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerTest,
    wifNetVer: CoinsConf.zcashTransparentTestNet.params.wifNetVer,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder:
        (params, config) => P2PKHAddrEncoder().encodeKey(
          params.pubKey,
          netVersion: CoinsConf.zcashTransparentTestNet.params.p2pkhNetVer,
        ),
  );

  /// Configuration for Zcash test net
  final BipCoinConfig zcashRegtest = BipCoinConfig(
    coinNames: CoinsConf.zcashTransparentRegtest.coinName,
    coinIdx: Slip44.testnet,
    chainType: ChainType.testnet,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerTest,
    wifNetVer: CoinsConf.zcashTransparentRegtest.params.wifNetVer,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder:
        (params, config) => P2PKHAddrEncoder().encodeKey(
          params.pubKey,
          netVersion: CoinsConf.zcashTransparentRegtest.params.p2pkhNetVer,
        ),
  );

  /// Configuration for Zilliqa
  final BipCoinConfig zilliqa = BipCoinConfig(
    coinNames: CoinsConf.zilliqa.coinName,
    coinIdx: Slip44.zilliqa,
    chainType: ChainType.mainnet,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder:
        (params, config) => ZilAddrEncoder().encodeKey(params.pubKey),
  );

  final BipCoinConfig tonMainnet = BipCoinConfig(
    coinNames: CoinsConf.tonMainnet.coinName,
    coinIdx: Slip44.ton,
    chainType: ChainType.mainnet,
    defPath: derPathHardenedShort,
    keyNetVer: Bip44Conf.bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.ed25519,
    addressEncoder:
        (params, config) =>
            throw AddressConverterException(
              "Address derivation is not supported using coinConfig. Please use TonAddrEncoder class instead.",
            ),
  );
  final BipCoinConfig tonTestnet = BipCoinConfig(
    coinNames: CoinsConf.tonTestnet.coinName,
    coinIdx: Slip44.testnet,
    chainType: ChainType.testnet,
    defPath: derPathHardenedShort,
    keyNetVer: Bip44Conf.bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.ed25519,
    addressEncoder:
        (params, config) =>
            throw AddressConverterException(
              "Address derivation is not supported using coinConfig. Please use TonAddrEncoder class instead.",
            ),
  );

  /// Configuration for Electra Protocol main net
  final BipCoinConfig electraProtocolMainNet = BipCoinConfig(
    coinNames: CoinsConf.electraProtocolMainNet.coinName,
    coinIdx: Slip44.electraProtocol,
    chainType: ChainType.mainnet,
    defPath: derPathNonHardenedFull,
    keyNetVer: Bip32KeyNetVersions(
      [0x04, 0x88, 0xb2, 0x1e],
      [0x04, 0x88, 0xad, 0xe4],
    ),
    wifNetVer: CoinsConf.electraProtocolMainNet.params.wifNetVer,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder:
        (params, config) => P2PKHAddrEncoder().encodeKey(
          params.pubKey,
          netVersion: CoinsConf.electraProtocolMainNet.params.p2pkhNetVer,
        ),
  );

  /// Configuration for Electra Protocol test net
  final BipCoinConfig electraProtocolTestNet = BipCoinConfig(
    coinNames: CoinsConf.electraProtocolTestNet.coinName,
    coinIdx: Slip44.testnet,
    chainType: ChainType.testnet,
    defPath: derPathNonHardenedFull,
    keyNetVer: Bip32KeyNetVersions(
      [0x04, 0x35, 0x87, 0xcf],
      [0x04, 0x35, 0x83, 0x94],
    ),
    wifNetVer: CoinsConf.electraProtocolTestNet.params.wifNetVer,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder:
        (params, config) => P2PKHAddrEncoder().encodeKey(
          params.pubKey,
          netVersion: CoinsConf.electraProtocolTestNet.params.p2pkhNetVer,
        ),
  );

  /// Configuration for Sui mainnet (Secp256k1)
  final BipCoinConfig suiSecp256k1 = BipCoinConfig(
    coinNames: CoinsConf.sui.coinName,
    coinIdx: Slip44.sui,
    chainType: ChainType.mainnet,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    purpose: Bip32KeyIndex.hardenIndex(54),
    type: EllipticCurveTypes.secp256k1,
    addressEncoder:
        (params, config) => SuiSecp256k1AddrEncoder().encodeKey(params.pubKey),
  );

  /// Configuration for Sui mainnet (Secp256r1)
  final BipCoinConfig suiSecp256r1 = BipCoinConfig(
    coinNames: CoinsConf.sui.coinName,
    coinIdx: Slip44.sui,
    chainType: ChainType.mainnet,
    defPath: derPathNonHardenedFull,
    purpose: Bip32KeyIndex.hardenIndex(74),
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.nist256p1Hybrid,
    addressEncoder:
        (params, config) => SuiSecp256r1AddrEncoder().encodeKey(params.pubKey),
  );

  /// Configuration for Sui mainnet (Ed25519)
  final BipCoinConfig suiEd25519 = BipCoinConfig(
    coinNames: CoinsConf.sui.coinName,
    coinIdx: Slip44.sui,
    chainType: ChainType.mainnet,
    defPath: derPathHardenedFull,
    keyNetVer: bip44BtcKeyNetVerMain,
    wifNetVer: null,
    type: EllipticCurveTypes.ed25519,
    addressEncoder:
        (params, config) => SuiAddrEncoder().encodeKey(params.pubKey),
  );
}
