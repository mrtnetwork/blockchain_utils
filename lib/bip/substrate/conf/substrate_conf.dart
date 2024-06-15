import 'package:blockchain_utils/bip/bip/conf/bip_coins.dart';
import 'package:blockchain_utils/bip/coin_conf/coins_conf.dart';
import 'package:blockchain_utils/bip/substrate/conf/substrate_coins.dart';
import 'package:blockchain_utils/exception/exception.dart';

import 'substrate_coin_conf.dart';

/// A configuration class for Substrate coins that defines the key network versions and
/// maps each supported SubstrateCoins to its corresponding SubstrateConf.
class SubstrateConf {
  /// Retrieves the SubstrateCoinConf for the given SubstrateCoin. If the provided coin
  /// is not an instance of SubstrateCoins, an error is thrown.
  static SubstrateCoinConf getCoin(CryptoCoins coin) {
    if (coin is! SubstrateCoins) {
      throw const ArgumentException(
          "Coin type is not an enumerative of SubstrateCoins");
    }
    return coinToConf[coin.value]!;
  }

  /// A mapping that associates each SubstrateCoins (enum) with its corresponding
  /// SubstrateCoinConf configuration.
  static final Map<SubstrateCoins, SubstrateCoinConf> coinToConf = {
    SubstrateCoins.acala: SubstrateConf.acala,
    SubstrateCoins.bifrost: SubstrateConf.bifrost,
    SubstrateCoins.chainx: SubstrateConf.chainX,
    SubstrateCoins.edgeware: SubstrateConf.edgeware,
    SubstrateCoins.generic: SubstrateConf.generic,
    SubstrateCoins.karura: SubstrateConf.karura,
    SubstrateCoins.kusama: SubstrateConf.kusama,
    SubstrateCoins.moonbeam: SubstrateConf.moonbeam,
    SubstrateCoins.moonriver: SubstrateConf.moonriver,
    SubstrateCoins.phala: SubstrateConf.phala,
    SubstrateCoins.plasm: SubstrateConf.plasm,
    SubstrateCoins.polkadot: SubstrateConf.polkadot,
    SubstrateCoins.sora: SubstrateConf.sora,
    SubstrateCoins.stafi: SubstrateConf.stafi,
  };
  // Configuration for Acala
  static final SubstrateCoinConf acala =
      SubstrateCoinConf.fromCoinConf(CoinsConf.acala);

  // Configuration for Bifrost
  static final SubstrateCoinConf bifrost =
      SubstrateCoinConf.fromCoinConf(CoinsConf.bifrost);

  // Configuration for ChainX
  static final SubstrateCoinConf chainX =
      SubstrateCoinConf.fromCoinConf(CoinsConf.chainX);

  // Configuration for Edgeware
  static final SubstrateCoinConf edgeware =
      SubstrateCoinConf.fromCoinConf(CoinsConf.edgeware);

  // Configuration for generic Substrate coin
  static final SubstrateCoinConf generic =
      SubstrateCoinConf.fromCoinConf(CoinsConf.genericSubstrate);

  // Configuration for Karura
  static final SubstrateCoinConf karura =
      SubstrateCoinConf.fromCoinConf(CoinsConf.karura);

  // Configuration for Kusama
  static final SubstrateCoinConf kusama =
      SubstrateCoinConf.fromCoinConf(CoinsConf.kusama);

  // Configuration for Moonbeam
  static final SubstrateCoinConf moonbeam =
      SubstrateCoinConf.fromCoinConf(CoinsConf.moonbeam);

  // Configuration for Moonriver
  static final SubstrateCoinConf moonriver =
      SubstrateCoinConf.fromCoinConf(CoinsConf.moonriver);

  // Configuration for Phala
  static final SubstrateCoinConf phala =
      SubstrateCoinConf.fromCoinConf(CoinsConf.phala);

  // Configuration for Plasm
  static final SubstrateCoinConf plasm =
      SubstrateCoinConf.fromCoinConf(CoinsConf.plasm);

  // Configuration for Polkadot
  static final SubstrateCoinConf polkadot =
      SubstrateCoinConf.fromCoinConf(CoinsConf.polkadot);

  // Configuration for Sora
  static final SubstrateCoinConf sora =
      SubstrateCoinConf.fromCoinConf(CoinsConf.sora);

  // Configuration for Stafi
  static final SubstrateCoinConf stafi =
      SubstrateCoinConf.fromCoinConf(CoinsConf.stafi);
}
