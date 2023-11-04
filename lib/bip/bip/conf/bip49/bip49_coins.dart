import 'package:blockchain_utils/bip/bip/conf/bip_coins.dart';

/// An enumeration of supported cryptocurrencies for BIP49. It includes both main
/// networks and test networks of various cryptocurrencies.
enum Bip49Coins implements BipCoins {
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
}
