import 'package:blockchain_utils/protocol/bip/bip/bip32/bip32_key_data.dart';
import 'package:blockchain_utils/protocol/bip/bip/bip32/bip32_key_net_ver.dart';
import 'package:blockchain_utils/protocol/bip/bip/conf/config/bip_coin_conf.dart';
import 'package:blockchain_utils/protocol/bip/bip/conf/core/coin_conf.dart';
import 'package:blockchain_utils/crypto/crypto/keys/types/types.dart';
import 'package:blockchain_utils/protocol/bip/coin_conf/models/coins_name.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// A class representing the configuration for Bitcoin Cash (BCH) based on the BIP framework.
class BipBitcoinCashConf extends BaseBipCoinConfig<BipBitcoinCashConf> {
  /// Flag to indicate whether legacy address format should be used.
  final bool useLagacyAdder;

  /// Constructor for BipBitcoinCashConf.
  const BipBitcoinCashConf({
    required super.coinNames,
    required super.coinIdx,
    required super.chainType,
    required super.defPath,
    required super.keyNetVer,
    required super.wifNetVer,
    required super.type,
    required super.addressEncoder,
    super.purpose,
    this.useLagacyAdder = false,
    this.hwSupport = const [],
  });

  /// Hardware-wallet support claims, one entry per (device, variant) pair.
  /// Resolve with `hwFor(hwSupport, variant)`; empty = unknown.
  final List<HwVariantSupport> hwSupport;

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
    CryptoKeyType? type,
    CbAddrEncoder<BipBitcoinCashConf>? addressEncoder,
    bool? useLagacyAdder,
    Bip32KeyIndex? purpose,
    List<HwVariantSupport>? hwSupport,
  }) {
    return BipBitcoinCashConf(
      coinNames: coinNames ?? this.coinNames,
      coinIdx: coinIdx ?? this.coinIdx,
      chainType: chainType ?? this.chainType,
      defPath: defPath ?? this.defPath,
      keyNetVer: keyNetVer ?? this.keyNetVer,
      wifNetVer: wifNetVer ?? this.wifNetVer,
      type: type ?? this.type,
      addressEncoder: addressEncoder ?? this.addressEncoder,
      useLagacyAdder: useLagacyAdder ?? this.useLagacyAdder,
      purpose: purpose ?? this.purpose,
      hwSupport: hwSupport ?? this.hwSupport,
    );
  }

  @override
  DefaultHdKeyDerivator? get defaultHdKeyDerivator => null;
}
