import 'package:blockchain_utils/bip/bip/bip32/bip32_key_data.dart';
import 'package:blockchain_utils/bip/bip/bip44/bip44_base.dart';
import 'package:blockchain_utils/bip/bip/bip49/bip49_base.dart';
import 'package:blockchain_utils/bip/bip/bip84/bip84_base.dart';
import 'package:blockchain_utils/bip/bip/bip86/bip86_base.dart';
import 'package:blockchain_utils/bip/bip/conf/config/bip_coin_conf.dart';
import 'package:blockchain_utils/bip/bip/conf/core/coins.dart';
import 'package:blockchain_utils/bip/bip/conf/bip44/bip44_coins.dart';
import 'package:blockchain_utils/bip/bip/conf/bip49/bip49_coins.dart';
import 'package:blockchain_utils/bip/bip/conf/bip84/bip84_coins.dart';
import 'package:blockchain_utils/bip/bip/conf/bip86/bip86_coins.dart';

abstract class BipCoins implements CryptoCoins<BipCoinConfig> {
  const BipCoins();

  /// Gets the collection of cryptocurrency coins.
  @override
  CryptoCoins get value;

  @override
  String get coinName;

  @override
  BipCoinConfig get conf;

  @override
  bool get isBipCoin => true;

  static CryptoCoins? fromName(String name, BipProposal proposal) {
    switch (proposal) {
      case BipProposal.bip44:
        return Bip44Coins.fromName(name);
      case BipProposal.bip49:
        return Bip49Coins.fromName(name);
      case BipProposal.bip84:
        return Bip84Coins.fromName(name);
      case BipProposal.bip86:
        return Bip86Coins.fromName(name);
      default:
        return null;
    }
  }

  @override
  BipProposal get proposal;

  @override
  String toString() {
    return "$runtimeType.$coinName";
  }
}

// abstract class BipProposals implements CoinProposal {
//   abstract final Bip32KeyIndex purpose;
// }

/// Enum representing different BIP proposals.
class BipProposal implements CoinProposal {
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

  /// Extension method to get the corresponding [purpose] key index for each [BipProposal].
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
