import 'package:blockchain_utils/bip/bip/conf/bip/bip_coins.dart';
import 'package:blockchain_utils/bip/bip/conf/config/bip_coin_conf.dart';
import 'package:blockchain_utils/bip/bip/conf/core/coins.dart';
import 'package:blockchain_utils/bip/cardano/cip1852/conf/cip1852_conf.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';

/// An enumeration of supported cryptocurrencies for CIP1852. It includes both main
/// networks and test networks of various cryptocurrencies.
enum Cip1852Coins implements BipCoins {
  // Mainnets
  cardanoIcarus('cardanoIcarus'),
  cardanoLedger('cardanoLedger'),

  // Testnets
  cardanoIcarusTestnet('cardanoIcarusTestnet'),
  cardanoLedgerTestnet('cardanoLedgerTestnet');

  final String name;

  const Cip1852Coins(this.name);

  @override
  Cip1852Coins get value => this;

  @override
  String get coinName {
    return name;
  }

  static Cip1852Coins? fromName(String name) {
    return values.firstWhereNullable((element) => element.name == name);
  }

  @override
  BipCoinConfig get conf {
    final config = Cip1852Conf();
    return switch (this) {
      Cip1852Coins.cardanoIcarus => config.cardanoIcarusMainNet,
      Cip1852Coins.cardanoLedger => config.cardanoLedgerMainNet,
      Cip1852Coins.cardanoIcarusTestnet => config.cardanoIcarusTestNet,
      Cip1852Coins.cardanoLedgerTestnet => config.cardanoLedgerTestNet,
    };
  }

  @override
  CoinProposal get proposal => CoinProposal.cip1852;
}
