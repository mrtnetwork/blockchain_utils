import 'package:blockchain_utils/protocol/bip/bip/bip32/bip32_key_data.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/protocol/bip/bip/bip44/bip44_base.dart'
    show Bip44Const;
import 'package:blockchain_utils/protocol/bip/bip/bip49/bip49_base.dart'
    show Bip49Const;
import 'package:blockchain_utils/protocol/bip/bip/bip84/bip84_base.dart';
import 'package:blockchain_utils/protocol/bip/bip/bip86/bip86_base.dart'
    show Bip86Const;
import 'package:blockchain_utils/protocol/bip/bip/conf/bip44/bip44_coins.dart'
    show Bip44Coins;
import 'package:blockchain_utils/protocol/bip/bip/conf/bip49/bip49_coins.dart'
    show Bip49Coins;
import 'package:blockchain_utils/protocol/bip/bip/conf/bip84/bip84_coins.dart'
    show Bip84Coins;
import 'package:blockchain_utils/protocol/bip/bip/conf/bip86/bip86_coins.dart'
    show Bip86Coins;
import 'package:blockchain_utils/protocol/bip/bip/eip2334/eip2334_const.dart';
import 'package:blockchain_utils/protocol/bip/bip/eip2334/eip2334_coins.dart'
    show Eip2334Coins;
import 'package:blockchain_utils/protocol/bip/bip/nep649/nep649_coins.dart'
    show Nep649Coins;
import 'package:blockchain_utils/protocol/zip32/conf/coins.dart';
import 'package:blockchain_utils/protocol/zip32/zip32/zip32.dart';
import 'package:blockchain_utils/protocol/bip/cardano/cip0019/conf/cip0019_coins.dart'
    show Cip0019Coins;
import 'package:blockchain_utils/protocol/non_derivable_coin/non_derivable_coin.dart';
import 'package:blockchain_utils/protocol/bip/cardano/cip1852/conf/cip1852_coins.dart';
import 'package:blockchain_utils/protocol/bip/monero/conf/monero_coins.dart';
import 'package:blockchain_utils/protocol/substrate/conf/substrate_coins.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/helper/helper.dart';
import 'package:blockchain_utils/protocol/bip/bip/conf/core/coin_conf.dart';

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

  int get identifier;
  static const List<CryptoCoins> values = [
    ...Bip44Coins.values,
    ...Bip49Coins.values,
    ...Bip84Coins.values,
    ...Bip86Coins.values,
    ...Eip2334Coins.values,
    ...Nep649Coins.values,
    ...Cip0019Coins.values,
    ...Cip1852Coins.values,
    ...SubstrateCoins.values,
    ...MoneroCoins.values,
    ...ZIP32Coins.values,
    ...NonDerivableCoins.values,
  ];

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
      case CoinProposal.eip2334:
        return Eip2334Coins.fromName(name);
      case CoinProposal.nep649:
        return Nep649Coins.fromName(name);
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
      case CoinProposal.nonDerivable:
        return NonDerivableCoins.fromName(name);
    }
  }

  CoinProposal get proposal;

  static CryptoCoins? fromIdentifier(int identifier) {
    return values.firstWhereNullable(
      (element) => element.identifier == identifier,
    );
  }

  @override
  String toString() {
    return "$runtimeType.$coinName";
  }
}

enum CoinProposal {
  nonDerivable("nonDerivable"),
  bip44("bip44"),
  bip49("bip49"),
  bip84("bip84"),
  bip86("bip86"),
  eip2334("eip2334"),
  nep649("nep649"),
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
              throw CoreErrors.invalidOperationArguments(
                "CoinProposal",
                reason: "Unable to locate a proposal with the given name.",
                details: {"Name": name},
              ),
    );
  }

  Bip32KeyIndex get purpose {
    switch (this) {
      case CoinProposal.bip44:
        return Bip44Const.purpose;
      case CoinProposal.bip49:
        return Bip49Const.purpose;
      case CoinProposal.bip84:
        return Bip84Const.purpose;
      case CoinProposal.bip86:
        return Bip86Const.purpose;
      case CoinProposal.eip2334:
        // EIP-2334 purpose is a plain (non-hardened) 12381 index.
        return Bip32KeyIndex(Eip2334Const.purpose);
      case CoinProposal.nep649:
        return Bip44Const.purpose;
      case CoinProposal.zip32:
        return Zip32Const.purpose;
      default:
        return Bip44Const.purpose;
    }
  }

  bool get isBip {
    switch (this) {
      case CoinProposal.bip44:
      case CoinProposal.bip49:
      case CoinProposal.bip84:
      case CoinProposal.bip86:
      case CoinProposal.nep649:
      case CoinProposal.cip1852:
      case CoinProposal.cip0019:
        return true;
      default:
        return false;
    }
  }

  bool get isZip {
    return this == CoinProposal.zip32;
  }

  bool get isSubstrate {
    return this == CoinProposal.substrate;
  }

  bool get isMonero {
    return this == CoinProposal.monero;
  }
}
