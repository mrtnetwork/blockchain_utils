import 'package:blockchain_utils/bip/bip/conf/bip/bip_coins.dart';
import 'package:blockchain_utils/bip/bip/conf/bip49/bip49_conf.dart';
import 'package:blockchain_utils/bip/bip/conf/config/bip_coin_conf.dart';
import 'package:blockchain_utils/bip/bip/conf/core/coins.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';

/// An enumeration of supported cryptocurrencies for BIP49. It includes both main
/// networks and test networks of various cryptocurrencies.
enum Bip49Coins implements BipCoins {
  // Mainnets
  bitcoin('bitcoin'),
  bitcoinCash('bitcoinCash'),
  bitcoinCashSlp('bitcoinCashSlp'),
  bitcoinSv('bitcoinSv'),
  dash('dash'),
  dogecoin('dogecoin'),
  ecash('ecash'),
  litecoin('litecoin'),
  zcash('zcash'),
  pepecoin('pepecoin'),
  electraProtocol('electraProtocol'),

  // Testnets
  bitcoinCashTestnet('bitcoinCashTestnet'),
  bitcoinCashSlpTestnet('bitcoinCashSlpTestnet'),
  bitcoinSvTestnet('bitcoinSvTestnet'),
  bitcoinTestnet('bitcoinTestnet'),
  dashTestnet('dashTestnet'),
  dogecoinTestnet('dogecoinTestnet'),
  ecashTestnet('ecashTestnet'),
  litecoinTestnet('litecoinTestnet'),
  zcashTestnet('zcashTestnet'),
  pepecoinTestnet('pepecoinTestnet'),
  electraProtocolTestnet('electraProtocolTestnet');

  final String name;

  const Bip49Coins(this.name);

  @override
  Bip49Coins get value => this;

  @override
  String get coinName => name;

  @override
  BaseBipCoinConfig get conf {
    final config = Bip49Conf();
    return switch (this) {
      bitcoin => config.bitcoinMainNet,
      bitcoinTestnet => config.bitcoinTestNet,
      bitcoinCash => config.bitcoinCashMainNet,
      bitcoinCashTestnet => config.bitcoinCashTestNet,
      bitcoinCashSlp => config.bitcoinCashSlpMainNet,
      bitcoinCashSlpTestnet => config.bitcoinCashSlpTestNet,
      bitcoinSv => config.bitcoinSvMainNet,
      bitcoinSvTestnet => config.bitcoinSvTestNet,
      dash => config.dashMainNet,
      dashTestnet => config.dashTestNet,
      dogecoin => config.dogecoinMainNet,
      dogecoinTestnet => config.dogecoinTestNet,
      ecash => config.ecashMainNet,
      ecashTestnet => config.ecashTestNet,
      litecoin => config.litecoinMainNet,
      litecoinTestnet => config.litecoinTestNet,
      zcash => config.zcashMainNet,
      zcashTestnet => config.zcashTestNet,
      pepecoin => config.pepeMainnet,
      pepecoinTestnet => config.pepeTestnet,
      electraProtocol => config.electraProtocolMainNet,
      electraProtocolTestnet => config.electraProtocolTestNet,
    };
  }

  static Bip49Coins? fromName(String name) {
    return values.firstWhereNullable((element) => element.name == name);
  }

  @override
  CoinProposal get proposal => CoinProposal.bip49;
}
