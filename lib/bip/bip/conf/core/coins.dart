import 'package:blockchain_utils/bip/bip/bip32/bip32_key_data.dart';
import 'package:blockchain_utils/bip/bip/bip44/bip44_base.dart' show Bip44Const;
import 'package:blockchain_utils/bip/bip/bip49/bip49_base.dart' show Bip49Const;
import 'package:blockchain_utils/bip/bip/bip84/bip84_base.dart';
import 'package:blockchain_utils/bip/bip/bip86/bip86_base.dart' show Bip86Const;
import 'package:blockchain_utils/bip/bip/conf/bip44/bip44_coins.dart'
    show Bip44Coins;
import 'package:blockchain_utils/bip/bip/conf/bip49/bip49_coins.dart'
    show Bip49Coins;
import 'package:blockchain_utils/bip/bip/conf/bip84/bip84_coins.dart'
    show Bip84Coins;
import 'package:blockchain_utils/bip/bip/conf/bip86/bip86_coins.dart'
    show Bip86Coins;
import 'package:blockchain_utils/bip/bip/zip32/conf/coins.dart';
import 'package:blockchain_utils/bip/cardano/cip0019/conf/cip0019_coins.dart'
    show Cip0019Coins;
import 'package:blockchain_utils/bip/cardano/cip1852/conf/cip1852_coins.dart';
import 'package:blockchain_utils/bip/monero/conf/monero_coins.dart';
import 'package:blockchain_utils/bip/substrate/conf/substrate_coins.dart';
import 'package:blockchain_utils/exception/exception/exception.dart';
import 'coin_conf.dart';

/// An abstract class representing a collection of cryptocurrency coins.
///
/// This abstract class defines a contract for classes that provide a collection
/// of cryptocurrency coins. Subclasses should implement the 'value' getter to
/// return an instance of themselves or a specific type that represents the
/// collection of coins.
abstract class CryptoCoins<T extends BaseCoinConfig> {
  /// Gets the collection of cryptocurrency coins.
  CryptoCoins get value;

  String get coinName;

  T get conf;

  static CryptoCoins? getCoin(String name, CoinProposal proposal) {
    switch (proposal) {
      case CoinProposal.bip44:
        return Bip44Coins.fromName(name);
      case CoinProposal.bip49:
        return Bip49Coins.fromName(name);
      case CoinProposal.bip84:
        return Bip84Coins.fromName(name);
      case CoinProposal.bip86:
        return Bip86Coins.fromName(name);
      case CoinProposal.cip0019:
        return Cip0019Coins.fromName(name);
      case CoinProposal.cip1852:
        return Cip1852Coins.fromName(name);
      case CoinProposal.substrate:
        return SubstrateCoins.fromName(name);
      case CoinProposal.monero:
        return MoneroCoins.fromName(name);
      case CoinProposal.zip32:
        return ZIP32Coins.fromName(name);
    }
  }

  CoinProposal get proposal;

  @override
  String toString() {
    return "$runtimeType.$coinName";
  }
}

enum CoinProposal {
  bip44("bip44"),
  bip49("bip49"),
  bip84("bip84"),
  bip86("bip86"),
  cip1852("cip1852"),
  substrate("substrate"),
  monero("monero"),
  cip0019("CIP-0019"),
  zip32("zip32");

  final String name;
  const CoinProposal(this.name);
  static CoinProposal fromName(String name) {
    return values.firstWhere(
      (element) => element.name == name,
      orElse:
          () =>
              throw ArgumentException.invalidOperationArguments(
                "CoinProposal",
                reason: "Unable to locate a proposal with the given name.",
                details: {"Name": name},
              ),
    );
  }

  Bip32KeyIndex? get purpose {
    switch (this) {
      case CoinProposal.bip44:
        return Bip44Const.purpose;
      case CoinProposal.bip49:
        return Bip49Const.purpose;
      case CoinProposal.bip84:
        return Bip84Const.purpose;
      case CoinProposal.bip86:
        return Bip86Const.purpose;
      default:
        return null;
    }
  }
}
