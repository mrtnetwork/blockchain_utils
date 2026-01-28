import 'package:blockchain_utils/bip/bip/bip32/base/bip32_base.dart';
import 'package:blockchain_utils/bip/bip/bip32/base/derivator.dart';
import 'package:blockchain_utils/bip/bip/bip32/bip32_const.dart';
import 'package:blockchain_utils/bip/bip/bip32/bip32_ex.dart';
import 'package:blockchain_utils/bip/bip/bip32/bip32_key_data.dart';
import 'package:blockchain_utils/bip/bip/bip32/bip32_key_net_ver.dart';
import 'package:blockchain_utils/bip/bip/bip32/slip10/bip32_slip10_key_derivator.dart';
import 'package:blockchain_utils/bip/bip/bip32/slip10/bip32_slip10_mst_key_generator.dart';
import 'package:blockchain_utils/bip/ecc/curve/elliptic_curve_types.dart';

/// Represents a Bip32Slip10Ed25519Blake2b hierarchical deterministic key for Ed25519-Blake2b curve.
class Bip32Slip10Ed25519Blake2b extends Bip32Base<Bip32Slip10Ed25519Blake2b> {
  /// constructor for creating an instance with provided key data.
  Bip32Slip10Ed25519Blake2b({
    required super.keyData,
    required super.keyNetVer,
    required super.privKey,
    required super.pubKey,
  });

  /// constructor for creating a key from a seed.
  Bip32Slip10Ed25519Blake2b.fromSeed(super.seedBytes, [super.keyNetVer])
    : super.fromSeed();

  /// constructor for creating a key from a private key.
  Bip32Slip10Ed25519Blake2b.fromPrivateKey(
    List<int> privKey, {
    Bip32KeyData? keyData,
    Bip32KeyNetVersions? keyNetVer,
  }) : super.fromPrivateKey(privKey, keyData, keyNetVer);

  /// constructor for creating a key from a public key.
  Bip32Slip10Ed25519Blake2b.fromPublicKey(
    List<int> pubkey, {
    Bip32KeyData? keyData,
    Bip32KeyNetVersions? keyNetVer,
  }) : super.fromPublicKey(pubkey, keyData, keyNetVer);

  /// constructor for creating a key from an extended key string.
  Bip32Slip10Ed25519Blake2b.fromExtendedKey(super.exKeyStr, [super.keyNetVer])
    : super.fromExtendedKey();

  /// Returns the curve type Ed25519-blake2b.
  @override
  EllipticCurveTypes get curveType {
    return EllipticCurveTypes.ed25519Blake2b;
  }

  @override
  Bip32Slip10Ed25519Blake2b childKey(Bip32KeyIndex index) {
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

      return Bip32Slip10Ed25519Blake2b(
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
    throw Bip32KeyError.publicDerivationNotSupported;
  }

  /// Returns the default key network versions network.
  @override
  Bip32KeyNetVersions get defaultKeyNetVersion {
    return Bip32Const.mainNetKeyNetVersions;
  }

  /// Returns the key derivator for Ed25519.
  @override
  Bip32Slip10Ed25519Derivator get keyDerivator {
    return Bip32Slip10Ed25519Derivator();
  }

  /// Returns the master key generator for Ed25519.
  @override
  IBip32MstKeyGenerator get masterKeyGenerator {
    return Bip32Slip10Ed25519MstKeyGenerator();
  }
}
