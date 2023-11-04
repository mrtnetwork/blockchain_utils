import 'package:blockchain_utils/bip/coin_conf/coins_name.dart';

/// A class representing the configuration of a specific cryptocurrency coin.
class CoinConf {
  final CoinNames coinName;
  final Map<String, dynamic> params;

  /// Constructor to create a CoinConf instance.
  ///
  /// Parameters:
  /// - `coinName`: An enum representing the name of the cryptocurrency coin.
  /// - `params`: A map containing various parameters specific to the coin.
  const CoinConf({required this.coinName, required this.params});

  /// Retrieves and returns the name of the cryptocurrency coin.
  String get name => coinName.name;

  /// Retrieves and returns a specific parameter of the coin configuration.
  ///
  /// Parameters:
  /// - `name`: The name of the parameter to retrieve.
  T? getParam<T>(String name) => params[name];

  @override
  String toString() {
    return name;
  }
}
