import 'package:blockchain_utils/crypto/crypto/keys/types/types.dart';
import 'package:blockchain_utils/protocol/bip/bip/bip32/bip32_key_net_ver.dart';
import 'package:blockchain_utils/protocol/bip/bip/conf/core/coin_conf.dart';
import 'package:blockchain_utils/protocol/bip/bip/eip2334/eip2334_const.dart';
import 'package:blockchain_utils/protocol/bip/coin_conf/constant/coins_conf.dart';
import 'package:blockchain_utils/protocol/bip/coin_conf/models/coins_name.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

class Eip2334CoinConfig implements CoinConfig<Eip2334CoinConfig> {
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
  final CbAddrEncoder<Eip2334CoinConfig> addressEncoder;

  /// Ethereum Beacon-chain coin type (3600).
  final int coinIdx;

  /// Default derivation path (first withdrawal key).
  final String defPath;

  const Eip2334CoinConfig({
    required this.coinNames,
    required this.type,
    required this.chainType,
    required this.addressEncoder,
    required this.coinIdx,
    required this.defPath,
  });

  String encodeAddress(EncodeAddressDefaultParams params) {
    return addressEncoder(params, this);
  }
}

/// A configuration class for EIP-2334 coins.
class Eip2334Conf {
  /// Configuration for Ethereum Beacon-chain validator keys (EIP-2333/2334).
  /// BLS validator keys have no addresses: they are identified by the
  /// 48-byte G1 public key, so the encoder throws (Hedera precedent).
  final Eip2334CoinConfig ethereumBls = Eip2334CoinConfig(
    coinNames: CoinsConf.ethereumBls.coinName,
    coinIdx: Eip2334Const.ethereumCoinType,
    chainType: ChainType.mainnet,
    defPath: '0/0',
    type: CryptoKeyType.bls12G1,
    addressEncoder: (params, config) {
      throw BuError(DefaultErrorType.badPublicKey,
        "BLS validator keys have no addresses; use the 48-byte public key.",
      );
    },
  );

  final Eip2334CoinConfig tezosBls = Eip2334CoinConfig(
    coinNames: CoinsConf.tezos.coinName,
    coinIdx: 1729,
    chainType: ChainType.mainnet,
    defPath: '0/0',
    type: CryptoKeyType.bls12G1,
    addressEncoder: (params, config) {
      throw BuError(DefaultErrorType.invalidAddress,
        "Tezos BLS keys address as tz4 via the Tezos address encoder, not here.",
      );
    },
  );

  final Eip2334CoinConfig filecoinBls = Eip2334CoinConfig(
    coinNames: CoinsConf.filecoin.coinName,
    coinIdx: 461,
    chainType: ChainType.mainnet,
    defPath: '0/0',
    type: CryptoKeyType.bls12G1,
    addressEncoder: (params, config) {
      throw BuError(DefaultErrorType.invalidAddress,
        "Filecoin BLS keys address as f3 via the Filecoin address encoder, not here.",
      );
    },
  );
}
