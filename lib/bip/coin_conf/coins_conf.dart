/// Main net

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
    params: {
      "addr_ss58_format": 10,
    },
  );

  /// Configuration for Akash Network
  static const CoinConf akashNetwork = CoinConf(
    coinName: CoinNames("Akash Network", "AKT"),
    params: {
      "addr_hrp": Slip173.akashNetwork,
    },
  );

  /// Configuration for Algorand
  static const CoinConf algorand = CoinConf(
    coinName: CoinNames("Algorand", "ALGO"),
    params: {},
  );

  /// Class container for coins configuration.

  /// Configuration for Aptos
  static const CoinConf aptos = CoinConf(
    coinName: CoinNames("Aptos", "APTOS"),
    params: {
      "addr_prefix": "0x",
    },
  );

  /// Configuration for Avax C-Chain
  static const CoinConf avaxCChain = CoinConf(
    coinName: CoinNames("Avax C-Chain", "AVAX"),
    params: {},
  );

  /// Configuration for Avax P-Chain
  static const CoinConf avaxPChain = CoinConf(
    coinName: CoinNames("Avax P-Chain", "AVAX"),
    params: {
      "addr_hrp": "avax",
      "addr_prefix": "P-",
    },
  );

  /// Configuration for Avax X-Chain
  static const CoinConf avaxXChain = CoinConf(
    coinName: CoinNames("Avax X-Chain", "AVAX"),
    params: {
      "addr_hrp": "avax",
      "addr_prefix": "X-",
    },
  );

  /// Configuration for Axelar
  static const CoinConf axelar = CoinConf(
    coinName: CoinNames("Axelar", "AXL"),
    params: {
      "addr_hrp": Slip173.axelar,
    },
  );

  /// Configuration for Band Protocol
  static const CoinConf bandProtocol = CoinConf(
    coinName: CoinNames("Band Protocol", "BAND"),
    params: {
      "addr_hrp": Slip173.bandProtocol,
    },
  );

  /// Configuration for Bifrost
  static const CoinConf bifrost = CoinConf(
    coinName: CoinNames("Bifrost", "BNC"),
    params: {
      "addr_ss58_format": 6,
    },
  );

  /// Configuration for Binance Chain
  static const CoinConf binanceChain = CoinConf(
    coinName: CoinNames("Binance Chain", "BNB"),
    params: {
      "addr_hrp": Slip173.binanceChain,
    },
  );

  /// Configuration for Binance Smart Chain
  static const CoinConf binanceSmartChain = CoinConf(
    coinName: CoinNames("Binance Smart Chain", "BNB"),
    params: {},
  );

  /// Configuration for Bitcoin main net
  static const CoinConf bitcoinMainNet = CoinConf(
    coinName: CoinNames("Bitcoin", "BTC"),
    params: {
      "p2pkh_net_ver": btcP2PKHNetVerMn,
      "p2sh_net_ver": btcP2SHNetVerMn,
      "p2wpkh_hrp": btcP2WPKHHrpMn,
      "p2wpkh_wit_ver": btcP2WPKHWitVerMn,
      "p2tr_hrp": btcP2TRHrpMn,
      "p2tr_wit_ver": btcP2TRWitVerMn,
      "wif_net_ver": btcWifNetVerMn,
    },
  );

  /// Configuration for Bitcoin test net
  static const CoinConf bitcoinTestNet = CoinConf(
    coinName: CoinNames("Bitcoin TestNet", "BTC"),
    params: {
      "p2pkh_net_ver": btcP2PKHNetVerTn,
      "p2sh_net_ver": btcP2SHNetVerTn,
      "p2wpkh_hrp": btcP2WPKHHrpTn,
      "p2wpkh_wit_ver": btcP2WPKHWitVerTn,
      "p2tr_hrp": btcP2TRHrpTn,
      "p2tr_wit_ver": btcP2TRWitVerMn,
      "wif_net_ver": btcWifNetVerTn,
    },
  );

  /// Configuration for Bitcoin Cash main net
  static const CoinConf bitcoinCashMainNet = CoinConf(
    coinName: CoinNames("Bitcoin Cash", "BCH"),
    params: {
      "p2pkh_std_hrp": "bitcoincash",
      "p2pkh_std_net_ver": btcP2PKHNetVerMn,
      "p2pkh_legacy_net_ver": btcP2PKHNetVerMn,
      "p2sh_std_hrp": "bitcoincash",
      "p2sh_std_net_ver": [0x08],
      "p2sh_legacy_net_ver": btcP2SHNetVerMn,
      "wif_net_ver": btcWifNetVerMn,
    },
  );

  /// Configuration for Bitcoin Cash test net
  static const CoinConf bitcoinCashTestNet = CoinConf(
    coinName: CoinNames("Bitcoin Cash TestNet", "BCH"),
    params: {
      "p2pkh_std_hrp": "bchtest",
      "p2pkh_std_net_ver": [0x00],
      "p2pkh_legacy_net_ver": btcP2PKHNetVerTn,
      "p2sh_std_hrp": "bchtest",
      "p2sh_std_net_ver": [0x08],
      "p2sh_legacy_net_ver": btcP2SHNetVerTn,
      "wif_net_ver": btcWifNetVerTn,
    },
  );

  /// Configuration for Bitcoin Cash Simple Ledger Protocol main net
  static const CoinConf bitcoinCashSlpMainNet = CoinConf(
    coinName: CoinNames("Bitcoin Cash SLP", "SLP"),
    params: {
      "p2pkh_std_hrp": "simpleledger",
      "p2pkh_std_net_ver": [0x00],
      "p2pkh_legacy_net_ver": btcP2PKHNetVerMn,
      "p2sh_std_hrp": "simpleledger",
      "p2sh_std_net_ver": [0x08],
      "p2sh_legacy_net_ver": btcP2SHNetVerMn,
      "wif_net_ver": btcWifNetVerMn,
    },
  );

  /// Configuration for Bitcoin Cash Simple Ledger Protocol test net
  static const CoinConf bitcoinCashSlpTestNet = CoinConf(
    coinName: CoinNames("Bitcoin Cash SLP TestNet", "SLP"),
    params: {
      "p2pkh_std_hrp": "slptest",
      "p2pkh_std_net_ver": [0x00],
      "p2pkh_legacy_net_ver": btcP2PKHNetVerTn,
      "p2sh_std_hrp": "slptest",
      "p2sh_std_net_ver": [0x08],
      "p2sh_legacy_net_ver": btcP2SHNetVerTn,
      "wif_net_ver": btcWifNetVerTn,
    },
  );

  /// Configuration for Bitcoin SV main net
  static const CoinConf bitcoinSvMainNet = CoinConf(
    coinName: CoinNames("BitcoinSV", "BSV"),
    params: {
      "p2pkh_net_ver": btcP2PKHNetVerMn,
      "p2sh_net_ver": btcP2SHNetVerMn,
      "wif_net_ver": btcWifNetVerMn,
    },
  );

  /// Configuration for Bitcoin SV test net
  static const CoinConf bitcoinSvTestNet = CoinConf(
    coinName: CoinNames("BitcoinSV TestNet", "BSV"),
    params: {
      "p2pkh_net_ver": btcP2PKHNetVerTn,
      "p2sh_net_ver": btcP2SHNetVerTn,
      "wif_net_ver": btcWifNetVerTn,
    },
  );

  /// Configuration for Cardano main net
  static const CoinConf cardanoMainNet = CoinConf(
    coinName: CoinNames("Cardano", "ADA"),
    params: {
      "addr_hrp": "addr",
      "staking_addr_hrp": "stake",
    },
  );

  /// Configuration for Cardano test
  static const CoinConf cardanoTestNet = CoinConf(
    coinName: CoinNames("Cardano TestNet", "ADA"),
    params: {
      "addr_hrp": "addr_test",
      "staking_addr_hrp": "stake_test",
    },
  );

  /// Configuration for Celo
  static const CoinConf celo = CoinConf(
    coinName: CoinNames("Celo", "CELO"),
    params: {},
  );

  /// Configuration for Certik
  static const CoinConf certik = CoinConf(
    coinName: CoinNames("Certik", "CTK"),
    params: {
      "addr_hrp": Slip173.certik,
    },
  );

  /// Configuration for ChainX
  static const CoinConf chainX = CoinConf(
    coinName: CoinNames("ChainX", "PCX"),
    params: {
      "addr_ss58_format": 44,
    },
  );

  /// Configuration for Chihuahua
  static const CoinConf chihuahua = CoinConf(
    coinName: CoinNames("Chihuahua", "HUAHUA"),
    params: {
      "addr_hrp": Slip173.chihuahua,
    },
  );

  /// Configuration for Cosmos
  static const CoinConf cosmos = CoinConf(
    coinName: CoinNames("Cosmos", "ATOM"),
    params: {
      "addr_hrp": Slip173.cosmos,
    },
  );

  /// Configuration for Dash main net
  static const CoinConf dashMainNet = CoinConf(
    coinName: CoinNames("Dash", "DASH"),
    params: {
      "p2pkh_net_ver": [0x4c],
      "p2sh_net_ver": [0x10],
      "wif_net_ver": [0xcc],
    },
  );

  /// Configuration for Dash test net
  static const CoinConf dashTestNet = CoinConf(
    coinName: CoinNames("Dash TestNet", "DASH"),
    params: {
      "p2pkh_net_ver": [0x8c],
      "p2sh_net_ver": [0x13],
      "wif_net_ver": btcWifNetVerTn,
    },
  );

  /// Configuration for Dogecoin main net
  static const CoinConf dogecoinMainNet = CoinConf(
    coinName: CoinNames("Dogecoin", "DOGE"),
    params: {
      "p2pkh_net_ver": [0x1e],
      "p2sh_net_ver": [0x16],
      "wif_net_ver": [0x9e],
    },
  );

  /// Configuration for Dogecoin test net
  static const CoinConf dogecoinTestNet = CoinConf(
    coinName: CoinNames("Dogecoin TestNet", "DOGE"),
    params: {
      "p2pkh_net_ver": [0x71],
      "p2sh_net_ver": btcP2SHNetVerTn,

      ///btcP2SHNetVerTn,
      "wif_net_ver": [0xf1],
    },
  );

  /// Configuration for eCash main net
  static const CoinConf ecashMainNet = CoinConf(
    coinName: CoinNames("eCash", "XEC"),
    params: {
      "p2pkh_std_hrp": "ecash",
      "p2pkh_std_net_ver": [0x00],
      "p2pkh_legacy_net_ver": btcP2PKHNetVerMn,
      "p2sh_std_hrp": "ecash",
      "p2sh_std_net_ver": [0x08],
      "p2sh_legacy_net_ver": btcP2SHNetVerMn,
      "wif_net_ver": btcWifNetVerMn,
    },
  );

  /// Configuration for eCash test net
  static const CoinConf ecashTestNet = CoinConf(
    coinName: CoinNames("eCash TestNet", "XEC"),
    params: {
      "p2pkh_std_hrp": "ectest",
      "p2pkh_std_net_ver": [0x00],
      "p2pkh_legacy_net_ver": btcP2PKHNetVerTn,
      "p2sh_std_hrp": "ectest",
      "p2sh_std_net_ver": [0x08],
      "p2sh_legacy_net_ver": btcP2SHNetVerTn,
      "wif_net_ver": btcWifNetVerTn,
    },
  );

  /// Configuration for Edgeware
  static const CoinConf edgeware = CoinConf(
    coinName: CoinNames("Edgeware", "EDG"),
    params: {
      "addr_ss58_format": 7,
    },
  );

  /// Configuration for Elrond
  static const CoinConf elrond = CoinConf(
    coinName: CoinNames("Elrond eGold", "eGLD"),
    params: {
      "addr_hrp": Slip173.elrond,
    },
  );

  /// Configuration for Eos
  static const CoinConf eos = CoinConf(
    coinName: CoinNames("EOS", "EOS"),
    params: {
      "addr_prefix": "EOS",
    },
  );

  /// Configuration for Ergo main net
  static const CoinConf ergoMainNet = CoinConf(
    coinName: CoinNames("Ergo", "ERGO"),
    params: {},
  );

  /// Configuration for Ergo test net
  static const CoinConf ergoTestNet = CoinConf(
    coinName: CoinNames("Ergo TestNet", "ERGO"),
    params: {},
  );

  /// Configuration for Ethereum
  static const CoinConf ethereum = CoinConf(
    coinName: CoinNames("Ethereum", "ETH"),
    params: {
      "addr_prefix": "0x",
    },
  );

  /// Configuration for Ethereum Classic
  static const CoinConf ethereumClassic = CoinConf(
    coinName: CoinNames("Ethereum Classic", "ETC"),
    params: {},
  );

  /// Configuration for Fantom Opera
  static const CoinConf fantomOpera = CoinConf(
    coinName: CoinNames("Fantom Opera", "FTM"),
    params: {},
  );

  /// Configuration for Filecoin
  static const CoinConf filecoin = CoinConf(
    coinName: CoinNames("Filecoin", "FIL"),
    params: {
      "addr_prefix": "f",
    },
  );

  /// Configuration for generic Substrate coin
  static const CoinConf genericSubstrate = CoinConf(
    coinName: CoinNames("Generic Substrate", ""),
    params: {
      "addr_ss58_format": 42,
    },
  );

  /// Configuration for Harmony One
  static const CoinConf harmonyOne = CoinConf(
    coinName: CoinNames("Harmony One", "ONE"),
    params: {
      "addr_hrp": Slip173.harmonyOne,
    },
  );

  /// Configuration for Huobi Chain
  static const CoinConf huobiChain = CoinConf(
    coinName: CoinNames("Huobi Token", "HT"),
    params: {},
  );

  /// Configuration for Icon
  static const CoinConf icon = CoinConf(
    coinName: CoinNames("Icon", "ICX"),
    params: {
      "addr_prefix": "hx",
    },
  );

  /// Configuration for Injective
  static const CoinConf injective = CoinConf(
    coinName: CoinNames("Injective", "INJ"),
    params: {
      "addr_hrp": Slip173.injective,
    },
  );

  /// Configuration for IRISnet
  static const CoinConf irisNet = CoinConf(
    coinName: CoinNames("IRIS Network", "IRIS"),
    params: {
      "addr_hrp": Slip173.irisNetwork,
    },
  );

  /// Configuration for Karura
  static const CoinConf karura = CoinConf(
    coinName: CoinNames("Karura", "KAR"),
    params: {
      "addr_ss58_format": 8,
    },
  );

  /// Configuration for Kava
  static const CoinConf kava = CoinConf(
    coinName: CoinNames("Kava", "KAVA"),
    params: {
      "addr_hrp": Slip173.kava,
    },
  );

  /// Configuration for Kusama
  static const CoinConf kusama = CoinConf(
    coinName: CoinNames("Kusama", "KSM"),
    params: {
      "addr_ss58_format": 2,
    },
  );

  /// Configuration for Litecoin main net
  static const CoinConf litecoinMainNet = CoinConf(
    coinName: CoinNames("Litecoin", "LTC"),
    params: {
      "p2pkh_std_net_ver": [0x30],
      "p2pkh_depr_net_ver": btcP2PKHNetVerMn,
      "p2sh_std_net_ver": [0x32],
      "p2sh_depr_net_ver": btcP2SHNetVerMn,
      "p2wpkh_hrp": Slip173.litecoinMainnet,
      "p2wpkh_wit_ver": btcP2WPKHWitVerMn,
      "wif_net_ver": [0xb0],
    },
  );

  /// Configuration for Litecoin test net
  static const CoinConf litecoinTestNet = CoinConf(
    coinName: CoinNames("Litecoin TestNet", "LTC"),
    params: {
      "p2pkh_std_net_ver": [0x6f],
      "p2pkh_depr_net_ver": btcP2PKHNetVerTn,
      "p2sh_std_net_ver": [0x3a],
      "p2sh_depr_net_ver": btcP2SHNetVerTn,
      "p2wpkh_hrp": Slip173.litecoinTestnet,
      "p2wpkh_wit_ver": btcP2WPKHWitVerTn,
      "wif_net_ver": btcWifNetVerTn,
    },
  );

  /// Configuration for Monero main net
  static const CoinConf moneroMainNet = CoinConf(
    coinName: CoinNames("Monero", "XMR"),
    params: {
      "addr_net_ver": [0x12],
      "addr_int_net_ver": [0x13],
      "subaddr_net_ver": [0x2A],
    },
  );

  /// Configuration for Monero stage net
  static const CoinConf moneroStageNet = CoinConf(
    coinName: CoinNames("Monero StageNet", "XMR"),
    params: {
      "addr_net_ver": [0x18],
      "addr_int_net_ver": [0x19],
      "subaddr_net_ver": [0x24],
    },
  );

  /// Configuration for Monero test net
  static const CoinConf moneroTestNet = CoinConf(
    coinName: CoinNames("Monero TestNet", "XMR"),
    params: {
      "addr_net_ver": [0x35],
      "addr_int_net_ver": [0x36],
      "subaddr_net_ver": [0x3F],
    },
  );

  /// Configuration for Moonbeam
  static const CoinConf moonbeam = CoinConf(
    coinName: CoinNames("Moonbeam", "GLMR"),
    params: {
      "addr_ss58_format": 1284,
    },
  );

  /// Configuration for Moonriver
  static const CoinConf moonriver = CoinConf(
    coinName: CoinNames("Moonriver", "MOVR"),
    params: {
      "addr_ss58_format": 1285,
    },
  );

  /// Configuration for Nano
  static const CoinConf nano = CoinConf(
    coinName: CoinNames("Nano", "NANO"),
    params: {
      "addr_prefix": "nano_",
    },
  );

  /// Configuration for Near Protocol
  static const CoinConf nearProtocol = CoinConf(
    coinName: CoinNames("Near Protocol", "NEAR"),
    params: {},
  );

  /// Configuration for Neo
  static const CoinConf neo = CoinConf(
    coinName: CoinNames("NEO", "NEO"),
    params: {
      "addr_ver": [0x17],
    },
  );

  /// Configuration for Nine Chronicles Gold
  static const CoinConf nineChroniclesGold = CoinConf(
    coinName: CoinNames("NineChroniclesGold", "NCG"),
    params: {},
  );

  /// Configuration for OKEx Chain
  static const CoinConf okexChain = CoinConf(
    coinName: CoinNames("OKExChain", "OKT"),
    params: {
      "addr_hrp": Slip173.okexChain,
    },
  );

  /// Configuration for Ontology
  static const CoinConf ontology = CoinConf(
    coinName: CoinNames("Ontology", "ONT"),
    params: {
      "addr_ver": [0x17],
    },
  );

  /// Configuration for Osmosis
  static const CoinConf osmosis = CoinConf(
    coinName: CoinNames("Osmosis", "OSMO"),
    params: {
      "addr_hrp": Slip173.osmosis,
    },
  );

  /// Configuration for Phala
  static const CoinConf phala = CoinConf(
    coinName: CoinNames("Phala Network", "PHA"),
    params: {
      "addr_ss58_format": 30,
    },
  );

  /// Configuration for Pi Network
  static const CoinConf piNetwork = CoinConf(
    coinName: CoinNames("Pi Network", "PI"),
    params: {},
  );

  /// Configuration for Plasm
  static const CoinConf plasm = CoinConf(
    coinName: CoinNames("Plasm Network", "PLM"),
    params: {
      "addr_ss58_format": 5,
    },
  );

  /// Configuration for Polkadot
  static const CoinConf polkadot = CoinConf(
    coinName: CoinNames("Polkadot", "DOT"),
    params: {
      "addr_ss58_format": 0,
    },
  );

  /// Configuration for Polygon
  static const CoinConf polygon = CoinConf(
    coinName: CoinNames("Polygon", "MATIC"),
    params: {},
  );

  /// Configuration for Ripple
  static const CoinConf ripple = CoinConf(
    coinName: CoinNames("Ripple", "XRP"),
    params: {
      "p2pkh_net_ver": btcP2PKHNetVerMn,
    },
  );

  /// Configuration for Secret Network
  static const CoinConf secretNetwork = CoinConf(
    coinName: CoinNames("Secret Network", "SCRT"),
    params: {
      "addr_hrp": Slip173.secretNetwork,
    },
  );

  /// Configuration for Solana
  static const CoinConf solana = CoinConf(
    coinName: CoinNames("Solana", "SOL"),
    params: {},
  );

  /// Configuration for Sora
  static const CoinConf sora = CoinConf(
    coinName: CoinNames("Sora", "XOR"),
    params: {
      "addr_ss58_format": 69,
    },
  );

  /// Configuration for Stafi
  static const CoinConf stafi = CoinConf(
    coinName: CoinNames("Stafi", "FIS"),
    params: {
      "addr_ss58_format": 20,
    },
  );

  /// Configuration for Stellar
  static const CoinConf stellar = CoinConf(
    coinName: CoinNames("Stellar", "XLM"),
    params: {},
  );

  /// Configuration for Terra
  static const CoinConf terra = CoinConf(
    coinName: CoinNames("Terra", "LUNA"),
    params: {
      "addr_hrp": Slip173.terra,
    },
  );

  /// Configuration for Tezos
  static const CoinConf tezos = CoinConf(
    coinName: CoinNames("Tezos", "XTZ"),
    params: {},
  );

  /// Configuration for Theta
  static const CoinConf theta = CoinConf(
    coinName: CoinNames("Theta Network", "THETA"),
    params: {},
  );

  /// Configuration for Tron
  static const CoinConf tron = CoinConf(
    coinName: CoinNames("Tron", "TRX"),
    params: {
      "addr_prefix": [0x41],
    },
  );

  /// Configuration for VeChain
  static const CoinConf veChain = CoinConf(
    coinName: CoinNames("VeChain", "VET"),
    params: {},
  );

  /// Configuration for Verge
  static const CoinConf verge = CoinConf(
    coinName: CoinNames("Verge", "XVG"),
    params: {
      "p2pkh_net_ver": [0x1e],
      "wif_net_ver": [0x9e],
    },
  );

  /// Configuration for Zcash main net
  static const CoinConf zcashMainNet = CoinConf(
    coinName: CoinNames("Zcash", "ZEC"),
    params: {
      "p2pkh_net_ver": [0x1c, 0xb8],
      "p2sh_net_ver": [0x1c, 0xbd],
      "wif_net_ver": btcWifNetVerMn,
    },
  );

  /// Configuration for Zcash test net
  static const CoinConf zcashTestNet = CoinConf(
    coinName: CoinNames("Zcash TestNet", "ZEC"),
    params: {
      "p2pkh_net_ver": [0x1d, 0x25],
      "p2sh_net_ver": [0x1c, 0xba],
      "wif_net_ver": btcWifNetVerTn,
    },
  );

  /// Configuration for Zilliqa
  static const CoinConf zilliqa = CoinConf(
    coinName: CoinNames("Zilliqa", "ZIL"),
    params: {
      "addr_hrp": Slip173.zilliqa,
    },
  );
}
