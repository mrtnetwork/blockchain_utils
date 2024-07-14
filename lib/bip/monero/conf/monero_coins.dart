import 'package:blockchain_utils/bip/bip/conf/core/coins.dart';
import 'monero_coin_conf.dart';
import 'monero_conf.dart';

/// An enumeration of supported cryptocurrencies for Monero. It includes both main
/// networks and test networks of various cryptocurrencies.
class MoneroCoins implements CryptoCoins<MoneroCoinConf> {
  /// mainnets
  static const MoneroCoins moneroMainnet = MoneroCoins._('moneroMainnet');

  /// testnets
  static const MoneroCoins moneroStagenet = MoneroCoins._('moneroStagenet');
  static const MoneroCoins moneroTestnet = MoneroCoins._('moneroTestnet');

  static const List<MoneroCoins> values = [
    moneroMainnet,
    moneroStagenet,
    moneroTestnet
  ];
  static MoneroCoins? fromName(String name) {
    try {
      return _coinToConf.keys.firstWhere((element) => element.name == name);
    } on StateError {
      return null;
    }
  }

  final String name;

  const MoneroCoins._(this.name);

  @override
  MoneroCoins get value {
    return this;
  }

  @override
  String get coinName {
    return name;
  }

  @override
  MoneroCoinConf get conf => _coinToConf[this]!;
  @override
  CoinProposal get proposal => MoneroProposal.monero;

  /// A mapping that associates each MoneroCoins (enum) with its corresponding
  /// MoneroCoinConf configuration.
  static final Map<MoneroCoins, MoneroCoinConf> _coinToConf = {
    MoneroCoins.moneroMainnet: MoneroConf.mainNet,
    MoneroCoins.moneroStagenet: MoneroConf.stageNet,
    MoneroCoins.moneroTestnet: MoneroConf.testNet
  };

  @override
  bool get isBipCoin => false;
}

class MoneroProposal implements CoinProposal {
  static const MoneroProposal monero = MoneroProposal._('monero');

  const MoneroProposal._(this.name);
  final String name;

  @override
  String get specName => name;
  @override
  MoneroProposal get value => this;

  static const List<MoneroProposal> values = [monero];
}
