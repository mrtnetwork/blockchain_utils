import 'package:blockchain_utils/bip/bip/bip32/bip32_key_data.dart';
import 'package:blockchain_utils/bip/bip/bip32/bip32_key_net_ver.dart';
import 'package:blockchain_utils/bip/bip/conf/core/coin_conf.dart';
import 'package:blockchain_utils/bip/coin_conf/models/coins_name.dart';
import 'package:blockchain_utils/bip/ecc/curve/elliptic_curve_types.dart';
import 'package:blockchain_utils/bip/zcash/src/types.dart';

/// A base class representing configuration parameters for a cryptocurrency coin.
class ZIP32CoinConfig implements CoinConfig<ZIP32CoinConfig> {
  final Bip32KeyIndex purpose;
  final ZCashNetwork network;

  /// Configuration properties.
  @override
  final CoinNames coinNames;
  final int coinIdx;
  @override
  final ChainType chainType;
  final String defPath;
  @override
  final Bip32KeyNetVersions keyNetVer;
  // final Bip32KeyNetVersions bip32keyNetVersions;
  @override
  final List<int>? wifNetVer = null;
  @override
  final ADDRENCODER<ZIP32CoinConfig> addressEncoder;
  @override
  final EllipticCurveTypes type;

  final String hrpSaplingExtendedSpendingKey;
  final String hrpSaplingExtendedFullViewingKey;
  final String hrpSaplingPaymentAddress;
  final List<int> b58SproutAddressPrefix;
  final List<int> b58SecretKeyPrefix;
  final List<int> b58PubkeyAddressPrefix;
  final List<int> b58ScriptAddressPrefix;
  final String hrpTexAddress;
  final String hrpUnifiedAddress;
  final String hrpUnifiedFvk;
  final String hrpUnifiedIvk;

  String encodeAddress(EncodeAddressDefaultParams params) {
    return addressEncoder(params, this);
  }

  const ZIP32CoinConfig({
    required this.coinNames,
    required this.type,
    required this.coinIdx,
    required this.chainType,
    required this.defPath,
    required this.network,
    required this.keyNetVer,
    required this.addressEncoder,
    required this.purpose,
    required this.hrpSaplingExtendedSpendingKey,
    required this.hrpSaplingExtendedFullViewingKey,
    required this.hrpSaplingPaymentAddress,
    required this.b58SproutAddressPrefix,
    required this.b58SecretKeyPrefix,
    required this.b58PubkeyAddressPrefix,
    required this.b58ScriptAddressPrefix,
    required this.hrpTexAddress,
    required this.hrpUnifiedAddress,
    required this.hrpUnifiedFvk,
    required this.hrpUnifiedIvk,
  });

  @override
  bool get hasExtendedKeys => true;

  @override
  bool get hasWif => false;

  @override
  DefaultHdKeyDerivator? get defaultHdKeyDerivator => null;
}
