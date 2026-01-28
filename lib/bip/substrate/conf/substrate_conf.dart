import 'package:blockchain_utils/bip/address/substrate_addr.dart';
import 'package:blockchain_utils/bip/bip/conf/core/coin_conf.dart';
import 'package:blockchain_utils/bip/coin_conf/constant/coins_conf.dart';
import 'package:blockchain_utils/bip/ecc/curve/elliptic_curve_types.dart';
import 'substrate_coin_conf.dart';

/// A configuration class for Substrate coins that defines the key network versions and
/// maps each supported SubstrateCoins to its corresponding SubstrateConf.
class SubstrateConf {
  final SubstrateCoinConf acalaEd25519 = SubstrateCoinConf.fromCoinConf(
    coinConf: CoinsConf.acala,
    addressEncode:
        (params, config) => SubstrateEd25519AddrEncoder().encodeKey(
          params.pubKey,
          ss58Format: params.ss58Format ?? config.ss58Format,
        ),
    type: EllipticCurveTypes.ed25519,
    chainType: ChainType.mainnet,
  );
  // Configuration for Acala
  final SubstrateCoinConf acalaSecp256k1 = SubstrateCoinConf.fromCoinConf(
    coinConf: CoinsConf.acala,
    addressEncode:
        (params, config) => SubstrateSecp256k1AddrEncoder().encodeKey(
          params.pubKey,
          ss58Format: params.ss58Format ?? config.ss58Format,
        ),
    type: EllipticCurveTypes.secp256k1,
    chainType: ChainType.mainnet,
  );

  final SubstrateCoinConf acalaSr25519 = SubstrateCoinConf.fromCoinConf(
    coinConf: CoinsConf.acala,
    addressEncode:
        (params, config) => SubstrateSr25519AddrEncoder().encodeKey(
          params.pubKey,
          ss58Format: params.ss58Format ?? config.ss58Format,
        ),
    type: EllipticCurveTypes.sr25519,
    chainType: ChainType.mainnet,
  );

  // Configuration for Bifrost
  final SubstrateCoinConf bifrostEd25519 = SubstrateCoinConf.fromCoinConf(
    coinConf: CoinsConf.bifrost,
    addressEncode:
        (params, config) => SubstrateEd25519AddrEncoder().encodeKey(
          params.pubKey,
          ss58Format: params.ss58Format ?? config.ss58Format,
        ),
    type: EllipticCurveTypes.ed25519,
    chainType: ChainType.mainnet,
  );
  final SubstrateCoinConf bifrostSecp256k1 = SubstrateCoinConf.fromCoinConf(
    coinConf: CoinsConf.bifrost,
    addressEncode:
        (params, config) => SubstrateSecp256k1AddrEncoder().encodeKey(
          params.pubKey,
          ss58Format: params.ss58Format ?? config.ss58Format,
        ),
    type: EllipticCurveTypes.secp256k1,
    chainType: ChainType.mainnet,
  );
  final SubstrateCoinConf bifrostSr25519 = SubstrateCoinConf.fromCoinConf(
    coinConf: CoinsConf.bifrost,
    addressEncode:
        (params, config) => SubstrateSr25519AddrEncoder().encodeKey(
          params.pubKey,
          ss58Format: params.ss58Format ?? config.ss58Format,
        ),
    type: EllipticCurveTypes.sr25519,
    chainType: ChainType.mainnet,
  );

