import 'package:blockchain_utils/bip/address/substrate_addr.dart';
import 'package:blockchain_utils/bip/coin_conf/coins_conf.dart';
import 'package:blockchain_utils/bip/ecc/curve/elliptic_curve_types.dart';
import 'substrate_coin_conf.dart';

/// A configuration class for Substrate coins that defines the key network versions and
/// maps each supported SubstrateCoins to its corresponding SubstrateConf.
class SubstrateConf {
  static final SubstrateCoinConf acalaEd25519 = SubstrateCoinConf.fromCoinConf(
      coinConf: CoinsConf.acala,
      addressEncode: ([kwargs]) => SubstrateEd25519AddrEncoder(),
      type: EllipticCurveTypes.ed25519);
  // Configuration for Acala
  static final SubstrateCoinConf acalaSecp256k1 =
      SubstrateCoinConf.fromCoinConf(
          coinConf: CoinsConf.acala,
          addressEncode: ([kwargs]) => SubstrateSecp256k1AddrEncoder(),
          type: EllipticCurveTypes.secp256k1);

  static final SubstrateCoinConf acalaSr25519 = SubstrateCoinConf.fromCoinConf(
      coinConf: CoinsConf.acala,
      addressEncode: ([kwargs]) => SubstrateSr25519AddrEncoder(),
      type: EllipticCurveTypes.sr25519);

