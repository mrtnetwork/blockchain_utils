import 'package:blockchain_utils/bip/bip/conf/bip_coins.dart';
import 'package:blockchain_utils/bip/coin_conf/coins_conf.dart';
import 'package:blockchain_utils/bip/monero/conf/monero_coin_conf.dart';
import 'package:blockchain_utils/bip/monero/conf/monero_coins.dart';
import 'package:blockchain_utils/exception/exception.dart';

/// A configuration class for Monero that defines the key network versions and
/// maps each supported MoneroCoins to its corresponding CoinConfig.
class MoneroConf {
  /// Retrieves the MoneroCoinConf for the given MoneroCoins. If the provided coin
  /// is not an instance of MoneroCoins, an error is thrown.
  static MoneroCoinConf getCoin(CryptoCoins coin) {
    if (coin is! MoneroCoins) {
      throw const ArgumentException(
          "Coin type is not an enumerative of MoneroCoins");
    }
    return coinToConf[coin.value]!;
  }

  /// A mapping that associates each MoneroCoins (enum) with its corresponding
  /// MoneroCoinConf configuration.
  static final Map<MoneroCoins, MoneroCoinConf> coinToConf = {
    MoneroCoins.moneroMainnet: MoneroConf.mainNet,
    MoneroCoins.moneroStagenet: MoneroConf.stageNet,
    MoneroCoins.moneroTestnet: MoneroConf.testNet,
  };

  // Configuration for Monero main net
  static final MoneroCoinConf mainNet =
      MoneroCoinConf.fromCoinConf(CoinsConf.moneroMainNet);

  // Configuration for Monero stage net
  static final MoneroCoinConf stageNet =
      MoneroCoinConf.fromCoinConf(CoinsConf.moneroStageNet);

  // Configuration for Monero test net
  static final MoneroCoinConf testNet =
      MoneroCoinConf.fromCoinConf(CoinsConf.moneroTestNet);
}