  // Configuration for ChainX
  final SubstrateCoinConf chainXEd25519 = SubstrateCoinConf.fromCoinConf(
    coinConf: CoinsConf.chainX,
    addressEncode:
        (params, config) => SubstrateEd25519AddrEncoder().encodeKey(
          params.pubKey,
          ss58Format: params.ss58Format ?? config.ss58Format,
        ),
    type: EllipticCurveTypes.ed25519,
    chainType: ChainType.mainnet,
  );
  final SubstrateCoinConf chainXSecp256k1 = SubstrateCoinConf.fromCoinConf(
    coinConf: CoinsConf.chainX,
    addressEncode:
        (params, config) => SubstrateSecp256k1AddrEncoder().encodeKey(
          params.pubKey,
          ss58Format: params.ss58Format ?? config.ss58Format,
        ),
    type: EllipticCurveTypes.secp256k1,
    chainType: ChainType.mainnet,
  );
  final SubstrateCoinConf chainXSr25519 = SubstrateCoinConf.fromCoinConf(
    coinConf: CoinsConf.chainX,
    addressEncode:
        (params, config) => SubstrateSr25519AddrEncoder().encodeKey(
          params.pubKey,
          ss58Format: params.ss58Format ?? config.ss58Format,
        ),
    type: EllipticCurveTypes.sr25519,
    chainType: ChainType.mainnet,
  );

  // Configuration for Edgeware
  final SubstrateCoinConf edgewareEd25519 = SubstrateCoinConf.fromCoinConf(
    coinConf: CoinsConf.edgeware,
    addressEncode:
        (params, config) => SubstrateEd25519AddrEncoder().encodeKey(
          params.pubKey,
          ss58Format: params.ss58Format ?? config.ss58Format,
        ),
    type: EllipticCurveTypes.ed25519,
    chainType: ChainType.mainnet,
  );
  final SubstrateCoinConf edgewareSecp256k1 = SubstrateCoinConf.fromCoinConf(
    coinConf: CoinsConf.edgeware,
    addressEncode:
        (params, config) => SubstrateSecp256k1AddrEncoder().encodeKey(
          params.pubKey,
          ss58Format: params.ss58Format ?? config.ss58Format,
        ),
    type: EllipticCurveTypes.secp256k1,
    chainType: ChainType.mainnet,
  );
  final SubstrateCoinConf edgewareSr25519 = SubstrateCoinConf.fromCoinConf(
    coinConf: CoinsConf.edgeware,
    addressEncode:
        (params, config) => SubstrateSr25519AddrEncoder().encodeKey(
          params.pubKey,
          ss58Format: params.ss58Format ?? config.ss58Format,
        ),
    type: EllipticCurveTypes.sr25519,
    chainType: ChainType.mainnet,
  );

  // Configuration for generic Substrate coin
  final SubstrateCoinConf genericEd25519 = SubstrateCoinConf.fromCoinConf(
    coinConf: CoinsConf.genericSubstrate,
    addressEncode:
        (params, config) => SubstrateEd25519AddrEncoder().encodeKey(
          params.pubKey,
          ss58Format: params.ss58Format ?? config.ss58Format,
        ),
    type: EllipticCurveTypes.ed25519,
    chainType: ChainType.mainnet,
  );
  final SubstrateCoinConf genericSecp256k1 = SubstrateCoinConf.fromCoinConf(
    coinConf: CoinsConf.genericSubstrate,
    addressEncode:
        (params, config) => SubstrateSecp256k1AddrEncoder().encodeKey(
          params.pubKey,
          ss58Format: params.ss58Format ?? config.ss58Format,
        ),
    type: EllipticCurveTypes.secp256k1,
    chainType: ChainType.mainnet,
  );
  final SubstrateCoinConf genericSr25519 = SubstrateCoinConf.fromCoinConf(
    coinConf: CoinsConf.genericSubstrate,
    addressEncode:
        (params, config) => SubstrateSr25519AddrEncoder().encodeKey(
          params.pubKey,
          ss58Format: params.ss58Format ?? config.ss58Format,
        ),
    type: EllipticCurveTypes.sr25519,
    chainType: ChainType.mainnet,
  );

