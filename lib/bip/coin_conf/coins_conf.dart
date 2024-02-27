import 'package:blockchain_utils/bip/slip/slip173/slip173.dart';
import 'package:blockchain_utils/bip/coin_conf/coins_name.dart';

import 'coin_conf.dart';

/// Bitcoin network parameters for mainnet and testnet.
const btcP2PKHNetVerMn = [0x00];
const btcP2SHNetVerMn = [0x05];
const btcP2WPKHHrpMn = Slip173.bitcoinMainnet;
const btcP2WPKHWitVerMn = 0;
const btcP2TRHrpMn = Slip173.bitcoinMainnet;
const btcP2TRWitVerMn = 1;
const btcWifNetVerMn = [0x80];

/// Testnet
const btcP2PKHNetVerTn = [0x6f];
const btcP2SHNetVerTn = [0xc4];
const btcP2WPKHHrpTn = Slip173.bitcoinTestnet;
const btcP2WPKHWitVerTn = 0;
const btcP2TRHrpTn = Slip173.bitcoinTestnet;
const btcP2TRWitVerTn = 1;
const btcWifNetVerTn = [0xef];

/// A class that provides configurations for various cryptocurrencies.
class CoinsConf {
  /// Configuration for Acala
  static const CoinConf acala = CoinConf(
      coinName: CoinNames("Acala", "ACA"),
      params: CoinParams(addrSs58Format: 10));

  /// Configuration for Akash Network
  static const CoinConf akashNetwork = CoinConf(
    coinName: CoinNames("Akash Network", "AKT"),
    params: CoinParams(
      addrHrp: Slip173.akashNetwork,
    ),
  );

  /// Configuration for Algorand
  static const CoinConf algorand =
      CoinConf(coinName: CoinNames("Algorand", "ALGO"), params: CoinParams());

  /// Class container for coins configuration.

  /// Configuration for Aptos
  static const CoinConf aptos = CoinConf(
      coinName: CoinNames("Aptos", "APTOS"),
      params: CoinParams(
        addrPrefix: "0x",
      ));

  /// Configuration for Avax C-Chain
  static const CoinConf avaxCChain = CoinConf(
      coinName: CoinNames("Avax C-Chain", "AVAX"), params: CoinParams());

  /// Configuration for Avax P-Chain
  static const CoinConf avaxPChain = CoinConf(
    coinName: CoinNames("Avax P-Chain", "AVAX"),
    params: CoinParams(
      addrHrp: "avax",
      addrPrefix: "P-",
    ),
  );

  /// Configuration for Avax X-Chain
  static const CoinConf avaxXChain = CoinConf(
    coinName: CoinNames("Avax X-Chain", "AVAX"),
    params: CoinParams(
      addrHrp: "avax",
      addrPrefix: "X-",
    ),
  );

  /// Configuration for Axelar
  static const CoinConf axelar = CoinConf(
    coinName: CoinNames("Axelar", "AXL"),
    params: CoinParams(
      addrHrp: Slip173.axelar,
    ),
  );

  /// Configuration for Band Protocol
  static const CoinConf bandProtocol = CoinConf(
    coinName: CoinNames("Band Protocol", "BAND"),
    params: CoinParams(
      addrHrp: Slip173.bandProtocol,
    ),
  );

  /// Configuration for Bifrost
  static const CoinConf bifrost = CoinConf(
    coinName: CoinNames("Bifrost", "BNC"),
    params: CoinParams(
      addrSs58Format: 6,
    ),
  );

  /// Configuration for Binance Chain
  static const CoinConf binanceChain = CoinConf(
    coinName: CoinNames("Binance Chain", "BNB"),
    params: CoinParams(
      addrHrp: Slip173.binanceChain,
    ),
  );

  /// Configuration for Binance Smart Chain
  static const CoinConf binanceSmartChain = CoinConf(
      coinName: CoinNames("Binance Smart Chain", "BNB"), params: CoinParams());

