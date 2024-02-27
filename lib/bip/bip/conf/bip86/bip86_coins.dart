import 'package:blockchain_utils/bip/bip/conf/bip86/bip86_conf.dart';
import 'package:blockchain_utils/bip/bip/conf/bip_coin_conf.dart';
import 'package:blockchain_utils/bip/bip/conf/bip_coins.dart';

/// An enumeration of supported cryptocurrencies for BIP86. It includes both main
/// networks and test networks of various cryptocurrencies.
class Bip86Coins implements CryptoCoins {
  /// mainnets
  static const Bip86Coins bitcoin = Bip86Coins._('bitcoin');

  /// testnets
  static const Bip86Coins bitcoinTestnet = Bip86Coins._('bitcoinTestnet');

  static const List<Bip86Coins> values = [bitcoin, bitcoinTestnet];

  final String name;

  const Bip86Coins._(this.name);

  @override
  Bip86Coins get value {
    return this;
  }

  @override
  String get coinName {
    return name;
  }

  @override
  CoinConfig get conf => _coinToConf[this]!;

  static Bip86Coins? fromName(String name) {
    try {
      return _coinToConf.keys.firstWhere((element) => element.name == name);
    } on StateError {
      return null;
    }
  }

  /// A mapping that associates each BIP86Coin (enum) with its corresponding
  /// CoinConfig configuration.
  static final Map<Bip86Coins, CoinConfig> _coinToConf = {
    Bip86Coins.bitcoin: Bip86Conf.bitcoinMainNet,
    Bip86Coins.bitcoinTestnet: Bip86Conf.bitcoinTestNet,
  };

  @override
  BipProposal get proposal => BipProposal.bip86;
}
