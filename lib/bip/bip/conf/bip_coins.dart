import 'package:blockchain_utils/bip/bip/bip.dart';
import 'package:blockchain_utils/bip/bip/conf/bip_coin_conf.dart';
import 'package:blockchain_utils/bip/cardano/cardano.dart';

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

  static CryptoCoins? fromName(String name) {
    CryptoCoins? coin = Bip44Coins.fromName(name);
    coin ??= Bip49Coins.fromName(name);
    coin ??= Bip84Coins.fromName(name);
    coin ??= Bip86Coins.fromName(name);
    coin ??= Cip1852Coins.fromName(name);
    return coin;
  }

  BipProposal get proposal;
}

/// Enum representing different BIP proposals.
enum BipProposal {
  bip44,
  bip49,
  bip84,
  bip86;

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
