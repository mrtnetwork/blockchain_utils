import 'package:blockchain_utils/bip/address/encoder.dart';
import 'package:blockchain_utils/bip/bip/bip32/bip32_key_net_ver.dart';
import 'package:blockchain_utils/bip/ecc/curve/elliptic_curve_types.dart';
import 'package:blockchain_utils/bip/coin_conf/models/coins_name.dart';
import 'package:blockchain_utils/exception/const/const.dart';

/// A typedef for the address encoder function that takes optional dynamic parameters.
typedef AddrEncoder = BlockchainAddressEncoder Function([dynamic kwargs]);

enum ChainType {
  testnet("testnet"),
  mainnet("mainnet");

  final String tr;
  const ChainType(this.tr);
  bool get isMainnet => this == mainnet;
  static ChainType fromValue(dynamic val) {
    if (val is bool) {
      if (val) return ChainType.mainnet;
      return ChainType.testnet;
    }
    return values.firstWhere((e) => e.name == val,
        orElse: () => throw ExceptionConst.itemNotFound(item: 'chain type'));
  }
}

/// A base class representing configuration parameters for a cryptocurrency coin.
abstract class CoinConfig {
  /// Base Configuration properties.
  abstract final CoinNames coinNames;
  abstract final AddrEncoder addressEncoder;
  abstract final EllipticCurveTypes type;
  abstract final Map<String, dynamic> addrParams;
  abstract final ChainType chainType;
  bool get hasWif;
  bool get hasExtendedKeys;
  abstract final Bip32KeyNetVersions? keyNetVer;
  abstract final List<int>? wifNetVer;
}
