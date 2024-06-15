import 'package:blockchain_utils/bip/bip/bip32/bip32_key_ser.dart';
import 'package:blockchain_utils/bip/ecc/keys/i_keys.dart';
import 'package:blockchain_utils/bip/ecc/curve/elliptic_curve_types.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/point/base.dart';
import 'bip32_key_data.dart';
import 'bip32_key_net_ver.dart';

/// An abstract base class for BIP32 keys. It provides common properties and methods
/// for BIP32 keys, including the elliptic curve type, key data, and key network versions.
abstract class Bip32KeyBase {
  final EllipticCurveTypes curveType;
  final Bip32KeyData keyData;
  final Bip32KeyNetVersions keyNetVer;

  /// Creates a Bip32KeyBase instance with the specified key data, key network versions,
  /// and elliptic curve type.
  const Bip32KeyBase(this.keyData, this.keyNetVer, this.curveType);

  /// Gets the chain code associated with the BIP32 key.
  Bip32ChainCode get chainCode {
    return keyData.chainCode;
  }

  /// Gets the extended representation of the BIP32 key.
  String get toExtended;

  String toHex({bool lowerCase = true, String? prefix = ""});
}

/// Represents a BIP32 public key with associated data such as the elliptic curve type,
/// key data, and key network versions.
class Bip32PublicKey extends Bip32KeyBase {
  final IPublicKey pubKey;

  /// Creates a Bip32PublicKey instance with the provided public key, key data, and key network versions.
  Bip32PublicKey(
    this.pubKey,
    Bip32KeyData keyData,
    Bip32KeyNetVersions keyNetVer,
  ) : super(keyData, keyNetVer, pubKey.curve);

  /// Gets the underlying public key.
  IPublicKey get key {
    return pubKey;
  }

  /// Gets the compressed representation of the public key.
  List<int> get compressed {
    return pubKey.compressed;
  }

  /// Gets the uncompressed representation of the public ke
  List<int> get uncompressed {
    return pubKey.uncompressed;
  }

  /// Gets the abstract point representation of the public key.
  AbstractPoint get point {
    return pubKey.point;
  }

  /// Gets the fingerprint of the public key, derived from the key identifier.
  Bip32FingerPrint get fingerPrint {
    return Bip32FingerPrint(keyIdentifier);
  }

  /// Gets the key identifier, which is the hash of the compressed public key.
  List<int> get keyIdentifier {
    return QuickCrypto.hash160(pubKey.compressed);
  }

  /// Gets the extended key of public key.
  @override
  String get toExtended {
    return Bip32PublicKeySerializer.serialize(pubKey, keyData, keyNetVer);
  }

  /// Creates a [Bip32PublicKey] from a byte representation, key data, key network versions, and curve type.
  static Bip32PublicKey fromBytes(
    List<int> keyBytes,
    Bip32KeyData keyData,
    Bip32KeyNetVersions keyNetVer,
    EllipticCurveTypes curveType,
  ) {
    return Bip32PublicKey(
      IPublicKey.fromBytes(keyBytes, curveType),
      keyData,
      keyNetVer,
    );
  }

  @override
  String toHex(
      {bool withPrefix = true, bool lowerCase = true, String? prefix = ""}) {
    return pubKey.toHex(
        lowerCase: lowerCase, prefix: prefix, withPrefix: withPrefix);
  }
}

/// Represents a BIP32 private key with associated data such as the elliptic curve type,
/// key data, and key network versions.
class Bip32PrivateKey extends Bip32KeyBase {
  final IPrivateKey privKey;

  /// Creates a Bip32PrivateKey instance with the provided private key, key data, and key network versions.
  Bip32PrivateKey(
    this.privKey,
    Bip32KeyData keyData,
    Bip32KeyNetVersions keyNetVer,
  ) : super(keyData, keyNetVer, privKey.curveType);

  /// Gets the underlying private key object.
  IPrivateKey keyObject() {
    return privKey;
  }

  /// Gets the raw representation of the private key.
  List<int> get raw {
    return privKey.raw;
  }

  /// Gets the corresponding public key derived from this private key.
  Bip32PublicKey get publicKey {
    return Bip32PublicKey(
      privKey.publicKey,
      keyData,
      keyNetVer,
    );
  }

  /// Gets the extended key of private key.
  @override
  String get toExtended {
    return Bip32PrivateKeySerializer.serialize(privKey, keyData, keyNetVer);
  }

  /// Creates a Bip32PrivateKey from a byte representation, key data, key network versions, and curve type.
  static Bip32PrivateKey fromBytes(
    List<int> keyBytes,
    Bip32KeyData keyData,
    Bip32KeyNetVersions keyNetVer,
    EllipticCurveTypes curveType,
  ) {
    return Bip32PrivateKey(
        IPrivateKey.fromBytes(keyBytes, curveType), keyData, keyNetVer);
  }

  @override
  String toHex({bool lowerCase = true, String? prefix = ""}) {
    return privKey.toHex(lowerCase: lowerCase, prefix: prefix);
  }
}
