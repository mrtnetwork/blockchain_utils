import 'package:blockchain_utils/bip/coin_conf/coin_conf.dart';
import 'package:blockchain_utils/bip/coin_conf/coins_name.dart';

/// Configuration class for Monero-based cryptocurrencies, specifying various parameters
/// such as network versions, address types, and coin names.
class MoneroCoinConf {
  final CoinNames coinNames;
  final List<int> addrNetVer;
  final List<int> intAddrNetVer;
  final List<int> subaddrNetVer;

  /// address parameters
  final Map<String, List<int>> addrParams = {};

  /// private constructor
  MoneroCoinConf._(
      this.coinNames, this.addrNetVer, this.intAddrNetVer, this.subaddrNetVer);

  /// MoneroCoinConf from coinConf
  factory MoneroCoinConf.fromCoinConf(CoinConf coinConf) {
    return MoneroCoinConf._(
      coinConf.coinName,
      coinConf.params.addrNetVer!,
      coinConf.params.addrIntNetVer!,
      coinConf.params.subaddrNetVer!,
    );
  }
}