  /// Configuration for Bitcoin main net
  static const CoinConf bitcoinMainNet = CoinConf(
    coinName: CoinNames("Bitcoin", "BTC"),
    params: CoinParams(
      p2pkhNetVer: btcP2PKHNetVerMn,
      p2shNetVer: btcP2SHNetVerMn,
      p2wpkhHrp: btcP2WPKHHrpMn,
      p2wpkhWitVer: btcP2WPKHWitVerMn,
      p2trHrp: btcP2TRHrpMn,
      p2trWitVer: btcP2TRWitVerMn,
      wifNetVer: btcWifNetVerMn,
    ),
  );

  /// Configuration for Bitcoin test net
  static const CoinConf bitcoinTestNet = CoinConf(
    coinName: CoinNames("Bitcoin TestNet", "BTC"),
    params: CoinParams(
      p2pkhNetVer: btcP2PKHNetVerTn,
      p2shNetVer: btcP2SHNetVerTn,
      p2wpkhHrp: btcP2WPKHHrpTn,
      p2wpkhWitVer: btcP2WPKHWitVerTn,
      p2trHrp: btcP2TRHrpTn,
      p2trWitVer: btcP2TRWitVerMn,
      wifNetVer: btcWifNetVerTn,
    ),
  );

  /// Configuration for Bitcoin Cash main net
  static const CoinConf bitcoinCashMainNet = CoinConf(
    coinName: CoinNames("Bitcoin Cash", "BCH"),
    params: CoinParams(
      p2pkhStdHrp: "bitcoincash",
      p2pkhStdNetVer: btcP2PKHNetVerMn,
      p2pkhLegacyNetVer: btcP2PKHNetVerMn,
      p2shStdHrp: "bitcoincash",
      p2shStdNetVer: [0x08],
      p2shLegacyNetVer: btcP2SHNetVerMn,
      wifNetVer: btcWifNetVerMn,
    ),
  );

  /// Configuration for Bitcoin Cash test net
  static const CoinConf bitcoinCashTestNet = CoinConf(
    coinName: CoinNames("Bitcoin Cash TestNet", "BCH"),
    params: CoinParams(
      p2pkhStdHrp: "bchtest",
      p2pkhStdNetVer: [0x00],
      p2pkhLegacyNetVer: btcP2PKHNetVerTn,
      p2shStdHrp: "bchtest",
      p2shStdNetVer: [0x08],
      p2shLegacyNetVer: btcP2SHNetVerTn,
      wifNetVer: btcWifNetVerTn,
    ),
  );

  /// Configuration for Bitcoin Cash Simple Ledger Protocol main net
  static const CoinConf bitcoinCashSlpMainNet = CoinConf(
    coinName: CoinNames("Bitcoin Cash SLP", "SLP"),
    params: CoinParams(
      p2pkhStdHrp: "simpleledger",
      p2pkhStdNetVer: [0x00],
      p2pkhLegacyNetVer: btcP2PKHNetVerMn,
      p2shStdHrp: "simpleledger",
      p2shStdNetVer: [0x08],
      p2shLegacyNetVer: btcP2SHNetVerMn,
      wifNetVer: btcWifNetVerMn,
    ),
  );

  /// Configuration for Bitcoin Cash Simple Ledger Protocol test net
  static const CoinConf bitcoinCashSlpTestNet = CoinConf(
    coinName: CoinNames("Bitcoin Cash SLP TestNet", "SLP"),
    params: CoinParams(
      p2pkhStdHrp: "slptest",
      p2pkhStdNetVer: [0x00],
      p2pkhLegacyNetVer: btcP2PKHNetVerTn,
      p2shStdHrp: "slptest",
      p2shStdNetVer: [0x08],
      p2shLegacyNetVer: btcP2SHNetVerTn,
      wifNetVer: btcWifNetVerTn,
    ),
  );

  /// Configuration for Bitcoin SV main net
  static const CoinConf bitcoinSvMainNet = CoinConf(
    coinName: CoinNames("BitcoinSV", "BSV"),
    params: CoinParams(
      p2pkhNetVer: btcP2PKHNetVerMn,
      p2shNetVer: btcP2SHNetVerMn,
      wifNetVer: btcWifNetVerMn,
    ),
  );

