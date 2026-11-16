import 'package:blockchain_utils/protocol/bip/bip/bip32/base/derivator.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/protocol/bip/bip/bip32/bip32_key_data.dart';
import 'package:blockchain_utils/protocol/bip/bip/bip32/bip32_key_net_ver.dart';
import 'package:blockchain_utils/protocol/bip/bip/bip32/bip32_key_ser.dart';
import 'package:blockchain_utils/protocol/bip/bip/bip32/bip32_keys.dart';
import 'package:blockchain_utils/protocol/bip/bip/bip32/bip32_path.dart';
import 'package:blockchain_utils/protocol/hd_key/types.dart';

import 'package:blockchain_utils/crypto/crypto/keys/types/types.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/helper/helper.dart';

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// An abstract base class for BIP-32 hierarchical deterministic key management.
abstract class Bip32Base<BIP extends Bip32Base<BIP>>
    with SecretState
    implements HDKeyManager<Bip32KeyBase, Bip32KeyBase, Bip32KeyIndex, BIP> {
  Bip32PrivateKey? _privKey;
  @override
  late final Bip32PublicKey publicKey;

  /// Gets the private key of this BIP-32 key.
  @override
  Bip32PrivateKey get privateKey {
    final key = _privKey;
    if (isPublicOnly || key == null) {
      throw const BuError(DefaultErrorType.invalidKeyData,
        'Public-only deterministic keys have no private half',
      );
    }
    return key;
  }

  /// Initializes a private key if [privKey] is provided, otherwise returns null.
  static Bip32PrivateKey? _initializePrivateKey(
    List<int>? privKey,
    List<int>? pubKey,
    Bip32KeyData keyData,
    Bip32KeyNetVersions keyNetVer,
    CryptoKeyType type,
  ) {
    if (privKey != null) {
      return Bip32PrivateKey.fromBytes(privKey, keyData, keyNetVer, type);
    }
    return null;
  }

  /// Initializes a public key based on [privKey] or [pubKey].
  static Bip32PublicKey _initializePublicKey(
    List<int>? privKey,
    List<int>? pubKey,
    Bip32KeyData keyData,
    Bip32KeyNetVersions keyNetVer,
    CryptoKeyType type,
  ) {
    if (privKey != null) {
      final bip32PrivateKey = Bip32PrivateKey.fromBytes(
        privKey,
        keyData,
        keyNetVer,
        type,
      );
      return bip32PrivateKey.publicKey;
    } else {
      if (pubKey == null) {
        throw BuError(DefaultErrorType.badPublicKey,'Missing public key.');
      }
      return Bip32PublicKey.fromBytes(pubKey, keyData, keyNetVer, type);
    }
  }

  /// Creates a BIP-32 key from an extended key string.
  ///
  /// The [exKeyStr] parameter represents the extended key string, and the
  /// optional [keyNetVer] specifies the key network version.
  Bip32Base.fromExtendedKey(String exKeyStr, [Bip32KeyNetVersions? keyNetVer]) {
    keyNetVer ??= defaultKeyNetVersion;
    final deserKey = Bip32KeyDeserializer.deserializeKey(
      exKeyStr,
      keyNetVer: keyNetVer,
    );

    BuBytes keyBytes = deserKey.toBytes();
    final Bip32KeyData keyData = deserKey.keyData;
    final isPublic = deserKey.isPublic;
    if (isPublic) {
      keyBytes = Bip32KeyDeserializer.deserializePublicKey(keyBytes, type);
    }

    if (keyData.depth.depth == 0) {
      if (!keyData.fingerPrint.isMasterKey()) {
        throw BuError(DefaultErrorType.invalidArgument,'Invalid extended master fingerPrint.');
      }
      if (keyData.index.index != 0) {
        throw BuError(DefaultErrorType.invalidArgument,'Invalid extended master child index.');
      }
    }
    _privKey = _initializePrivateKey(
      isPublic ? null : keyBytes,
      isPublic ? keyBytes : null,
      keyData,
      keyNetVer,
      type,
    );
    publicKey = _initializePublicKey(
      isPublic ? null : keyBytes,
      isPublic ? keyBytes : null,
      keyData,
      keyNetVer,
      type,
    );
    keyBytes.forceZero();
  }

  /// Creates a BIP-32 key from an extended key bytese.
  Bip32Base.fromExtendedPrivateKeyBytes(
    List<int> key, [
    Bip32KeyNetVersions? keyNetVer,
  ]) {
    keyNetVer ??= defaultKeyNetVersion;
    final deserKey = Bip32KeyDeserializer.deserializeKeyBytes(
      serKeyBytes: key,
      isPublic: false,
      withPrefix: false,
    );
    BuBytes keyBytes = deserKey.toBytes();
    final Bip32KeyData keyData = deserKey.keyData;
    if (deserKey.isPublic) {
      throw BuError(DefaultErrorType.unsupported,"Unsupported extended public key.");
    }
    if (keyData.depth.depth == 0) {
      if (!keyData.fingerPrint.isMasterKey()) {
        throw BuError(DefaultErrorType.invalidArgument,'Invalid extended master fingerPrint.');
      }
      if (keyData.index.index != 0) {
        throw BuError(DefaultErrorType.invalidArgument,'Invalid extended master child index.');
      }
    }
    _privKey = _initializePrivateKey(keyBytes, null, keyData, keyNetVer, type);
    publicKey = _initializePublicKey(keyBytes, null, keyData, keyNetVer, type);

    keyBytes.forceZero();
  }

  /// Creates a BIP-32 key from a seed.
  ///
  /// The [seedBytes] parameter is used to generate a master key, and the
  /// optional [keyNetVer] specifies the key network version.
  Bip32Base.fromSeed(List<int> seedBytes, [Bip32KeyNetVersions? keyNetVer]) {
    seedBytes = seedBytes.asImmutableBytes;
    keyNetVer ??= defaultKeyNetVersion;
    final result = masterKeyGenerator.generateFromSeed(seedBytes);
    final keyData = Bip32KeyData(chainCode: result.chainCode);
    _privKey = _initializePrivateKey(
      result.key,
      null,
      keyData,
      keyNetVer,
      type,
    );
    publicKey = _initializePublicKey(
      result.key,
      null,
      keyData,
      keyNetVer,
      type,
    );
  }

  /// Creates a BIP-32 key from a private key.
  ///
  /// The [privKey] parameter represents the private key bytes, and the optional
  /// [keyData] and [keyNetVer] parameters specify key data and network versions.
  Bip32Base.fromPrivateKey(
    List<int> privKey, [
    Bip32KeyData? keyData,
    Bip32KeyNetVersions? keyNetVer,
  ]) {
    privKey = privKey.asImmutableBytes;
    keyNetVer ??= defaultKeyNetVersion;
    keyData ??= Bip32KeyData();
    _privKey = _initializePrivateKey(privKey, null, keyData, keyNetVer, type);
    publicKey = _initializePublicKey(privKey, null, keyData, keyNetVer, type);
  }

  /// Creates a BIP-32 key from a public key.
  ///
  /// The [pubKey] parameter represents the public key bytes, and the optional
  /// [keyData] and [keyNetVer] parameters specify key data and network versions.
  Bip32Base.fromPublicKey(
    List<int> pubKey, [
    Bip32KeyData? keyData,
    Bip32KeyNetVersions? keyNetVer,
  ]) {
    pubKey = pubKey.asImmutableBytes;
    keyNetVer ??= defaultKeyNetVersion;
    keyData ??= Bip32KeyData();
    _privKey = _initializePrivateKey(null, pubKey, keyData, keyNetVer, type);
    publicKey = _initializePublicKey(null, pubKey, keyData, keyNetVer, type);
  }

  /// Creates a BIP-32 key from provided parameters.
  ///
  /// The [privKey] and [pubKey] parameters represent private and public key bytes,
  /// while [keyData] and [keyNetVer] specify key data and network versions.
  Bip32Base({
    required List<int>? privKey,
    required List<int>? pubKey,
    required Bip32KeyData keyData,
    required Bip32KeyNetVersions keyNetVer,
  }) {
    _privKey = _initializePrivateKey(privKey, pubKey, keyData, keyNetVer, type);
    publicKey = _initializePublicKey(privKey, pubKey, keyData, keyNetVer, type);
  }

  /// Derives a new BIP-32 key using a derivation path.
  ///
  /// The [path] parameter represents the derivation path, such as "m/0/1/2".
  @override
  BIP derivePath(String path) {
    final pathInstance = Bip32PathParser.parse(path);

    if (depth.depth > 0 && pathInstance.isAbsolute) {
      throw CoreErrors.invalidOperationArguments(
        "derivePath",
        name: "path",
        reason:
            'Absolute paths can only be derived from a master key, not child ones',
      );
    }
    BIP derivedObject = this as BIP;
    for (final pathElement in pathInstance.elems) {
      final parent = derivedObject;
      derivedObject = parent.childKey(pathElement);

      if (!identical(parent, this)) {
        parent.dispose();
      }
    }
    return derivedObject;
  }

  /// Derives a child BIP-32 key from the current key.
  @override
  BIP childKey(Bip32KeyIndex index);

  /// Converts this BIP-32 key to a public-only key.
  void convertToPublic({bool disposeKey = true}) {
    if (disposeKey) {
      _privKey?.dispose();
    }
    _privKey = null;
  }

  /// Checks if this key is public-only.
  bool get isPublicOnly {
    return _privKey == null;
  }

  /// Gets the key network versions.
  Bip32KeyNetVersions get keyNetVersions {
    return publicKey.keyNetVer;
  }

  /// Gets the current depth of this key.
  Bip32Depth get depth {
    return publicKey.keyData.depth;
  }

  /// Gets the current index of this key.
  Bip32KeyIndex get index {
    return publicKey.keyData.index;
  }

  /// Gets the chain code associated with this key.
  Bip32ChainCode get chainCode {
    return publicKey.keyData.chainCode;
  }

  /// Get public key fingerprint.
  Bip32FingerPrint get fingerPrint {
    return publicKey.fingerPrint;
  }

  /// Gets the parent fingerprint of this key.
  Bip32FingerPrint get parentFingerPrint {
    return publicKey.keyData.fingerPrint;
  }

  /// Checks if public derivation is supported for this key.
  bool get isPublicDerivationSupported {
    return keyDerivator.isPublicDerivationSupported();
  }

  /// Gets the elliptic curve type for this key.
  CryptoKeyType get type;

  /// Gets the default key network version.
  Bip32KeyNetVersions get defaultKeyNetVersion;

  /// Gets the key derivator for this key.
  IBip32ChildKeyDerivator get keyDerivator;

  /// Gets the master key generator for this key.
  IBip32MstKeyGenerator get masterKeyGenerator;

  @override
  void dispose() {
    convertToPublic(disposeKey: true);
  }
}
