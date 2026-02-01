import 'package:blockchain_utils/bip/bip/bip32/base/derivator.dart';
import 'package:blockchain_utils/bip/bip/bip32/bip32_ex.dart';
import 'package:blockchain_utils/bip/bip/bip32/bip32_key_data.dart';
import 'package:blockchain_utils/bip/bip/bip32/bip32_key_net_ver.dart';
import 'package:blockchain_utils/bip/bip/bip32/bip32_key_ser.dart';
import 'package:blockchain_utils/bip/bip/bip32/bip32_keys.dart';
import 'package:blockchain_utils/bip/bip/bip32/bip32_path.dart';
import 'package:blockchain_utils/bip/bip/hd_key/types.dart';

import 'package:blockchain_utils/bip/ecc/curve/elliptic_curve_types.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/helper/helper.dart';

/// An abstract base class for BIP-32 hierarchical deterministic key management.
abstract class Bip32Base<BIP extends Bip32Base<BIP>>
    implements HDKeyManager<Bip32KeyBase, Bip32KeyBase, Bip32KeyIndex, BIP> {
  late Bip32PrivateKey? _privKey;
  late Bip32PublicKey _pubKey;

  /// Gets the public key of this BIP-32 key.
  @override
  Bip32PublicKey get publicKey => _pubKey;

  /// Gets the private key of this BIP-32 key.
  @override
  Bip32PrivateKey get privateKey {
    if (isPublicOnly) {
      throw const Bip32KeyError(
        'Public-only deterministic keys have no private half',
      );
    }
    return _privKey!;
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

    final keyBytes = deserKey.keyBytes;
    final Bip32KeyData keyData = deserKey.keyData;
    final isPublic = deserKey.isPublic;

    if (keyData.depth.depth == 0) {
      if (!keyData.fingerPrint.isMasterKey()) {
        throw Bip32KeyError('Invalid extended master fingerPrint.');
      }
      if (keyData.index.index != 0) {
        throw Bip32KeyError('Invalid extended master child index.');
      }
    }
    _privKey = _initializePrivateKey(
      isPublic ? null : keyBytes,
      isPublic ? keyBytes : null,
      keyData,
      keyNetVer,
      curveType,
    );
    _pubKey = _initializePublicKey(
      isPublic ? null : keyBytes,
      isPublic ? keyBytes : null,
      keyData,
      keyNetVer,
      curveType,
    );
  }

  /// Creates a BIP-32 key from an extended key bytese.
  Bip32Base.fromExtendedPrivateKeyBytes(
    List<int> key, [
    Bip32KeyNetVersions? keyNetVer,
  ]) {
    keyNetVer ??= defaultKeyNetVersion;
    final deserKey = Bip32KeyDeserializer.deserializeKeyBytesWithoutPrefix(key);
    final keyBytes = deserKey.keyBytes;
    final Bip32KeyData keyData = deserKey.keyData;
    assert(!deserKey.isPublic);
    if (keyData.depth.depth == 0) {
      if (!keyData.fingerPrint.isMasterKey()) {
        throw Bip32KeyError('Invalid extended master fingerPrint.');
      }
      if (keyData.index.index != 0) {
        throw Bip32KeyError('Invalid extended master child index.');
      }
    }
    _privKey = _initializePrivateKey(
      keyBytes,
      null,
      keyData,
      keyNetVer,
      curveType,
    );
    _pubKey = _initializePublicKey(
      keyBytes,
      null,
      keyData,
      keyNetVer,
      curveType,
    );
  }

  // /// Creates a BIP-32 key from an extended key bytese exclude prefix.
  // Bip32Base.fromExtendedPrivateKeyBytes(List<int> key) {
  //   final deserKey = Bip32KeyDeserializer.deserializeKeyBytes(
  //     key,
  //     keyNetVer: keyNetVer,
  //   );

  //   final keyBytes = deserKey.keyBytes;
  //   final Bip32KeyData keyData = deserKey.keyData;
  //   final isPublic = deserKey.isPublic;

  //   if (keyData.depth.depth == 0) {
  //     if (!keyData.fingerPrint.isMasterKey()) {
  //       throw Bip32KeyError('Invalid extended master fingerPrint.');
  //     }
  //     if (keyData.index.index != 0) {
  //       throw Bip32KeyError('Invalid extended master child index.');
  //     }
  //   }
  //   _privKey = _initializePrivateKey(
  //     isPublic ? null : keyBytes,
  //     isPublic ? keyBytes : null,
  //     keyData,
  //     keyNetVer,
  //     curveType,
  //   );
  //   _pubKey = _initializePublicKey(
  //     isPublic ? null : keyBytes,
  //     isPublic ? keyBytes : null,
  //     keyData,
  //     keyNetVer,
  //     curveType,
  //   );
  // }

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
      curveType,
    );
    _pubKey = _initializePublicKey(
      result.key,
      null,
      keyData,
      keyNetVer,
      curveType,
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
    _privKey = _initializePrivateKey(
      privKey,
      null,
      keyData,
      keyNetVer,
      curveType,
    );
    _pubKey = _initializePublicKey(
      privKey,
      null,
      keyData,
      keyNetVer,
      curveType,
    );
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
    _privKey = _initializePrivateKey(
      null,
      pubKey,
      keyData,
      keyNetVer,
      curveType,
    );
    _pubKey = _initializePublicKey(null, pubKey, keyData, keyNetVer, curveType);
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
    _privKey = _initializePrivateKey(
      privKey,
      pubKey,
      keyData,
      keyNetVer,
      curveType,
    );
    _pubKey = _initializePublicKey(
      privKey,
      pubKey,
      keyData,
      keyNetVer,
      curveType,
    );
  }

  /// Derives a new BIP-32 key using a derivation path.
  ///
  /// The [path] parameter represents the derivation path, such as "m/0/1/2".
  BIP derivePath(String path) {
    final pathInstance = Bip32PathParser.parse(path);

    if (depth.depth > 0 && pathInstance.isAbsolute) {
      throw ArgumentException.invalidOperationArguments(
        "derivePath",
        name: "path",
        reason:
            'Absolute paths can only be derived from a master key, not child ones',
      );
    }
    BIP derivedObject = this as BIP;

    for (final pathElement in pathInstance.elems) {
      derivedObject = derivedObject.childKey(pathElement);
    }
    return derivedObject;
  }

  /// Derives a child BIP-32 key from the current key.
  BIP childKey(Bip32KeyIndex index);

  /// Converts this BIP-32 key to a public-only key.
  void convertToPublic() {
    _privKey = null;
  }

  /// Checks if this key is public-only.
  bool get isPublicOnly {
    return _privKey == null;
  }

  /// Gets the key network versions.
  Bip32KeyNetVersions get keyNetVersions {
    return _pubKey.keyNetVer;
  }

  /// Gets the current depth of this key.
  Bip32Depth get depth {
    return _pubKey.keyData.depth;
  }

  /// Gets the current index of this key.
  Bip32KeyIndex get index {
    return _pubKey.keyData.index;
  }

  /// Gets the chain code associated with this key.
  Bip32ChainCode get chainCode {
    return _pubKey.keyData.chainCode;
  }

  /// Get public key fingerprint.
  Bip32FingerPrint get fingerPrint {
    return _pubKey.fingerPrint;
  }

  /// Gets the parent fingerprint of this key.
  Bip32FingerPrint get parentFingerPrint {
    return _pubKey.keyData.fingerPrint;
  }

  /// Checks if public derivation is supported for this key.
  bool get isPublicDerivationSupported {
    return keyDerivator.isPublicDerivationSupported();
  }

  /// Initializes a private key if [privKey] is provided, otherwise returns null.
  static Bip32PrivateKey? _initializePrivateKey(
    List<int>? privKey,
    List<int>? pubKey,
    Bip32KeyData keyData,
    Bip32KeyNetVersions keyNetVer,
    EllipticCurveTypes curve,
  ) {
    if (privKey != null) {
      return Bip32PrivateKey.fromBytes(privKey, keyData, keyNetVer, curve);
    }
    return null;
  }

  /// Initializes a public key based on [privKey] or [pubKey].
  static Bip32PublicKey _initializePublicKey(
    List<int>? privKey,
    List<int>? pubKey,
    Bip32KeyData keyData,
    Bip32KeyNetVersions keyNetVer,
    EllipticCurveTypes curve,
  ) {
    if (privKey != null) {
      final bip32PrivateKey = Bip32PrivateKey.fromBytes(
        privKey,
        keyData,
        keyNetVer,
        curve,
      );
      return bip32PrivateKey.publicKey;
    } else {
      return Bip32PublicKey.fromBytes(pubKey!, keyData, keyNetVer, curve);
    }
  }

  /// Gets the elliptic curve type for this key.
  EllipticCurveTypes get curveType;

  /// Gets the default key network version.
  Bip32KeyNetVersions get defaultKeyNetVersion;

  /// Gets the key derivator for this key.
  IBip32ChildKeyDerivator get keyDerivator;

  /// Gets the master key generator for this key.
  IBip32MstKeyGenerator get masterKeyGenerator;
}
