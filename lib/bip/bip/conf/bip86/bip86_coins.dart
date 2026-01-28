import 'package:blockchain_utils/bip/bip/conf/bip/bip_coins.dart';
import 'package:blockchain_utils/bip/bip/conf/bip86/bip86_conf.dart';
import 'package:blockchain_utils/bip/bip/conf/config/bip_coin_conf.dart';
import 'package:blockchain_utils/bip/bip/conf/core/coins.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';

/// An enumeration of supported cryptocurrencies for BIP86. It includes both main
/// networks and test networks of various cryptocurrencies.
enum Bip86Coins implements BipCoins {
  // Mainnets
  bitcoin('bitcoin'),

  // Testnets
  bitcoinTestnet('bitcoinTestnet');

  final String name;

  const Bip86Coins(this.name);

  @override
  Bip86Coins get value {
    return this;
  }

  @override
  String get coinName {
    return name;
  }

  @override
  BipCoinConfig get conf {
    final config = Bip86Conf();
    return switch (this) {
      bitcoin => config.bitcoinMainNet,
      bitcoinTestnet => config.bitcoinTestNet,
    };
  }

  static Bip86Coins? fromName(String name) {
    return values.firstWhereNullable((element) => element.name == name);
  }

  @override
  CoinProposal get proposal => CoinProposal.bip86;
}
