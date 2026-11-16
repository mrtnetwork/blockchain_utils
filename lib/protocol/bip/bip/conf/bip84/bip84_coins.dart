import 'package:blockchain_utils/protocol/bip/bip/conf/bip/bip_coins.dart';
import 'package:blockchain_utils/protocol/bip/bip/conf/bip84/bip84_conf.dart';
import 'package:blockchain_utils/protocol/bip/bip/conf/config/bip_coin_conf.dart';
import 'package:blockchain_utils/protocol/bip/bip/conf/core/coins.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';

/// An enumeration of supported cryptocurrencies for BIP84. It includes both main
/// networks and test networks of various cryptocurrencies.
enum Bip84Coins implements BipCoins {
  // Mainnets
  bitcoin('bitcoin', 401),
  litecoin('litecoin', 402),
  electraProtocol('electraProtocol', 403),

  // Testnets
  bitcoinTestnet('bitcoinTestnet', 404),
  litecoinTestnet('litecoinTestnet', 405),
  electraProtocolTestnet('electraProtocolTestnet', 406),
  bitcoinRegtest('bitcoinRegtest', 407);

  final String name;
  @override
  final int identifier;

  const Bip84Coins(this.name, this.identifier);

  @override
  Bip84Coins get value => this;

  @override
  String get coinName => name;

  @override
  BipCoinConfig get conf {
    final config = Bip84Conf();
    return switch (this) {
      Bip84Coins.bitcoin => config.bitcoinMainNet,
      Bip84Coins.bitcoinTestnet => config.bitcoinTestNet,
      Bip84Coins.litecoin => config.litecoinMainNet,
      Bip84Coins.litecoinTestnet => config.litecoinTestNet,
      Bip84Coins.electraProtocol => config.electraProtocolMainNet,
      Bip84Coins.electraProtocolTestnet => config.electraProtocolTestNet,
      Bip84Coins.bitcoinRegtest => config.bitcoinRegtest,
    };
  }

  static Bip84Coins? fromName(String name) {
    return values.firstWhereNullable((element) => element.name == name);
  }

  @override
  CoinProposal get proposal => CoinProposal.bip84;
}
