import 'package:blockchain_utils/bip/bip/conf/bip_coin_conf.dart';
import 'package:blockchain_utils/bip/bip/conf/bip_coins.dart';

/// An enumeration of supported cryptocurrencies for Monero. It includes both main
/// networks and test networks of various cryptocurrencies.
class MoneroCoins implements CryptoCoins {
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
  CoinConfig get conf => throw UnimplementedError();
  @override
  BipProposal get proposal => throw UnimplementedError();
}
