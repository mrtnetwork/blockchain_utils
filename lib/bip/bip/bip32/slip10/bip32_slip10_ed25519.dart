import 'package:blockchain_utils/bip/bip/bip32/base/bip32_base.dart';
import 'package:blockchain_utils/bip/bip/bip32/base/ibip32_key_derivator.dart';
import 'package:blockchain_utils/bip/bip/bip32/base/ibip32_mst_key_generator.dart';
import 'package:blockchain_utils/bip/bip/bip32/bip32_const.dart';
import 'package:blockchain_utils/bip/bip/bip32/bip32_ex.dart';
import 'package:blockchain_utils/bip/bip/bip32/bip32_key_data.dart';
import 'package:blockchain_utils/bip/bip/bip32/bip32_key_net_ver.dart';
import 'package:blockchain_utils/bip/bip/bip32/slip10/bip32_slip10_ed25519_blake2b.dart';
import 'package:blockchain_utils/bip/bip/bip32/slip10/bip32_slip10_key_derivator.dart';
import 'package:blockchain_utils/bip/bip/bip32/slip10/bip32_slip10_mst_key_generator.dart';
import 'package:blockchain_utils/bip/ecc/curve/elliptic_curve_types.dart';

/// Represents a Bip32Slip10Ed25519 hierarchical deterministic key for Ed25519 curve.
///
/// This class extends the [Bip32Base] class and provides functionality for
/// working with Bip32Slip10Ed25519 keys. It is used for key derivation and
/// management within the Ed25519 curve.
///
/// Constructors:
/// - [Bip32Slip10Ed25519] constructor for creating an instance with provided key data.
/// - [Bip32Slip10Ed25519.fromSeed] constructor for creating a key from a seed.
/// - [Bip32Slip10Ed25519.fromPrivateKey] constructor for creating a key from a private key.
/// - [Bip32Slip10Ed25519.fromPublicKey] constructor for creating a key from a public key.
/// - [Bip32Slip10Ed25519.fromExtendedKey] constructor for creating a key from an extended key string.
///
/// This class is specific to the Ed25519 curve and provides necessary methods for
/// working with this curve, such as key derivation and management.
class Bip32Slip10Ed25519 extends Bip32Base {
  /// constructor for creating an instance with provided key data.
  Bip32Slip10Ed25519(
      {required super.keyData,
      required super.keyNetVer,
      required super.privKey,
      required super.pubKey});

  /// constructor for creating a key from a seed.
  Bip32Slip10Ed25519.fromSeed(super.seedBytes, [super.keyNetVer])
      : super.fromSeed();

  /// constructor for creating a key from a private key.
  Bip32Slip10Ed25519.fromPrivateKey(List<int> privKey,
      {Bip32KeyData? keyData, Bip32KeyNetVersions? keyNetVer})
      : super.fromPrivateKey(privKey, keyData, keyNetVer);

  /// constructor for creating a key from a public key.
  Bip32Slip10Ed25519.fromPublicKey(List<int> pubkey,
      {Bip32KeyData? keyData, Bip32KeyNetVersions? keyNetVer})
      : super.fromPublicKey(pubkey, keyData, keyNetVer);

  /// constructor for creating a key from an extended key string.
  Bip32Slip10Ed25519.fromExtendedKey(super.exKeyStr, [super.keyNetVer])
      : super.fromExtendedKey();

  /// Derives a child key from the current key, based on the provided index.
  ///
  /// This method derives a child key from the current key, either privately
  /// or publicly, depending on the input and key type. If the current key is
  /// private, it can derive both private and public child keys. If the current
  /// key is public, it can only derive public child keys.
  /// For [Bip32Slip10Ed25519Derivator] derivator, it can only derive private child keys.
  ///
  /// - [index]: The index used to derive the child key.
  ///
  /// If the current key is private:
  ///   - For non-hardened derivation, this method can derive both private and
  ///     public child keys.
  ///
  /// Returns a new key instance representing the derived child key. If public
  /// derivation is not supported or if there's an issue with the derivation
  /// process, an error is thrown.
  @override
  Bip32Slip10Ed25519 childKey(Bip32KeyIndex index) {
    final isPublic = isPublicOnly;

    if (!isPublic) {
      if (!index.isHardened && !isPublicDerivationSupported) {
        throw const Bip32KeyError(
            'Private child derivation with not-hardened index is not supported');
      }
      assert(!isPublicOnly);
      final result =
          keyDerivator.ckdPriv(privateKey, publicKey, index, curveType);

      if (curveType == EllipticCurveTypes.ed25519Blake2b) {
        return Bip32Slip10Ed25519Blake2b(
            keyData: Bip32KeyData(
              chainCode: Bip32ChainCode(result.item2),
              depth: depth.increase(),
              index: index,
              parentFingerPrint: fingerPrint,
            ),
            keyNetVer: keyNetVersions,
            privKey: result.item1,
            pubKey: null);
      }

      return Bip32Slip10Ed25519(
          keyData: Bip32KeyData(
            chainCode: Bip32ChainCode(result.item2),
            depth: depth.increase(),
            index: index,
            parentFingerPrint: fingerPrint,
          ),
          keyNetVer: keyNetVersions,
          privKey: result.item1,
          pubKey: null);
    }
    throw const Bip32KeyError('Public child derivation is not supported');
  }

  /// Returns the curve type, ED25519.
  @override
  EllipticCurveTypes get curveType {
    return EllipticCurveTypes.ed25519;
  }

  /// Returns the default key network versions network.
  ///
  /// This method returns the default key network versions,
  /// which are used when creating keys.
  @override
  Bip32KeyNetVersions get defaultKeyNetVersion {
    return Bip32Const.mainNetKeyNetVersions;
  }

  /// Returns the key derivator for Ed25519.
  ///
  /// This method returns an instance of the [Bip32Slip10Ed25519Derivator]
  /// class, which is used for key derivation within the Ed25519 curve.
  @override
  IBip32KeyDerivator get keyDerivator {
    return Bip32Slip10Ed25519Derivator();
  }

  /// Returns the master key generator for Ed25519.
  ///
  /// This method returns an instance of the [Bip32Slip10Ed25519MstKeyGenerator]
  /// class, which is used for generating the master key within the Ed25519 curve.
  @override
  IBip32MstKeyGenerator get masterKeyGenerator {
    return Bip32Slip10Ed25519MstKeyGenerator();
  }
}
