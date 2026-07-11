import 'package:blockchain_utils/bip/bip/bip32/bip32_key_net_ver.dart';
import 'package:blockchain_utils/bip/coin_conf/models/coins_name.dart';
import 'package:blockchain_utils/bip/ecc/curve/elliptic_curve_types.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';

typedef CbAddrEncoder<CONFIG extends BaseCoinConfig> =
    String Function(EncodeAddressDefaultParams params, CONFIG config);

class EncodeAddressDefaultParams {
  final List<int> pubKey;
  final List<int>? chainCode;

  /// Substrate related config
  final int? ss58Format;

  /// Ada byron legacy related.
  final String? path;
  final List<int>? hdPathKey;

  EncodeAddressDefaultParams({
    required List<int> pubKey,
    this.ss58Format,
    this.path,
    List<int>? hdPathKey,
    List<int>? chainCode,
  }) : chainCode = chainCode?.asImmutableBytes,
       pubKey = pubKey.asImmutableBytes,
       hdPathKey = hdPathKey?.asImmutableBytes;
}

enum ChainType {
  testnet("testnet", 1),
  mainnet("mainnet", 2);

  final String tr;
  final int value;
  const ChainType(this.tr, this.value);
  bool get isMainnet => this == mainnet;
  static ChainType fromValue(dynamic val) {
    if (val is bool) {
      if (val) return ChainType.mainnet;
      return ChainType.testnet;
    }
    if (val is int) {
      return values.firstWhere(
        (e) => e.value == val,
        orElse: () => throw ItemNotFoundException(value: val),
      );
    }
    return values.firstWhere(
      (e) => e.name == val,
      orElse: () => throw ItemNotFoundException(value: val),
    );
  }
}

enum DefaultHdKeyDerivator { icarus }

abstract class BaseCoinConfig {
  abstract final DefaultHdKeyDerivator? defaultHdKeyDerivator;

  /// Base Configuration properties.
  abstract final CoinNames coinNames;
  abstract final EllipticCurveTypes type;
  abstract final ChainType chainType;
  bool get hasWif;
  bool get hasExtendedKeys;
  abstract final Bip32KeyNetVersions? keyNetVer;
  abstract final List<int>? wifNetVer;
}

/// A base class representing configuration parameters for a cryptocurrency coin.
abstract class CoinConfig<T extends BaseCoinConfig> implements BaseCoinConfig {
  abstract final CbAddrEncoder<T> addressEncoder;
}
