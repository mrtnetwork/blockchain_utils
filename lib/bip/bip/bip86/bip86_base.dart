import 'package:blockchain_utils/bip/bip/bip32/base/bip32_base.dart';
import 'package:blockchain_utils/bip/bip/bip32/bip32_key_data.dart';
import 'package:blockchain_utils/bip/bip/bip44/base/bip44_base.dart';
import 'package:blockchain_utils/bip/bip/bip44/base/bip44_base_ex.dart';
import 'package:blockchain_utils/bip/bip/conf/bip86/bip86_coins.dart';
import 'package:blockchain_utils/bip/bip/conf/config/bip_coin_conf.dart';

/// Constants related to BIP-86 (Bitcoin Improvement Proposal 86).
class Bip86Const {
  /// The name of the BIP-86 specification.
  static const String specName = "BIP-0086";

  /// The purpose index for BIP-86, derived as a hardened index (86').
  static final Bip32KeyIndex purpose = Bip32KeyIndex.hardenIndex(86);
}

class Bip86 extends Bip44Base {
  /// private constructor
  Bip86._(Bip32Base bip32Obj, BipCoinConfig coinConf)
      : super(bip32Obj, coinConf);

  /// Constructor for creating a [Bip86] object from a seed and coin.
  Bip86.fromSeed(List<int> seedBytes, Bip86Coins coinType)
      : super.fromSeed(seedBytes, coinType.conf);

  /// Constructor for creating a [Bip86] object from a extended key and coin.
  Bip86.fromExtendedKey(String extendedKey, Bip86Coins coinType)
      : super.fromExtendedKey(extendedKey, coinType.conf);

  /// Constructor for creating a [Bip86] object from a private key and coin.
  Bip86.fromPrivateKey(List<int> privateKeyBytes, Bip86Coins coinType,
      {Bip32KeyData? keyData})
      : super.fromPrivateKey(privateKeyBytes, coinType.conf,
            keyData: keyData ?? Bip32KeyData());

  /// Constructor for creating a [Bip86] object from a public key and coin.
  Bip86.fromPublicKey(List<int> pubkeyBytes, Bip86Coins coinType,
      {Bip32KeyData? keyData})
      : super.fromPublicKey(pubkeyBytes, coinType.conf,
            keyData: keyData ??
                Bip32KeyData(depth: Bip32Depth(Bip44Levels.account.value)));

  /// derive purpose
  @override
  Bip44Base get purpose {
    if (!isLevel(Bip44Levels.master)) {
      throw Bip44DepthError(
          "Current depth (${bip32.depth.toInt()}) is not suitable for deriving purpose");
    }
    return Bip86._(bip32.childKey(Bip86Const.purpose), coinConf);
  }

  /// derive coin
  @override
  Bip86 get coin {
    if (!isLevel(Bip44Levels.purpose)) {
      throw Bip44DepthError(
          "Current depth (${bip32.depth.toInt()}) is not suitable for deriving coin");
    }
    final coinIndex = coinConf.coinIdx;
    return Bip86._(
        bip32.childKey(Bip32KeyIndex.hardenIndex(coinIndex)), coinConf);
  }

  /// derive account with index
  @override
  Bip86 account(int accIndex) {
    if (!isLevel(Bip44Levels.coin)) {
      throw Bip44DepthError(
          "Current depth (${bip32.depth.toInt()}) is not suitable for deriving account");
    }
    return Bip86._(
        bip32.childKey(Bip32KeyIndex.hardenIndex(accIndex)), coinConf);
  }

  /// derive change with change type [Bip44Changes] internal or external
  @override
  Bip86 change(Bip44Changes changeType) {
    if (!isLevel(Bip44Levels.account)) {
      throw Bip44DepthError(
          "Current depth (${bip32.depth.toInt()}) is not suitable for deriving change");
    }
    Bip32KeyIndex changeIndex = Bip32KeyIndex(changeType.value);
    if (!bip32Object.isPublicDerivationSupported) {
      changeIndex = Bip32KeyIndex.hardenIndex(changeType.value);
    }
    return Bip86._(bip32.childKey(changeIndex), coinConf);
  }

  /// derive address with index
  @override
  Bip86 addressIndex(int addressIndex) {
    if (!isLevel(Bip44Levels.change)) {
      throw Bip44DepthError(
          "Current depth (${bip32.depth.toInt()}) is not suitable for deriving address");
    }
    Bip32KeyIndex changeIndex = Bip32KeyIndex(addressIndex);
    if (!bip32Object.isPublicDerivationSupported) {
      changeIndex = Bip32KeyIndex.hardenIndex(addressIndex);
    }
    return Bip86._(bip32.childKey(changeIndex), coinConf);
  }

  /// derive default path
  @override
  Bip86 get deriveDefaultPath {
    Bip44Base bipObj = purpose.coin;
    return Bip86._(bipObj.bip32.derivePath(bipObj.coinConf.defPath), coinConf);
  }

  /// Specification name
  @override
  String get specName {
    return Bip86Const.specName;
  }
}
