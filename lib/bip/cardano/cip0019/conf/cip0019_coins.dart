import 'package:blockchain_utils/bip/bip/conf/bip/bip_coins.dart';
import 'package:blockchain_utils/bip/bip/conf/config/bip_coin_conf.dart';
import 'package:blockchain_utils/bip/bip/conf/core/coins.dart';
import 'package:blockchain_utils/bip/cardano/cip0019/conf/cip0019_conf.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';

/// An enumeration of supported cryptocurrencies for CIP0019. It includes both main
/// networks and test networks of various cryptocurrencies.
enum Cip0019Coins implements BipCoins {
  // Mainnets
  byronLegacy('byronLegacy'),

  /// Testnets
  byronLegacyTestnet('byronLegacyTestnet');

  final String name;

  const Cip0019Coins(this.name);

  @override
  Cip0019Coins get value => this;

  @override
  String get coinName {
    return name;
  }

  static Cip0019Coins? fromName(String name) {
    return values.firstWhereNullable((element) => element.name == name);
  }

  @override
  BipCoinConfig get conf {
    final config = Cip0019Conf();
    return switch (this) {
      byronLegacy => config.byronLegacy,
      byronLegacyTestnet => config.byronLegacyTestnet,
    };
  }

  @override
  CoinProposal get proposal => CoinProposal.cip0019;
}
