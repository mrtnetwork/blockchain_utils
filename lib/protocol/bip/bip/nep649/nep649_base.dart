import 'package:blockchain_utils/protocol/bip/bip/bip32/bip32_key_data.dart';
import 'package:blockchain_utils/protocol/bip/bip/bip44/base/bip44_base.dart'
    show Bip44Changes, Bip44Levels;
import 'package:blockchain_utils/protocol/bip/bip/bip32/slip10/slip10_mldsa65.dart';

import 'package:blockchain_utils/protocol/bip/bip/nep649/nep649_conf.dart';
import 'package:blockchain_utils/protocol/bip/bip/nep649/nep649_keys.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// Abstract base class for NEP-649 hierarchical deterministic wallets,
/// mirrors `Bip44Base` but drives `Slip10Mldsa65` (all levels hardened).
abstract class Nep649Base<NEP649 extends Nep649Base<NEP649>> with SecretState {
  late final Slip10Mldsa65 slip10;

  late final Nep649CoinConfig coinConf;

  Nep649Base.fromSeed(List<int> seedBytes, Nep649CoinConfig coin) {
    final node = Slip10Mldsa65.fromSeed(seedBytes);
    final validate = _validate(node, coin);
    slip10 = validate.$1;
    coinConf = validate.$2;
  }

  /// Constructor for creating a [Nep649Base] object from a 32-byte node
  /// secret and coin.
  Nep649Base.fromPrivateKey(
    List<int> privateKeyBytes,
    Nep649CoinConfig coin, {
    Bip32KeyData? keyData,
  }) {
    final node = Slip10Mldsa65.fromNodeSecret(privateKeyBytes, keyData);
    final validate = _validate(node, coin);
    slip10 = validate.$1;
    coinConf = validate.$2;
  }

  /// Constructor for creating a [Nep649Base] object from a 1952-byte
  /// ML-DSA-65 public key and coin.
  Nep649Base.fromPublicKey(
    List<int> pubkeyBytes,
    Nep649CoinConfig coin, {
    Bip32KeyData? keyData,
  }) {
    final node = Slip10Mldsa65.fromPublicKey(pubkeyBytes, keyData);
    final validate = _validate(node, coin);
    slip10 = validate.$1;
    coinConf = validate.$2;
  }
  static (Slip10Mldsa65, Nep649CoinConfig) _validate(
    Slip10Mldsa65 node,

    Nep649CoinConfig coinConf,
  ) {
    final int depth = node.depth.depth;

    if (node.isPublicOnly) {
      if (depth < Bip44Levels.account.value ||
          depth > Bip44Levels.addressIndex.value) {
        throw BuError(DefaultErrorType.invalidArgument,
          "Depth of the public-only Nep649 object ($depth) is below account level or beyond address index level",
        );
      }
    } else {
      if (depth < 0 || depth > Bip44Levels.addressIndex.value) {
        throw BuError(DefaultErrorType.invalidArgument,
          "Depth of the Nep649 object ($depth) is invalid or beyond address index level",
        );
      }
    }

    return (node, coinConf);
  }

  /// Constructor for creating a [Nep649Base] object from a [Slip10Mldsa65]
  /// node and coin [Nep649CoinConfig].
  Nep649Base(this.slip10, this.coinConf) {
    _validate(slip10, coinConf);
  }

  /// [Nep649PublicKey] public key
  Nep649PublicKey get publicKey {
    return Nep649PublicKey(slip10.publicKey, coinConf);
  }

  /// [Nep649PrivateKey] privatekey
  Nep649PrivateKey get privateKey {
    if (slip10.isPublicOnly) {
      throw const BuError(DefaultErrorType.invalidArgument,"The Slip10Mldsa65 object is public-only");
    }
    return Nep649PrivateKey(slip10.privateKey, coinConf);
  }

  Slip10Mldsa65 get slip10Object => slip10;

  /// check if is public only
  bool get isPublicOnly => slip10.isPublicOnly;

  /// [Bip44Levels] level
  Bip44Levels get level {
    return Bip44Levels.fromInt(slip10.depth.depth);
  }

  /// check level with current level
  bool isLevel(Bip44Levels level) {
    return slip10.depth.depth == level.value;
  }

  /// derive default path
  NEP649 get deriveDefaultPath;

  /// derive purpose
  NEP649 get purpose;

  /// derive coin
  NEP649 get coin;

  /// derive account with index
  NEP649 account(int accIndex);

  /// derive change with change type [Bip44Changes] internal or external
  NEP649 change(Bip44Changes changeType);

  /// derive address with index
  NEP649 addressIndex(int addressIndex);

  /// spec name
  String get specName;

  @override
  void dispose() {
    slip10.dispose();
  }
}
