import 'package:blockchain_utils/bip/address/encoder.dart';
import 'package:blockchain_utils/bip/bip/bip32/bip32_key_net_ver.dart';
import 'package:blockchain_utils/bip/bip/conf/config/bip_coin_conf.dart';
import 'package:blockchain_utils/bip/bip/conf/core/coin_conf.dart';
import 'package:blockchain_utils/bip/ecc/curve/elliptic_curve_types.dart';
import 'package:blockchain_utils/bip/coin_conf/models/coins_name.dart';

/// A class representing the configuration for Bitcoin Cash (BCH) based on the BIP framework.
class BipBitcoinCashConf extends BipCoinConfig {
  /// Flag to indicate whether legacy address format should be used.
  final bool useLagacyAdder;

  /// Returns an address encoder based on the 'useLagacyAdder' flag.
  @override
  BlockchainAddressEncoder encoder() {
    return addressEncoder([useLagacyAdder]);
  }

  /// Constructor for BipBitcoinCashConf.
  @override
  const BipBitcoinCashConf({
    required super.coinNames,
    required super.coinIdx,
    required super.chainType,
    required super.defPath,
    required super.keyNetVer,
    required super.wifNetVer,
    required super.type,
    required super.addressEncoder,
    required super.addrParams,
    this.useLagacyAdder = false,
  });

  /// Overrides the 'addrParams' getter to return the appropriate address parameters
  /// based on the 'useLagacyAdder' flag.
  @override
  Map<String, dynamic> get addrParams {
    if (useLagacyAdder) {
      return super.addrParams["legacy"];
    }
    return super.addrParams['std'];
  }

  /// Creates a copy of the BipBitcoinCashConf object with optional properties updated.
  @override
  BipBitcoinCashConf copy({
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
    bool? useLagacyAdder,
  }) {
    return BipBitcoinCashConf(
        coinNames: coinNames ?? this.coinNames,
        coinIdx: coinIdx ?? this.coinIdx,
        chainType: chainType ?? this.chainType,
        defPath: defPath ?? this.defPath,
        keyNetVer: keyNetVer ?? this.keyNetVer,
        wifNetVer: wifNetVer ?? this.wifNetVer,
        addrParams: addrParams ?? this.addrParams,
        type: type ?? this.type,
        addressEncoder: addressEncoder ?? this.addressEncoder,
        useLagacyAdder: useLagacyAdder ?? this.useLagacyAdder);
  }
}
