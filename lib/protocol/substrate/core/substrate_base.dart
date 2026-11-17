import 'package:blockchain_utils/protocol/substrate/conf/substrate_coin_conf.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/protocol/substrate/conf/substrate_coins.dart';
import 'package:blockchain_utils/protocol/substrate/keys/substrate_keys.dart';
import 'package:blockchain_utils/protocol/substrate/path/substrate_path.dart';
import 'package:blockchain_utils/crypto/crypto/keys/sr25519/keys/keys.dart';
import 'package:blockchain_utils/crypto/crypto/keys/sr25519/keys/types.dart';
import 'package:blockchain_utils/crypto/crypto/keys/types/types.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/exception/exceptions.dart';

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// Constants used in Substrate-related operations.
class SubstrateConst {
  /// The minimum byte length for a seed in Substrate. Longer seeds are
  /// silently truncated to this length by `getSecretKey` — pass exactly
  static const int seedMinByteLen = 32;

  /// Domain-separation prefixes for hard-derive KDF ("Ed25519HDKD" ASCII).
  static const List<int> hdkd = [
    44,
    69,
    100,
    50,
    53,
    53,
    49,
    57,
    72,
    68,
    75,
    68,
  ];
  static const List<int> secp256k1HDKD = [
    52,
    83,
    101,
    99,
    112,
    50,
    53,
    54,
    107,
    49,
    72,
    68,
    75,
    68,
  ];
}

class _SubstrateUtils {
  static SecretBytes getSecretKey(List<int> seedBytes, CryptoKeyType curve) {
    if (seedBytes.length < SubstrateConst.seedMinByteLen) {
      throw CoreErrors.invalidOperationArguments(
        "getSecretKey",
        name: "seedBytes",
        reason: "Invalid seed length.",
      );
    }
    final seed = seedBytes.sublist(0, SubstrateConst.seedMinByteLen);
    if (curve == CryptoKeyType.sr25519) {
      final SchnorrkelMiniSecretKey miniSecretKey = SchnorrkelMiniSecretKey(
        seed,
      );
      final secretKey = miniSecretKey.toSecretKey();
      return SecretBytes.take(secretKey.toBytes());
    }
    return SecretBytes.take(seed);
  }
}

/// A class representing a Substrate context that includes private and public keys,
/// a path, and coin configuration.
class Substrate with SecretState {
  /// Private key (nullable)
  SubstratePrvKey? _priveKey;

  /// Public key
  final SubstratePubKey publicKey;

  /// Path
  final SubstratePath path;

  /// Coin configuration
  final SubstrateCoinConf coinConf;

  /// Private constructor to create a Substrate context.
  Substrate._(this._priveKey, this.publicKey, this.path, this.coinConf);

  /// Create a Substrate context from a seed and coin type.
  factory Substrate.fromSeed(List<int> seedBytes, SubstrateCoins coinType) {
    final secretKey = _SubstrateUtils.getSecretKey(
      seedBytes,
      coinType.conf.type,
    );
    try {
      final privateKey = SubstratePrvKey.fromBytes(secretKey, coinType.conf);
      return Substrate._(
        privateKey,
        privateKey.publicKey,
        SubstratePath(),
        coinType.conf,
      );
    } finally {
      secretKey.zero();
    }
  }

  /// Create a Substrate context from a seed, path, and coin type.
  factory Substrate.fromSeedAndPath(
    List<int> seedBytes,
    String path,
    SubstrateCoins coinType,
  ) {
    final substrateCtx = Substrate.fromSeed(seedBytes, coinType);
    return substrateCtx.derivePath(path);
  }

  /// Create a Substrate context from a private key and coin type.
  factory Substrate.fromPrivateKey(
    List<int> privateKeyBytes,
    SubstrateCoins coinType,
  ) {
    final privateKey = SubstratePrvKey.fromBytes(
      privateKeyBytes,
      coinType.conf,
    );

    return Substrate._(
      privateKey,
      privateKey.publicKey,
      SubstratePath(),
      coinType.conf,
    );
  }

