import 'package:blockchain_utils/crypto/crypto/keys/types/types.dart';
import 'package:blockchain_utils/encoding/base58/base58.dart';
import 'package:blockchain_utils/protocol/bip/bip/bip32/bip32_key_data.dart';
import 'package:blockchain_utils/protocol/bip/bip/bip32/bip32_key_net_ver.dart';
import 'package:blockchain_utils/protocol/bip/bip/conf/const/bip_conf_const.dart';
import 'package:blockchain_utils/protocol/bip/bip/conf/core/coin_conf.dart';
import 'package:blockchain_utils/protocol/bip/coin_conf/constant/coins_conf.dart';
import 'package:blockchain_utils/protocol/bip/coin_conf/models/coins_name.dart';
import 'package:blockchain_utils/protocol/bip/slip/slip44/slip44.dart';

class Nep649CoinConfig implements CoinConfig<Nep649CoinConfig> {
  @override
  final CoinNames coinNames;
  @override
  final CryptoKeyType type;
  @override
  final ChainType chainType;
  @override
  final bool hasWif = false;
  @override
  final bool hasExtendedKeys = false;
  @override
  final Bip32KeyNetVersions? keyNetVer = null;
  @override
  final List<int>? wifNetVer = null;
  @override
  final DefaultHdKeyDerivator? defaultHdKeyDerivator = null;
  @override
  final CbAddrEncoder<Nep649CoinConfig> addressEncoder;

  /// SLIP-44 coin type (NEAR).
  final int coinIdx;

  /// Default derivation path (NEP-649 short path).
  final String defPath;

  /// BIP-44 purpose level override (null falls back to 44').
  final Bip32KeyIndex? purpose;

  const Nep649CoinConfig({
    required this.coinNames,
    required this.type,
    required this.chainType,
    required this.addressEncoder,
    required this.coinIdx,
    required this.defPath,
    this.purpose,
  });

  String encodeAddress(EncodeAddressDefaultParams params) {
    return addressEncoder(params, this);
  }
}

/// A configuration class for NEP-649 coins.
class Nep649Conf {
  /// Configuration for Near Protocol ML-DSA-65 access keys (NEP-649).
  final Nep649CoinConfig nearMldsa = Nep649CoinConfig(
    coinNames: CoinsConf.nearProtocol.coinName,
    coinIdx: Slip44.nearProtocol,
    chainType: ChainType.mainnet,
    defPath: derPathHardenedShort,
    type: CryptoKeyType.mldsa65,
    addressEncoder:
        (params, config) => 'ml-dsa-65:${Base58Encoder.encode(params.pubKey)}',
  );
}
