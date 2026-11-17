import 'package:blockchain_utils/protocol/bip/bip/bip32/bip32_key_data.dart';
import 'package:blockchain_utils/protocol/bip/bip/bip44/base/bip44_base.dart';
import 'package:blockchain_utils/protocol/bip/bip/conf/bip49/bip49_coins.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// Constants related to BIP-49 (Bitcoin Improvement Proposal 44).
class Bip49Const {
  /// The name of the BIP-49 specification.
  static const String specName = "BIP-0049";

  /// The purpose index for BIP-49, derived as a hardened index (49').
  static final Bip32KeyIndex purpose = Bip32KeyIndex.hardenIndex(49);
}

class Bip49 extends Bip44Base<Bip49> {
  /// private constractor
  Bip49._(super.bip32Obj, super.coinConf);

  /// Constructor for creating a [Bip49] object from a seed and coin.
  Bip49.fromSeed(List<int> seedBytes, Bip49Coins coinType)
    : super.fromSeed(seedBytes, coinType.conf);

  /// Constructor for creating a [Bip49] object from a extended key and coin.
  Bip49.fromExtendedKey(String extendedKey, Bip49Coins coinType)
    : super.fromExtendedKey(extendedKey, coinType.conf);

  /// Constructor for creating a [Bip49] object from a private key and coin.
  Bip49.fromPrivateKey(
    List<int> privateKeyBytes,
    Bip49Coins coinType, {
    Bip32KeyData? keyData,
  }) : super.fromPrivateKey(
         privateKeyBytes,
         coinType.conf,
         keyData: keyData ?? Bip32KeyData(),
       );

  /// Constructor for creating a [Bip49] object from a public key and coin.
  Bip49.fromPublicKey(
    List<int> pubkeyBytes,
    Bip49Coins coinType, {
    Bip32KeyData? keyData,
  }) : super.fromPublicKey(
         pubkeyBytes,
         coinType.conf,
         keyData:
             keyData ??
             Bip32KeyData(depth: Bip32Depth(Bip44Levels.account.value)),
       );

  /// derive purpose
  @override
  Bip49 get purpose {
    if (!isLevel(Bip44Levels.master)) {
      throw BuError(
        DefaultErrorType.invalidArgument,
        "Current depth (${bip32.depth.toInt()}) is not suitable for deriving purpose",
      );
    }
    return Bip49._(
      bip32.childKey(coinConf.purpose ?? Bip49Const.purpose),
      coinConf,
    );
  }

  /// derive coin
  @override
  Bip49 get coin {
    if (!isLevel(Bip44Levels.purpose)) {
      throw BuError(
        DefaultErrorType.invalidArgument,
        "Current depth (${bip32.depth.toInt()}) is not suitable for deriving coin",
      );
    }
    final coinIndex = coinConf.coinIdx;
    return Bip49._(
      bip32.childKey(Bip32KeyIndex.hardenIndex(coinIndex)),
      coinConf,
    );
  }

  /// derive account with index
  @override
  Bip49 account(int accIndex) {
    if (!isLevel(Bip44Levels.coin)) {
      throw BuError(
        DefaultErrorType.invalidArgument,
        "Current depth (${bip32.depth.toInt()}) is not suitable for deriving account",
      );
    }
    return Bip49._(
      bip32.childKey(Bip32KeyIndex.hardenIndex(accIndex)),
      coinConf,
    );
  }

  /// derive change with change type [Bip44Changes] internal or external
  @override
  Bip49 change(Bip44Changes changeType) {
    if (!isLevel(Bip44Levels.account)) {
      throw BuError(
        DefaultErrorType.invalidArgument,
        "Current depth (${bip32.depth.toInt()}) is not suitable for deriving change",
      );
    }
    Bip32KeyIndex changeIndex = Bip32KeyIndex(changeType.value);
    if (!bip32Object.isPublicDerivationSupported) {
      changeIndex = Bip32KeyIndex.hardenIndex(changeType.value);
    }
    return Bip49._(bip32.childKey(changeIndex), coinConf);
  }

  /// derive address with index
  @override
  Bip49 addressIndex(int addressIndex) {
    if (!isLevel(Bip44Levels.change)) {
      throw BuError(
        DefaultErrorType.invalidArgument,
        "Current depth (${bip32.depth.toInt()}) is not suitable for deriving address",
      );
    }
    Bip32KeyIndex changeIndex = Bip32KeyIndex(addressIndex);
    if (!bip32Object.isPublicDerivationSupported) {
      changeIndex = Bip32KeyIndex.hardenIndex(addressIndex);
    }
    return Bip49._(bip32.childKey(changeIndex), coinConf);
  }

  /// derive default path
  @override
  Bip49 get deriveDefaultPath {
    final Bip44Base bipObj = purpose.coin;
    return Bip49._(bipObj.bip32.derivePath(bipObj.coinConf.defPath), coinConf);
  }

  /// Specification name
  @override
  String get specName {
    return Bip49Const.specName;
  }
}
