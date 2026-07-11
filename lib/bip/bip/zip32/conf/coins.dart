import 'package:blockchain_utils/bip/bip/conf/core/coins.dart';
import 'package:blockchain_utils/bip/bip/zip32/conf/config.dart';
import 'package:blockchain_utils/bip/bip/zip32/conf/zcash.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';

enum ZIP32Coins implements CryptoCoins<ZIP32CoinConfig> {
  // Mainnet
  zCashSapling('zCashSapling', 1001),
  zCashOrchard('zCashOrchard', 1002),
  // Testnets
  zCashTestnetSapling('zCashTestnetSapling', 1003),
  zCashRegtestSapling('zCashRegtestSapling', 1004),
  zCashTestnetOrchard('zCashTestnetOrchard', 1005),
  zCashRegtestOrchard('zCashRegtestOrchard', 1006);

  @override
  final int identifier;
  final String name;

  const ZIP32Coins(this.name, this.identifier);
  @override
  ZIP32Coins get value {
    return this;
  }

  @override
  String get coinName {
    return name;
  }

  @override
  ZIP32CoinConfig get conf {
    final config = ZcashConf();
    return switch (this) {
      ZIP32Coins.zCashOrchard => config.zCashMainnetOrchard,
      ZIP32Coins.zCashSapling => config.zCashMainnetSapling,
      ZIP32Coins.zCashRegtestOrchard => config.zCashRegtestOrchard,
      ZIP32Coins.zCashRegtestSapling => config.zCashRegtestSapling,
      ZIP32Coins.zCashTestnetSapling => config.zCashTestnetSapling,
      ZIP32Coins.zCashTestnetOrchard => config.zCashTestnetOrchard,
    };
  }

  static ZIP32Coins? fromName(String name) {
    return values.firstWhereNullable((element) => element.name == name);
  }

  @override
  CoinProposal get proposal => CoinProposal.zip32;
}