  // Configuration for Bifrost
  static final SubstrateCoinConf bifrostEd25519 =
      SubstrateCoinConf.fromCoinConf(
          coinConf: CoinsConf.bifrost,
          addressEncode: ([kwargs]) => SubstrateEd25519AddrEncoder(),
          type: EllipticCurveTypes.ed25519);
  static final SubstrateCoinConf bifrostSecp256k1 =
      SubstrateCoinConf.fromCoinConf(
          coinConf: CoinsConf.bifrost,
          addressEncode: ([kwargs]) => SubstrateSecp256k1AddrEncoder(),
          type: EllipticCurveTypes.secp256k1);
  static final SubstrateCoinConf bifrostSr25519 =
      SubstrateCoinConf.fromCoinConf(
          coinConf: CoinsConf.bifrost,
          addressEncode: ([kwargs]) => SubstrateSr25519AddrEncoder(),
          type: EllipticCurveTypes.sr25519);

// Configuration for ChainX
  static final SubstrateCoinConf chainXEd25519 = SubstrateCoinConf.fromCoinConf(
      coinConf: CoinsConf.chainX,
      addressEncode: ([kwargs]) => SubstrateEd25519AddrEncoder(),
      type: EllipticCurveTypes.ed25519);
  static final SubstrateCoinConf chainXSecp256k1 =
      SubstrateCoinConf.fromCoinConf(
          coinConf: CoinsConf.chainX,
          addressEncode: ([kwargs]) => SubstrateSecp256k1AddrEncoder(),
          type: EllipticCurveTypes.secp256k1);
  static final SubstrateCoinConf chainXSr25519 = SubstrateCoinConf.fromCoinConf(
      coinConf: CoinsConf.chainX,
      addressEncode: ([kwargs]) => SubstrateSr25519AddrEncoder(),
      type: EllipticCurveTypes.sr25519);

// Configuration for Edgeware
  static final SubstrateCoinConf edgewareEd25519 =
      SubstrateCoinConf.fromCoinConf(
          coinConf: CoinsConf.edgeware,
          addressEncode: ([kwargs]) => SubstrateEd25519AddrEncoder(),
          type: EllipticCurveTypes.ed25519);
  static final SubstrateCoinConf edgewareSecp256k1 =
      SubstrateCoinConf.fromCoinConf(
          coinConf: CoinsConf.edgeware,
          addressEncode: ([kwargs]) => SubstrateSecp256k1AddrEncoder(),
          type: EllipticCurveTypes.secp256k1);
  static final SubstrateCoinConf edgewareSr25519 =
      SubstrateCoinConf.fromCoinConf(
          coinConf: CoinsConf.edgeware,
          addressEncode: ([kwargs]) => SubstrateSr25519AddrEncoder(),
          type: EllipticCurveTypes.sr25519);

// Configuration for generic Substrate coin
  static final SubstrateCoinConf genericEd25519 =
      SubstrateCoinConf.fromCoinConf(
          coinConf: CoinsConf.genericSubstrate,
          addressEncode: ([kwargs]) => SubstrateEd25519AddrEncoder(),
          type: EllipticCurveTypes.ed25519);
  static final SubstrateCoinConf genericSecp256k1 =
      SubstrateCoinConf.fromCoinConf(
          coinConf: CoinsConf.genericSubstrate,
          addressEncode: ([kwargs]) => SubstrateSecp256k1AddrEncoder(),
          type: EllipticCurveTypes.secp256k1);
  static final SubstrateCoinConf genericSr25519 =
      SubstrateCoinConf.fromCoinConf(
          coinConf: CoinsConf.genericSubstrate,
          addressEncode: ([kwargs]) => SubstrateSr25519AddrEncoder(),
          type: EllipticCurveTypes.sr25519);

// Configuration for Karura
  static final SubstrateCoinConf karuraEd25519 = SubstrateCoinConf.fromCoinConf(
      coinConf: CoinsConf.karura,
      addressEncode: ([kwargs]) => SubstrateEd25519AddrEncoder(),
      type: EllipticCurveTypes.ed25519);
  static final SubstrateCoinConf karuraSecp256k1 =
      SubstrateCoinConf.fromCoinConf(
          coinConf: CoinsConf.karura,
          addressEncode: ([kwargs]) => SubstrateSecp256k1AddrEncoder(),
          type: EllipticCurveTypes.secp256k1);
  static final SubstrateCoinConf karuraSr25519 = SubstrateCoinConf.fromCoinConf(
      coinConf: CoinsConf.karura,
      addressEncode: ([kwargs]) => SubstrateSr25519AddrEncoder(),
      type: EllipticCurveTypes.sr25519);

// Configuration for Kusama
  static final SubstrateCoinConf kusamaEd25519 = SubstrateCoinConf.fromCoinConf(
      coinConf: CoinsConf.kusama,
      addressEncode: ([kwargs]) => SubstrateEd25519AddrEncoder(),
      type: EllipticCurveTypes.ed25519);
  static final SubstrateCoinConf kusamaSecp256k1 =
      SubstrateCoinConf.fromCoinConf(
          coinConf: CoinsConf.kusama,
          addressEncode: ([kwargs]) => SubstrateSecp256k1AddrEncoder(),
          type: EllipticCurveTypes.secp256k1);
  static final SubstrateCoinConf kusamaSr25519 = SubstrateCoinConf.fromCoinConf(
      coinConf: CoinsConf.kusama,
      addressEncode: ([kwargs]) => SubstrateSr25519AddrEncoder(),
      type: EllipticCurveTypes.sr25519);

// Configuration for Moonbeam
  static final SubstrateCoinConf moonbeamEd25519 =
      SubstrateCoinConf.fromCoinConf(
          coinConf: CoinsConf.moonbeam,
          addressEncode: ([kwargs]) => SubstrateEd25519AddrEncoder(),
          type: EllipticCurveTypes.ed25519);
  static final SubstrateCoinConf moonbeamSecp256k1 =
      SubstrateCoinConf.fromCoinConf(
          coinConf: CoinsConf.moonbeam,
          addressEncode: ([kwargs]) => SubstrateSecp256k1AddrEncoder(),
          type: EllipticCurveTypes.secp256k1);
  static final SubstrateCoinConf moonbeamSr25519 =
      SubstrateCoinConf.fromCoinConf(
          coinConf: CoinsConf.moonbeam,
          addressEncode: ([kwargs]) => SubstrateSr25519AddrEncoder(),
          type: EllipticCurveTypes.sr25519);

// Configuration for Moonriver
  static final SubstrateCoinConf moonriverEd25519 =
      SubstrateCoinConf.fromCoinConf(
          coinConf: CoinsConf.moonriver,
          addressEncode: ([kwargs]) => SubstrateEd25519AddrEncoder(),
          type: EllipticCurveTypes.ed25519);
  static final SubstrateCoinConf moonriverSecp256k1 =
      SubstrateCoinConf.fromCoinConf(
          coinConf: CoinsConf.moonriver,
          addressEncode: ([kwargs]) => SubstrateSecp256k1AddrEncoder(),
          type: EllipticCurveTypes.secp256k1);
  static final SubstrateCoinConf moonriverSr25519 =
      SubstrateCoinConf.fromCoinConf(
          coinConf: CoinsConf.moonriver,
          addressEncode: ([kwargs]) => SubstrateSr25519AddrEncoder(),
          type: EllipticCurveTypes.sr25519);

// Configuration for Phala
  static final SubstrateCoinConf phalaEd25519 = SubstrateCoinConf.fromCoinConf(
      coinConf: CoinsConf.phala,
      addressEncode: ([kwargs]) => SubstrateEd25519AddrEncoder(),
      type: EllipticCurveTypes.ed25519);
  static final SubstrateCoinConf phalaSecp256k1 =
      SubstrateCoinConf.fromCoinConf(
          coinConf: CoinsConf.phala,
          addressEncode: ([kwargs]) => SubstrateSecp256k1AddrEncoder(),
          type: EllipticCurveTypes.secp256k1);
  static final SubstrateCoinConf phalaSr25519 = SubstrateCoinConf.fromCoinConf(
      coinConf: CoinsConf.phala,
      addressEncode: ([kwargs]) => SubstrateSr25519AddrEncoder(),
      type: EllipticCurveTypes.sr25519);

// Configuration for Plasm
  static final SubstrateCoinConf plasmEd25519 = SubstrateCoinConf.fromCoinConf(
      coinConf: CoinsConf.plasm,
      addressEncode: ([kwargs]) => SubstrateEd25519AddrEncoder(),
      type: EllipticCurveTypes.ed25519);
  static final SubstrateCoinConf plasmSecp256k1 =
      SubstrateCoinConf.fromCoinConf(
          coinConf: CoinsConf.plasm,
          addressEncode: ([kwargs]) => SubstrateSecp256k1AddrEncoder(),
          type: EllipticCurveTypes.secp256k1);
  static final SubstrateCoinConf plasmSr25519 = SubstrateCoinConf.fromCoinConf(
      coinConf: CoinsConf.plasm,
      addressEncode: ([kwargs]) => SubstrateSr25519AddrEncoder(),
      type: EllipticCurveTypes.sr25519);

// Configuration for Polkadot
  static final SubstrateCoinConf polkadotEd25519 =
      SubstrateCoinConf.fromCoinConf(
          coinConf: CoinsConf.polkadot,
          addressEncode: ([kwargs]) => SubstrateEd25519AddrEncoder(),
          type: EllipticCurveTypes.ed25519);
  static final SubstrateCoinConf polkadotSecp256k1 =
      SubstrateCoinConf.fromCoinConf(
          coinConf: CoinsConf.polkadot,
          addressEncode: ([kwargs]) => SubstrateSecp256k1AddrEncoder(),
          type: EllipticCurveTypes.secp256k1);
  static final SubstrateCoinConf polkadotSr25519 =
      SubstrateCoinConf.fromCoinConf(
          coinConf: CoinsConf.polkadot,
          addressEncode: ([kwargs]) => SubstrateSr25519AddrEncoder(),
          type: EllipticCurveTypes.sr25519);

// Configuration for Sora
  static final SubstrateCoinConf soraEd25519 = SubstrateCoinConf.fromCoinConf(
      coinConf: CoinsConf.sora,
      addressEncode: ([kwargs]) => SubstrateEd25519AddrEncoder(),
      type: EllipticCurveTypes.ed25519);
  static final SubstrateCoinConf soraSecp256k1 = SubstrateCoinConf.fromCoinConf(
      coinConf: CoinsConf.sora,
      addressEncode: ([kwargs]) => SubstrateSecp256k1AddrEncoder(),
      type: EllipticCurveTypes.secp256k1);
  static final SubstrateCoinConf soraSr25519 = SubstrateCoinConf.fromCoinConf(
      coinConf: CoinsConf.sora,
      addressEncode: ([kwargs]) => SubstrateSr25519AddrEncoder(),
      type: EllipticCurveTypes.sr25519);

// Configuration for Stafi
  static final SubstrateCoinConf stafiEd25519 = SubstrateCoinConf.fromCoinConf(
      coinConf: CoinsConf.stafi,
      addressEncode: ([kwargs]) => SubstrateEd25519AddrEncoder(),
      type: EllipticCurveTypes.ed25519);
  static final SubstrateCoinConf stafiSecp256k1 =
      SubstrateCoinConf.fromCoinConf(
          coinConf: CoinsConf.stafi,
          addressEncode: ([kwargs]) => SubstrateSecp256k1AddrEncoder(),
          type: EllipticCurveTypes.secp256k1);
  static final SubstrateCoinConf stafiSr25519 = SubstrateCoinConf.fromCoinConf(
      coinConf: CoinsConf.stafi,
      addressEncode: ([kwargs]) => SubstrateSr25519AddrEncoder(),
      type: EllipticCurveTypes.sr25519);
}
