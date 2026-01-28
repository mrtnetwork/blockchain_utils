import 'package:blockchain_utils/bip/bip/conf/core/coins.dart';
import 'package:blockchain_utils/bip/substrate/conf/substrate_coin_conf.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';

import 'substrate_conf.dart';

enum SubstrateCoins implements CryptoCoins<SubstrateCoinConf> {
  // Acala
  acalaEd25519('acalaEd25519'),
  acalaSecp256k1('acalaSecp256k1'),
  acalaSr25519('acalaSr25519'),

  // Bifrost
  bifrostEd25519('bifrostEd25519'),
  bifrostSecp256k1('bifrostSecp256k1'),
  bifrostSr25519('bifrostSr25519'),

  // ChainX
  chainxEd25519('chainxEd25519'),
  chainxSecp256k1('chainxSecp256k1'),
  chainxSr25519('chainxSr25519'),

  // Edgeware
  edgewareEd25519('edgewareEd25519'),
  edgewareSecp256k1('edgewareSecp256k1'),
  edgewareSr25519('edgewareSr25519'),

  // Generic Substrate
  genericEd25519('genericEd25519'),
  genericSecp256k1('genericSecp256k1'),
  genericSr25519('genericSr25519'),

  // Karura
  karuraEd25519('karuraEd25519'),
  karuraSecp256k1('karuraSecp256k1'),
  karuraSr25519('karuraSr25519'),

  // Kusama
  kusamaEd25519('kusamaEd25519'),
  kusamaSecp256k1('kusamaSecp256k1'),
  kusamaSr25519('kusamaSr25519'),

  // Moonbeam
  moonbeamEd25519('moonbeamEd25519'),
  moonbeamSecp256k1('moonbeamSecp256k1'),
  moonbeamSr25519('moonbeamSr25519'),

  // Moonriver
  moonriverEd25519('moonriverEd25519'),
  moonriverSecp256k1('moonriverSecp256k1'),
  moonriverSr25519('moonriverSr25519'),

  // Phala
  phalaEd25519('phalaEd25519'),
  phalaSecp256k1('phalaSecp256k1'),
  phalaSr25519('phalaSr25519'),

  // Plasm (Astar)
  plasmEd25519('plasmEd25519'),
  plasmSecp256k1('plasmSecp256k1'),
  plasmSr25519('plasmSr25519'),

  // Polkadot
  polkadotEd25519('polkadotEd25519'),
  polkadotSecp256k1('polkadotSecp256k1'),
  polkadotSr25519('polkadotSr25519'),

  // Sora
  soraEd25519('soraEd25519'),
  soraSecp256k1('soraSecp256k1'),
  soraSr25519('soraSr25519'),

  // Stafi
  stafiEd25519('stafiEd25519'),
  stafiSecp256k1('stafiSecp256k1'),
  stafiSr25519('stafiSr25519');

  final String name;

  const SubstrateCoins(this.name);
  @override
  SubstrateCoins get value => this;

  @override
  String get coinName {
    return name;
  }

  @override
  SubstrateCoinConf get conf {
    final config = SubstrateConf();
    return switch (this) {
      SubstrateCoins.acalaEd25519 => config.acalaEd25519,
      SubstrateCoins.acalaSecp256k1 => config.acalaSecp256k1,
      SubstrateCoins.acalaSr25519 => config.acalaSr25519,
      SubstrateCoins.bifrostEd25519 => config.bifrostEd25519,
      SubstrateCoins.bifrostSecp256k1 => config.bifrostSecp256k1,
      SubstrateCoins.bifrostSr25519 => config.bifrostSr25519,
      SubstrateCoins.chainxEd25519 => config.chainXEd25519,
      SubstrateCoins.chainxSecp256k1 => config.chainXSecp256k1,
      SubstrateCoins.chainxSr25519 => config.chainXSr25519,
      SubstrateCoins.edgewareEd25519 => config.edgewareEd25519,
      SubstrateCoins.edgewareSecp256k1 => config.edgewareSecp256k1,
      SubstrateCoins.edgewareSr25519 => config.edgewareSr25519,
      SubstrateCoins.genericEd25519 => config.genericEd25519,
      SubstrateCoins.genericSecp256k1 => config.genericSecp256k1,
      SubstrateCoins.genericSr25519 => config.genericSr25519,
      SubstrateCoins.karuraEd25519 => config.karuraEd25519,
      SubstrateCoins.karuraSecp256k1 => config.karuraSecp256k1,
      SubstrateCoins.karuraSr25519 => config.karuraSr25519,
      SubstrateCoins.kusamaEd25519 => config.kusamaEd25519,
      SubstrateCoins.kusamaSecp256k1 => config.kusamaSecp256k1,
      SubstrateCoins.kusamaSr25519 => config.kusamaSr25519,
      SubstrateCoins.moonbeamEd25519 => config.moonbeamEd25519,
      SubstrateCoins.moonbeamSecp256k1 => config.moonbeamSecp256k1,
      SubstrateCoins.moonbeamSr25519 => config.moonbeamSr25519,
      SubstrateCoins.moonriverEd25519 => config.moonriverEd25519,
      SubstrateCoins.moonriverSecp256k1 => config.moonriverSecp256k1,
      SubstrateCoins.moonriverSr25519 => config.moonriverSr25519,
      SubstrateCoins.phalaEd25519 => config.phalaEd25519,
      SubstrateCoins.phalaSecp256k1 => config.phalaSecp256k1,
      SubstrateCoins.phalaSr25519 => config.phalaSr25519,
      SubstrateCoins.plasmEd25519 => config.plasmEd25519,
      SubstrateCoins.plasmSecp256k1 => config.plasmSecp256k1,
      SubstrateCoins.plasmSr25519 => config.plasmSr25519,
      SubstrateCoins.polkadotEd25519 => config.polkadotEd25519,
      SubstrateCoins.polkadotSecp256k1 => config.polkadotSecp256k1,
      SubstrateCoins.polkadotSr25519 => config.polkadotSr25519,
      SubstrateCoins.soraEd25519 => config.soraEd25519,
      SubstrateCoins.soraSecp256k1 => config.soraSecp256k1,
      SubstrateCoins.soraSr25519 => config.soraSr25519,
      SubstrateCoins.stafiEd25519 => config.stafiEd25519,
      SubstrateCoins.stafiSecp256k1 => config.stafiSecp256k1,
      SubstrateCoins.stafiSr25519 => config.stafiSr25519,
    };
  }

  @override
  CoinProposal get proposal => CoinProposal.substrate;

  static SubstrateCoins? fromName(String name) {
    return values.firstWhereNullable((element) => element.name == name);
  }
}
