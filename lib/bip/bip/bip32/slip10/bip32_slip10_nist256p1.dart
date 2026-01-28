import 'package:blockchain_utils/bip/bip/bip32/base/bip32_base.dart';
import 'package:blockchain_utils/bip/bip/bip32/bip32_const.dart';
import 'package:blockchain_utils/bip/bip/bip32/bip32_ex.dart';
import 'package:blockchain_utils/bip/bip/bip32/bip32_key_data.dart';
import 'package:blockchain_utils/bip/bip/bip32/bip32_key_net_ver.dart';
import 'package:blockchain_utils/bip/bip/bip32/slip10/bip32_slip10_mst_key_generator.dart';
import 'package:blockchain_utils/bip/ecc/curve/elliptic_curve_types.dart';

import 'bip32_slip10_key_derivator.dart';

/// Represents a Bip32Slip10Nist256p1 hierarchical deterministic key for NIST256P1 curve.
class Bip32Slip10Nist256p1 extends Bip32Base<Bip32Slip10Nist256p1> {
  Bip32Slip10Nist256p1._({
    required super.keyData,
    required super.keyNetVer,
    required super.privKey,
    required super.pubKey,
  });

  /// constructor for creating a key from a seed.
  Bip32Slip10Nist256p1.fromSeed(super.seedBytes, [super.keyNetVer])
    : super.fromSeed();

  /// constructor for creating a key from an extended key string.
  Bip32Slip10Nist256p1.fromExtendedKey(super.exKeyStr, [super.keyNetVer])
    : super.fromExtendedKey();

  /// constructor for creating a key from a private key.
  Bip32Slip10Nist256p1.fromPrivateKey(
    List<int> privKey, {
    Bip32KeyData? keyData,
    Bip32KeyNetVersions? keyNetVer,
  }) : super.fromPrivateKey(privKey, keyData, keyNetVer);

  /// constructor for creating a key from a public key.
  Bip32Slip10Nist256p1.fromPublicKey(
    List<int> pubkey, {
    Bip32KeyData? keyData,
    Bip32KeyNetVersions? keyNetVer,
  }) : super.fromPublicKey(pubkey, keyData, keyNetVer);

  /// Derives a child key from the current key, based on the provided index.
  ///
  /// This method derives a child key from the current key, either privately
  /// or publicly, depending on the input and key type. If the current key is
  /// private, it can derive both private and public child keys. If the current
  /// key is public, it can only derive public child keys.
  ///
  /// - [index]: The index used to derive the child key.
  ///
  /// If the current key is private:
  ///   - For non-hardened derivation, this method can derive both private and
  ///     public child keys.
  ///   - For hardened derivation, it can only derive private child keys.
  ///
  /// Returns a new key instance representing the derived child key. If public
  /// derivation is not supported or if there's an issue with the derivation
  /// process, an error is thrown.
  @override
  Bip32Slip10Nist256p1 childKey(Bip32KeyIndex index) {
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

      return Bip32Slip10Nist256p1._(
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
    return Bip32Slip10Nist256p1._(
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

  /// Returns the curve type, NIST256P1.
  @override
  EllipticCurveTypes get curveType {
    return EllipticCurveTypes.nist256p1;
  }

  /// Returns the default key network versions network.
  @override
  Bip32KeyNetVersions get defaultKeyNetVersion {
    return Bip32Const.mainNetKeyNetVersions;
  }

  /// Returns the key derivator for NIST256P1.
  @override
  Bip32Slip10EcdsaDerivator get keyDerivator {
    return Bip32Slip10EcdsaDerivator();
  }

  /// Returns the master key generator for NIST256P1.
  @override
  Bip32Slip10Nist256p1MstKeyGenerator get masterKeyGenerator {
    return Bip32Slip10Nist256p1MstKeyGenerator();
  }
}
