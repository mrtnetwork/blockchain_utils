import 'package:blockchain_utils/bip/bip/conf/bip_coin_conf.dart';
import 'package:blockchain_utils/bip/bip/conf/bip_coins.dart';

/// An enumeration of supported cryptocurrencies for SubstrateCoins.
enum SubstrateCoins implements CryptoCoins {
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

  String get coinName {
    return this.name;
  }

  CoinConfig get conf => throw UnimplementedError();
  BipProposal get proposal => throw UnimplementedError();
}
