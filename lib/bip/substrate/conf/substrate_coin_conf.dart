import 'package:blockchain_utils/bip/bip/bip32/bip32_key_net_ver.dart';
import 'package:blockchain_utils/bip/bip/conf/core/coin_conf.dart';
import 'package:blockchain_utils/bip/coin_conf/models/coin_conf.dart';
import 'package:blockchain_utils/bip/coin_conf/models/coins_name.dart';
import 'package:blockchain_utils/bip/ecc/curve/elliptic_curve_types.dart';

/// A class representing the configuration for a Substrate-based cryptocurrency.
class SubstrateCoinConf implements CoinConfig {
  /// Coin names and symbols
  @override
  final CoinNames coinNames;

  /// Address format identifier
  final int ss58Format;

  /// Constructor for creating a SubstrateCoinConf instance.
  ///
  /// It initializes the Substrate cryptocurrency's coin names and symbols [coinNames]
  /// and the SS58 address format identifier [ss58Format].
  const SubstrateCoinConf(
      {required this.coinNames,
      required this.ss58Format,
      required this.addressEncoder,
      required this.type,
      this.addrParams = const {},
      required this.chainType});

  /// Factory method to create a SubstrateCoinConf from a generic CoinConf.
  ///
  /// This method takes a generic `CoinConf` instance and extracts the coin names
  /// and SS58 address format information to create a `SubstrateCoinConf`.
  factory SubstrateCoinConf.fromCoinConf(
      {required CoinConf coinConf,
      required AddrEncoder addressEncode,
      required EllipticCurveTypes type,
      required ChainType chainType}) {
    return SubstrateCoinConf(
        coinNames: coinConf.coinName,
        ss58Format: coinConf.params.addrSs58Format!,
        addressEncoder: addressEncode,
        type: type,
        chainType: chainType);
  }

  @override
  final AddrEncoder addressEncoder;

  @override
  final EllipticCurveTypes type;

  @override
  final Map<String, dynamic> addrParams;

  @override
  final ChainType chainType;

  @override
  bool get hasExtendedKeys => false;

  @override
  bool get hasWif => false;

  @override
  final Bip32KeyNetVersions? keyNetVer = null;
  @override
  final List<int>? wifNetVer = null;
}
