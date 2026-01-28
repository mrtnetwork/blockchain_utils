import 'package:blockchain_utils/bip/bip/bip32/base/bip32_base.dart';
import 'package:blockchain_utils/bip/bip/bip32/bip32_const.dart';
import 'package:blockchain_utils/bip/bip/bip32/bip32_ex.dart';
import 'package:blockchain_utils/bip/bip/bip32/bip32_key_data.dart';
import 'package:blockchain_utils/bip/bip/bip32/bip32_key_net_ver.dart';
import 'package:blockchain_utils/bip/bip/bip32/bip32_keys.dart';
import 'package:blockchain_utils/bip/bip/bip32/slip10/bip32_slip10_mst_key_generator.dart';
import 'package:blockchain_utils/bip/ecc/curve/elliptic_curve_types.dart';
import 'package:blockchain_utils/bip/ecc/keys/i_keys.dart';

import 'bip32_slip10_key_derivator.dart';

/// Represents a Bip32Slip10Nist256p1Hybrid hierarchical deterministic key for NIST256P1 curve.
class Bip32Slip10Nist256p1Hybrid extends Bip32Base<Bip32Slip10Nist256p1Hybrid> {
  Bip32Slip10Nist256p1Hybrid._({
    required super.keyData,
    required super.keyNetVer,
    required super.privKey,
    required super.pubKey,
  });

  /// constructor for creating a key from a seed.
  Bip32Slip10Nist256p1Hybrid.fromSeed(super.seedBytes, [super.keyNetVer])
    : super.fromSeed();

  /// constructor for creating a key from an extended key string.
  Bip32Slip10Nist256p1Hybrid.fromExtendedKey(super.exKeyStr, [super.keyNetVer])
    : super.fromExtendedKey();

  /// constructor for creating a key from a private key.
  Bip32Slip10Nist256p1Hybrid.fromPrivateKey(
    List<int> privKey, {
    Bip32KeyData? keyData,
    Bip32KeyNetVersions? keyNetVer,
  }) : super.fromPrivateKey(privKey, keyData, keyNetVer);

  /// Derives a child key from the current key, based on the provided index.
  @override
  Bip32Slip10Nist256p1Hybrid childKey(Bip32KeyIndex index) {
    final isPublic = isPublicOnly;
    if (isPublicOnly) {
      throw Bip32KeyError(
        'Nist256p1 Hyprid Derivation without private key is not supported',
      );
    }
    final secpPublicKey = Bip32PublicKey(
      IPrivateKey.fromBytes(
        privateKey.raw,
        EllipticCurveTypes.secp256k1,
      ).publicKey,
      publicKey.keyData,
      publicKey.keyNetVer,
    );
    // final secPP
    if (!isPublic) {
      if (!index.isHardened && !isPublicDerivationSupported) {
        throw Bip32KeyError.notHardenedIndexNotSupported;
      }
      final result = keyDerivator.deriveFromSecret(
        parent: privateKey,
        ctx: secpPublicKey,
        index: index,
        type: EllipticCurveTypes.secp256k1,
      );

      return Bip32Slip10Nist256p1Hybrid._(
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
      parent: secpPublicKey,
      index: index,
      type: EllipticCurveTypes.secp256k1,
    );
    return Bip32Slip10Nist256p1Hybrid._(
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
    return EllipticCurveTypes.nist256p1Hybrid;
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
  Bip32Slip10Secp256k1MstKeyGenerator get masterKeyGenerator {
    return Bip32Slip10Secp256k1MstKeyGenerator();
  }
}