  /// Configuration for Bitcoin SV test net
  static const CoinConf bitcoinSvTestNet = CoinConf(
    coinName: CoinNames("BitcoinSV TestNet", "BSV"),
    params: CoinParams(
      p2pkhNetVer: btcP2PKHNetVerTn,
      p2shNetVer: btcP2SHNetVerTn,
      wifNetVer: btcWifNetVerTn,
    ),
  );

  /// Configuration for Cardano main net
  static const CoinConf cardanoMainNet = CoinConf(
    coinName: CoinNames("Cardano", "ADA"),
    params: CoinParams(
      addrHrp: "addr",
      stakingAddrHrp: "stake",
    ),
  );

  /// Configuration for Cardano test
  static const CoinConf cardanoTestNet = CoinConf(
    coinName: CoinNames("Cardano TestNet", "ADA"),
    params: CoinParams(
      addrHrp: "addr_test",
      stakingAddrHrp: "stake_test",
    ),
  );

  /// Configuration for Celo
  static const CoinConf celo =
      CoinConf(coinName: CoinNames("Celo", "CELO"), params: CoinParams());

  /// Configuration for Certik
  static const CoinConf certik = CoinConf(
    coinName: CoinNames("Certik", "CTK"),
    params: CoinParams(
      addrHrp: Slip173.certik,
    ),
  );

  /// Configuration for ChainX
  static const CoinConf chainX = CoinConf(
    coinName: CoinNames("ChainX", "PCX"),
    params: CoinParams(
      addrSs58Format: 44,
    ),
  );

  /// Configuration for Chihuahua
  static const CoinConf chihuahua = CoinConf(
    coinName: CoinNames("Chihuahua", "HUAHUA"),
    params: CoinParams(
      addrHrp: Slip173.chihuahua,
    ),
  );

  /// Configuration for Cosmos
  static const CoinConf cosmos = CoinConf(
    coinName: CoinNames("Cosmos", "ATOM"),
    params: CoinParams(
      addrHrp: Slip173.cosmos,
    ),
  );

  /// Configuration for Dash main net
  static const CoinConf dashMainNet = CoinConf(
    coinName: CoinNames("Dash", "DASH"),
    params: CoinParams(
      p2pkhNetVer: [0x4c],
      p2shNetVer: [0x10],
      wifNetVer: [0xcc],
    ),
  );

  /// Configuration for Dash test net
  static const CoinConf dashTestNet = CoinConf(
    coinName: CoinNames("Dash TestNet", "DASH"),
    params: CoinParams(
      p2pkhNetVer: [0x8c],
      p2shNetVer: [0x13],
      wifNetVer: btcWifNetVerTn,
    ),
  );

  /// Configuration for Dogecoin main net
  static const CoinConf dogecoinMainNet = CoinConf(
    coinName: CoinNames("Dogecoin", "DOGE"),
    params: CoinParams(
      p2pkhNetVer: [0x1e],
      p2shNetVer: [0x16],
      wifNetVer: [0x9e],
    ),
  );

  /// Configuration for Dogecoin test net
  static const CoinConf dogecoinTestNet = CoinConf(
    coinName: CoinNames("Dogecoin TestNet", "DOGE"),
    params: CoinParams(
      p2pkhNetVer: [0x71],
      p2shNetVer: btcP2SHNetVerTn,
      wifNetVer: [0xf1],
    ),
  );

  /// Configuration for eCash main net
  static const CoinConf ecashMainNet = CoinConf(
    coinName: CoinNames("eCash", "XEC"),
    params: CoinParams(
      p2pkhStdHrp: "ecash",
      p2pkhStdNetVer: [0x00],
      p2pkhLegacyNetVer: btcP2PKHNetVerMn,
      p2shStdHrp: "ecash",
      p2shStdNetVer: [0x08],
      p2shLegacyNetVer: btcP2SHNetVerMn,
      wifNetVer: btcWifNetVerMn,
    ),
  );

  /// Configuration for eCash test net
  static const CoinConf ecashTestNet = CoinConf(
    coinName: CoinNames("eCash TestNet", "XEC"),
    params: CoinParams(
      p2pkhStdHrp: "ectest",
      p2pkhStdNetVer: [0x00],
      p2pkhLegacyNetVer: btcP2PKHNetVerTn,
      p2shStdHrp: "ectest",
      p2shStdNetVer: [0x08],
      p2shLegacyNetVer: btcP2SHNetVerTn,
      wifNetVer: btcWifNetVerTn,
    ),
  );

