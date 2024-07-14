import 'package:blockchain_utils/bip/bip/bip32/bip32_key_data.dart';
import 'package:blockchain_utils/bip/bip/conf/bip/bip_coins.dart';
import 'package:blockchain_utils/bip/bip/conf/config/bip_coin_conf.dart';
import 'package:blockchain_utils/bip/cardano/cip1852/cip1852.dart';
import 'package:blockchain_utils/bip/cardano/cip1852/conf/cip1852_conf.dart';

/// An enumeration of supported cryptocurrencies for CIP1852. It includes both main
/// networks and test networks of various cryptocurrencies.
class Cip1852Coins extends BipCoins {
  /// mainnets
  static const Cip1852Coins cardanoIcarus = Cip1852Coins._('cardanoIcarus');
  static const Cip1852Coins cardanoLedger = Cip1852Coins._('cardanoLedger');

  /// testnets
  static const Cip1852Coins cardanoIcarusTestnet =
      Cip1852Coins._('cardanoIcarusTestnet');
  static const Cip1852Coins cardanoLedgerTestnet =
      Cip1852Coins._('cardanoLedgerTestnet');

  final String name;

  const Cip1852Coins._(this.name);

  @override
  Cip1852Coins get value => this;

  @override
  String get coinName {
    return name;
  }

  static Cip1852Coins? fromName(String name) {
    try {
      return _coinToConf.keys.firstWhere((element) => element.name == name);
    } on StateError {
      return null;
    }
  }

  @override
  BipCoinConfig get conf => _coinToConf[this]!;

  /// A mapping that associates each Cip1852Coins (enum) with its corresponding
  /// BipCoinConfig configuration.
  static final Map<Cip1852Coins, BipCoinConfig> _coinToConf = {
    Cip1852Coins.cardanoIcarus: Cip1852Conf.cardanoIcarusMainNet,
    Cip1852Coins.cardanoLedger: Cip1852Conf.cardanoLedgerMainNet,
    Cip1852Coins.cardanoIcarusTestnet: Cip1852Conf.cardanoIcarusTestNet,
    Cip1852Coins.cardanoLedgerTestnet: Cip1852Conf.cardanoLedgerTestNet,
  };

  @override
  BipProposal get proposal => CipProposal.cip1852;
}

class CipProposal implements BipProposal {
  static const CipProposal cip1852 = CipProposal._('cip1852');

  const CipProposal._(this.name);
  @override
  final String name;

  @override
  String get specName => name;
  @override
  CipProposal get value => this;

  static const List<CipProposal> values = [cip1852];

  @override
  Bip32KeyIndex get purpose => Cip1852Const.purpose;
}
