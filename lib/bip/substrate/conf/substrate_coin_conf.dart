import 'package:blockchain_utils/bip/coin_conf/coin_conf.dart';
import 'package:blockchain_utils/bip/coin_conf/coins_name.dart';

/// A class representing the configuration for a Substrate-based cryptocurrency.
class SubstrateCoinConf {
  /// Coin names and symbols
  final CoinNames coinNames;

  /// Address format identifier
  final int ss58Format;

  /// Constructor for creating a SubstrateCoinConf instance.
  ///
  /// It initializes the Substrate cryptocurrency's coin names and symbols [coinNames]
  /// and the SS58 address format identifier [ss58Format].
  SubstrateCoinConf({required this.coinNames, required this.ss58Format});

  /// Factory method to create a SubstrateCoinConf from a generic CoinConf.
  ///
  /// This method takes a generic `CoinConf` instance and extracts the coin names
  /// and SS58 address format information to create a `SubstrateCoinConf`.
  factory SubstrateCoinConf.fromCoinConf(CoinConf coinConf) {
    return SubstrateCoinConf(
        coinNames: coinConf.coinName,
        ss58Format: coinConf.params.addrSs58Format!);
  }

  /// Get the Substrate-specific address parameters as a map.
  Map<String, int> get addrParams => {"ss58_format": ss58Format};
}
