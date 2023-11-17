import 'package:blockchain_utils/bip/bip/conf/bip86/bip86_conf.dart';
import 'package:blockchain_utils/bip/bip/conf/bip_coin_conf.dart';
import 'package:blockchain_utils/bip/bip/conf/bip_coins.dart';

/// An enumeration of supported cryptocurrencies for BIP86. It includes both main
/// networks and test networks of various cryptocurrencies.
enum Bip86Coins implements CryptoCoins {
  /// mainnets
  bitcoin,

  /// testnets
  bitcoinTestnet;

  @override
  Bip86Coins get value {
    return this;
  }

  String get coinName {
    return this.name;
  }

  CoinConfig get conf => _coinToConf[this]!;

  static Bip86Coins? fromName(String name) {
    try {
      return values.firstWhere((element) => element.name == name);
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

  BipProposal get proposal => BipProposal.bip86;
}
