import 'package:blockchain_utils/bip/bip/conf/bip_coin_conf.dart';
import 'package:blockchain_utils/bip/bip/conf/bip_coins.dart';

/// An enumeration of supported cryptocurrencies for Monero. It includes both main
/// networks and test networks of various cryptocurrencies.
enum MoneroCoins implements CryptoCoins {
  /// mainnets
  moneroMainnet,

  /// testnets
  moneroStagenet,
  moneroTestnet;

  @override
  MoneroCoins get value {
    return this;
  }

  String get coinName {
    return this.name;
  }

  CoinConfig get conf => throw UnimplementedError();
  BipProposal get proposal => throw UnimplementedError();
}
