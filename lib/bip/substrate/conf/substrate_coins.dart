import 'package:blockchain_utils/bip/bip/conf/core/coins.dart';
import 'package:blockchain_utils/bip/substrate/conf/substrate_coin_conf.dart';

import 'substrate_conf.dart';

/// An enumeration of supported cryptocurrencies for SubstrateCoins.
class SubstrateCoins implements CryptoCoins<SubstrateCoinConf> {
  static const SubstrateCoins acalaEd25519 = SubstrateCoins._('acalaEd25519');
  static const SubstrateCoins acalaSecp256k1 =
      SubstrateCoins._('acalaSecp256k1');
  static const SubstrateCoins acalaSr25519 = SubstrateCoins._('acalaSr25519');

  // Configuration for Bifrost
  static const SubstrateCoins bifrostEd25519 =
      SubstrateCoins._('bifrostEd25519');
  static const SubstrateCoins bifrostSecp256k1 =
      SubstrateCoins._('bifrostSecp256k1');
  static const SubstrateCoins bifrostSr25519 =
      SubstrateCoins._('bifrostSr25519');

// Configuration for ChainX
  static const SubstrateCoins chainxEd25519 = SubstrateCoins._('chainxEd25519');
  static const SubstrateCoins chainxSecp256k1 =
      SubstrateCoins._('chainxSecp256k1');
  static const SubstrateCoins chainxSr25519 = SubstrateCoins._('chainxSr25519');

// Configuration for Edgeware
  static const SubstrateCoins edgewareEd25519 =
      SubstrateCoins._('edgewareEd25519');
  static const SubstrateCoins edgewareSecp256k1 =
      SubstrateCoins._('edgewareSecp256k1');
  static const SubstrateCoins edgewareSr25519 =
      SubstrateCoins._('edgewareSr25519');

// Configuration for generic Substrate coin
  static const SubstrateCoins genericEd25519 =
      SubstrateCoins._('genericEd25519');
  static const SubstrateCoins genericSecp256k1 =
      SubstrateCoins._('genericSecp256k1');
  static const SubstrateCoins genericSr25519 =
      SubstrateCoins._('genericSr25519');

// Configuration for Karura
  static const SubstrateCoins karuraEd25519 = SubstrateCoins._('karuraEd25519');
  static const SubstrateCoins karuraSecp256k1 =
      SubstrateCoins._('karuraSecp256k1');
  static const SubstrateCoins karuraSr25519 = SubstrateCoins._('karuraSr25519');

// Configuration for Kusama
  static const SubstrateCoins kusamaEd25519 = SubstrateCoins._('kusamaEd25519');
  static const SubstrateCoins kusamaSecp256k1 =
      SubstrateCoins._('kusamaSecp256k1');
  static const SubstrateCoins kusamaSr25519 = SubstrateCoins._('kusamaSr25519');

// Configuration for Moonbeam
  static const SubstrateCoins moonbeamEd25519 =
      SubstrateCoins._('moonbeamEd25519');
  static const SubstrateCoins moonbeamSecp256k1 =
      SubstrateCoins._('moonbeamSecp256k1');
  static const SubstrateCoins moonbeamSr25519 =
      SubstrateCoins._('moonbeamSr25519');

// Configuration for Moonriver
  static const SubstrateCoins moonriverEd25519 =
      SubstrateCoins._('moonriverEd25519');
  static const SubstrateCoins moonriverSecp256k1 =
      SubstrateCoins._('moonriverSecp256k1');
  static const SubstrateCoins moonriverSr25519 =
      SubstrateCoins._('moonriverSr25519');

// Configuration for Phala
  static const SubstrateCoins phalaEd25519 = SubstrateCoins._('phalaEd25519');
  static const SubstrateCoins phalaSecp256k1 =
      SubstrateCoins._('phalaSecp256k1');
  static const SubstrateCoins phalaSr25519 = SubstrateCoins._('phalaSr25519');

// Configuration for Plasm
  static const SubstrateCoins plasmEd25519 = SubstrateCoins._('plasmEd25519');
  static const SubstrateCoins plasmSecp256k1 =
      SubstrateCoins._('plasmSecp256k1');
  static const SubstrateCoins plasmSr25519 = SubstrateCoins._('plasmSr25519');

// Configuration for Polkadot
  static const SubstrateCoins polkadotEd25519 =
      SubstrateCoins._('polkadotEd25519');
  static const SubstrateCoins polkadotSecp256k1 =
      SubstrateCoins._('polkadotSecp256k1');
  static const SubstrateCoins polkadotSr25519 =
      SubstrateCoins._('polkadotSr25519');

// Configuration for Sora
  static const SubstrateCoins soraEd25519 = SubstrateCoins._('soraEd25519');
  static const SubstrateCoins soraSecp256k1 = SubstrateCoins._('soraSecp256k1');
  static const SubstrateCoins soraSr25519 = SubstrateCoins._('soraSr25519');

// Configuration for Stafi
  static const SubstrateCoins stafiEd25519 = SubstrateCoins._('stafiEd25519');
  static const SubstrateCoins stafiSecp256k1 =
      SubstrateCoins._('stafiSecp256k1');
  static const SubstrateCoins stafiSr25519 = SubstrateCoins._('stafiSr25519');

