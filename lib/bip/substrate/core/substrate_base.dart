import 'package:blockchain_utils/bip/ecc/bip_ecc.dart';
import 'package:blockchain_utils/bip/substrate/conf/substrate_coin_conf.dart';
import 'package:blockchain_utils/bip/substrate/conf/substrate_coins.dart';
import 'package:blockchain_utils/bip/substrate/exception/substrate_ex.dart';
import 'package:blockchain_utils/bip/substrate/keys/substrate_keys.dart';
import 'package:blockchain_utils/bip/substrate/path/substrate_path.dart';
import 'package:blockchain_utils/crypto/crypto/schnorrkel/keys/keys.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/exception/exception.dart';

/// Constants used in Substrate-related operations.
class SubstrateConst {
  /// The minimum byte length for a seed in Substrate.
  static const int seedMinByteLen = 32;
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
    68
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
    68
  ];
}

class _SubstrateUtils {
  static List<int> getSecretKey(List<int> seedBytes, EllipticCurveTypes curve) {
    if (seedBytes.length < SubstrateConst.seedMinByteLen) {
      throw const ArgumentException(
        'Seed length is too small, it shall be at least ${SubstrateConst.seedMinByteLen} bytes',
      );
    }
    final seed = seedBytes.sublist(0, SubstrateConst.seedMinByteLen);
    if (curve == EllipticCurveTypes.sr25519) {
      final SchnorrkelMiniSecretKey miniSecretKey =
          SchnorrkelMiniSecretKey.fromBytes(seed);
      final secretKey = miniSecretKey.toSecretKey();
      return secretKey.toBytes();
    }
    return seed;
  }
}

/// A class representing a Substrate context that includes private and public keys,
/// a path, and coin configuration.
class Substrate {
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
    final secretKey =
        _SubstrateUtils.getSecretKey(seedBytes, coinType.conf.type);
    final privateKey = SubstratePrvKey.fromBytes(secretKey, coinType.conf);
    return Substrate._(
        privateKey, privateKey.publicKey, SubstratePath(), coinType.conf);
  }

  /// Create a Substrate context from a seed, path, and coin type.
  factory Substrate.fromSeedAndPath(
      List<int> seedBytes, dynamic path, SubstrateCoins coinType) {
    final substrateCtx = Substrate.fromSeed(seedBytes, coinType);
    return substrateCtx.derivePath(path);
  }

  /// Create a Substrate context from a private key and coin type.
  factory Substrate.fromPrivateKey(
      List<int> privateKeyBytes, SubstrateCoins coinType) {
    final privateKey =
        SubstratePrvKey.fromBytes(privateKeyBytes, coinType.conf);

    return Substrate._(
      privateKey,
      privateKey.publicKey,
      SubstratePath(),
      coinType.conf,
    );
  }

  /// Create a Substrate context from a public key and coin type.
  factory Substrate.fromPublicKey(
      List<int> publicKey, SubstrateCoins coinType) {
    return Substrate._(
      null,
      SubstratePubKey.fromBytes(keyBytes: publicKey, coinConf: coinType.conf),
      SubstratePath(),
      coinType.conf,
    );
  }

  /// Get the private key associated with this Substrate context.
  ///
  /// Throws a [SubstrateKeyError] if this context is public-only.
  SubstratePrvKey get priveKey {
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

  Substrate _ckdPrivSr25519(SubstratePathElem pathElem) {
    final secret = (priveKey.privKey as Sr25519PrivateKey).secretKey;
    SchnorrkelSecretKey result;

    if (pathElem.isHard) {
      result = secret.hardDerive(pathElem.chainCode).item1;
    } else {
      result = secret.softDerive(pathElem.chainCode).item1;
    }
    final privateKey = SubstratePrvKey.fromBytes(result.toBytes(), coinConf);
    return Substrate._(
      privateKey,
      privateKey.publicKey,
      path.addElem(pathElem),
      coinConf,
    );
  }

  /// Perform private child key derivation for the current context.
  Substrate _ckdPriv(SubstratePathElem pathElem) {
    if (publicKey.coinConf.type == EllipticCurveTypes.sr25519) {
      return _ckdPrivSr25519(pathElem);
    }
    // if (!pathElem.isHard) {
    //   throw const SubstrateKeyError(
    //       'Public child derivation cannot be used to create a hardened child key');
    // }
    List<int> hdkd = publicKey.coinConf.type == EllipticCurveTypes.ed25519
        ? SubstrateConst.hdkd
        : SubstrateConst.secp256k1HDKD;
    final key = QuickCrypto.blake2b256Hash([
      ...hdkd,
      ..._priveKey!.raw,
      ...pathElem.chainCode,
    ]);
    final privateKey = SubstratePrvKey.fromBytes(key, coinConf);
    return Substrate._(
      privateKey,
      privateKey.publicKey,
      path.addElem(pathElem),
      coinConf,
    );
  }

  Substrate _ckdPubSr25519(SubstratePathElem pathElem) {
    final SchnorrkelPublicKey key =
        (publicKey.pubKey as Sr25519PublicKey).publicKey;
    final pubKeyBytes = key.derive(pathElem.chainCode).item1;
    return Substrate._(
      null,
      SubstratePubKey.fromBytes(
          keyBytes: pubKeyBytes.toBytes(), coinConf: coinConf),
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
    if (publicKey.coinConf.type == EllipticCurveTypes.sr25519) {
      return _ckdPubSr25519(pathElem);
    }
    throw SubstrateKeyError(
        "Public key drivation is not support in substrate ${publicKey.pubKey.curve.name}");
  }
}
