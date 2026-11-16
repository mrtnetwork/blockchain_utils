library;

export 'package:blockchain_utils/protocol/bip/bip/nep649/nep649_base.dart';
export 'package:blockchain_utils/protocol/bip/bip/nep649/nep649_coins.dart';
export 'package:blockchain_utils/protocol/bip/bip/nep649/nep649_conf.dart';
export 'package:blockchain_utils/protocol/bip/bip/nep649/nep649_const.dart';
export 'package:blockchain_utils/protocol/bip/bip/nep649/nep649_keys.dart';

import 'package:blockchain_utils/protocol/bip/bip/bip32/bip32_key_data.dart';
import 'package:blockchain_utils/protocol/bip/bip/bip44/base/bip44_base.dart'
    show Bip44Changes, Bip44Levels;
import 'package:blockchain_utils/protocol/bip/bip/nep649/nep649_base.dart';
import 'package:blockchain_utils/protocol/bip/bip/nep649/nep649_coins.dart';
import 'package:blockchain_utils/protocol/bip/bip/nep649/nep649_const.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// NEP-649 hierarchical deterministic wallet, mirrors `Bip44`.
///
/// Drives `Slip10Mldsa65`: every level is hardened, so `change` and
/// `addressIndex` always harden (unlike `Bip44`, which leaves them
/// non-hardened when public derivation is supported).
class Nep649 extends Nep649Base<Nep649> {
  // private constructor
  Nep649._(super.slip10, super.coinConf);

  /// Constructor for creating a [Nep649] object from a seed and coin.
  Nep649.fromSeed(List<int> seedBytes, Nep649Coins coinType)
    : super.fromSeed(seedBytes, coinType.conf);

  /// Constructor for creating a [Nep649] object from a 32-byte node
  /// secret and coin.
  Nep649.fromPrivateKey(
    List<int> privateKeyBytes,
    Nep649Coins coinType, {
    Bip32KeyData? keyData,
  }) : super.fromPrivateKey(
         privateKeyBytes,
         coinType.conf,
         keyData: keyData ?? Bip32KeyData(),
       );

  /// Constructor for creating a [Nep649] object from a 1952-byte
  /// ML-DSA-65 public key and coin.
  Nep649.fromPublicKey(
    List<int> pubkeyBytes,
    Nep649Coins coinType, {
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
  Nep649 get purpose {
    if (!isLevel(Bip44Levels.master)) {
      throw BuError(DefaultErrorType.invalidArgument,
        "Current depth (${slip10.depth.toInt()}) is not suitable for deriving purpose",
      );
    }
    return Nep649._(
      slip10.childKey(coinConf.purpose ?? Nep649Const.purposeIndex),
      coinConf,
    );
  }

  /// derive default path
  @override
  Nep649 get deriveDefaultPath {
    final Nep649 nepObj = purpose.coin;
    return Nep649._(
      nepObj.slip10.derivePath(nepObj.coinConf.defPath),
      coinConf,
    );
  }

  /// derive coin
  @override
  Nep649 get coin {
    if (!isLevel(Bip44Levels.purpose)) {
      throw BuError(DefaultErrorType.invalidArgument,
        "Current depth (${slip10.depth.toInt()}) is not suitable for deriving coin",
      );
    }
    final coinIndex = coinConf.coinIdx;
    return Nep649._(
      slip10.childKey(Bip32KeyIndex.hardenIndex(coinIndex)),
      coinConf,
    );
  }

  /// derive account with index
  @override
  Nep649 account(int accIndex) {
    if (!isLevel(Bip44Levels.coin)) {
      throw BuError(DefaultErrorType.invalidArgument,
        "Current depth (${slip10.depth.toInt()}) is not suitable for deriving account",
      );
    }
    return Nep649._(
      slip10.childKey(Bip32KeyIndex.hardenIndex(accIndex)),
      coinConf,
    );
  }

  /// derive change with change type [Bip44Changes] internal or external
  @override
  Nep649 change(Bip44Changes changeType) {
    if (!isLevel(Bip44Levels.account)) {
      throw BuError(DefaultErrorType.invalidArgument,
        "Current depth (${slip10.depth.toInt()}) is not suitable for deriving change",
      );
    }
    return Nep649._(
      slip10.childKey(Bip32KeyIndex.hardenIndex(changeType.value)),
      coinConf,
    );
  }

  /// derive address with index
  @override
  Nep649 addressIndex(int addressIndex) {
    if (!isLevel(Bip44Levels.change)) {
      throw BuError(DefaultErrorType.invalidArgument,
        "Current depth (${slip10.depth.toInt()}) is not suitable for deriving address",
      );
    }
    return Nep649._(
      slip10.childKey(Bip32KeyIndex.hardenIndex(addressIndex)),
      coinConf,
    );
  }

  /// Specification name
  @override
  String get specName {
    return Nep649Const.specName;
  }
}