  /// Configuration for Edgeware
  static const CoinConf edgeware = CoinConf(
    coinName: CoinNames("Edgeware", "EDG"),
    params: CoinParams(
      addrSs58Format: 7,
    ),
  );

  /// Configuration for Elrond
  static const CoinConf elrond = CoinConf(
    coinName: CoinNames("Elrond eGold", "eGLD"),
    params: CoinParams(
      addrHrp: Slip173.elrond,
    ),
  );

  /// Configuration for Eos
  static const CoinConf eos = CoinConf(
    coinName: CoinNames("EOS", "EOS"),
    params: CoinParams(
      addrPrefix: "EOS",
    ),
  );

  /// Configuration for Ergo main net
  static const CoinConf ergoMainNet =
      CoinConf(coinName: CoinNames("Ergo", "ERGO"), params: CoinParams());

  /// Configuration for Ergo test net
  static const CoinConf ergoTestNet = CoinConf(
      coinName: CoinNames("Ergo TestNet", "ERGO"), params: CoinParams());

  /// Configuration for Ethereum
  static const CoinConf ethereum = CoinConf(
    coinName: CoinNames("Ethereum", "ETH"),
    params: CoinParams(
      addrPrefix: "0x",
    ),
  );

  /// Configuration for Ethereum Classic
  static const CoinConf ethereumClassic = CoinConf(
      coinName: CoinNames("Ethereum Classic", "ETC"), params: CoinParams());

  /// Configuration for Fantom Opera
  static const CoinConf fantomOpera = CoinConf(
      coinName: CoinNames("Fantom Opera", "FTM"), params: CoinParams());

  /// Configuration for Filecoin
  static const CoinConf filecoin = CoinConf(
    coinName: CoinNames("Filecoin", "FIL"),
    params: CoinParams(
      addrPrefix: "f",
    ),
  );

  /// Configuration for generic Substrate coin
  static const CoinConf genericSubstrate = CoinConf(
      coinName: CoinNames("Generic Substrate", ""),
      params: CoinParams(addrSs58Format: 42));

  /// Configuration for Harmony One
  static const CoinConf harmonyOne = CoinConf(
    coinName: CoinNames("Harmony One", "ONE"),
    params: CoinParams(
      addrHrp: Slip173.harmonyOne,
    ),
  );

  /// Configuration for Huobi Chain
  static const CoinConf huobiChain =
      CoinConf(coinName: CoinNames("Huobi Token", "HT"), params: CoinParams());

  /// Configuration for Icon
  static const CoinConf icon = CoinConf(
    coinName: CoinNames("Icon", "ICX"),
    params: CoinParams(
      addrPrefix: "hx",
    ),
  );

  /// Configuration for Injective
  static const CoinConf injective = CoinConf(
    coinName: CoinNames("Injective", "INJ"),
    params: CoinParams(
      addrHrp: Slip173.injective,
    ),
  );

  /// Configuration for IRISnet
  static const CoinConf irisNet = CoinConf(
    coinName: CoinNames("IRIS Network", "IRIS"),
    params: CoinParams(
      addrHrp: Slip173.irisNetwork,
    ),
  );

  /// Configuration for Karura
  static const CoinConf karura = CoinConf(
      coinName: CoinNames("Karura", "KAR"),
      params: CoinParams(addrSs58Format: 8));

  /// Configuration for Kava
  static const CoinConf kava = CoinConf(
    coinName: CoinNames("Kava", "KAVA"),
    params: CoinParams(
      addrHrp: Slip173.kava,
    ),
  );

  /// Configuration for Kusama
  static const CoinConf kusama = CoinConf(
      coinName: CoinNames("Kusama", "KSM"),
      params: CoinParams(addrSs58Format: 2));

