import 'package:blockchain_utils/protocol/bip/bip/conf/core/coins.dart';
import 'package:blockchain_utils/protocol/bip/bip/eip2334/eip2334_conf.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';

enum Eip2334Coins implements CryptoCoins<Eip2334CoinConfig> {
  ethereumBls('ethereumBls', 3001),
  tezosBls('tezosBls', 3002),
  filecoinBls('filecoinBls', 3003);

  final String name;
  @override
  final int identifier;

  const Eip2334Coins(this.name, this.identifier);
  @override
  Eip2334Coins get value {
    return this;
  }

  @override
  String get coinName {
    return name;
  }

  @override
  Eip2334CoinConfig get conf {
    final config = Eip2334Conf();
    return switch (this) {
      Eip2334Coins.ethereumBls => config.ethereumBls,
      Eip2334Coins.tezosBls => config.tezosBls,
      Eip2334Coins.filecoinBls => config.filecoinBls,
    };
  }

  static Eip2334Coins? fromName(String name) {
    return values.firstWhereNullable((element) => element.name == name);
  }

  @override
  CoinProposal get proposal => CoinProposal.eip2334;

  @override
  String toString() {
    return "Eip2334Coins.$name";
  }
}
