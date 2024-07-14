import 'package:blockchain_utils/bip/bip/bip32/bip32_key_net_ver.dart';
import 'package:blockchain_utils/bip/bip/conf/core/coin_conf.dart';
import 'package:blockchain_utils/bip/coin_conf/coin_conf.dart';
import 'package:blockchain_utils/bip/coin_conf/coins_name.dart';
import 'package:blockchain_utils/bip/ecc/curve/elliptic_curve_types.dart';

/// Configuration class for Monero-based cryptocurrencies, specifying various parameters
/// such as network versions, address types, and coin names.
class MoneroCoinConf implements CoinConfig {
  @override
  final CoinNames coinNames;
  final List<int> addrNetVer;
  final List<int> intAddrNetVer;
  final List<int> subaddrNetVer;

  /// address parameters
  @override
  final Map<String, List<int>> addrParams = {};

  /// private constructor
  MoneroCoinConf._(this.coinNames, this.addrNetVer, this.intAddrNetVer,
      this.subaddrNetVer, this.isTestnet);

  /// MoneroCoinConf from coinConf
  factory MoneroCoinConf.fromCoinConf(CoinConf coinConf, {bool? isTestnet}) {
    return MoneroCoinConf._(
        coinConf.coinName,
        coinConf.params.addrNetVer!,
        coinConf.params.addrIntNetVer!,
        coinConf.params.subaddrNetVer!,
        isTestnet);
  }

  @override
  AddrEncoder get addressEncoder => throw UnimplementedError();

  @override
  EllipticCurveTypes get type => EllipticCurveTypes.ed25519Monero;

  @override
  final bool? isTestnet;

  @override
  bool get hasExtendedKeys => false;

  @override
  bool get hasWif => false;

  @override
  final Bip32KeyNetVersions? keyNetVer = null;

  @override
  final List<int>? wifNetVer = null;
}