  // Configuration for Karura
  final SubstrateCoinConf karuraEd25519 = SubstrateCoinConf.fromCoinConf(
    coinConf: CoinsConf.karura,
    addressEncode:
        (params, config) => SubstrateEd25519AddrEncoder().encodeKey(
          params.pubKey,
          ss58Format: params.ss58Format ?? config.ss58Format,
        ),
    type: EllipticCurveTypes.ed25519,
    chainType: ChainType.mainnet,
  );
  final SubstrateCoinConf karuraSecp256k1 = SubstrateCoinConf.fromCoinConf(
    coinConf: CoinsConf.karura,
    addressEncode:
        (params, config) => SubstrateSecp256k1AddrEncoder().encodeKey(
          params.pubKey,
          ss58Format: params.ss58Format ?? config.ss58Format,
        ),
    type: EllipticCurveTypes.secp256k1,
    chainType: ChainType.mainnet,
  );
  final SubstrateCoinConf karuraSr25519 = SubstrateCoinConf.fromCoinConf(
    coinConf: CoinsConf.karura,
    addressEncode:
        (params, config) => SubstrateSr25519AddrEncoder().encodeKey(
          params.pubKey,
          ss58Format: params.ss58Format ?? config.ss58Format,
        ),
    type: EllipticCurveTypes.sr25519,
    chainType: ChainType.mainnet,
  );

  // Configuration for Kusama
  final SubstrateCoinConf kusamaEd25519 = SubstrateCoinConf.fromCoinConf(
    coinConf: CoinsConf.kusama,
    addressEncode:
        (params, config) => SubstrateEd25519AddrEncoder().encodeKey(
          params.pubKey,
          ss58Format: params.ss58Format ?? config.ss58Format,
        ),
    type: EllipticCurveTypes.ed25519,
    chainType: ChainType.mainnet,
  );
  final SubstrateCoinConf kusamaSecp256k1 = SubstrateCoinConf.fromCoinConf(
    coinConf: CoinsConf.kusama,
    addressEncode:
        (params, config) => SubstrateSecp256k1AddrEncoder().encodeKey(
          params.pubKey,
          ss58Format: params.ss58Format ?? config.ss58Format,
        ),
    type: EllipticCurveTypes.secp256k1,
    chainType: ChainType.mainnet,
  );
  final SubstrateCoinConf kusamaSr25519 = SubstrateCoinConf.fromCoinConf(
    coinConf: CoinsConf.kusama,
    addressEncode:
        (params, config) => SubstrateSr25519AddrEncoder().encodeKey(
          params.pubKey,
          ss58Format: params.ss58Format ?? config.ss58Format,
        ),
    type: EllipticCurveTypes.sr25519,
    chainType: ChainType.mainnet,
  );

  // Configuration for Moonbeam
  final SubstrateCoinConf moonbeamEd25519 = SubstrateCoinConf.fromCoinConf(
    coinConf: CoinsConf.moonbeam,
    addressEncode:
        (params, config) => SubstrateEd25519AddrEncoder().encodeKey(
          params.pubKey,
          ss58Format: params.ss58Format ?? config.ss58Format,
        ),
    type: EllipticCurveTypes.ed25519,
    chainType: ChainType.mainnet,
  );
  final SubstrateCoinConf moonbeamSecp256k1 = SubstrateCoinConf.fromCoinConf(
    coinConf: CoinsConf.moonbeam,
    addressEncode:
        (params, config) => SubstrateSecp256k1AddrEncoder().encodeKey(
          params.pubKey,
          ss58Format: params.ss58Format ?? config.ss58Format,
        ),
    type: EllipticCurveTypes.secp256k1,
    chainType: ChainType.mainnet,
  );
  final SubstrateCoinConf moonbeamSr25519 = SubstrateCoinConf.fromCoinConf(
    coinConf: CoinsConf.moonbeam,
    addressEncode:
        (params, config) => SubstrateSr25519AddrEncoder().encodeKey(
          params.pubKey,
          ss58Format: params.ss58Format ?? config.ss58Format,
        ),
    type: EllipticCurveTypes.sr25519,
    chainType: ChainType.mainnet,
  );

