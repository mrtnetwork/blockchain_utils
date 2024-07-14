import 'package:blockchain_utils/bip/bip/bip32/base/bip32_base.dart';
import 'package:blockchain_utils/bip/bip/bip44/base/bip44_base.dart';
import 'package:blockchain_utils/bip/bip/bip44/base/bip44_base_ex.dart';
import 'package:blockchain_utils/bip/bip/conf/bip44/bip44_coins.dart';
import 'package:blockchain_utils/bip/bip/conf/config/bip_coin_conf.dart';
import '../bip32/bip32_key_data.dart';

/// Constants related to BIP-44 (Bitcoin Improvement Proposal 44).
class Bip44Const {
  /// The name of the BIP-44 specification.
  static const String specName = "BIP-0044";

  /// The purpose index for BIP-44, derived as a hardened index (44').
  static final Bip32KeyIndex purpose = Bip32KeyIndex.hardenIndex(44);
}

class Bip44 extends Bip44Base {
  // private constractor
  Bip44._(Bip32Base bip32Obj, BipCoinConfig coinConf)
      : super(bip32Obj, coinConf);

  /// Constructor for creating a [Bip44] object from a seed and coin.
  Bip44.fromSeed(List<int> seedBytes, Bip44Coins coinType)
      : super.fromSeed(seedBytes, coinType.conf);

  /// Constructor for creating a [Bip44] object from a extended key and coin.
  Bip44.fromExtendedKey(String extendedKey, Bip44Coins coinType)
      : super.fromExtendedKey(extendedKey, coinType.conf);

  /// Constructor for creating a [Bip44] object from a private key and coin.
  Bip44.fromPrivateKey(List<int> privateKeyBytes, Bip44Coins coinType,
      {Bip32KeyData? keyData})
      : super.fromPrivateKey(privateKeyBytes, coinType.conf,
            keyData: keyData ?? Bip32KeyData());

  /// Constructor for creating a [Bip44] object from a public key and coin.
  Bip44.fromPublicKey(List<int> pubkeyBytes, Bip44Coins coinType,
      {Bip32KeyData? keyData})
      : super.fromPublicKey(pubkeyBytes, coinType.conf,
            keyData: keyData ??
                Bip32KeyData(depth: Bip32Depth(Bip44Levels.account.value)));

  /// derive purpose
  @override
  Bip44 get purpose {
    if (!isLevel(Bip44Levels.master)) {
      throw Bip44DepthError(
          "Current depth (${bip32.depth.toInt()}) is not suitable for deriving purpose");
    }
    return Bip44._(bip32.childKey(Bip44Const.purpose), coinConf);
  }

  /// derive default path
  @override
  Bip44 get deriveDefaultPath {
    Bip44 bipObj = purpose.coin;
    return Bip44._(bipObj.bip32.derivePath(bipObj.coinConf.defPath), coinConf);
  }

  /// derive coin
  @override
  Bip44 get coin {
    if (!isLevel(Bip44Levels.purpose)) {
      throw Bip44DepthError(
          "Current depth (${bip32.depth.toInt()}) is not suitable for deriving coin");
    }
    final coinIndex = coinConf.coinIdx;
    return Bip44._(
        bip32.childKey(Bip32KeyIndex.hardenIndex(coinIndex)), coinConf);
  }

  /// derive account with index
  @override
  Bip44 account(int accIndex) {
    if (!isLevel(Bip44Levels.coin)) {
      throw Bip44DepthError(
          "Current depth (${bip32.depth.toInt()}) is not suitable for deriving account");
    }
    return Bip44._(
        bip32.childKey(Bip32KeyIndex.hardenIndex(accIndex)), coinConf);
  }

  /// derive change with change type [Bip44Changes] internal or external
  @override
  Bip44 change(Bip44Changes changeType) {
    if (!isLevel(Bip44Levels.account)) {
      throw Bip44DepthError(
          "Current depth (${bip32.depth.toInt()}) is not suitable for deriving change");
    }
    Bip32KeyIndex changeIndex = Bip32KeyIndex(changeType.value);
    if (!bip32Object.isPublicDerivationSupported) {
      changeIndex = Bip32KeyIndex.hardenIndex(changeType.value);
    }
    return Bip44._(bip32.childKey(changeIndex), coinConf);
  }

  /// derive address with index
  @override
  Bip44 addressIndex(int addressIndex) {
    if (!isLevel(Bip44Levels.change)) {
      throw Bip44DepthError(
          "Current depth (${bip32.depth.toInt()}) is not suitable for deriving address");
    }
    Bip32KeyIndex changeIndex = Bip32KeyIndex(addressIndex);
    if (!bip32Object.isPublicDerivationSupported) {
      changeIndex = Bip32KeyIndex.hardenIndex(addressIndex);
    }
    return Bip44._(bip32.childKey(changeIndex), coinConf);
  }

  /// Specification name
  @override
  String get specName {
    return Bip44Const.specName;
  }
}
