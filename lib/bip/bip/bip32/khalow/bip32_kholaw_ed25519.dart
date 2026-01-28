import 'package:blockchain_utils/bip/bip/bip32/base/bip32_base.dart';
import 'package:blockchain_utils/bip/bip/bip32/base/derivator.dart';
import 'package:blockchain_utils/bip/bip/bip32/bip32_const.dart';
import 'package:blockchain_utils/bip/bip/bip32/bip32_ex.dart';
import 'package:blockchain_utils/bip/bip/bip32/bip32_key_data.dart';
import 'package:blockchain_utils/bip/bip/bip32/bip32_key_net_ver.dart';
import 'package:blockchain_utils/bip/bip/bip32/khalow/bip32_kholaw_mst_key_generator.dart';
import 'package:blockchain_utils/bip/ecc/curve/elliptic_curve_types.dart';
import 'bip32_kholaw_ed25519_key_derivator.dart';

/// A class representing Bip32 hierarchical deterministic keys using the Kholaw elliptic curve with Ed25519 keys.
class Bip32KholawEd25519 extends Bip32Base<Bip32KholawEd25519> {
  /// Private constructor for creating an instance with specified parameters.
  Bip32KholawEd25519._({
    required super.keyData,
    required super.keyNetVer,
    required super.privKey,
    required super.pubKey,
  });

  /// Creates a Bip32 key pair from a private key.
  Bip32KholawEd25519.fromPrivateKey(
    List<int> privKey, {
    Bip32KeyData? keyData,
    Bip32KeyNetVersions? keyNetVer,
  }) : super.fromPrivateKey(privKey, keyData, keyNetVer);

  /// Creates a Bip32 key pair from an extended key.
  Bip32KholawEd25519.fromExtendedKey(super.exKeyStr, [super.keyNetVer])
    : super.fromExtendedKey();

  /// Creates a Bip32 key pair from a seed.
  Bip32KholawEd25519.fromSeed(super.seedBytes, [super.keyNetVer])
    : super.fromSeed();

  /// Creates a Bip32 key pair from a public key.
  Bip32KholawEd25519.fromPublicKey(
    List<int> pubkey, {
    Bip32KeyData? keyData,
    Bip32KeyNetVersions? keyNetVer,
  }) : super.fromPublicKey(pubkey, keyData, keyNetVer);

  /// Generates a child key based on the given [index].
  ///
  /// Parameters:
  /// - [index]: The index of the child key to generate.
  ///
  /// Throws:
  /// - [Bip32KeyError]: If private child derivation with a non-hardened index is not supported.
  ///
  @override
  Bip32KholawEd25519 childKey(Bip32KeyIndex index) {
    final isPublic = isPublicOnly;

    if (!isPublic) {
      if (!index.isHardened && !isPublicDerivationSupported) {
        throw Bip32KeyError.notHardenedIndexNotSupported;
      }
      assert(!isPublicOnly);
      final result = keyDerivator.deriveFromSecret(
        parent: privateKey,
        ctx: publicKey,
        index: index,
        type: curveType,
      );

      return Bip32KholawEd25519._(
        keyData: Bip32KeyData(
          chainCode: result.chainCode,
          depth: depth.increase(),
          index: index,
          fingerPrint: fingerPrint,
        ),
        keyNetVer: keyNetVersions,
        privKey: result.key,
        pubKey: null,
      );
    }

    // Check if supported
    if (!isPublicDerivationSupported) {
      throw Bip32KeyError.publicDerivationNotSupported;
    }
    if (index.isHardened) {
      throw Bip32KeyError.publicHardenedIndexNotSupported;
    }
    final result = keyDerivator.deriveFromPublic(
      parent: publicKey,
      index: index,
      type: curveType,
    );
    return Bip32KholawEd25519._(
      keyData: Bip32KeyData(
        chainCode: result.chainCode,
        depth: depth.increase(),
        index: index,
        fingerPrint: fingerPrint,
      ),
      keyNetVer: keyNetVersions,
      privKey: null,
      pubKey: result.key,
    );
  }

  /// Returns the elliptic curve type associated with this Bip32 key.
  @override
  EllipticCurveTypes get curveType {
    return EllipticCurveTypes.ed25519Kholaw;
  }

  /// Returns the default Bip32 key network versions.
  @override
  Bip32KeyNetVersions get defaultKeyNetVersion {
    return Bip32Const.kholawKeyNetVersions;
  }

  /// Returns the key derivator used for Bip32KholawEd25519 keys.
  @override
  IBip32ChildKeyDerivator get keyDerivator {
    return Bip32KholawEd25519KeyDerivator();
  }

  /// Returns the master key generator used for Bip32KholawEd25519 keys.
  @override
  IBip32MstKeyGenerator get masterKeyGenerator {
    return Bip32KholawEd25519MstKeyGenerator();
  }
}
