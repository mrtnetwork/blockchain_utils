import 'package:blockchain_utils/bip/bip/conf/bip_coins.dart';

/// An enumeration of supported cryptocurrencies for BIP86. It includes both main
/// networks and test networks of various cryptocurrencies.
enum Bip86Coins implements BipCoins {
  /// mainnets
  bitcoin,

  /// testnets
  bitcoinTestnet;

  @override
  Bip86Coins get value {
    return this;
  }
}
