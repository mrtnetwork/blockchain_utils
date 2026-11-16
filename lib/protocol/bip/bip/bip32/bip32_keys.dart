import 'package:blockchain_utils/protocol/bip/bip/bip32/bip32_key_ser.dart';
import 'package:blockchain_utils/protocol/hd_key/types.dart';
import 'package:blockchain_utils/crypto/crypto/keys/types/types.dart';
import 'package:blockchain_utils/crypto/crypto/keys/core/i_keys.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';
import 'package:blockchain_utils/protocol/bip/bip/bip32/bip32_key_data.dart';
import 'package:blockchain_utils/protocol/bip/bip/bip32/bip32_key_net_ver.dart';

abstract class Bip32KeyBase extends CryptoKeyBase<Bip32KeyData> {
  const Bip32KeyBase(super.keyData, this.type);
  final CryptoKeyType type;
  String get toExtended;
  BuBytes toExtendedBytes({bool withPrefix = true});
}

/// Represents a BIP32 public key with associated data such as the elliptic curve type,
/// key data, and key network versions.
class Bip32PublicKey extends Bip32KeyBase {
  final IPublicKey pubKey;
  final Bip32KeyNetVersions keyNetVer;

  /// Creates a Bip32PublicKey instance with the provided public key, key data, and key network versions.
  Bip32PublicKey(this.pubKey, Bip32KeyData keyData, this.keyNetVer)
    : super(keyData, pubKey.type);

  /// Gets the underlying public key.
  IPublicKey get key {
    return pubKey;
  }

  /// Gets the fingerprint of the public key, derived from the key identifier.
  Bip32FingerPrint get fingerPrint {
    return Bip32FingerPrint(keyIdentifier);
  }

  /// Gets the key identifier, which is the hash of the compressed public key.
  BuBytes get keyIdentifier {
    return QuickCrypto.hash160(
      Bip32PublicKeySerializer.serializePublicKey(pubKey),
    );
  }

  /// Gets the extended key of public key.
  @override
  String get toExtended {
    return Bip32PublicKeySerializer.serialize(pubKey, keyData, keyNetVer);
  }

  ChainCode get chainCode => keyData.chainCode;

  @override
  BuBytes toExtendedBytes({bool withPrefix = true}) =>
      Bip32PublicKeySerializer.serializeBytes(
        pubKey: pubKey,
        keyData: keyData,
        withPrefix: withPrefix,
        keyNetVer: keyNetVer,
      );

  /// Creates a [Bip32PublicKey] from a byte representation, key data, key network versions, and curve type.
  static Bip32PublicKey fromBytes(
    List<int> keyBytes,
    Bip32KeyData keyData,
    Bip32KeyNetVersions keyNetVer,
    CryptoKeyType curveType,
  ) {
    return Bip32PublicKey(
      IPublicKey.fromBytes(keyBytes, curveType),
      keyData,
      keyNetVer,
    );
  }

  BuBytes toPublicKeyBytes({CryptoKeyEncoding mode = CryptoKeyEncoding.base}) =>
      pubKey.toBytes(mode: mode);

  BuBytes toBip32PublicKeyBytes({
    CryptoKeyEncoding mode = CryptoKeyEncoding.base,
  }) {
    return Bip32PublicKeySerializer.serializePublicKey(pubKey, mode: mode);
  }
}

/// Represents a BIP32 private key with associated data such as the elliptic curve type,
/// key data, and key network versions.
class Bip32PrivateKey extends Bip32KeyBase with SecretState {
  final IPrivateKey privKey;
  final Bip32KeyNetVersions keyNetVer;

  /// Creates a Bip32PrivateKey instance with the provided private key, key data, and key network versions.
  Bip32PrivateKey(this.privKey, Bip32KeyData keyData, this.keyNetVer)
    : super(keyData, privKey.type);

  /// Gets the underlying private key object.
  IPrivateKey keyObject() {
    return privKey;
  }

  /// Gets the raw representation of the private key.
  SecretBytes toBytes({SecretTransform? transform}) {
    return privKey.toBytes(transform: transform);
  }

  /// Gets the corresponding public key derived from this private key.
  Bip32PublicKey get publicKey {
    return Bip32PublicKey(privKey.publicKey, keyData, keyNetVer);
  }

  /// Gets the extended key of private key.
  @override
  String get toExtended {
    return Bip32PrivateKeySerializer.serialize(privKey, keyData, keyNetVer);
  }

  @override
  BuBytes toExtendedBytes({bool withPrefix = true}) =>
      Bip32PrivateKeySerializer.serializeBytes(
        privKey: privKey,
        keyData: keyData,
        keyNetVer: keyNetVer,
        withPrefix: withPrefix,
      );

  /// Creates a Bip32PrivateKey from a byte representation, key data, key network versions, and curve type.
  static Bip32PrivateKey fromBytes(
    List<int> keyBytes,
    Bip32KeyData keyData,
    Bip32KeyNetVersions keyNetVer,
    CryptoKeyType curveType,
  ) {
    return Bip32PrivateKey(
      IPrivateKey.fromBytes(keyBytes, curveType),
      keyData,
      keyNetVer,
    );
  }

  @override
  void dispose() {
    privKey.dispose();
  }
}
