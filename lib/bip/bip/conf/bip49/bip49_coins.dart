import 'package:blockchain_utils/bip/bip/conf/bip/bip_coins.dart';
import 'package:blockchain_utils/bip/bip/conf/bip49/bip49_conf.dart';
import 'package:blockchain_utils/bip/bip/conf/config/bip_coin_conf.dart';
import 'package:blockchain_utils/bip/bip/conf/core/coins.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';

/// An enumeration of supported cryptocurrencies for BIP49. It includes both main
/// networks and test networks of various cryptocurrencies.
enum Bip49Coins implements BipCoins {
  // Mainnets
  bitcoin('bitcoin', 201),
  bitcoinCash('bitcoinCash', 202),
  bitcoinCashSlp('bitcoinCashSlp', 203),
  bitcoinSv('bitcoinSv', 204),
  dash('dash', 205),
  dogecoin('dogecoin', 206),
  ecash('ecash', 207),
  litecoin('litecoin', 208),
  zcash('zcash', 209),
  pepecoin('pepecoin', 210),
  electraProtocol('electraProtocol', 211),

  // Testnets
  bitcoinCashTestnet('bitcoinCashTestnet', 212),
  bitcoinCashSlpTestnet('bitcoinCashSlpTestnet', 213),
  bitcoinSvTestnet('bitcoinSvTestnet', 214),
  bitcoinTestnet('bitcoinTestnet', 215),
  dashTestnet('dashTestnet', 216),
  dogecoinTestnet('dogecoinTestnet', 217),
  ecashTestnet('ecashTestnet', 218),
  litecoinTestnet('litecoinTestnet', 219),
  zcashTestnet('zcashTestnet', 220),
  zcashRegtest('zcashRegtest', 221),
  pepecoinTestnet('pepecoinTestnet', 222),
  electraProtocolTestnet('electraProtocolTestnet', 223);

  final String name;

  @override
  final int identifier;

  const Bip49Coins(this.name, this.identifier);

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
      zcashRegtest => config.zcashRegtest,
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
