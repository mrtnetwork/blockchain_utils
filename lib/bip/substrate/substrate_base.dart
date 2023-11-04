import 'package:blockchain_utils/bip/substrate/conf/substrate_coin_conf.dart';
import 'package:blockchain_utils/bip/substrate/conf/substrate_conf.dart';
import 'package:blockchain_utils/bip/substrate/substrate_ex.dart';
import 'package:blockchain_utils/bip/substrate/substrate_keys.dart';
import 'package:blockchain_utils/crypto/crypto/schnorrkel/keys/keys.dart';

import 'conf/substrate_coins.dart';
import 'substrate_path.dart';

/// Constants used in Substrate-related operations.
class SubstrateConst {
  /// The minimum byte length for a seed in Substrate.
  static const int seedMinByteLen = 32;
}

/// A class representing a Substrate context that includes private and public keys,
/// a path, and coin configuration.
class Substrate {
  /// Private key (nullable)
  SubstratePrivateKey? _priveKey;

  /// Public key
  final SubstratePublicKey publicKey;

  /// Path
  final SubstratePath path;

  /// Coin configuration
  final SubstrateCoinConf coinConf;

  /// Private constructor to create a Substrate context.
  Substrate._(this._priveKey, this.publicKey, this.path, this.coinConf);

  /// Create a Substrate context from a seed and coin type.
  factory Substrate.fromSeed(List<int> seedBytes, SubstrateCoins coinType) {
    if (seedBytes.length < SubstrateConst.seedMinByteLen) {
      throw ArgumentError(
        'Seed length is too small, it shall be at least ${SubstrateConst.seedMinByteLen} bytes',
      );
    }

    final seed = seedBytes.sublist(0, SubstrateConst.seedMinByteLen);
    final SchnorrkelMiniSecretKey miniSecretKey =
        SchnorrkelMiniSecretKey.fromBytes(seed);
    final secretKey = miniSecretKey.toSecretKey();

    return Substrate._(
      SubstratePrivateKey.fromBytes(
          secretKey.toBytes(), SubstrateConf.getCoin(coinType)),
      SubstratePublicKey.fromBytes(
          secretKey.publicKey().toBytes(), SubstrateConf.getCoin(coinType)),
      SubstratePath(),
      SubstrateConf.getCoin(coinType),
    );
  }

  /// Create a Substrate context from a seed, path, and coin type.
  factory Substrate.fromSeedAndPath(
      List<int> seedBytes, dynamic path, SubstrateCoins coinType) {
    final substrateCtx = Substrate.fromSeed(seedBytes, coinType);
    return substrateCtx.derivePath(path);
  }

  /// Create a Substrate context from a private key and coin type.
  factory Substrate.fromPrivateKey(
      List<int> privateKey, SubstrateCoins coinType) {
    final prv = SubstratePrivateKey.fromBytes(
        privateKey, SubstrateConf.getCoin(coinType));
    return Substrate._(
      prv,
      SubstratePublicKey.fromBytes(
          prv.privKey.publicKey.compressed, SubstrateConf.getCoin(coinType)),
      SubstratePath(),
      SubstrateConf.getCoin(coinType),
    );
  }

  /// Create a Substrate context from a public key and coin type.
  factory Substrate.fromPublicKey(
      List<int> publicKey, SubstrateCoins coinType) {
    return Substrate._(
      null,
      SubstratePublicKey.fromBytes(publicKey, SubstrateConf.getCoin(coinType)),
      SubstratePath(),
      SubstrateConf.getCoin(coinType),
    );
  }

  /// Get the private key associated with this Substrate context.
  ///
  /// Throws a [SubstrateKeyError] if this context is public-only.
  SubstratePrivateKey get priveKey {
    if (isPublicOnly) {
      throw const SubstrateKeyError(
          'Public-only deterministic keys have no private half');
    }
    return _priveKey!;
  }

  /// Derive a new Substrate context from the current context using the provided path.
  ///
  /// This method creates a child context by applying the path to the current context.
  /// Returns the new Substrate context after applying the path.
  Substrate derivePath(String path) {
    final p = SubstratePathParser.parse(path);

    Substrate substrateObj = this;
    for (final pathElem in p) {
      substrateObj = substrateObj.childKey(pathElem);
    }

    return substrateObj;
  }

  /// Convert this Substrate context to public-only mode.
  ///
  /// Removes the private key, making this context only contain a public key.
  void convertToPublic() {
    _priveKey = null;
  }

  /// Check if this Substrate context is in public-only mode.
  bool get isPublicOnly {
    return _priveKey == null;
  }

  /// Derive a new Substrate context from the current context using the provided path element.
  ///
  /// If this context is not in public-only mode, it uses private child key derivation.
  /// Otherwise, it uses public child key derivation.
  ///
  /// Returns the new Substrate context after deriving the child key.
  Substrate childKey(SubstratePathElem pathElem) {
    return !isPublicOnly ? _ckdPriv(pathElem) : _ckdPub(pathElem);
  }

  /// Perform private child key derivation for the current context.
  Substrate _ckdPriv(SubstratePathElem pathElem) {
    final secret = priveKey.privKey.secretKey;
    SchnorrkelSecretKey result;

    if (pathElem.isHard) {
      result = secret.hardDerive(pathElem.chainCode).$1;
    } else {
      result = secret.softDerive(pathElem.chainCode).$1;
    }
    return Substrate._(
      SubstratePrivateKey.fromBytes(result.toBytes(), coinConf),
      SubstratePublicKey.fromBytes(result.publicKey().toBytes(), coinConf),
      path.addElem(pathElem),
      coinConf,
    );
  }

  /// Perform public child key derivation for the current context.
  Substrate _ckdPub(SubstratePathElem pathElem) {
    if (pathElem.isHard) {
      throw const SubstrateKeyError(
          'Public child derivation cannot be used to create a hardened child key');
    }
    final pubKeyBytes =
        publicKey.pubKey.publicKey.derive(pathElem.chainCode).$1;
    return Substrate._(
      null,
      SubstratePublicKey.fromBytes(pubKeyBytes.toBytes(), coinConf),
      path.addElem(pathElem),
      coinConf,
    );
  }
}
