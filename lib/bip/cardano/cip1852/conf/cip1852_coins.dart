import 'package:blockchain_utils/bip/bip/conf/bip_coin_conf.dart';
import 'package:blockchain_utils/bip/bip/conf/bip_coins.dart';
import 'package:blockchain_utils/bip/cardano/cip1852/conf/cip1852_conf.dart';

/// An enumeration of supported cryptocurrencies for CIP1852. It includes both main
/// networks and test networks of various cryptocurrencies.
enum Cip1852Coins implements CryptoCoins {
  /// mainnets
  cardanoIcarus,
  cardanoLedger,

  /// testnets
  cardanoIcarusTestnet,
  cardanoLedgerTestnet;

  @override
  Cip1852Coins get value => this;

  String get coinName {
    return this.name;
  }

  static Cip1852Coins? fromName(String name) {
    try {
      return values.firstWhere((element) => element.name == name);
    } on StateError {
      return null;
    }
  }

  CoinConfig get conf => _coinToConf[this]!;

  /// A mapping that associates each Cip1852Coins (enum) with its corresponding
  /// CoinConfig configuration.
  static final Map<CryptoCoins, CoinConfig> _coinToConf = {
    Cip1852Coins.cardanoIcarus: Cip1852Conf.cardanoIcarusMainNet,
    Cip1852Coins.cardanoLedger: Cip1852Conf.cardanoLedgerMainNet,
    Cip1852Coins.cardanoIcarusTestnet: Cip1852Conf.cardanoIcarusTestNet,
    Cip1852Coins.cardanoLedgerTestnet: Cip1852Conf.cardanoLedgerTestNet,
  };
  BipProposal get proposal => throw UnimplementedError();
}
