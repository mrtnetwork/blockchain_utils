import 'package:blockchain_utils/bip/bip/conf/bip49/bip49_conf.dart';
import 'package:blockchain_utils/bip/bip/conf/bip_coin_conf.dart';
import 'package:blockchain_utils/bip/bip/conf/bip_coins.dart';

/// An enumeration of supported cryptocurrencies for BIP49. It includes both main
/// networks and test networks of various cryptocurrencies.
class Bip49Coins implements CryptoCoins {
  static const Bip49Coins bitcoin = Bip49Coins._('bitcoin');
  static const Bip49Coins bitcoinCash = Bip49Coins._('bitcoinCash');
  static const Bip49Coins bitcoinCashSlp = Bip49Coins._('bitcoinCashSlp');
  static const Bip49Coins bitcoinSv = Bip49Coins._('bitcoinSv');
  static const Bip49Coins dash = Bip49Coins._('dash');
  static const Bip49Coins dogecoin = Bip49Coins._('dogecoin');
  static const Bip49Coins ecash = Bip49Coins._('ecash');
  static const Bip49Coins litecoin = Bip49Coins._('litecoin');
  static const Bip49Coins zcash = Bip49Coins._('zcash');
  static const Bip49Coins pepecoin = Bip49Coins._('pepecoin');

  // Test nets
  static const Bip49Coins bitcoinCashTestnet =
      Bip49Coins._('bitcoinCashTestnet');
  static const Bip49Coins bitcoinCashSlpTestnet =
      Bip49Coins._('bitcoinCashSlpTestnet');
  static const Bip49Coins bitcoinSvTestnet = Bip49Coins._('bitcoinSvTestnet');
  static const Bip49Coins bitcoinTestnet = Bip49Coins._('bitcoinTestnet');
  static const Bip49Coins dashTestnet = Bip49Coins._('dashTestnet');
  static const Bip49Coins dogecoinTestnet = Bip49Coins._('dogecoinTestnet');
  static const Bip49Coins ecashTestnet = Bip49Coins._('ecashTestnet');
  static const Bip49Coins litecoinTestnet = Bip49Coins._('litecoinTestnet');
  static const Bip49Coins zcashTestnet = Bip49Coins._('zcashTestnet');
  static const Bip49Coins pepecoinTestnet = Bip49Coins._('pepecoinTestnet');

  final String name;

  const Bip49Coins._(this.name);

  @override
  Bip49Coins get value => this;

  @override
  String get coinName => name;

  @override
  CoinConfig get conf => _coinToConf[this]!;

  static Bip49Coins? fromName(String name) {
    try {
      return _coinToConf.keys.firstWhere((element) => element.name == name);
    } on StateError {
      return null;
    }
  }

  static List<Bip49Coins> get values => _coinToConf.keys.toList();

  /// A mapping that associates each BIP49Coin (enum) with its corresponding
  /// CoinConfig configuration.
  static final Map<Bip49Coins, CoinConfig> _coinToConf = {
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
    Bip49Coins.pepecoin: Bip49Conf.pepeMainnet,
    Bip49Coins.pepecoinTestnet: Bip49Conf.pepeTestnet
  };
  @override
  BipProposal get proposal => BipProposal.bip49;
}
