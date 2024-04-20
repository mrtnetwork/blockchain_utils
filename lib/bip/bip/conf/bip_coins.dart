import 'package:blockchain_utils/bip/bip/conf/bip_coin_conf.dart';
import 'package:blockchain_utils/blockchain_utils.dart';

/// An abstract class representing a collection of cryptocurrency coins.
///
/// This abstract class defines a contract for classes that provide a collection
/// of cryptocurrency coins. Subclasses should implement the 'value' getter to
/// return an instance of themselves or a specific type that represents the
/// collection of coins.
abstract class CryptoCoins {
  /// Gets the collection of cryptocurrency coins.
  CryptoCoins get value;

  String get coinName;

  CoinConfig get conf;

  static CryptoCoins? getCoin(String name, CryptoProposal proposal) {
    switch (proposal) {
      case BipProposal.bip44:
        return Bip44Coins.fromName(name);
      case BipProposal.bip49:
        return Bip49Coins.fromName(name);
      case BipProposal.bip84:
        return Bip84Coins.fromName(name);
      case BipProposal.bip86:
        return Bip86Coins.fromName(name);
      case CipProposal.cip1852:
        return Cip1852Coins.fromName(name);
      default:
        return null;
    }
  }

  CryptoProposal get proposal;

  @override
  String toString() {
    return "$runtimeType.$coinName";
  }
}

abstract class CryptoProposal {
  String get specName;
  CryptoProposal get value;
  Bip32KeyIndex get purpose;

  static CryptoProposal fromName(String name) {
    try {
      return BipProposal.values.firstWhere((element) => element.name == name);
    } on StateError {
      return CipProposal.values.firstWhere(
        (element) => element.name == name,
        orElse: () => throw MessageException(
            "Unable to locate a proposal with the given name.",
            details: {"Name": name}),
      );
    }
  }
}

class CipProposal implements CryptoProposal {
  static const CipProposal cip1852 = CipProposal._('cip1852');

  const CipProposal._(this.name);
  final String name;

  @override
  String get specName => name;
  @override
  CipProposal get value => this;

  static const List<CipProposal> values = [cip1852];

  @override
  Bip32KeyIndex get purpose => Cip1852Const.purpose;
}

/// Enum representing different BIP proposals.
class BipProposal implements CryptoProposal {
  static const BipProposal bip44 = BipProposal._('bip44');
  static const BipProposal bip49 = BipProposal._('bip49');
  static const BipProposal bip84 = BipProposal._('bip84');
  static const BipProposal bip86 = BipProposal._('bip86');

  static const List<BipProposal> values = [bip44, bip49, bip84, bip86];

  final String name;

  const BipProposal._(this.name);

  @override
  String get specName => name;
  @override
  BipProposal get value => this;

  /// Extension method to get the corresponding [Bip32KeyIndex.purpose] for each [BipProposal].
  @override
  Bip32KeyIndex get purpose {
    switch (this) {
      case BipProposal.bip44:
        return Bip44Const.purpose;
      case BipProposal.bip49:
        return Bip49Const.purpose;
      case BipProposal.bip84:
        return Bip84Const.purpose;
      default:
        return Bip86Const.purpose;
    }
  }
}
