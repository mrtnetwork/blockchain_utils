import 'package:blockchain_utils/protocol/bip/bip/bip32/bip32_key_data.dart';
import 'package:blockchain_utils/protocol/bip/bip/bip32/bip32_key_net_ver.dart';
import 'package:blockchain_utils/protocol/bip/bip/conf/core/coin_conf.dart';
import 'package:blockchain_utils/crypto/crypto/keys/types/types.dart';
import 'package:blockchain_utils/protocol/bip/coin_conf/models/coins_name.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// A base class representing configuration parameters for a cryptocurrency coin.
abstract class BaseBipCoinConfig<CONFIG extends BaseCoinConfig>
    implements CoinConfig<CONFIG> {
  /// Configuration properties.
  @override
  final CoinNames coinNames;
  final int coinIdx;
  @override
  final ChainType chainType;
  final String defPath;
  @override
  final Bip32KeyNetVersions keyNetVer;
  @override
  final List<int>? wifNetVer;
  @override
  final CbAddrEncoder<CONFIG> addressEncoder;

  String encodeAddress(EncodeAddressDefaultParams params) {
    return addressEncoder(params, this as CONFIG);
  }

  @override
  final CryptoKeyType type;

  final Bip32KeyIndex? purpose;

  /// Constructor for BipCoinConfig.
  const BaseBipCoinConfig({
    required this.coinNames,
    required this.coinIdx,
    required this.chainType,
    required this.defPath,
    required this.keyNetVer,
    required this.wifNetVer,
    required this.type,
    required this.addressEncoder,
    this.purpose,
  });

  BaseBipCoinConfig<CONFIG> copy({
    CoinNames? coinNames,
    int? coinIdx,
    ChainType? chainType,
    String? defPath,
    Bip32KeyNetVersions? keyNetVer,
    List<int>? wifNetVer,
    CryptoKeyType? type,
    CbAddrEncoder<CONFIG>? addressEncoder,
    Bip32KeyIndex? purpose,
  });

  @override
  bool get hasExtendedKeys => true;

  @override
  bool get hasWif => wifNetVer != null;
}

/// A base class representing configuration parameters for a cryptocurrency coin.
class BipCoinConfig extends BaseBipCoinConfig<BipCoinConfig> {
  /// Creates a copy of the BipCoinConfig object with optional properties updated.
  @override
  BipCoinConfig copy({
    CoinNames? coinNames,
    int? coinIdx,
    ChainType? chainType,
    String? defPath,
    Bip32KeyNetVersions? keyNetVer,
    List<int>? wifNetVer,
    CryptoKeyType? type,
    CbAddrEncoder<BipCoinConfig>? addressEncoder,
    Bip32KeyIndex? purpose,
    DefaultHdKeyDerivator? defaultHdKeyDerivator,
    List<HwVariantSupport>? hwSupport,
  }) {
    return BipCoinConfig(
      coinNames: coinNames ?? this.coinNames,
      coinIdx: coinIdx ?? this.coinIdx,
      chainType: chainType ?? this.chainType,
      defPath: defPath ?? this.defPath,
      keyNetVer: keyNetVer ?? this.keyNetVer,
      wifNetVer: wifNetVer ?? this.wifNetVer,
      type: type ?? this.type,
      addressEncoder: addressEncoder ?? this.addressEncoder,
      defaultHdKeyDerivator:
          defaultHdKeyDerivator ?? this.defaultHdKeyDerivator,
      purpose: purpose ?? this.purpose,
      hwSupport: hwSupport ?? this.hwSupport,
    );
  }

  /// Constructor for BipCoinConfig.
  const BipCoinConfig({
    required super.coinNames,
    required super.coinIdx,
    required super.chainType,
    required super.defPath,
    required super.keyNetVer,
    required super.wifNetVer,
    required super.type,
    required super.addressEncoder,
    this.defaultHdKeyDerivator,
    super.purpose,
    this.hwSupport = const [],
  });

  /// Hardware-wallet support claims for this coin, one entry per
  /// (device, variant) pair. `variant` is the address/script type
  /// (`'p2pkh' | 'p2wpkh' | 'p2sh' | 'p2tr'`) for UTXO coins, the curve
  /// name for the rest. Resolve with `hwFor(config.hwSupport, variant)`;
  /// no entry for a variant = unknown (never shipped as supported).
  final List<HwVariantSupport> hwSupport;

  @override
  bool get hasExtendedKeys => true;

  @override
  bool get hasWif => wifNetVer != null;

  @override
  final DefaultHdKeyDerivator? defaultHdKeyDerivator;
}
