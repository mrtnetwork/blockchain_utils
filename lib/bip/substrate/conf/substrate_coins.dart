import 'package:blockchain_utils/bip/bip/conf/bip_coins.dart';

/// An enumeration of supported cryptocurrencies for SubstrateCoins.
enum SubstrateCoins implements BipCoins {
  acala,
  bifrost,
  chainx,
  edgeware,
  generic,
  karura,
  kusama,
  moonbeam,
  moonriver,
  phala,
  plasm,
  polkadot,
  sora,
  stafi;

  @override
  SubstrateCoins get value => this;
}
