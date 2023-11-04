import 'package:blockchain_utils/bip/bip/conf/bip_coins.dart';

/// An enumeration of supported cryptocurrencies for CIP1852. It includes both main
/// networks and test networks of various cryptocurrencies.
enum Cip1852Coins implements BipCoins {
  /// mainnets
  cardanoIcarus,
  cardanoLedger,

  /// testnets
  cardanoIcarusTestnet,
  cardanoLedgerTestnet;

  @override
  Cip1852Coins get value => this;
}