  final String name;

  const SubstrateCoins._(this.name);

  @override
  SubstrateCoins get value => this;

  @override
  String get coinName {
    return name;
  }

  @override
  SubstrateCoinConf get conf => _coinToConf[this]!;
  @override
  CoinProposal get proposal => SubstratePropoosal.substrate;

  static SubstrateCoins? fromName(String name) {
    try {
      return values.firstWhere((element) => element.name == name);
    } on StateError {
      return null;
    }
  }

  static const List<SubstrateCoins> values = [
    SubstrateCoins.acalaEd25519,
    SubstrateCoins.acalaSecp256k1,
    SubstrateCoins.acalaSr25519,
    SubstrateCoins.bifrostEd25519,
    SubstrateCoins.bifrostSecp256k1,
    SubstrateCoins.bifrostSr25519,
    SubstrateCoins.chainxEd25519,
    SubstrateCoins.chainxSecp256k1,
    SubstrateCoins.chainxSr25519,
    SubstrateCoins.edgewareEd25519,
    SubstrateCoins.edgewareSecp256k1,
    SubstrateCoins.edgewareSr25519,
    SubstrateCoins.genericEd25519,
    SubstrateCoins.genericSecp256k1,
    SubstrateCoins.genericSr25519,
    SubstrateCoins.karuraEd25519,
    SubstrateCoins.karuraSecp256k1,
    SubstrateCoins.karuraSr25519,
    SubstrateCoins.kusamaEd25519,
    SubstrateCoins.kusamaSecp256k1,
    SubstrateCoins.kusamaSr25519,
    SubstrateCoins.moonbeamEd25519,
    SubstrateCoins.moonbeamSecp256k1,
    SubstrateCoins.moonbeamSr25519,
    SubstrateCoins.moonriverEd25519,
    SubstrateCoins.moonriverSecp256k1,
    SubstrateCoins.moonriverSr25519,
    SubstrateCoins.phalaEd25519,
    SubstrateCoins.phalaSecp256k1,
    SubstrateCoins.phalaSr25519,
    SubstrateCoins.plasmEd25519,
    SubstrateCoins.plasmSecp256k1,
    SubstrateCoins.plasmSr25519,
    SubstrateCoins.polkadotEd25519,
    SubstrateCoins.polkadotSecp256k1,
    SubstrateCoins.polkadotSr25519,
    SubstrateCoins.soraEd25519,
    SubstrateCoins.soraSecp256k1,
    SubstrateCoins.soraSr25519,
    SubstrateCoins.stafiEd25519,
    SubstrateCoins.stafiSecp256k1,
    SubstrateCoins.stafiSr25519
  ];

