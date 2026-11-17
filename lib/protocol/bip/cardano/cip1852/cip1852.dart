import 'package:blockchain_utils/protocol/bip/bip/bip32/bip32_key_data.dart';
import 'package:blockchain_utils/protocol/bip/bip/bip44/base/bip44_base.dart';
import 'package:blockchain_utils/protocol/bip/cardano/cip1852/conf/cip1852_coins.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// Constants related to CIP-1852 (Cardano Improvement Proposal 1852).
class Cip1852Const {
  /// The name of the CIP-1852 specification.
  static const String specName = "CIP-1852";

  /// The purpose index for CIP-1852, derived as a hardened index (1852').
  static final Bip32KeyIndex purpose = Bip32KeyIndex.hardenIndex(1852);
}

class Cip1852 extends Bip44Base<Cip1852> {
  /// private constractor
  Cip1852._(super.bip32Obj, super.coinConf);

  /// Constructor for creating a [Cip1852] object from a bip32 object and coin.
  Cip1852.fromBip32(super.bip, super.coin);

  /// Constructor for creating a [Cip1852] object from a seed and coin.
  Cip1852.fromSeed(List<int> seedBytes, Cip1852Coins coinType)
    : super.fromSeed(seedBytes, coinType.conf);

  /// Constructor for creating a [Cip1852] object from a extended key and coin.
  Cip1852.fromExtendedKey(String extendedKey, Cip1852Coins coinType)
    : super.fromExtendedKey(extendedKey, coinType.conf);

  /// Constructor for creating a [Cip1852] object from a private key and coin.
  Cip1852.fromPrivateKey(
    List<int> privateKeyBytes,
    Cip1852Coins coinType, {
    Bip32KeyData? keyData,
  }) : super.fromPrivateKey(
         privateKeyBytes,
         coinType.conf,
         keyData: keyData ?? Bip32KeyData(),
       );

  /// Constructor for creating a [Cip1852] object from a public key and coin.
  Cip1852.fromPublicKey(
    List<int> pubkeyBytes,
    Cip1852Coins coinType, {
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
  Cip1852 get purpose {
    if (!isLevel(Bip44Levels.master)) {
      throw BuError(
        DefaultErrorType.invalidArgument,
        "Current depth (${bip32.depth.toInt()}) is not suitable for deriving purpose",
      );
    }
    return Cip1852._(bip32.childKey(Cip1852Const.purpose), coinConf);
  }

  /// derive coin
  @override
  Cip1852 get coin {
    if (!isLevel(Bip44Levels.purpose)) {
      throw BuError(
        DefaultErrorType.invalidArgument,
        "Current depth (${bip32.depth.toInt()}) is not suitable for deriving coin",
      );
    }
    final coinIndex = coinConf.coinIdx;
    return Cip1852._(
      bip32.childKey(Bip32KeyIndex.hardenIndex(coinIndex)),
      coinConf,
    );
  }

  /// derive account with index
  @override
  Cip1852 account(int accIndex) {
    if (!isLevel(Bip44Levels.coin)) {
      throw BuError(
        DefaultErrorType.invalidArgument,
        "Current depth (${bip32.depth.toInt()}) is not suitable for deriving account",
      );
    }
    return Cip1852._(
      bip32.childKey(Bip32KeyIndex.hardenIndex(accIndex)),
      coinConf,
    );
  }

  /// derive change with change type [Bip44Changes] internal or external
  @override
  Cip1852 change(Bip44Changes changeType) {
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
    return Cip1852._(bip32.childKey(changeIndex), coinConf);
  }

  /// derive address with index
  @override
  Cip1852 addressIndex(int addressIndex) {
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
    return Cip1852._(bip32.childKey(changeIndex), coinConf);
  }

  /// derive default path
  @override
  Cip1852 get deriveDefaultPath {
    final Bip44Base bipObj = purpose.coin;
    return Cip1852._(
      bipObj.bip32.derivePath(bipObj.coinConf.defPath),
      coinConf,
    );
  }

  /// Specification name
  @override
  String get specName {
    return Cip1852Const.specName;
  }
}
