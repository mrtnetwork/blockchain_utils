import 'package:blockchain_utils/bip/bip/bip32/base/bip32_base.dart';
import 'package:blockchain_utils/bip/bip/bip32/base/ibip32_key_derivator.dart';
import 'package:blockchain_utils/bip/bip/bip32/base/ibip32_mst_key_generator.dart';
import 'package:blockchain_utils/bip/bip/bip32/bip32_const.dart';
import 'package:blockchain_utils/bip/bip/bip32/bip32_ex.dart';
import 'package:blockchain_utils/bip/bip/bip32/bip32_key_data.dart';
import 'package:blockchain_utils/bip/bip/bip32/bip32_key_net_ver.dart';
import 'package:blockchain_utils/bip/bip/bip32/khalow/bip32_kholaw_ed25519_key_derivator.dart';
import 'package:blockchain_utils/bip/cardano/bip32/cardano_icarus_mst_key_generator.dart';

import 'package:blockchain_utils/bip/ecc/curve/elliptic_curve_types.dart';

/// This class provides a foundation for managing hierarchical deterministic keys
/// according to the cardano Icarus BIP-32. It includes methods and properties for
/// working with extended keys, deriving child keys, and conversion between
/// public and private keys.
/// Constructors:
/// - [CardanoIcarusBip32._]: A private constructor used to create an instance with specified key data, network versions, private key, and public key.
/// - [CardanoIcarusBip32.fromPrivateKey]: Creates a Bip32 key pair from a private key.
/// - [CardanoIcarusBip32.fromExtendedKey]: Creates a Bip32 key pair from an extended key.
/// - [CardanoIcarusBip32.fromSeed]: Creates a Bip32 key pair from a seed.
/// - [CardanoIcarusBip32.fromPublicKey]: Creates a Bip32 key pair from a public key.
class CardanoIcarusBip32 extends Bip32Base {
  /// Private constructor for creating an instance with specified parameters.
  CardanoIcarusBip32._(
      {required super.privKey,
      required super.pubKey,
      required super.keyData,
      required super.keyNetVer});

  /// Creates a [CardanoIcarusBip32] instance from a private key.
  CardanoIcarusBip32.fromPrivateKey(List<int> privKey,
      {Bip32KeyData? keyData, Bip32KeyNetVersions? keyNetVer})
      : super.fromPrivateKey(privKey, keyData, keyNetVer);

  /// Creates a [CardanoIcarusBip32] instance from a extended key.
  CardanoIcarusBip32.fromExtendedKey(super.exKeyStr, [super.keyNetVer])
      : super.fromExtendedKey();

  /// Creates a [CardanoIcarusBip32] instance from a public key.
  CardanoIcarusBip32.fromPublicKey(List<int> pubkey,
      {Bip32KeyData? keyData, Bip32KeyNetVersions? keyNetVer})
      : super.fromPublicKey(pubkey, keyData, keyNetVer);

  /// Creates a [CardanoIcarusBip32] instance from a seed.
  CardanoIcarusBip32.fromSeed(super.seedBytes, [super.keyNetVer])
      : super.fromSeed();

  /// Generates a child key based on the given [index].
  ///
  /// This method derives a child key from the current Bip32 key.
  /// It can be either a private or public child derivation based on the current key type.
  ///
  /// Parameters:
  /// - [index]: The index of the child key to generate.
  ///
  /// Returns:
  /// - A new [CardanoIcarusBip32] instance representing the child key.
  ///
  /// Throws:
  /// - [Bip32KeyError]: If private child derivation with a non-hardened index is not supported.
  ///
  /// Note: This method is used to create child keys from the current key, both for private and public keys,
  /// and is determined by the key type (public or private).
  @override
  CardanoIcarusBip32 childKey(Bip32KeyIndex index) {
    final isPublic = isPublicOnly;

    if (!isPublic) {
      if (!index.isHardened && !isPublicDerivationSupported) {
        throw const Bip32KeyError(
            'Private child derivation with not-hardened index is not supported');
      }
      assert(!isPublicOnly);
      final result =
          keyDerivator.ckdPriv(privateKey, publicKey, index, curveType);

      return CardanoIcarusBip32._(
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

    // Check if supported
    if (!isPublicDerivationSupported) {
      throw const Bip32KeyError('Public child derivation is not supported');
    }
    if (index.isHardened) {
      throw const Bip32KeyError(
          "Public child derivation cannot be used to create an hardened child key");
    }
    final result = keyDerivator.ckdPub(publicKey, index, curveType);
    return CardanoIcarusBip32._(
        keyData: Bip32KeyData(
          chainCode: Bip32ChainCode(result.item2),
          depth: depth.increase(),
          index: index,
          parentFingerPrint: fingerPrint,
        ),
        keyNetVer: keyNetVersions,
        privKey: null,
        pubKey: result.item1);
  }

  /// Returns the elliptic curve type associated with this Bip32 key.
  ///
  /// This getter returns the elliptic curve type,
  /// which is always [EllipticCurveTypes.ed25519Kholaw] for [CardanoIcarusBip32] keys.
  @override
  EllipticCurveTypes get curveType {
    return EllipticCurveTypes.ed25519Kholaw;
  }

  /// Returns the default Bip32 key network versions.
  ///
  /// This getter returns the default network versions for [CardanoIcarusBip32] keys.
  @override
  Bip32KeyNetVersions get defaultKeyNetVersion {
    return Bip32Const.kholawKeyNetVersions;
  }

  /// Returns the key derivator used for [CardanoIcarusBip32] keys.
  ///
  /// This getter returns an instance of [Bip32KholawEd25519KeyDerivator] as the key derivator for this key type.
  @override
  IBip32KeyDerivator get keyDerivator {
    return Bip32KholawEd25519KeyDerivator();
  }

  /// Returns the master key generator used for [CardanoIcarusBip32] keys.
  ///
  /// This getter returns an instance of [CardanoIcarusMstKeyGenerator] as the master key generator for this key type.
  @override
  IBip32MstKeyGenerator get masterKeyGenerator {
    return CardanoIcarusMstKeyGenerator();
  }
}
