import 'package:blockchain_utils/bip/bip/conf/core/coins.dart';
import 'package:blockchain_utils/bip/bip/zip32/conf/config.dart';
import 'package:blockchain_utils/bip/bip/zip32/conf/zcash.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';

enum ZIP32Coins implements CryptoCoins<ZIP32CoinConfig> {
  // Mainnet
  zCashSapling('zCashSapling'),
  zCashOrchard('zCashOrchard'),
  // Testnets
  zCashTestnetSapling('zCashTestnetSapling'),
  zCashRegtestSapling('zCashRegtestSapling'),
  zCashTestnetOrchard('zCashTestnetOrchard'),
  zCashRegtestOrchard('zCashRegtestOrchard');

  final String name;

  const ZIP32Coins(this.name);
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
