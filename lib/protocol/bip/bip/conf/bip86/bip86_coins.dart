import 'package:blockchain_utils/protocol/bip/bip/conf/bip/bip_coins.dart';
import 'package:blockchain_utils/protocol/bip/bip/conf/bip86/bip86_conf.dart';
import 'package:blockchain_utils/protocol/bip/bip/conf/config/bip_coin_conf.dart';
import 'package:blockchain_utils/protocol/bip/bip/conf/core/coins.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';

/// An enumeration of supported cryptocurrencies for BIP86. It includes both main
/// networks and test networks of various cryptocurrencies.
enum Bip86Coins implements BipCoins {
  // Mainnets
  bitcoin('bitcoin', 501),

  // Testnets
  bitcoinTestnet('bitcoinTestnet', 502),
  bitcoinRegtest('bitcoinRegtest', 503);

  final String name;
  @override
  final int identifier;
  const Bip86Coins(this.name, this.identifier);

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
      bitcoinRegtest => config.bitcoinRegtest,
    };
  }

  static Bip86Coins? fromName(String name) {
    return values.firstWhereNullable((element) => element.name == name);
  }

  @override
  CoinProposal get proposal => CoinProposal.bip86;
}
