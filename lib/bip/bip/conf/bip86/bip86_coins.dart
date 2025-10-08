import 'package:blockchain_utils/bip/bip/conf/bip/bip_coins.dart';
import 'package:blockchain_utils/bip/bip/conf/bip86/bip86_conf.dart';
import 'package:blockchain_utils/bip/bip/conf/config/bip_coin_conf.dart';
import 'package:blockchain_utils/bip/ecc/curve/elliptic_curve_types.dart';

/// An enumeration of supported cryptocurrencies for BIP86. It includes both main
/// networks and test networks of various cryptocurrencies.
class Bip86Coins extends BipCoins {
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
  BipCoinConfig get conf => _coinToConf[this]!;

  static Bip86Coins? fromName(String name) {
    try {
      return _coinToConf.keys.firstWhere((element) => element.name == name);
    } on StateError {
      return null;
    }
  }

  static List<Bip86Coins> fromCurve(EllipticCurveTypes type) {
    return _coinToConf.entries
        .where((element) => element.value.type == type)
        .map((e) => e.key)
        .toList();
  }

  /// A mapping that associates each BIP86Coin (enum) with its corresponding
  /// BipCoinConfig configuration.
  static final Map<Bip86Coins, BipCoinConfig> _coinToConf = {
    Bip86Coins.bitcoin: Bip86Conf.bitcoinMainNet,
    Bip86Coins.bitcoinTestnet: Bip86Conf.bitcoinTestNet,
  };

  @override
  BipProposal get proposal => BipProposal.bip86;
}