  /// Create a Substrate context from a public key and coin type.
  factory Substrate.fromPublicKey(
    List<int> publicKey,
    SubstrateCoins coinType,
  ) {
    return Substrate._(
      null,
      SubstratePubKey.fromBytes(keyBytes: publicKey, coinConf: coinType.conf),
      SubstratePath(),
      coinType.conf,
    );
  }

  CryptoKeyType get type => coinConf.type;

  /// Get the private key associated with this Substrate context.
  ///
  /// Throws a [SubstrateKeyError] if this context is public-only.
  SubstratePrvKey get priveKey {
    final priv = _priveKey;
    if (priv == null) {
      throw const BuError(
        DefaultErrorType.invalidKeyData,
        'Public-only deterministic keys have no private half',
      );
    }
    return priv;
  }

  /// Derive a new Substrate context from the current context using the provided path.
  ///
  /// This method creates a child context by applying the path to the current context.
  /// Returns the new Substrate context after applying the path.
  Substrate derivePath(String path) {
    final pathInstance = SubstratePathParser.parse(path);
    Substrate substrateObj = this;
    for (final pathElement in pathInstance.elems) {
      final parent = substrateObj;
      substrateObj = parent.childKey(pathElement);

      if (!identical(parent, this)) {
        parent.dispose();
      }
    }
    return substrateObj;
  }

  /// Convert this Substrate context to public-only mode.
  ///
  /// Removes the private key, making this context only contain a public key.
  void convertToPublic({bool disposeKey = true}) {
    if (disposeKey) {
      _priveKey?.dispose();
    }
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

  Substrate _ckdPrivSr25519(SubstratePathElem pathElem) {
    final secret = (priveKey.privKey as SR25519PrivateKey);
    SR25519PrivateKey result;

    if (pathElem.isHard) {
      result = secret.hardDerive(pathElem.chainCode).$1;
    } else {
      result = secret.softDerive(pathElem.chainCode).$1;
    }
    final privateKey = SubstratePrvKey.fromPrivateKey(result, coinConf);
    return Substrate._(
      privateKey,
      privateKey.publicKey,
      path.addElem(pathElem),
      coinConf,
    );
  }

  /// Perform private child key derivation for the current context.
  Substrate _ckdPriv(SubstratePathElem pathElem) {
    if (publicKey.coinConf.type == CryptoKeyType.sr25519) {
      return _ckdPrivSr25519(pathElem);
    }

    final List<int> hdkd =
        publicKey.coinConf.type == CryptoKeyType.ed25519
            ? SubstrateConst.hdkd
            : SubstrateConst.secp256k1HDKD;
    final key = _priveKey!.toBytes().useValue((k) {
      return QuickCrypto.blake2b256Hash([...hdkd, ...k, ...pathElem.chainCode]);
    }, zero: true);
    try {
      final privateKey = SubstratePrvKey.fromBytes(key, coinConf);
      return Substrate._(
        privateKey,
        privateKey.publicKey,
        path.addElem(pathElem),
        coinConf,
      );
    } finally {
      key.forceZero();
    }
  }

  Substrate _ckdPubSr25519(SubstratePathElem pathElem) {
    final SR25519PublicKey key = (publicKey.pubKey as SR25519PublicKey);
    final pubKeyBytes = key.derive(pathElem.chainCode).$1;
    return Substrate._(
      null,
      SubstratePubKey.fromPublicKey(publicKey: pubKeyBytes, coinConf: coinConf),
      path.addElem(pathElem),
      coinConf,
    );
  }

  /// Perform public child key derivation for the current context.
  Substrate _ckdPub(SubstratePathElem pathElem) {
    if (pathElem.isHard) {
      throw const BuError(
        DefaultErrorType.unsupported,
        "Public child derivation with hardened index is not supported.",
      );
    }
    if (publicKey.coinConf.type == CryptoKeyType.sr25519) {
      return _ckdPubSr25519(pathElem);
    }
    throw BuError(
      DefaultErrorType.unsupported,
      "Public child derivation is not supported.",
    );
  }

  @override
  void dispose() {
    convertToPublic(disposeKey: true);
  }
}
