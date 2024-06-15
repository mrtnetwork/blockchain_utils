import 'package:blockchain_utils/bip/bip/bip32/base/ibip32_key_derivator.dart';
import 'package:blockchain_utils/bip/bip/bip32/bip32_ex.dart';
import 'package:blockchain_utils/bip/bip/bip32/bip32_key_data.dart';
import 'package:blockchain_utils/bip/bip/bip32/bip32_key_net_ver.dart';
import 'package:blockchain_utils/bip/bip/bip32/bip32_key_ser.dart';
import 'package:blockchain_utils/bip/bip/bip32/bip32_keys.dart';
import 'package:blockchain_utils/bip/bip/bip32/bip32_path.dart';

import 'package:blockchain_utils/bip/ecc/curve/elliptic_curve_types.dart';
import 'package:blockchain_utils/exception/exception.dart';

import 'ibip32_mst_key_generator.dart';

/// An abstract base class for BIP-32 hierarchical deterministic key management.
///
/// This class provides a foundation for managing hierarchical deterministic keys
/// according to the BIP-32 standard. It includes methods and properties for
/// working with extended keys, deriving child keys, and conversion between
/// public and private keys.
abstract class Bip32Base {
  late Bip32PrivateKey? _privKey;
  late Bip32PublicKey _pubKey;

  /// Gets the public key of this BIP-32 key.
  Bip32PublicKey get publicKey => _pubKey;

  /// Gets the private key of this BIP-32 key.
  Bip32PrivateKey get privateKey {
    if (isPublicOnly) {
      throw const Bip32KeyError(
          'Public-only deterministic keys have no private half');
    }
    return _privKey!;
  }

  /// Creates a BIP-32 key from an extended key string.
  ///
  /// The [exKeyStr] parameter represents the extended key string, and the
  /// optional [keyNetVer] specifies the key network version.
  Bip32Base.fromExtendedKey(String exKeyStr, [Bip32KeyNetVersions? keyNetVer]) {
    keyNetVer ??= defaultKeyNetVersion;
    final deserKey =
        Bip32KeyDeserializer.deserializeKey(exKeyStr, keyNetVer: keyNetVer);

    final keyBytes = deserKey.keyBytes;
    Bip32KeyData keyData = deserKey.keyData;
    final isPublic = deserKey.isPublic;

    if (keyData.depth.depth == 0) {
      if (!keyData.parentFingerPrint.isMasterKey()) {
        throw Bip32KeyError(
            'Invalid extended master key (wrong fingerprint: ${keyData.parentFingerPrint.toHex()})');
      }
      if (keyData.index.index != 0) {
        throw Bip32KeyError(
            'Invalid extended master key (wrong child index: ${keyData.index.toInt()})');
      }
    }
    _privKey = _initializePrivateKey(isPublic ? null : keyBytes,
        isPublic ? keyBytes : null, keyData, keyNetVer, curveType);
    _pubKey = _initializePublicKey(isPublic ? null : keyBytes,
        isPublic ? keyBytes : null, keyData, keyNetVer, curveType);
  }

  /// Creates a BIP-32 key from a seed.
  ///
  /// The [seedBytes] parameter is used to generate a master key, and the
  /// optional [keyNetVer] specifies the key network version.
  Bip32Base.fromSeed(List<int> seedBytes, [Bip32KeyNetVersions? keyNetVer]) {
    keyNetVer ??= defaultKeyNetVersion;
    final result = masterKeyGenerator.generateFromSeed(seedBytes);
    final keyData = Bip32KeyData(chainCode: Bip32ChainCode(result.item2));
    _privKey = _initializePrivateKey(
        result.item1, null, keyData, keyNetVer, curveType);
    _pubKey =
        _initializePublicKey(result.item1, null, keyData, keyNetVer, curveType);
  }

  /// Creates a BIP-32 key from a private key.
  ///
  /// The [privKey] parameter represents the private key bytes, and the optional
  /// [keyData] and [keyNetVer] parameters specify key data and network versions.
  Bip32Base.fromPrivateKey(List<int> privKey,
      [Bip32KeyData? keyData, Bip32KeyNetVersions? keyNetVer]) {
    keyNetVer ??= defaultKeyNetVersion;
    keyData ??= Bip32KeyData();
    _privKey =
        _initializePrivateKey(privKey, null, keyData, keyNetVer, curveType);
    _pubKey =
        _initializePublicKey(privKey, null, keyData, keyNetVer, curveType);
  }

  /// Creates a BIP-32 key from a public key.
  ///
  /// The [pubKey] parameter represents the public key bytes, and the optional
  /// [keyData] and [keyNetVer] parameters specify key data and network versions.
  Bip32Base.fromPublicKey(List<int> pubKey,
      [Bip32KeyData? keyData, Bip32KeyNetVersions? keyNetVer]) {
    keyNetVer ??= defaultKeyNetVersion;
    keyData ??= Bip32KeyData();
    _privKey =
        _initializePrivateKey(null, pubKey, keyData, keyNetVer, curveType);
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
    _privKey =
        _initializePrivateKey(privKey, pubKey, keyData, keyNetVer, curveType);
    _pubKey =
        _initializePublicKey(privKey, pubKey, keyData, keyNetVer, curveType);
  }

  /// Derives a new BIP-32 key using a derivation path.
  ///
  /// The [path] parameter represents the derivation path, such as "m/0/1/2".
  Bip32Base derivePath(String path) {
    final pathInstance = Bip32PathParser.parse(path);

    if (depth.depth > 0 && pathInstance.isAbsolute) {
      throw const ArgumentException(
          'Absolute paths can only be derived from a master key, not child ones');
    }
    Bip32Base derivedObject = this;

    for (final pathElement in pathInstance.elems) {
      derivedObject = derivedObject.childKey(pathElement);
    }
    return derivedObject;
  }

  /// Derives a child BIP-32 key from the current key.
  Bip32Base childKey(Bip32KeyIndex index);

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
    return _pubKey.chainCode;
  }

  /// Get public key fingerprint.
  Bip32FingerPrint get fingerPrint {
    return _pubKey.fingerPrint;
  }

  /// Gets the parent fingerprint of this key.
  Bip32FingerPrint get parentFingerPrint {
    return _pubKey.keyData.parentFingerPrint;
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
      EllipticCurveTypes curve) {
    if (privKey != null) {
      final prv = Bip32PrivateKey.fromBytes(
        privKey,
        keyData,
        keyNetVer,
        curve,
      );
      return prv;
    }
    return null;
  }

  /// Initializes a public key based on [privKey] or [pubKey].
  static Bip32PublicKey _initializePublicKey(
      List<int>? privKey,
      List<int>? pubKey,
      Bip32KeyData keyData,
      Bip32KeyNetVersions keyNetVer,
      EllipticCurveTypes curve) {
    if (privKey != null) {
      final bip32PrivateKey = Bip32PrivateKey.fromBytes(
        privKey,
        keyData,
        keyNetVer,
        curve,
      );
      return bip32PrivateKey.publicKey;
    } else {
      return Bip32PublicKey.fromBytes(
        pubKey!,
        keyData,
        keyNetVer,
        curve,
      );
    }
  }

  /// Gets the elliptic curve type for this key.
  EllipticCurveTypes get curveType;

  /// Gets the default key network version.
  Bip32KeyNetVersions get defaultKeyNetVersion;

  /// Gets the key derivator for this key.
  IBip32KeyDerivator get keyDerivator;

  /// Gets the master key generator for this key.
  IBip32MstKeyGenerator get masterKeyGenerator;
}
