import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/protocol/bip/bip/eip2334/eip2334_conf.dart';
import 'package:blockchain_utils/protocol/bip/bip/eip2333/eip2333_bls.dart';
import 'package:blockchain_utils/protocol/bip/bip/eip2333/eip2333_key_data.dart';
import 'package:blockchain_utils/protocol/bip/bip/eip2334/eip2334_keys.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// Enumeration of EIP-2334 levels, mirrors `Bip44Levels`.
///
/// `signing` is the validator signing key: child 0 of its `use` (withdrawal)
/// node, i.e. `m/12381/3600/i/0/0`.
enum Eip2334Levels {
  /// Master level
  master(0, "Master"),

  /// Purpose level (12381)
  purpose(1, "Purpose"),

  /// Coin level (3600)
  coin(2, "Coin"),

  /// Account level (i-th validator set)
  account(3, "Account"),

  /// Use level (0 = withdrawal)
  use(4, "Use"),

  /// Signing level (child 0 of withdrawal)
  signing(5, "Signing");

  final int value;
  final String name;
  const Eip2334Levels(this.value, this.name);

  /// Create a [Eip2334Levels] instance from an integer value.
  factory Eip2334Levels.fromInt(int value) {
    return values.firstWhere(
      (e) => e.value == value,
      orElse:
          () =>
              throw CoreErrors.invalidOperationArguments(
                "Eip2334Levels",
                reason: "Invalid EIP-2334 depth.",
              ),
    );
  }

  @override
  String toString() {
    return "Eip2334Levels.$name";
  }
}

/// Abstract base class for EIP-2334 hierarchical deterministic wallets,
/// mirrors `Bip44Base` but drives `Eip2333Bls` (plain indexes only:
/// EIP-2334 paths have no hardened keys).
abstract class Eip2334Base<EIP2334 extends Eip2334Base<EIP2334>>
    with SecretState {
  late final Eip2333Bls eip2333;

  late final Eip2334CoinConfig coinConf;

  /// Constructor for creating a [Eip2334Base] object from a seed and coin.
  Eip2334Base.fromSeed(List<int> seedBytes, Eip2334CoinConfig coin) {
    final node = Eip2333Bls.fromSeed(seedBytes);
    final validate = _validate(node, coin);
    eip2333 = validate.$1;
    coinConf = validate.$2;
  }

  /// Constructor for creating a [Eip2334Base] object from a 32-byte BLS
  /// scalar and coin.
  Eip2334Base.fromPrivateKey(
    List<int> privateKeyBytes,

    Eip2334CoinConfig coin, {
    Eip2333KeyData? keyData,
  }) {
    final node = Eip2333Bls.fromPrivateKey(privateKeyBytes, keyData);
    final validate = _validate(node, coin);
    eip2333 = validate.$1;
    coinConf = validate.$2;
  }

  /// Constructor for creating a [Eip2334Base] object from a 48-byte G1
  /// public key and coin.
  Eip2334Base.fromPublicKey(
    List<int> pubkeyBytes,

    Eip2334CoinConfig coin, {
    Eip2333KeyData? keyData,
  }) {
    final node = Eip2333Bls.fromPublicKey(pubkeyBytes, keyData);
    final validate = _validate(node, coin);
    eip2333 = validate.$1;
    coinConf = validate.$2;
  }

  /// Internal validation method for checking the depth of the EIP-2334 object.
  static (Eip2333Bls, Eip2334CoinConfig) _validate(
    Eip2333Bls node,
    Eip2334CoinConfig coinConf,
  ) {
    final int depth = node.depth.depth;

    if (node.isPublicOnly) {
      if (depth < Eip2334Levels.account.value ||
          depth > Eip2334Levels.signing.value) {
        throw BuError(DefaultErrorType.invalidArgument,
          "Depth of the public-only Eip2334 object ($depth) is below account level or beyond signing level",
        );
      }
    } else {
      if (depth < 0 || depth > Eip2334Levels.signing.value) {
        throw BuError(DefaultErrorType.invalidArgument,
          "Depth of the Eip2334 object ($depth) is invalid or beyond signing level",
        );
      }
    }

    return (node, coinConf);
  }

  /// Constructor for creating a [Eip2334Base] object from a [Eip2333Bls]
  /// node and coin [Eip2334CoinConfig].
  Eip2334Base(this.eip2333, this.coinConf) {
    _validate(eip2333, coinConf);
  }

  /// [Eip2334PublicKey] public key
  Eip2334PublicKey get publicKey {
    return Eip2334PublicKey(eip2333.publicKey, coinConf);
  }

  /// [Eip2334PrivateKey] privatekey
  Eip2334PrivateKey get privateKey {
    if (eip2333.isPublicOnly) {
      throw const BuError(DefaultErrorType.invalidArgument,"The Eip2333Bls object is public-only");
    }
    return Eip2334PrivateKey(eip2333.privateKey, coinConf);
  }

  Eip2333Bls get eip2333Object => eip2333;

  /// check if is public only
  bool get isPublicOnly => eip2333.isPublicOnly;

  /// [Eip2334Levels] level
  Eip2334Levels get level {
    return Eip2334Levels.fromInt(eip2333.depth.depth);
  }

  /// check level with current eip-2334 level
  bool isLevel(Eip2334Levels level) {
    return eip2333.depth.depth == level.value;
  }

  /// derive default path (first withdrawal key)
  EIP2334 get deriveDefaultPath;

  /// derive purpose
  EIP2334 get purpose;

  /// derive coin
  EIP2334 get coin;

  /// derive account with index (i-th validator set)
  EIP2334 account(int accIndex);

  /// derive use with index (0 = withdrawal)
  EIP2334 use(int useIndex);

  /// derive signing key (child 0 of the withdrawal node)
  EIP2334 get signingKey;

  /// spec name
  String get specName;

  @override
  void dispose() {
    eip2333.dispose();
  }
}
