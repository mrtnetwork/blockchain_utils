import 'package:blockchain_utils/bip/bip/bip32/bip32_key_net_ver.dart';
import 'package:blockchain_utils/bip/bip/conf/config/bip_coin_conf.dart';
import 'package:blockchain_utils/bip/bip/conf/core/coin_conf.dart';
import 'package:blockchain_utils/bip/ecc/curve/elliptic_curve_types.dart';
import 'package:blockchain_utils/bip/coin_conf/models/coins_name.dart';

/// A class representing the configuration for Litecoin (LTC) based on the BIP framework.
class BipLitecoinConf extends BipCoinConfig {
  /// Configuration properties specific to Litecoin.
  final Bip32KeyNetVersions altKeyNetVer;
  final bool useDeprAddress;
  final bool useAltKeyNetVer;

  /// Constructor for BipLitecoinConf.
  const BipLitecoinConf({
    required super.coinNames,
    required super.coinIdx,
    required super.chainType,
    required super.defPath,
    required super.keyNetVer,
    required super.wifNetVer,
    required super.type,
    required super.addressEncoder,
    required super.addrParams,
    required this.altKeyNetVer,
    this.useAltKeyNetVer = false,
    this.useDeprAddress = false,
  });

  /// Overrides the 'addrParams' getter to return the appropriate address parameters
  /// based on the 'useDeprAddress' flag.
  @override
  Map<String, dynamic> get addrParams {
    return {
      "net_ver": useDeprAddress
          ? super.addrParams["depr_net_ver"]
          : super.addrParams['std_net_ver']
    };
  }

  /// Overrides the 'keyNetVer' getter to use the alternate key network version
  /// when the 'usAltKeyNetVer' flag is set to true.
  @override
  Bip32KeyNetVersions get keyNetVer =>
      useAltKeyNetVer ? altKeyNetVer : super.keyNetVer;
  @override

  /// Creates a copy of the BipLitecoinConf object with optional properties updated.
  BipLitecoinConf copy({
    CoinNames? coinNames,
    int? coinIdx,
    ChainType? chainType,
    String? defPath,
    Bip32KeyNetVersions? keyNetVer,
    Bip32KeyNetVersions? altKeyNetVer,
    List<int>? wifNetVer,
    Map<String, dynamic>? addrParams,
    EllipticCurveTypes? type,
    AddrEncoder? addressEncoder,
    bool? useAltKeyNetVer,
    bool? useDeprAddress,
  }) {
    return BipLitecoinConf(
        coinNames: coinNames ?? this.coinNames,
        coinIdx: coinIdx ?? this.coinIdx,
        chainType: chainType ?? this.chainType,
        defPath: defPath ?? this.defPath,
        keyNetVer: keyNetVer ?? this.keyNetVer,
        wifNetVer: wifNetVer ?? this.wifNetVer,
        addrParams: addrParams ?? this.addrParams,
        type: type ?? this.type,
        addressEncoder: addressEncoder ?? this.addressEncoder,
        altKeyNetVer: altKeyNetVer ?? this.altKeyNetVer,
        useAltKeyNetVer: useAltKeyNetVer ?? this.useAltKeyNetVer,
        useDeprAddress: useDeprAddress ?? this.useDeprAddress);
  }
}
