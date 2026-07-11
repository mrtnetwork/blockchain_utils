import 'package:blockchain_utils/bip/bip/conf/core/coins.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'monero_coin_conf.dart';
import 'monero_conf.dart';

/// An enumeration of supported cryptocurrencies for Monero. It includes both main
/// networks and test networks of various cryptocurrencies.
enum MoneroCoins implements CryptoCoins<MoneroCoinConf> {
  // Mainnet
  moneroMainnet('moneroMainnet', 901),

  // Testnets
  moneroStagenet('moneroStagenet', 902),
  moneroTestnet('moneroTestnet', 903);

  final String name;
  @override
  final int identifier;
  const MoneroCoins(this.name, this.identifier);
  @override
  MoneroCoins get value {
    return this;
  }

  @override
  String get coinName {
    return name;
  }

  static MoneroCoins? fromName(String name) {
    return values.firstWhereNullable((element) => element.name == name);
  }

  @override
  MoneroCoinConf get conf {
    final config = MoneroConf();
    return switch (this) {
      moneroMainnet => config.mainnet,
      moneroStagenet => config.stagenet,
      moneroTestnet => config.testnet,
    };
  }

  @override
  CoinProposal get proposal => CoinProposal.monero;
}
