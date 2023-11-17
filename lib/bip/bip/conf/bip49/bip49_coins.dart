import 'package:blockchain_utils/bip/bip/conf/bip49/bip49_conf.dart';
import 'package:blockchain_utils/bip/bip/conf/bip_coin_conf.dart';
import 'package:blockchain_utils/bip/bip/conf/bip_coins.dart';

/// An enumeration of supported cryptocurrencies for BIP49. It includes both main
/// networks and test networks of various cryptocurrencies.
enum Bip49Coins implements CryptoCoins {
  // Main nets
  bitcoin,
  bitcoinCash,
  bitcoinCashSlp,
  bitcoinSv,
  dash,
  dogecoin,
  ecash,
  litecoin,
  zcash,

  // Test nets
  bitcoinCashTestnet,
  bitcoinCashSlpTestnet,
  bitcoinSvTestnet,
  bitcoinTestnet,
  dashTestnet,
  dogecoinTestnet,
  ecashTestnet,
  litecoinTestnet,
  zcashTestnet;

  @override
  Bip49Coins get value {
    return this;
  }

  String get coinName {
    return this.name;
  }

  CoinConfig get conf => _coinToConf[this]!;

  static Bip49Coins? fromName(String name) {
    try {
      return values.firstWhere((element) => element.name == name);
    } on StateError {
      return null;
    }
  }

  /// A mapping that associates each BIP49Coin (enum) with its corresponding
  /// CoinConfig configuration.
  static Map<Bip49Coins, CoinConfig> _coinToConf = {
    Bip49Coins.bitcoin: Bip49Conf.bitcoinMainNet,
    Bip49Coins.bitcoinTestnet: Bip49Conf.bitcoinTestNet,
    Bip49Coins.bitcoinCash: Bip49Conf.bitcoinCashMainNet,
    Bip49Coins.bitcoinCashTestnet: Bip49Conf.bitcoinCashTestNet,
    Bip49Coins.bitcoinCashSlp: Bip49Conf.bitcoinCashSlpMainNet,
    Bip49Coins.bitcoinCashSlpTestnet: Bip49Conf.bitcoinCashSlpTestNet,
    Bip49Coins.bitcoinSv: Bip49Conf.bitcoinSvMainNet,
    Bip49Coins.bitcoinSvTestnet: Bip49Conf.bitcoinSvTestNet,
    Bip49Coins.dash: Bip49Conf.dashMainNet,
    Bip49Coins.dashTestnet: Bip49Conf.dashTestNet,
    Bip49Coins.dogecoin: Bip49Conf.dogecoinMainNet,
    Bip49Coins.dogecoinTestnet: Bip49Conf.dogecoinTestNet,
    Bip49Coins.ecash: Bip49Conf.ecashMainNet,
    Bip49Coins.ecashTestnet: Bip49Conf.ecashTestNet,
    Bip49Coins.litecoin: Bip49Conf.litecoinMainNet,
    Bip49Coins.litecoinTestnet: Bip49Conf.litecoinTestNet,
    Bip49Coins.zcash: Bip49Conf.zcashMainNet,
    Bip49Coins.zcashTestnet: Bip49Conf.zcashTestNet,
  };
  BipProposal get proposal => BipProposal.bip49;
}
