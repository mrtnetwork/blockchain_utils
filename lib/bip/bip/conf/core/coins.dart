import 'package:blockchain_utils/bip/bip/conf/bip/bip_coins.dart';
import 'package:blockchain_utils/bip/cardano/cip1852/conf/cip1852_coins.dart';
import 'package:blockchain_utils/bip/monero/conf/monero_coins.dart';
import 'package:blockchain_utils/bip/substrate/conf/substrate_coins.dart';
import 'package:blockchain_utils/exception/exception.dart';
import 'coin_conf.dart';

/// An abstract class representing a collection of cryptocurrency coins.
///
/// This abstract class defines a contract for classes that provide a collection
/// of cryptocurrency coins. Subclasses should implement the 'value' getter to
/// return an instance of themselves or a specific type that represents the
/// collection of coins.
abstract class CryptoCoins<T extends CoinConfig> {
  /// Gets the collection of cryptocurrency coins.
  CryptoCoins get value;

  String get coinName;

  T get conf;

  static CryptoCoins? getCoin(String name, CoinProposal proposal) {
    switch (proposal) {
      case BipProposal.bip44:
      case BipProposal.bip49:
      case BipProposal.bip84:
      case BipProposal.bip86:
        return BipCoins.fromName(name, proposal as BipProposal);
      case CipProposal.cip1852:
        return Cip1852Coins.fromName(name);
      case SubstratePropoosal.substrate:
        return SubstrateCoins.fromName(name);
      case MoneroProposal.monero:
        return MoneroCoins.fromName(name);
      default:
        return null;
    }
  }

  CoinProposal get proposal;

  bool get isBipCoin;

  @override
  String toString() {
    return "$runtimeType.$coinName";
  }
}

abstract class CoinProposal {
  String get specName;
  CoinProposal get value;

  static CoinProposal fromName(String name) {
    switch (name) {
      case "cip1852":
        return CipProposal.cip1852;
      case "substrate":
        return SubstratePropoosal.substrate;
      case "monero":
        return MoneroProposal.monero;
      default:
        return BipProposal.values.firstWhere(
          (element) => element.name == name,
          orElse: () => throw MessageException(
              "Unable to locate a proposal with the given name.",
              details: {"Name": name}),
        );
    }
  }
}
