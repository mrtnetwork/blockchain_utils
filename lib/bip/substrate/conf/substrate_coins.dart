import 'package:blockchain_utils/bip/bip/conf/bip_coin_conf.dart';
import 'package:blockchain_utils/bip/bip/conf/bip_coins.dart';

/// An enumeration of supported cryptocurrencies for SubstrateCoins.
class SubstrateCoins implements CryptoCoins {
  static const SubstrateCoins acala = SubstrateCoins._('acala');
  static const SubstrateCoins bifrost = SubstrateCoins._('bifrost');
  static const SubstrateCoins chainx = SubstrateCoins._('chainx');
  static const SubstrateCoins edgeware = SubstrateCoins._('edgeware');
  static const SubstrateCoins generic = SubstrateCoins._('generic');
  static const SubstrateCoins karura = SubstrateCoins._('karura');
  static const SubstrateCoins kusama = SubstrateCoins._('kusama');
  static const SubstrateCoins moonbeam = SubstrateCoins._('moonbeam');
  static const SubstrateCoins moonriver = SubstrateCoins._('moonriver');
  static const SubstrateCoins phala = SubstrateCoins._('phala');
  static const SubstrateCoins plasm = SubstrateCoins._('plasm');
  static const SubstrateCoins polkadot = SubstrateCoins._('polkadot');
  static const SubstrateCoins sora = SubstrateCoins._('sora');
  static const SubstrateCoins stafi = SubstrateCoins._('stafi');

  final String name;

  const SubstrateCoins._(this.name);

  @override
  SubstrateCoins get value => this;

  @override
  String get coinName {
    return name;
  }

  @override
  CoinConfig get conf => throw UnimplementedError();
  @override
  BipProposal get proposal => throw UnimplementedError();

  static const List<SubstrateCoins> values = [
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
    stafi,
  ];
}
