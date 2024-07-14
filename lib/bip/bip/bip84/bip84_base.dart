import 'package:blockchain_utils/bip/bip/bip32/base/bip32_base.dart';
import 'package:blockchain_utils/bip/bip/bip32/bip32_key_data.dart';
import 'package:blockchain_utils/bip/bip/bip44/base/bip44_base.dart';
import 'package:blockchain_utils/bip/bip/bip44/base/bip44_base_ex.dart';
import 'package:blockchain_utils/bip/bip/conf/bip84/bip84_coins.dart';
import 'package:blockchain_utils/bip/bip/conf/config/bip_coin_conf.dart';

/// Constants related to BIP-84 (Bitcoin Improvement Proposal 84).
class Bip84Const {
  /// The name of the BIP-84 specification.
  static const String specName = "BIP-0084";

  /// The purpose index for BIP-84, derived as a hardened index (84').
  static final Bip32KeyIndex purpose = Bip32KeyIndex.hardenIndex(84);
}

class Bip84 extends Bip44Base {
  /// private constractor
  Bip84._(Bip32Base bip32Obj, BipCoinConfig coinConf)
      : super(bip32Obj, coinConf);

  /// Constructor for creating a [Bip84] object from a seed and coin.
  Bip84.fromSeed(List<int> seedBytes, Bip84Coins coinType)
      : super.fromSeed(seedBytes, coinType.conf);

  /// Constructor for creating a [Bip84] object from a extended key and coin.
  Bip84.fromExtendedKey(String extendedKey, Bip84Coins coinType)
      : super.fromExtendedKey(extendedKey, coinType.conf);

  /// Constructor for creating a [Bip84] object from a private key and coin.
  Bip84.fromPrivateKey(List<int> privateKeyBytes, Bip84Coins coinType,
      {Bip32KeyData? keyData})
      : super.fromPrivateKey(privateKeyBytes, coinType.conf,
            keyData: keyData ?? Bip32KeyData());

  /// Constructor for creating a [Bip84] object from a public key and coin.
  Bip84.fromPublicKey(List<int> pubkeyBytes, Bip84Coins coinType,
      {Bip32KeyData? keyData})
      : super.fromPublicKey(pubkeyBytes, coinType.conf,
            keyData: keyData ??
                Bip32KeyData(depth: Bip32Depth(Bip44Levels.account.value)));

  /// derive purpose
  @override
  Bip84 get purpose {
    if (!isLevel(Bip44Levels.master)) {
      throw Bip44DepthError(
          "Current depth (${bip32.depth.toInt()}) is not suitable for deriving purpose");
    }
    return Bip84._(bip32.childKey(Bip84Const.purpose), coinConf);
  }

  /// derive coin
  @override
  Bip84 get coin {
    if (!isLevel(Bip44Levels.purpose)) {
      throw Bip44DepthError(
          "Current depth (${bip32.depth.toInt()}) is not suitable for deriving coin");
    }
    final coinIndex = coinConf.coinIdx;
    return Bip84._(
        bip32.childKey(Bip32KeyIndex.hardenIndex(coinIndex)), coinConf);
  }

  /// derive account with index
  @override
  Bip84 account(int accIndex) {
    if (!isLevel(Bip44Levels.coin)) {
      throw Bip44DepthError(
          "Current depth (${bip32.depth.toInt()}) is not suitable for deriving account");
    }
    return Bip84._(
        bip32.childKey(Bip32KeyIndex.hardenIndex(accIndex)), coinConf);
  }

  /// derive change with change type [Bip44Changes] internal or external
  @override
  Bip84 change(Bip44Changes changeType) {
    if (!isLevel(Bip44Levels.account)) {
      throw Bip44DepthError(
          "Current depth (${bip32.depth.toInt()}) is not suitable for deriving change");
    }
    Bip32KeyIndex changeIndex = Bip32KeyIndex(changeType.value);
    if (!bip32Object.isPublicDerivationSupported) {
      changeIndex = Bip32KeyIndex.hardenIndex(changeType.value);
    }
    return Bip84._(bip32.childKey(changeIndex), coinConf);
  }

  /// derive address with index
  @override
  Bip84 addressIndex(int addressIndex) {
    if (!isLevel(Bip44Levels.change)) {
      throw Bip44DepthError(
          "Current depth (${bip32.depth.toInt()}) is not suitable for deriving address");
    }
    Bip32KeyIndex changeIndex = Bip32KeyIndex(addressIndex);
    if (!bip32Object.isPublicDerivationSupported) {
      changeIndex = Bip32KeyIndex.hardenIndex(addressIndex);
    }
    return Bip84._(bip32.childKey(changeIndex), coinConf);
  }

  /// derive default path
  @override
  Bip84 get deriveDefaultPath {
    Bip44Base bipObj = purpose.coin;
    return Bip84._(bipObj.bip32.derivePath(bipObj.coinConf.defPath), coinConf);
  }

  /// Specification name
  @override
  String get specName {
    return Bip84Const.specName;
  }
}