  /// Configuration for Litecoin main net
  static const CoinConf litecoinMainNet = CoinConf(
    coinName: CoinNames("Litecoin", "LTC"),
    params: CoinParams(
      p2pkhStdNetVer: [0x30],
      p2pkhDeprNetVer: btcP2PKHNetVerMn,
      p2shStdNetVer: [0x32],
      p2shDeprNetVer: btcP2SHNetVerMn,
      p2wpkhHrp: Slip173.litecoinMainnet,
      p2wpkhWitVer: btcP2WPKHWitVerMn,
      wifNetVer: [0xb0],
    ),
  );

  /// Configuration for Litecoin test net
  static const CoinConf litecoinTestNet = CoinConf(
    coinName: CoinNames("Litecoin TestNet", "LTC"),
    params: CoinParams(
      p2pkhStdNetVer: [0x6f],
      p2pkhDeprNetVer: btcP2PKHNetVerTn,
      p2shStdNetVer: [0x3a],
      p2shDeprNetVer: btcP2SHNetVerTn,
      p2wpkhHrp: Slip173.litecoinTestnet,
      p2wpkhWitVer: btcP2WPKHWitVerTn,
      wifNetVer: btcWifNetVerTn,
    ),
  );

  /// Configuration for Monero main net
  static const CoinConf moneroMainNet = CoinConf(
    coinName: CoinNames("Monero", "XMR"),
    params: CoinParams(
      addrNetVer: [0x12],
      addrIntNetVer: [0x13],
      subaddrNetVer: [0x2A],
    ),
  );

  /// Configuration for Monero stage net
  static const CoinConf moneroStageNet = CoinConf(
    coinName: CoinNames("Monero StageNet", "XMR"),
    params: CoinParams(
      addrNetVer: [0x18],
      addrIntNetVer: [0x19],
      subaddrNetVer: [0x24],
    ),
  );

  /// Configuration for Monero test net
  static const CoinConf moneroTestNet = CoinConf(
    coinName: CoinNames("Monero TestNet", "XMR"),
    params: CoinParams(
      addrNetVer: [0x35],
      addrIntNetVer: [0x36],
      subaddrNetVer: [0x3F],
    ),
  );

  /// Configuration for Moonbeam
  static const CoinConf moonbeam = CoinConf(
      coinName: CoinNames("Moonbeam", "GLMR"),
      params: CoinParams(addrSs58Format: 1284));

  /// Configuration for Moonriver
  static const CoinConf moonriver = CoinConf(
      coinName: CoinNames("Moonriver", "MOVR"),
      params: CoinParams(addrSs58Format: 1285));

  /// Configuration for Nano
  static const CoinConf nano = CoinConf(
      coinName: CoinNames("Nano", "NANO"),
      params: CoinParams(addrPrefix: "nano_"));

  /// Configuration for Near Protocol
  static const CoinConf nearProtocol = CoinConf(
      coinName: CoinNames("Near Protocol", "NEAR"), params: CoinParams());

  /// Configuration for Neo
  static const CoinConf neo = CoinConf(
      coinName: CoinNames("NEO", "NEO"), params: CoinParams(addrVer: [0x17]));

  /// Configuration for Nine Chronicles Gold
  static const CoinConf nineChroniclesGold = CoinConf(
      coinName: CoinNames("NineChroniclesGold", "NCG"), params: CoinParams());

  /// Configuration for OKEx Chain
  static const CoinConf okexChain = CoinConf(
    coinName: CoinNames("OKExChain", "OKT"),
    params: CoinParams(
      addrHrp: Slip173.okexChain,
    ),
  );

  /// Configuration for Ontology
  static const CoinConf ontology = CoinConf(
      coinName: CoinNames("Ontology", "ONT"),
      params: CoinParams(addrVer: [0x17]));

  /// Configuration for Osmosis
  static const CoinConf osmosis = CoinConf(
    coinName: CoinNames("Osmosis", "OSMO"),
    params: CoinParams(
      addrHrp: Slip173.osmosis,
    ),
  );

  /// Configuration for Phala
  static const CoinConf phala = CoinConf(
      coinName: CoinNames("Phala Network", "PHA"),
      params: CoinParams(addrSs58Format: 30));

  /// Configuration for Pi Network
  static const CoinConf piNetwork =
      CoinConf(coinName: CoinNames("Pi Network", "PI"), params: CoinParams());