  // Configuration for Moonriver
  final SubstrateCoinConf moonriverEd25519 = SubstrateCoinConf.fromCoinConf(
    coinConf: CoinsConf.moonriver,
    addressEncode:
        (params, config) => SubstrateEd25519AddrEncoder().encodeKey(
          params.pubKey,
          ss58Format: params.ss58Format ?? config.ss58Format,
        ),
    type: EllipticCurveTypes.ed25519,
    chainType: ChainType.mainnet,
  );
  final SubstrateCoinConf moonriverSecp256k1 = SubstrateCoinConf.fromCoinConf(
    coinConf: CoinsConf.moonriver,
    addressEncode:
        (params, config) => SubstrateSecp256k1AddrEncoder().encodeKey(
          params.pubKey,
          ss58Format: params.ss58Format ?? config.ss58Format,
        ),
    type: EllipticCurveTypes.secp256k1,
    chainType: ChainType.mainnet,
  );
  final SubstrateCoinConf moonriverSr25519 = SubstrateCoinConf.fromCoinConf(
    coinConf: CoinsConf.moonriver,
    addressEncode:
        (params, config) => SubstrateSr25519AddrEncoder().encodeKey(
          params.pubKey,
          ss58Format: params.ss58Format ?? config.ss58Format,
        ),
    type: EllipticCurveTypes.sr25519,
    chainType: ChainType.mainnet,
  );

  // Configuration for Phala
  final SubstrateCoinConf phalaEd25519 = SubstrateCoinConf.fromCoinConf(
    coinConf: CoinsConf.phala,
    addressEncode:
        (params, config) => SubstrateEd25519AddrEncoder().encodeKey(
          params.pubKey,
          ss58Format: params.ss58Format ?? config.ss58Format,
        ),
    type: EllipticCurveTypes.ed25519,
    chainType: ChainType.mainnet,
  );
  final SubstrateCoinConf phalaSecp256k1 = SubstrateCoinConf.fromCoinConf(
    coinConf: CoinsConf.phala,
    addressEncode:
        (params, config) => SubstrateSecp256k1AddrEncoder().encodeKey(
          params.pubKey,
          ss58Format: params.ss58Format ?? config.ss58Format,
        ),
    type: EllipticCurveTypes.secp256k1,
    chainType: ChainType.mainnet,
  );
  final SubstrateCoinConf phalaSr25519 = SubstrateCoinConf.fromCoinConf(
    coinConf: CoinsConf.phala,
    addressEncode:
        (params, config) => SubstrateSr25519AddrEncoder().encodeKey(
          params.pubKey,
          ss58Format: params.ss58Format ?? config.ss58Format,
        ),
    type: EllipticCurveTypes.sr25519,
    chainType: ChainType.mainnet,
  );

  // Configuration for Plasm
  final SubstrateCoinConf plasmEd25519 = SubstrateCoinConf.fromCoinConf(
    coinConf: CoinsConf.plasm,
    addressEncode:
        (params, config) => SubstrateEd25519AddrEncoder().encodeKey(
          params.pubKey,
          ss58Format: params.ss58Format ?? config.ss58Format,
        ),
    type: EllipticCurveTypes.ed25519,
    chainType: ChainType.mainnet,
  );
  final SubstrateCoinConf plasmSecp256k1 = SubstrateCoinConf.fromCoinConf(
    coinConf: CoinsConf.plasm,
    addressEncode:
        (params, config) => SubstrateSecp256k1AddrEncoder().encodeKey(
          params.pubKey,
          ss58Format: params.ss58Format ?? config.ss58Format,
        ),
    type: EllipticCurveTypes.secp256k1,
    chainType: ChainType.mainnet,
  );
  final SubstrateCoinConf plasmSr25519 = SubstrateCoinConf.fromCoinConf(
    coinConf: CoinsConf.plasm,
    addressEncode:
        (params, config) => SubstrateSr25519AddrEncoder().encodeKey(
          params.pubKey,
          ss58Format: params.ss58Format ?? config.ss58Format,
        ),
    type: EllipticCurveTypes.sr25519,
    chainType: ChainType.mainnet,
  );

