import 'package:blockchain_utils/protocol/bip/bip/conf/core/coins.dart';
import 'package:blockchain_utils/protocol/bip/bip/nep649/nep649_conf.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';

enum Nep649Coins implements CryptoCoins<Nep649CoinConfig> {
  nearMldsa('nearMldsa', 3000);

  final String name;
  @override
  final int identifier;

  const Nep649Coins(this.name, this.identifier);
  @override
  Nep649Coins get value {
    return this;
  }

  @override
  String get coinName {
    return name;
  }

  @override
  Nep649CoinConfig get conf {
    final config = Nep649Conf();
    return switch (this) {
      Nep649Coins.nearMldsa => config.nearMldsa,
    };
  }

  static Nep649Coins? fromName(String name) {
    return values.firstWhereNullable((element) => element.name == name);
  }

  @override
  CoinProposal get proposal => CoinProposal.nep649;

  @override
  String toString() {
    return "Nep649Coins.$name";
  }
}