  /// A mapping that associates each SubstrateCoins (enum) with its corresponding
  /// SubstrateCoinConf configuration.
  static final Map<SubstrateCoins, SubstrateCoinConf> _coinToConf = {
    SubstrateCoins.acalaEd25519: SubstrateConf.acalaEd25519,
    SubstrateCoins.acalaSecp256k1: SubstrateConf.acalaSecp256k1,
    SubstrateCoins.acalaSr25519: SubstrateConf.acalaSr25519,
    SubstrateCoins.bifrostEd25519: SubstrateConf.bifrostEd25519,
    SubstrateCoins.bifrostSecp256k1: SubstrateConf.bifrostSecp256k1,
    SubstrateCoins.bifrostSr25519: SubstrateConf.bifrostSr25519,
    SubstrateCoins.chainxEd25519: SubstrateConf.chainXEd25519,
    SubstrateCoins.chainxSecp256k1: SubstrateConf.chainXSecp256k1,
    SubstrateCoins.chainxSr25519: SubstrateConf.chainXSr25519,
    SubstrateCoins.edgewareEd25519: SubstrateConf.edgewareEd25519,
    SubstrateCoins.edgewareSecp256k1: SubstrateConf.edgewareSecp256k1,
    SubstrateCoins.edgewareSr25519: SubstrateConf.edgewareSr25519,
    SubstrateCoins.genericEd25519: SubstrateConf.genericEd25519,
    SubstrateCoins.genericSecp256k1: SubstrateConf.genericSecp256k1,
    SubstrateCoins.genericSr25519: SubstrateConf.genericSr25519,
    SubstrateCoins.karuraEd25519: SubstrateConf.karuraEd25519,
    SubstrateCoins.karuraSecp256k1: SubstrateConf.karuraSecp256k1,
    SubstrateCoins.karuraSr25519: SubstrateConf.karuraSr25519,
    SubstrateCoins.kusamaEd25519: SubstrateConf.kusamaEd25519,
    SubstrateCoins.kusamaSecp256k1: SubstrateConf.kusamaSecp256k1,
    SubstrateCoins.kusamaSr25519: SubstrateConf.kusamaSr25519,
    SubstrateCoins.moonbeamEd25519: SubstrateConf.moonbeamEd25519,
    SubstrateCoins.moonbeamSecp256k1: SubstrateConf.moonbeamSecp256k1,
    SubstrateCoins.moonbeamSr25519: SubstrateConf.moonbeamSr25519,
    SubstrateCoins.moonriverEd25519: SubstrateConf.moonriverEd25519,
    SubstrateCoins.moonriverSecp256k1: SubstrateConf.moonriverSecp256k1,
    SubstrateCoins.moonriverSr25519: SubstrateConf.moonriverSr25519,
    SubstrateCoins.phalaEd25519: SubstrateConf.phalaEd25519,
    SubstrateCoins.phalaSecp256k1: SubstrateConf.phalaSecp256k1,
    SubstrateCoins.phalaSr25519: SubstrateConf.phalaSr25519,
    SubstrateCoins.plasmEd25519: SubstrateConf.plasmEd25519,
    SubstrateCoins.plasmSecp256k1: SubstrateConf.plasmSecp256k1,
    SubstrateCoins.plasmSr25519: SubstrateConf.plasmSr25519,
    SubstrateCoins.polkadotEd25519: SubstrateConf.polkadotEd25519,
    SubstrateCoins.polkadotSecp256k1: SubstrateConf.polkadotSecp256k1,
    SubstrateCoins.polkadotSr25519: SubstrateConf.polkadotSr25519,
    SubstrateCoins.soraEd25519: SubstrateConf.soraEd25519,
    SubstrateCoins.soraSecp256k1: SubstrateConf.soraSecp256k1,
    SubstrateCoins.soraSr25519: SubstrateConf.soraSr25519,
    SubstrateCoins.stafiEd25519: SubstrateConf.stafiEd25519,
    SubstrateCoins.stafiSecp256k1: SubstrateConf.stafiSecp256k1,
    SubstrateCoins.stafiSr25519: SubstrateConf.stafiSr25519
  };
  @override
  bool get isBipCoin => false;
}

class SubstratePropoosal implements CoinProposal {
  static const SubstratePropoosal substrate = SubstratePropoosal._('substrate');

  const SubstratePropoosal._(this.name);
  final String name;

  @override
  String get specName => name;
  @override
  CoinProposal get value => this;

  static const List<SubstratePropoosal> values = [substrate];
}