  // Configuration for Polkadot
  final SubstrateCoinConf polkadotEd25519 = SubstrateCoinConf.fromCoinConf(
    coinConf: CoinsConf.polkadot,
    addressEncode:
        (params, config) => SubstrateEd25519AddrEncoder().encodeKey(
          params.pubKey,
          ss58Format: params.ss58Format ?? config.ss58Format,
        ),
    type: EllipticCurveTypes.ed25519,
    chainType: ChainType.mainnet,
  );
  final SubstrateCoinConf polkadotSecp256k1 = SubstrateCoinConf.fromCoinConf(
    coinConf: CoinsConf.polkadot,
    addressEncode:
        (params, config) => SubstrateSecp256k1AddrEncoder().encodeKey(
          params.pubKey,
          ss58Format: params.ss58Format ?? config.ss58Format,
        ),
    type: EllipticCurveTypes.secp256k1,
    chainType: ChainType.mainnet,
  );
  final SubstrateCoinConf polkadotSr25519 = SubstrateCoinConf.fromCoinConf(
    coinConf: CoinsConf.polkadot,
    addressEncode:
        (params, config) => SubstrateSr25519AddrEncoder().encodeKey(
          params.pubKey,
          ss58Format: params.ss58Format ?? config.ss58Format,
        ),
    type: EllipticCurveTypes.sr25519,
    chainType: ChainType.mainnet,
  );

  // Configuration for Sora
  final SubstrateCoinConf soraEd25519 = SubstrateCoinConf.fromCoinConf(
    coinConf: CoinsConf.sora,
    addressEncode:
        (params, config) => SubstrateEd25519AddrEncoder().encodeKey(
          params.pubKey,
          ss58Format: params.ss58Format ?? config.ss58Format,
        ),
    type: EllipticCurveTypes.ed25519,
    chainType: ChainType.mainnet,
  );
  final SubstrateCoinConf soraSecp256k1 = SubstrateCoinConf.fromCoinConf(
    coinConf: CoinsConf.sora,
    addressEncode:
        (params, config) => SubstrateSecp256k1AddrEncoder().encodeKey(
          params.pubKey,
          ss58Format: params.ss58Format ?? config.ss58Format,
        ),
    type: EllipticCurveTypes.secp256k1,
    chainType: ChainType.mainnet,
  );
  final SubstrateCoinConf soraSr25519 = SubstrateCoinConf.fromCoinConf(
    coinConf: CoinsConf.sora,
    addressEncode:
        (params, config) => SubstrateSr25519AddrEncoder().encodeKey(
          params.pubKey,
          ss58Format: params.ss58Format ?? config.ss58Format,
        ),
    type: EllipticCurveTypes.sr25519,
    chainType: ChainType.mainnet,
  );

  // Configuration for Stafi
  final SubstrateCoinConf stafiEd25519 = SubstrateCoinConf.fromCoinConf(
    coinConf: CoinsConf.stafi,
    addressEncode:
        (params, config) => SubstrateEd25519AddrEncoder().encodeKey(
          params.pubKey,
          ss58Format: params.ss58Format ?? config.ss58Format,
        ),
    type: EllipticCurveTypes.ed25519,
    chainType: ChainType.mainnet,
  );
  final SubstrateCoinConf stafiSecp256k1 = SubstrateCoinConf.fromCoinConf(
    coinConf: CoinsConf.stafi,
    addressEncode:
        (params, config) => SubstrateSecp256k1AddrEncoder().encodeKey(
          params.pubKey,
          ss58Format: params.ss58Format ?? config.ss58Format,
        ),
    type: EllipticCurveTypes.secp256k1,
    chainType: ChainType.mainnet,
  );
  final SubstrateCoinConf stafiSr25519 = SubstrateCoinConf.fromCoinConf(
    coinConf: CoinsConf.stafi,
    addressEncode:
        (params, config) => SubstrateSr25519AddrEncoder().encodeKey(
          params.pubKey,
          ss58Format: params.ss58Format ?? config.ss58Format,
        ),
    type: EllipticCurveTypes.sr25519,
    chainType: ChainType.mainnet,
  );
}
