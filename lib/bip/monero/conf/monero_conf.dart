import 'package:blockchain_utils/bip/coin_conf/coins_conf.dart';
import 'package:blockchain_utils/bip/monero/conf/monero_coin_conf.dart';

/// A configuration class for Monero that defines the key network versions and
/// maps each supported MoneroCoins to its corresponding BipCoinConfig.
class MoneroConf {
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
