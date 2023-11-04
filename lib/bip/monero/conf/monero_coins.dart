import 'package:blockchain_utils/bip/bip/conf/bip_coins.dart';

/// An enumeration of supported cryptocurrencies for Monero. It includes both main
/// networks and test networks of various cryptocurrencies.
enum MoneroCoins implements BipCoins {
  /// mainnets
  moneroMainnet,

  /// testnets
  moneroStagenet,
  moneroTestnet;

  @override
  MoneroCoins get value {
    return this;
  }
}
