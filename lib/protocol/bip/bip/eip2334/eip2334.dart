library;

export 'package:blockchain_utils/protocol/bip/bip/eip2334/eip2334_base.dart';
export 'package:blockchain_utils/protocol/bip/bip/eip2334/eip2334_coins.dart';
export 'package:blockchain_utils/protocol/bip/bip/eip2334/eip2334_conf.dart';
export 'package:blockchain_utils/protocol/bip/bip/eip2334/eip2334_const.dart';
export 'package:blockchain_utils/protocol/bip/bip/eip2334/eip2334_keys.dart';

import 'package:blockchain_utils/protocol/bip/bip/eip2333/eip2333_key_data.dart';
import 'package:blockchain_utils/protocol/bip/bip/eip2334/eip2334_base.dart';
import 'package:blockchain_utils/protocol/bip/bip/eip2334/eip2334_coins.dart';
import 'package:blockchain_utils/protocol/bip/bip/eip2334/eip2334_const.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// EIP-2334 hierarchical deterministic wallet, mirrors `Bip44`.
///
/// Drives `Eip2333Bls`: all indexes are plain (EIP-2334 paths have no
/// hardened keys). Navigation: `purpose / coin / account(i) / use(j)`,
/// with `signingKey` as child 0 of the withdrawal (`use`) node.
class Eip2334 extends Eip2334Base<Eip2334> {
  // private constructor
  Eip2334._(super.eip2333, super.coinConf);

  /// Constructor for creating a [Eip2334] object from a seed and coin.
  Eip2334.fromSeed(List<int> seedBytes, Eip2334Coins coinType)
    : super.fromSeed(seedBytes, coinType.conf);

  /// Constructor for creating a [Eip2334] object from a 32-byte BLS
  /// scalar and coin.
  Eip2334.fromPrivateKey(
    List<int> privateKeyBytes,
    Eip2334Coins coinType, {
    Eip2333KeyData? keyData,
  }) : super.fromPrivateKey(
         privateKeyBytes,
         coinType.conf,
         keyData: keyData ?? Eip2333KeyData(),
       );

  /// Constructor for creating a [Eip2334] object from a 48-byte G1
  /// public key and coin.
  Eip2334.fromPublicKey(
    List<int> pubkeyBytes,
    Eip2334Coins coinType, {
    Eip2333KeyData? keyData,
  }) : super.fromPublicKey(
         pubkeyBytes,
         coinType.conf,
         keyData:
             keyData ??
             Eip2333KeyData(depth: Eip2333Depth(Eip2334Levels.account.value)),
       );

  /// derive purpose
  @override
  Eip2334 get purpose {
    if (!isLevel(Eip2334Levels.master)) {
      throw BuError(DefaultErrorType.invalidArgument,
        "Current depth (${eip2333.depth.toInt()}) is not suitable for deriving purpose",
      );
    }
    return Eip2334._(eip2333.childKey(Eip2334Const.purposeIndex), coinConf);
  }

  /// derive default path (first withdrawal key `m/12381/3600/0/0`)
  @override
  Eip2334 get deriveDefaultPath {
    final Eip2334 eipObj = purpose.coin;
    return Eip2334._(
      eipObj.eip2333.derivePath(eipObj.coinConf.defPath),
      coinConf,
    );
  }

  /// derive coin
  @override
  Eip2334 get coin {
    if (!isLevel(Eip2334Levels.purpose)) {
      throw BuError(DefaultErrorType.invalidArgument,
        "Current depth (${eip2333.depth.toInt()}) is not suitable for deriving coin",
      );
    }
    final coinIndex = coinConf.coinIdx;
    return Eip2334._(eip2333.childKey(Eip2333KeyIndex(coinIndex)), coinConf);
  }

  /// derive account with index (i-th validator set)
  @override
  Eip2334 account(int accIndex) {
    if (!isLevel(Eip2334Levels.coin)) {
      throw BuError(DefaultErrorType.invalidArgument,
        "Current depth (${eip2333.depth.toInt()}) is not suitable for deriving account",
      );
    }
    return Eip2334._(eip2333.childKey(Eip2333KeyIndex(accIndex)), coinConf);
  }

  /// derive use with index (0 = withdrawal)
  @override
  Eip2334 use(int useIndex) {
    if (!isLevel(Eip2334Levels.account)) {
      throw BuError(DefaultErrorType.invalidArgument,
        "Current depth (${eip2333.depth.toInt()}) is not suitable for deriving use",
      );
    }
    return Eip2334._(eip2333.childKey(Eip2333KeyIndex(useIndex)), coinConf);
  }

  /// derive signing key (child 0 of the withdrawal node)
  @override
  Eip2334 get signingKey {
    if (!isLevel(Eip2334Levels.use)) {
      throw BuError(DefaultErrorType.invalidArgument,
        "Current depth (${eip2333.depth.toInt()}) is not suitable for deriving signing key",
      );
    }
    return Eip2334._(
      eip2333.childKey(Eip2333KeyIndex(Eip2334Const.signingUse)),
      coinConf,
    );
  }

  /// Specification name
  @override
  String get specName {
    return Eip2334Const.specName;
  }
}
