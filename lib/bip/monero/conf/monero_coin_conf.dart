import 'package:blockchain_utils/bip/address/xmr_addr.dart';
import 'package:blockchain_utils/bip/bip/bip32/bip32_key_net_ver.dart';
import 'package:blockchain_utils/bip/bip/conf/core/coin_conf.dart';
import 'package:blockchain_utils/bip/coin_conf/models/coin_conf.dart';
import 'package:blockchain_utils/bip/coin_conf/models/coins_name.dart';
import 'package:blockchain_utils/bip/ecc/curve/elliptic_curve_types.dart';

/// Configuration class for Monero-based cryptocurrencies, specifying various parameters
/// such as network versions, address types, and coin names.
class MoneroCoinConf implements CoinConfig<MoneroCoinConf> {
  @override
  final CoinNames coinNames;
  final List<int> addrNetVer;
  final List<int> intAddrNetVer;
  final List<int> subaddrNetVer;

  /// private constructor
  MoneroCoinConf._(
    this.coinNames,
    this.addrNetVer,
    this.intAddrNetVer,
    this.subaddrNetVer,
    this.chainType,
  );

  /// MoneroCoinConf from coinConf
  factory MoneroCoinConf.fromCoinConf({
    required CoinConf coinConf,
    required ChainType chainType,
  }) {
    return MoneroCoinConf._(
      coinConf.coinName,
      coinConf.params.addrNetVer!,
      coinConf.params.addrIntNetVer!,
      coinConf.params.subaddrNetVer!,
      chainType,
    );
  }

  @override
  EllipticCurveTypes get type => EllipticCurveTypes.ed25519Monero;

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

  @override
  ADDRENCODER<MoneroCoinConf> get addressEncoder =>
      (params, confing) => XmrAddrEncoder().encodeKey(params.pubKey);

  @override
  DefaultHdKeyDerivator? get defaultHdKeyDerivator => null;
}
