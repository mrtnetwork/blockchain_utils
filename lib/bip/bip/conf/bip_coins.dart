import 'package:blockchain_utils/bip/bip/bip.dart';
import 'package:blockchain_utils/bip/bip/conf/bip_coin_conf.dart';

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
    if (proposal is BipProposal) {
      switch (proposal) {
        case BipProposal.bip44:
          return Bip44Coins.fromName(name);
        case BipProposal.bip49:
          return Bip49Coins.fromName(name);
        case BipProposal.bip84:
          return Bip84Coins.fromName(name);
        default:
          return Bip86Coins.fromName(name);
      }
    }
    return null;
  }

  CryptoProposal get proposal;
}

abstract class CryptoProposal {
  String get specName;
  CryptoProposal get value;

  static CryptoProposal fromName(String name) {
    return BipProposal.values.firstWhere((element) => element.name == name);
  }
}

/// Enum representing different BIP proposals.
enum BipProposal implements CryptoProposal {
  bip44,
  bip49,
  bip84,
  bip86;

  String get specName => this.name;
  BipProposal get value => this;

  /// Extension method to get the corresponding [Bip32KeyIndex.purpose] for each [BipProposal].
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