  /// Configuration for Plasm
  static const CoinConf plasm = CoinConf(
      coinName: CoinNames("Plasm Network", "PLM"),
      params: CoinParams(addrSs58Format: 5));

  /// Configuration for Polkadot
  static const CoinConf polkadot = CoinConf(
      coinName: CoinNames("Polkadot", "DOT"),
      params: CoinParams(addrSs58Format: 0));

  /// Configuration for Polygon
  static const CoinConf polygon =
      CoinConf(coinName: CoinNames("Polygon", "MATIC"), params: CoinParams());

  /// Configuration for Ripple
  static const CoinConf ripple = CoinConf(
      coinName: CoinNames("Ripple", "XRP"),
      params:
          CoinParams(p2pkhNetVer: btcP2PKHNetVerMn, addrNetVer: [0x05, 0x44]));

  /// Configuration for RippleTestNet
  static const CoinConf rippleTestNet = CoinConf(
      coinName: CoinNames("Ripple", "XRP"),
      params:
          CoinParams(p2pkhNetVer: btcP2PKHNetVerMn, addrNetVer: [0x04, 0x93]));

  /// Configuration for Secret Network
  static const CoinConf secretNetwork = CoinConf(
    coinName: CoinNames("Secret Network", "SCRT"),
    params: CoinParams(
      addrHrp: Slip173.secretNetwork,
    ),
  );

  /// Configuration for Solana
  static const CoinConf solana =
      CoinConf(coinName: CoinNames("Solana", "SOL"), params: CoinParams());

  /// Configuration for Sora
  static const CoinConf sora = CoinConf(
      coinName: CoinNames("Sora", "XOR"),
      params: CoinParams(addrSs58Format: 69));

  /// Configuration for Stafi
  static const CoinConf stafi = CoinConf(
      coinName: CoinNames("Stafi", "FIS"),
      params: CoinParams(addrSs58Format: 20));

  /// Configuration for Stellar
  static const CoinConf stellar =
      CoinConf(coinName: CoinNames("Stellar", "XLM"), params: CoinParams());

  /// Configuration for Terra
  static const CoinConf terra = CoinConf(
    coinName: CoinNames("Terra", "LUNA"),
    params: CoinParams(
      addrHrp: Slip173.terra,
    ),
  );

  /// Configuration for Tezos
  static const CoinConf tezos =
      CoinConf(coinName: CoinNames("Tezos", "XTZ"), params: CoinParams());

  /// Configuration for Theta
  static const CoinConf theta = CoinConf(
      coinName: CoinNames("Theta Network", "THETA"), params: CoinParams());

  /// Configuration for Tron
  static const CoinConf tron = CoinConf(
    coinName: CoinNames("Tron", "TRX"),
    params: CoinParams(
      addrPrefix: "0x41",
    ),
  );

  /// Configuration for VeChain
  static const CoinConf veChain =
      CoinConf(coinName: CoinNames("VeChain", "VET"), params: CoinParams());

  /// Configuration for Verge
  static const CoinConf verge = CoinConf(
    coinName: CoinNames("Verge", "XVG"),
    params: CoinParams(
      p2pkhNetVer: [0x1e],
      wifNetVer: [0x9e],
    ),
  );

  /// Configuration for Zcash main net
  static const CoinConf zcashMainNet = CoinConf(
    coinName: CoinNames("Zcash", "ZEC"),
    params: CoinParams(
      p2pkhNetVer: [0x1c, 0xb8],
      p2shNetVer: [0x1c, 0xbd],
      wifNetVer: btcWifNetVerMn,
    ),
  );

  /// Configuration for Zcash test net
  static const CoinConf zcashTestNet = CoinConf(
      coinName: CoinNames("Zcash TestNet", "ZEC"),
      params: CoinParams(
        p2pkhNetVer: [0x1d, 0x25],
        p2shNetVer: [0x1c, 0xba],
        wifNetVer: btcWifNetVerTn,
      ));

  /// Configuration for Zilliqa
  static const CoinConf zilliqa = CoinConf(
    coinName: CoinNames("Zilliqa", "ZIL"),
    params: CoinParams(
      addrHrp: Slip173.zilliqa,
    ),
  );
}
