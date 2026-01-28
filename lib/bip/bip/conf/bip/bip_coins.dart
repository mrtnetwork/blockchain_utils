import 'package:blockchain_utils/bip/bip/conf/config/bip_coin_conf.dart';
import 'package:blockchain_utils/bip/bip/conf/core/coins.dart';

abstract class BipCoins implements CryptoCoins<BaseBipCoinConfig> {
  const BipCoins();

  /// Gets the collection of cryptocurrency coins.
  @override
  CryptoCoins get value;

  @override
  String get coinName;

  @override
  BaseBipCoinConfig get conf;

  @override
  String toString() {
    return "$runtimeType.$coinName";
  }
}
