import 'package:blockchain_utils/crypto/crypto/keys/types/types.dart';
import 'package:blockchain_utils/protocol/bip/bip/bip32/bip32_key_net_ver.dart';
import 'package:blockchain_utils/protocol/bip/bip/conf/core/coin_conf.dart';
import 'package:blockchain_utils/protocol/bip/coin_conf/models/coins_name.dart';

/// Lean coin configuration for key types that have no HD derivation standard
/// (e.g. Filecoin BLS, NEAR ML-DSA-65).
///
/// Unlike [BipCoinConfig] it carries no HD baggage: no coin index, no default
/// path, no key net versions and no HD derivator. Coins using this config can
/// only tag imported or randomly generated keys with the correct key type;
/// any derivation attempt fails.
class NonDerivableCoinConfig implements BaseCoinConfig {
  @override
  final CoinNames coinNames;
  @override
  final CryptoKeyType type;
  @override
  final ChainType chainType;
  @override
  final bool hasWif;
  @override
  final bool hasExtendedKeys;
  @override
  final Bip32KeyNetVersions? keyNetVer;
  @override
  final List<int>? wifNetVer;
  @override
  final DefaultHdKeyDerivator? defaultHdKeyDerivator;

  final CbAddrEncoder<NonDerivableCoinConfig> addressEncoder;

  const NonDerivableCoinConfig({
    required this.coinNames,
    required this.type,
    required this.chainType,
    required this.addressEncoder,
    this.hasWif = false,
    this.hasExtendedKeys = false,
    this.keyNetVer,
    this.wifNetVer,
    this.defaultHdKeyDerivator,
  });
}
