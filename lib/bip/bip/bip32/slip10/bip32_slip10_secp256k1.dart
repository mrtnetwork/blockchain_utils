import 'package:blockchain_utils/bip/bip/bip32/base/bip32_base.dart';
import 'package:blockchain_utils/bip/bip/bip32/bip32_const.dart';
import 'package:blockchain_utils/bip/bip/bip32/bip32_ex.dart';
import 'package:blockchain_utils/bip/bip/bip32/bip32_key_data.dart';
import 'package:blockchain_utils/bip/bip/bip32/bip32_key_net_ver.dart';
import 'package:blockchain_utils/bip/bip/bip32/slip10/bip32_slip10_key_derivator.dart';
import 'package:blockchain_utils/bip/bip/bip32/slip10/bip32_slip10_mst_key_generator.dart';
import 'package:blockchain_utils/bip/ecc/curve/elliptic_curve_types.dart';

/// Represents a Bip32Slip10Secp256k1 hierarchical deterministic key for SECP256K1 curve.
class Bip32Slip10Secp256k1 extends Bip32Base<Bip32Slip10Secp256k1> {
  /// constructor for creating an instance with provided key data.
  Bip32Slip10Secp256k1._({
    required super.keyData,
    required super.keyNetVer,
    required super.privKey,
    required super.pubKey,
  });

  /// constructor for creating a key from a seed.
  Bip32Slip10Secp256k1.fromSeed(super.seedBytes, [super.keyNetVer])
    : super.fromSeed();

  /// constructor for creating a key from a public key.
  Bip32Slip10Secp256k1.fromPublicKey(
    List<int> pubkey, {
    Bip32KeyData? keyData,
    Bip32KeyNetVersions? keyNetVer,
  }) : super.fromPublicKey(pubkey, keyData, keyNetVer);

  /// constructor for creating a key from a private key.
  Bip32Slip10Secp256k1.fromPrivateKey(
    List<int> privKey, {
    Bip32KeyData? keyData,
    Bip32KeyNetVersions? keyNetVer,
  }) : super.fromPrivateKey(privKey, keyData, keyNetVer);

  /// constructor for creating a key from an extended key string.
  Bip32Slip10Secp256k1.fromExtendedKey(super.exKeyStr, [super.keyNetVer])
    : super.fromExtendedKey();

  /// constructor for creating a key from an extended key bytes exclude prefix.
  Bip32Slip10Secp256k1.fromExtendedPrivateKeyBytes(
    super.exKeyStr, [
    super.keyNetVer,
  ]) : super.fromExtendedPrivateKeyBytes();

  /// Returns the curve type, SECP256K1.
  @override
  EllipticCurveTypes get curveType {
    return EllipticCurveTypes.secp256k1;
  }

  /// Returns the default key network versions network.
  @override
  Bip32KeyNetVersions get defaultKeyNetVersion {
    return Bip32Const.mainNetKeyNetVersions;
  }

  /// Returns the key derivator for SECP256K1.
  @override
  Bip32Slip10EcdsaDerivator get keyDerivator {
    return Bip32Slip10EcdsaDerivator();
  }

  /// Returns the master key generator for SECP256K1.
  @override
  Bip32Slip10Secp256k1MstKeyGenerator get masterKeyGenerator {
    return Bip32Slip10Secp256k1MstKeyGenerator();
  }

  /// Derives a child key from the current key, based on the provided index.
  ///
  /// - [index]: The index used to derive the child key.
  ///
  @override
  Bip32Slip10Secp256k1 childKey(Bip32KeyIndex index) {
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
      return Bip32Slip10Secp256k1._(
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
    return Bip32Slip10Secp256k1._(
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
}
